import csv
from threading import Lock
from threading import Thread
import unicodedata
import re
import time
from pathlib import Path
import numpy as np


from objs import Storage


class Filter:
    def __init__(self, filter_file_loc, filter_var, master_file_loc, master_var, read_batch_size=10_000) -> None:
        self.filter_file_loc = filter_file_loc
        self.filter_var = filter_var
        self.master_file_loc = master_file_loc
        self.master_var = master_var

        self.read_batch_size = read_batch_size
        self.read_lock = Lock()

        # import using data into memory
        self.import_filter_data()

    
    def add_storage(self, storage):
        self.storage = storage


    def import_filter_data(self):
        data = []
        with open(self.filter_file_loc, 'r', encoding='utf-8') as fs:
            csvr = csv.reader(fs, delimiter=';', quotechar='\"')
            # skip first line
            csvr.__next__()
            for line in csvr:
                id = line[self.filter_var]
                data.append(id)
        data = remove_duplicates(data)
        self.filter_data = set(data)


    def open_file(self):
        self.ifs = open(self.master_file_loc, 'r', encoding='utf-8')
        self.csvr = csv.reader(self.ifs, delimiter=';', quotechar='\"')
        self.export_config = self.csvr.__next__()
        self.storage.init_export_file()
        

    def close_file(self):
        self.ifs.close()


    def process_file(self):
        self.open_file()

        no_threads = 100
        threads = []
        for _ in range(no_threads):
            threads.append(Thread(target=self.read_batch))
        for thread in threads:
            thread.start()
        for thread in threads:
            thread.join()

        self.close_file()

    
    def read_batch(self):
        end_of_file = False
        while not end_of_file:
            try:
                self.read_lock.acquire()
                lines = []
                for _ in range(self.read_batch_size):
                    line = self.csvr.__next__()
                    lines.append(line)
                self.read_lock.release()
            # except StopIteration when file ends
            except (EOFError, StopIteration):
                self.read_lock.release()
                end_of_file = True
            
            lines = [x for x in lines if self.filter(x)]

            self.storage.extend_data(lines)
    

    def filter(self, line):
        # check if the master_id is in the filtered list
        if line[self.master_var] in self.filter_data:
            return True
        else:
            return False


class NumericFilter(Filter):
    def __init__(self, filter_file_loc, filter_var, master_file_loc, master_var, read_batch_size=10_000) -> None:
        super().__init__(filter_file_loc, filter_var, master_file_loc, master_var, read_batch_size)


    def import_filter_data(self):
        data = []
        with open(self.filter_file_loc, 'r', encoding='utf-8') as fs:
            csvr = csv.reader(fs, delimiter=';', quotechar='\"')
            # skip first line
            csvr.__next__()
            for line in csvr:
                id = line[self.filter_var]
                data.append(id)
        data = remove_duplicates(data)
        self.filter_data = np.array(data, np.int64)
        self.filter_data = np.sort(self.filter_data)


    def read_batch(self):
        end_of_file = False
        while not end_of_file:
            try:
                self.read_lock.acquire()
                lines = []
                ids = []
                for _ in range(self.read_batch_size):
                    line = self.csvr.__next__()
                    lines.append(line)
                    ids.append(line[self.master_var])
                self.read_lock.release()
            # except StopIteration when file ends
            except (EOFError, StopIteration):
                self.read_lock.release()
                end_of_file = True
            
            ids = np.array(ids)
            in_filter = np.in1d(ids, self.filter_data)
            ret_lines = [line for line, inlist in zip(lines, in_filter) if inlist]

            self.storage.extend_data(ret_lines)



    def filter(self, line):
        # check if the master_id is in the filtered list
        id_num = line[self.master_var]
        np.searchsorted(self.filter_data, id_num)
        return False


