import gzip
import json
from pathlib import Path
from csv import writer as csv_writer

from threading import Thread

from multiprocessing import Lock
import re


class File:
    def __init__(self, file_path):
        self.file_path = file_path
        self.read_lock = Lock()


    def extract_contents(self) -> bool:
        # open compressed file
        self.compressed_contents = gzip.open(self.file_path, mode='rb')
        # extract contents
        # initialise threads
        no_threads = 100
        threads = []
        for _ in range(no_threads):
            threads.append(Thread(target=self.extract_data))
        for thread in threads:
            thread.start()
        for thread in threads:
            thread.join()

        if self.local_storage.data != []:
            self.local_storage.export_batch()

        return True


    def extract_data(self):
        end_of_file = False
        while not end_of_file:
            try:
                self.read_lock.acquire()
                raw_data = self.compressed_contents.readline()
                self.read_lock.release()
            except (EOFError, StopIteration):
                self.read_lock.release()
                end_of_file = True
                break
            except:
                pass
                self.read_lock.release()
            if not raw_data:
                break
            try:
                decoded = raw_data.decode('utf-8')
                json_data = json.loads(decoded)
                data = self.extract_json_data(json_data)
            except:
                pass
            # if the work is corrupted or has been deleted the function will return None
            # in this case the data should not be appended to the storage
            if data:
                self.local_storage.append_data(data)
            
        self.read_lock.release()

    
    def add_local_storage(self, storage):
        self.local_storage = storage


    def add_remote_storage(self, storage):
        self.remote_storage = storage


class Institution(File):
    def __init__(self, file_path):
        super().__init__(file_path)

    def extract_json_data(self, json_data):
        # store data on the paper in list
        inst_data = []

        inst_id = json_data['id']
        inst_id = int(re.search('[0-9]+', inst_id).group(0))
        inst_name = json_data['display_name']
        inst_country = json_data['country_code']
        inst_type = json_data['type']
        inst_url = json_data['homepage_url']
        works_count = json_data['works_count']
        cited_by_count = json_data['cited_by_count']
        
        try:
            associated_with = [x['id'] for x in json_data['associated_institutions']][:10]
            associated_with = [int(re.search('[0-9]+', x).group(0)) for x in associated_with]
        except Exception as e:
            associated_with = ['','','','','','','','','','']

        if not associated_with:
            associated_with = ['','','','','','','','','','']

        inst_data.extend([inst_id, inst_name, inst_country, inst_type, inst_url, works_count, cited_by_count])
        inst_data.extend(associated_with)

        return inst_data


class Affiliation(File):
    def __init__(self, file_path):
        super().__init__(file_path)


    def extract_data(self):
        end_of_file = False
        while not end_of_file:
            try:
                self.read_lock.acquire()
                raw_data = self.compressed_contents.readline()
                self.read_lock.release()
            except EOFError:
                self.read_lock.release()
                break
            except:
                self.read_lock.release()
                pass
            if not raw_data:
                break
                   
            decoded = raw_data.decode('utf-8')
            json_data = json.loads(decoded)
            data = self.extract_json_data(json_data)
            # if the work is corrupted or has been deleted the function will return None
            # in this case the data should not be appended to the storage
            if data:
                self.local_storage.extend_data(data)
        self.read_lock.release()
    

    def extract_json_data(self, json_data):
        # store data on the paper in list
        affiliation_data = []
        
        paper_id = json_data['id']
        paper_id = int(re.search('[0-9]+', paper_id).group(0))
        pub_year = json_data['publication_year']

        # extract data on authorship
        number_of_authors = len(json_data['authorships'])

        if number_of_authors == 0:
            return None
        else:
            authors = [x for x in json_data['authorships']]
            for author in authors:
                try:
                    author_id = author['author']['id']
                    author_id = int(re.search('[0-9]+', author_id).group(0))
                except:
                    return None

                aff_str = author['raw_affiliation_string']
                aff_inst_id = None
                affiiation_json = author['institutions']
                if affiiation_json:
                    if affiiation_json[0]:
                        try:
                            aff_inst_id = int(re.search('[0-9]+', affiiation_json[0]['id']).group(0))
                        except:
                            aff_str = None
                if not (aff_inst_id==None and aff_str == None):
                    affiliation_data.append([author_id, paper_id, aff_inst_id, aff_str, pub_year])
            
        return affiliation_data
   