class NameFilter:
    def __init__(self, filtered_names, import_file_location, export_file_location):
        self.filtered_names = set(filtered_names)
        self.file_location = import_file_location
        self.export_file_location = export_file_location

        self.read_lock = Lock()
        self.read_batch_size = 1000

        self.write_lock = Lock()
        self.write_batch_size = 100000

        self.data = []
        self.batch_size = 0

        self.total = 0

    # This function should be moved to legacy and Inherited from Filter object
    def open_file(self):
        self.ifs = open(self.file_location, 'r', encoding='utf-8')
        self.csvr = csv.reader(self.ifs, delimiter=';', quotechar='\"')
        self.export_config = self.csvr.__next__()
        self.init_export_file()
        
    # This function should be moved to legacy and Inherited from Filter object
    def close_file(self):
        self.ifs.close()

    # This function should be moved to legacy and Inherited from Filter object
    def process_file(self):
        self.open_file()

        no_threads = 100
        threads = []
        for _ in range(no_threads):
            threads.append(Thread(target=self.read_batch))
        for thread in threads:
            thread.start()
        for thread in threads:
            thread.join()

        self.close_file()


    def read_batch(self):
        end_of_file = False
        while not end_of_file:
        #for _ in range(100):
            try:
                self.read_lock.acquire()
                lines = []
                for _ in range(self.read_batch_size):
                    line = self.csvr.__next__()
                    lines.append(line)
                # except StopIteration when file ends
                self.read_lock.release()
            except (EOFError, StopIteration):
                end_of_file = True
            if not line:
                end_of_file = True
                break
            
            lines = [x for x in lines if self.filter_name(x)]

            self.extend_data(lines)


    def filter_name(self, line):
        names = line[2]
        names = clean_name(names)
        name_parts = names.split(' ')
        name_parts = [part for part in name_parts if len(part)>2]
        for name in name_parts:
            if name in self.filtered_names:
                # if the name returns a match in the list, return true
                return True
        # if no part of the name matched to the filter list, return false
        return False


    # This function should be moved to legacy and use Storage object instead
    def init_export_file(self):
        # this step overwrites the original file in this location
        with open(self.export_file_location, 'w', encoding='utf-8', newline='') as efs:
            csvw = csv.writer(efs, delimiter=';', quotechar='\"')
            csvw.writerow(self.export_config)
        

    # This function should be moved to legacy and use Storage object instead
    def extend_data(self, incoming_data):
        self.write_lock.acquire()
        self.data.extend(incoming_data)
        self.write_lock.release()
        self.batch_size += len(incoming_data)
        if self.batch_size > self.write_batch_size:
            self.write_lock.acquire()
            self.total += self.batch_size
            self.export_batch_to_csv()
            self.data = []
            self.batch_size = 0
            self.write_lock.release()


    # This function should be moved to legacy and use Storage object instead
    def export_batch_to_csv(self):
        with open(self.export_file_location, 'a', encoding='utf-8', newline='') as fs:
            csvw = csv.writer(fs, delimiter=';', quotechar='\"')
            csvw.writerows(self.data)
        return True


def clean_name(name:str):
    '''''
    Make names uniform: replace special characters
    '''''
    cleaned_name = name.upper()
    cleaned_name = unicodedata.normalize('NFD', cleaned_name).encode('ascii', 'ignore')
    cleaned_name = cleaned_name.decode('UTF-8')
    cleaned_name = re.sub('[^a-zA-Z ]', '', cleaned_name)

    return cleaned_name


def import_names(file_location):
    names = []
    with open(file_location, 'r', encoding='utf-8') as fs:
        csvr = csv.reader(fs)
        # skip first line
        csvr.__next__()
        for line in csvr:
            if line:
                name = line[0]
                if name:
                    clean = clean_name(name)
                    parts = clean.split(' ')
                    names.extend(parts)

    # remove duplicates in the list of names
    names = remove_duplicates(names)
    names = [n for n in names if len(n) > 3]
    return names


def remove_duplicates(listof):
    return list(dict.fromkeys(listof))


def filter_names():
    # import list of names
    names_location = (wd.parent / 'surnames').resolve()
    files = ['committee_surname.csv', 'director_surname.csv', 'evaulator_surname.csv']

    names = []

    for file in files:
        path = (names_location / file).resolve()
        file_names = import_names(path)
        names.extend(file_names)

    names = remove_duplicates(names)
    names = set(names)


    # specify file location
    export_dir = (wd.parent / 'data').resolve()
    raw_data_location = (export_dir / 'authors_data.csv').resolve()
    export_data_location = (export_dir / 'authors_data_filtered.csv').resolve()
    # initialise filter
    filter = NameFilter(names, raw_data_location, export_data_location)
    start_time = time.perf_counter()
    print('Process Started')
    filter.process_file()
    end_time = time.perf_counter()
    filter.export_batch_to_csv()
    print(f'Number of observations after filter: {filter.total}')