class Work(File):
    def __init__(self, file_path):
        super().__init__(file_path)


    def extract_data(self):
        end_of_file = False
        while not end_of_file:
            try:
                self.read_lock.acquire()
                raw_data = self.compressed_contents.readline()
                self.read_lock.release()
            except EOFError:
                self.read_lock.release()
                break
            except:
                self.read_lock.release()
                pass
            if not raw_data:
                break
                   
            decoded = raw_data.decode('utf-8')
            json_data = json.loads(decoded)
            data = self.extract_json_data(json_data)
            # if the work is corrupted or has been deleted the function will return None
            # in this case the data should not be appended to the storage
            if data:
                self.local_storage.extend_data(data)
        self.read_lock.release()
    

    def extract_json_data(self, json_data):
        # store data on the paper in list
        work_data = []

        # extract general data on the paper
        paper_id = json_data['id']
        paper_id = int(re.search('[0-9]+', paper_id).group(0))
        doi = json_data['doi']
        title = json_data['title']
        pub_year = json_data['publication_year']
        work_type = json_data['type']
        journal_id = json_data['host_venue']['id']
        if journal_id:
            journal_id = int(re.search('[0-9]+', journal_id).group(0))
        else:
            journal_id = ''

        citations = json_data['cited_by_count']
        # append general data to export
        work_data.extend([paper_id, doi, title, pub_year, work_type, journal_id, citations])

        # extract data on authorship
        number_of_authors = len(json_data['authorships'])

        try:
            x_concepts = [x['id'] for x in json_data['concepts']][:10]
            x_concepts = [int(re.search('[0-9]+', x).group(0)) for x in x_concepts]
        except Exception as e:
            x_concepts = ['','','','','','','','','','']
        
        if not x_concepts:
            x_concepts = ['','','','','','','','','','']

        dupe_data = []

        if number_of_authors == 0:
            return None
        else:
            authors = [x for x in json_data['authorships']]
            for author in authors:
                dupe_add = work_data.copy()
                try:
                    author_id = author['author']['id']
                    author_id = int(re.search('[0-9]+', author_id).group(0))
                except:
                    return None

                affiliation = author['raw_affiliation_string']
                aff_inst_id = None
                affiiation_json = author['institutions']
                if affiiation_json:
                    if affiiation_json[0]:
                        try:
                            aff_inst_id = int(re.search('[0-9]+', affiiation_json[0]['id']).group(0))
                        except:
                            pass
                if aff_inst_id:
                    affiliation = aff_inst_id

                if author['author_position'] == 'first':
                    first_author = 1
                    middle_author = 0
                    last_author = 0
                elif author['author_position'] == 'middle':
                    first_author = 0
                    middle_author = 1
                    last_author = 0
                elif author['author_position'] == 'last':
                    first_author = 0
                    middle_author = 0
                    last_author = 1
            
                dupe_add.insert(1, author_id)
                dupe_add.insert(2, affiliation)
                dupe_add.extend([first_author, middle_author, last_author])
                dupe_add.extend(x_concepts)
                dupe_data.append(dupe_add)
            
        return dupe_data
        

class Author(File):
    def __init__(self, file_path):
        super().__init__(file_path)


    def extract_json_data(self, json_data):
        # store data on the paper in list
        author_data = []
        author_id = json_data['id']
        author_id = int(re.search('[0-9]+', author_id).group(0))
        author_orcid_id = json_data['orcid']
        if not author_orcid_id:
            author_orcid_id = ''
        else:
            author_orcid_id = author_orcid_id.split('/')[-1]
        author_name = json_data['display_name']
        works_count = json_data['works_count']
        last_inst = json_data['last_known_institution']
        if last_inst:
            last_inst = json_data['last_known_institution']['id']
            last_inst = int(re.search('[0-9]+', last_inst).group(0))
        cited_by_count = json_data['cited_by_count']

        try:
            x_concepts = [x['id'] for x in json_data['x_concepts']][:10]
            x_concepts = [int(re.search('[0-9]+', x).group(0)) for x in x_concepts]
        except Exception as e:
            x_concepts = ['','','','','','','','','','']
        
        if not x_concepts:
            x_concepts = ['','','','','','','','','','']

        author_data.extend([author_id, author_orcid_id, author_name, works_count, cited_by_count])
        author_data.extend(x_concepts)
        return author_data


class Journal(File):
    def __init__(self, file_path):
        super().__init__(file_path)


    def extract_json_data(self, json_data):
        # store data on the paper in list
        journal_data = []
        journal_id = json_data['id']
        journal_id = int(re.search('[0-9]+', journal_id).group(0))
        journal_name = json_data['display_name']

        issn_nums = json_data['issn']
        if issn_nums:
            if len(issn_nums) > 1:
                issn1 = issn_nums[0]
                issn2 = issn_nums[1]
            else:
                issn1 = issn_nums[0]
                issn2 = ''
        else:
            issn1 = ''
            issn2 = ''

        works_count = json_data['works_count']
        cited_by_count = json_data['cited_by_count']

        publisher = json_data['publisher']

        try:
            x_concepts = [x['id'] for x in json_data['x_concepts']][:5]
            x_concepts = [int(re.search('[0-9]+', x).group(0)) for x in x_concepts]
        except Exception as e:
            x_concepts = ['','','','','','','','','','']
        
        if not x_concepts:
            x_concepts = ['','','','','','','','','','']

        journal_data.extend([journal_id, journal_name, issn1, issn2, works_count, cited_by_count, publisher])
        journal_data.extend(x_concepts)
        return journal_data


class Concept(File):
    def __init__(self, file_path):
        super().__init__(file_path)

        #concepts_vars = ['concept_id', 'concept_name', 'description', 'concept_works_count', 'concept_cited_by_count',
        #   'related_concept1', 'related_concept2', 'related_concept3', 'related_concept4', 'related_concept5']

    def extract_json_data(self, json_data):
        # store data on the paper in list
        concept_data = []
        concept_id = json_data['id']
        concept_id = int(re.search('[0-9]+', concept_id).group(0))
        concept_name = json_data['display_name']
        description = json_data['description']

        works_count = json_data['works_count']
        cited_by_count = json_data['cited_by_count']


        try:
            x_concepts = [x['id'] for x in json_data['related_concepts']][:5]
            x_concepts = [int(re.search('[0-9]+', x).group(0)) for x in x_concepts]
        except Exception as e:
            x_concepts = ['','','','','','','','','','']
        
        if not x_concepts:
            x_concepts = ['','','','','','','','','','']

        concept_data.extend([concept_id, concept_name, description, works_count, cited_by_count])
        concept_data.extend(x_concepts)
        return concept_data


class Storage:
    def __init__(self, export_location, extract_config, batch_size = 250_000 ,local=True):
        self.data = []
        self.batch_size = 0
        self.batch_length = batch_size
        self.export_location = Path(export_location)
        self.extract_config = extract_config

        self.lock = Lock()


    def append_data(self, incoming_data):
        self.lock.acquire()
        self.data.append(incoming_data)
        self.batch_size += 1
        if self.batch_size > self.batch_length:
            self.export_batch()
        self.lock.release()

    
    def extend_data(self, incoming_data):
        self.lock.acquire()
        self.data.extend(incoming_data)
        self.batch_size += len(incoming_data)
        if self.batch_size > self.batch_length:
            self.export_batch()
        self.lock.release()


    def init_export_file(self):
        # this step overwrites the original file in this location
        fs = open(self.export_location, 'w', encoding='utf-8', newline='')
        csvw = csv_writer(fs, delimiter=';', quotechar='\"')
        csvw.writerow(self.extract_config)


    def export_batch(self):
        # write to csv or upload to database. maybe both?
        self.export_batch_to_csv()
        # clear the current batch of data from memory
        self.data = []
        self.batch_size = 0
        

    def export_batch_to_csv(self):
        with open(self.export_location, 'a', encoding='utf-8', newline='') as fs:
            csvw = csv_writer(fs, delimiter=';', quotechar='\"')
            csvw.writerows(self.data)