def filter_teseo_authors():
    filter_file_loc = Path('/home/economics/ecudpb/data/merged_authors_teseo.csv') # cluster
    #filter_file_loc = Path('D://data/merged_authors_teseo.csv') # local PC
    master_file_loc = Path('/home/economics/ecudpb/data/authors_data_filtered.csv') # cluster
    #master_file_loc = Path('D://data/authors_head_10k.csv') # local PC
    teseo_author_filter = Filter(filter_file_loc=filter_file_loc, filter_var=1, master_file_loc=master_file_loc, master_var=0)

    storage_location = Path('/home/economics/ecudpb/data/openalex-teseo_authors.csv') # cluster
    #storage_location = Path('D://data/openalex-teseo_test.csv') # local PC
    varnames = ['author_id', 'author_orcid_id', 'author_name', 'works_count', 'cited_by_count', 'x_concepts1', 'x_concepts2', 'x_concepts3','x_concepts4','x_concepts5','x_concepts6','x_concepts7','x_concepts8','x_concepts9','x_concepts10']
    teseo_author_filter.add_storage(Storage(storage_location, extract_config=varnames, batch_size= 2_000))

    teseo_author_filter.process_file()

    teseo_author_filter.storage.export_batch()


def filter_econ_authors():
    filter_file_loc = Path('/home/economics/ecudpb/rae_data/economics_works.csv') # cluster
    #filter_file_loc = Path('D://data/merged_authors_teseo.csv') # local PC
    master_file_loc = Path('/home/economics/ecudpb/data/works_data.csv') # cluster
    #master_file_loc = Path('D://data/works_data_head_100k.csv') # local PC
    teseo_pub_filter = NumericFilter(filter_file_loc=filter_file_loc, filter_var=1, master_file_loc=master_file_loc, master_var=1)

    storage_location = Path('/home/economics/ecudpb/rae_data/economics_works.csv') # cluster
    #storage_location = Path('D://data/openalex-teseo_test.csv') # local PC
    varnames = ['paper_id', 'author_id', 'doi', 'title', 'pub_year', 'work_type', 'journal_id', 'citations', 'first_author', 'middle_author', 'last_author', 
            'xconcept1', 'xconcept2','xconcept3','xconcept4','xconcept5','xconcept6','xconcept7','xconcept8','xconcept9','xconcept10',]
    teseo_pub_filter.add_storage(Storage(storage_location, extract_config=varnames, batch_size= 10_000))

    teseo_pub_filter.process_file()

    teseo_pub_filter.storage.export_batch()


def filter_teseo_pubs():
    filter_file_loc = Path('/home/economics/ecudpb/rae_data/economics_works.csv') # cluster
    #filter_file_loc = Path('D://data/merged_authors_teseo.csv') # local PC
    master_file_loc = Path('/home/economics/ecudpb/data/works_data.csv') # cluster
    #master_file_loc = Path('D://data/works_data_head_100k.csv') # local PC
    teseo_pub_filter = NumericFilter(filter_file_loc=filter_file_loc, filter_var=1, master_file_loc=master_file_loc, master_var=1)

    storage_location = Path('/home/economics/ecudpb/rae_data/economics_works.csv') # cluster
    #storage_location = Path('D://data/openalex-teseo_test.csv') # local PC
    varnames = ['paper_id', 'author_id', 'doi', 'title', 'pub_year', 'work_type', 'journal_id', 'citations', 'first_author', 'middle_author', 'last_author', 
            'xconcept1', 'xconcept2','xconcept3','xconcept4','xconcept5','xconcept6','xconcept7','xconcept8','xconcept9','xconcept10',]
    teseo_pub_filter.add_storage(Storage(storage_location, extract_config=varnames, batch_size= 10_000))

    teseo_pub_filter.process_file()

    teseo_pub_filter.storage.export_batch()


def filter_econ_pubs():
    filter_file_loc = Path('/home/economics/ecudpb/rae_data/economics_works.csv') # cluster
    #filter_file_loc = Path('D://rae_data/economics_works.csv') # local PC
    master_file_loc = Path('/home/economics/ecudpb/data/works_data.csv') # cluster
    #master_file_loc = Path('D://data/works_data_head_100k.csv') # local PC
    econ_pub_filter = NumericFilter(filter_file_loc=filter_file_loc, filter_var=1, master_file_loc=master_file_loc, master_var=1)

    storage_location = Path('/home/economics/ecudpb/rae_data/openalex-econ-authors.csv') # cluster
    #storage_location = Path('D://data/openalex-econ-authors_test.csv') # local PC
    varnames = ['paper_id', 'author_id', 'doi', 'title', 'pub_year', 'work_type', 'journal_id', 'citations', 'first_author', 'middle_author', 'last_author', 
            'xconcept1', 'xconcept2','xconcept3','xconcept4','xconcept5','xconcept6','xconcept7','xconcept8','xconcept9','xconcept10']
    econ_pub_filter.add_storage(Storage(storage_location, extract_config=varnames, batch_size = 10_000))

    econ_pub_filter.process_file()

    econ_pub_filter.storage.export_batch()


def filter_econ_affiliations():
    filter_file_loc = Path('/home/economics/ecudpb/rae_data/openalex-econ-authors.csv') # cluster
    #filter_file_loc = Path('D://rae_data/economics_works.csv') # local PC
    master_file_loc = Path('/home/economics/ecudpb/rae_data/affiliations_data.csv') # cluster
    #master_file_loc = Path('D://data/works_data_head_100k.csv') # local PC
    econ_pub_filter = NumericFilter(filter_file_loc=filter_file_loc, filter_var=1, master_file_loc=master_file_loc, master_var=0)

    storage_location = Path('/home/economics/ecudpb/rae_data/openalex-econ-affiliations.csv') # cluster
    #storage_location = Path('D://data/openalex-econ-authors_test.csv') # local PC
    varnames = ['authod_id', 'paper_id', 'aff_inst_id', 'aff_inst_str', 'year']
    econ_pub_filter.add_storage(Storage(storage_location, extract_config=varnames, batch_size = 10_000))

    econ_pub_filter.process_file()

    econ_pub_filter.storage.export_batch()


def filter_econ_authors():
    filter_file_loc = Path('/home/economics/ecudpb/rae_data/economics_works.csv') # cluster
    #filter_file_loc = Path('D://rae_data/economics_works.csv') # local PC
    master_file_loc = Path('/home/economics/ecudpb/data/authors_data.csv') # cluster
    #master_file_loc = Path('D://data/works_data_head_100k.csv') # local PC
    econ_pub_filter = NumericFilter(filter_file_loc=filter_file_loc, filter_var=1, master_file_loc=master_file_loc, master_var=0)

    storage_location = Path('/home/economics/ecudpb/rae_data/openalex-econ_authors.csv') # cluster
    #storage_location = Path('D://data/openalex-econ-authors_test.csv') # local PC
    varnames = ['author_id', 'author_orcid_id', 'author_name', 'works_count', 'cited_by_count', 'x_concepts1', 'x_concepts2', 'x_concepts3','x_concepts4','x_concepts5','x_concepts6','x_concepts7','x_concepts8','x_concepts9','x_concepts10']
    econ_pub_filter.add_storage(Storage(storage_location, extract_config=varnames, batch_size = 10_000))

    econ_pub_filter.process_file()

    econ_pub_filter.storage.export_batch()


if __name__ == '__main__':
    wd = Path().cwd()
    # filter the openalex names to include only those in teseo
    # filter_names()

    # filter openalex authors based on teseo matches
    # filter_teseo_authors()

    # filter openalex publications based on teseo matches
    #filter_teseo_pubs()

    # filter openalex authors based on journals
    # filter_econ_authors()
    
    # filter openalex publications based on matches from journals
    #filter_econ_pubs()

    # filter openalex affiliations based on authors
    #filter_econ_affiliations()

    # filter openalex authors based on publications in economics journals
    filter_econ_authors()