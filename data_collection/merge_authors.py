import csv
import re
import unicodedata
from time import perf_counter
from pathlib import Path
from threading import Thread


FREQ_NAMES = set(['GARCIA','RODRIGUEZ','GONZALEZ','FERNANDEZ','LOPEZ','MARTINEZ','SANCHEZ','PEREZ','GOMEZ','MARTIN'])


from objs import Storage


class Database:
    def __init__(self, authors=None, storage=None) -> None:
        '''''
        Storage for a database of authors

        authors: set of Author objects
        storage: Storage object
        '''''
        # initialise a database 
        # optionally with a set of authors and a local storage
        # these can all be added to the database later
        self.authors = authors
        self.storage = storage
        # timers measuring the average time used by functions in the merge process
        self.timer1_length = 0
        self.timer1_count = 0
        self.timer2_length = 0
        self.timer2_count = 0
        self.timer3_length = 0
        self.timer3_count = 0


    def add_storage(self, storage):
        '''''
        Add a local storage to the database

        storage: Storage object
        '''''
        self.storage = storage

    
    def merge_authors(self, using_database):
        '''''
        Merge authors in the database to authors of another database.

        using_database: Database object, containing the authors to be merged
        '''''
        self.using_database = iter(using_database.authors)
        # initialise threads for merge procedure
        # the number of threads can be increased depending on the PC/cluster
        no_threads = 200
        threads = []

        # run parallel merge procedures
        for _ in range(no_threads):
            threads.append(Thread(target=self.merge))
        for thread in threads:
            # start threads
            thread.start()
        for thread in threads:
            # close threads
            thread.join()

    
    def generate_master_names(self):
        '''''
        Generate the sets of names used to filter during the merge procedure.
        '''''
        # unaltered fullname
        self.master_names = set([author.fullname for author in self.authors])
        # fullname with the least common surname
        self.master_search_names = set([author.search_fullname for author in self.authors])
        # INSERT FURTHER FILTER PROCEDURES HERE


    def merge(self):
        '''''
        Function used by each thread to merge authors in the using database
        This function is called by merge_authors()
        '''''
        # read the next author in the database, until the last author is reached
        end_of_batch = False
        while not end_of_batch:
            try:
                # get next author from database iterator
                using_author = next(self.using_database)
            # once there are no more authors left, break the loop
            except (EOFError, StopIteration):
                end_of_batch = True
                break
            
            # merge based on full name
            timer1_start = perf_counter()
            found =  using_author.fullname in self.master_names
            if found:
                timer3_start = perf_counter()
                matches = self.merge1(using_author)
                for match in matches:
                    self.storage.append_data([match, using_author.id, 1])
                timer3_end = perf_counter()
                timer3_total = timer3_end - timer3_start
                self.timer3_length += timer3_total
                self.timer3_count += 1

                timer1_end = perf_counter()
                timer1_total = timer1_end - timer1_start
                self.timer1_length += timer1_total
                self.timer1_count += 1
                continue
            timer1_end = perf_counter()
            timer1_total = timer1_end - timer1_start
            self.timer1_length += timer1_total
            self.timer1_count += 1
            # merge based on filtered master name
            timer2_start = perf_counter()
            found =  using_author.fullname in self.master_search_names
            if found:
                matches = self.merge2(using_author)
                for match in matches:
                    self.storage.append_data([match, using_author.id, 2])

                timer2_end = perf_counter()
                timer2_total = timer2_end - timer2_start
                self.timer2_length += timer2_total
                self.timer2_count += 1
                continue
            timer2_end = perf_counter()
            timer2_total = timer2_end - timer2_start
            self.timer2_length += timer2_total
            self.timer2_count += 1
            # merge based on parts in filtered master name, check whether filtered out surname appears anywhere
            # ADD ADDITIONAL MERGE PROCESSES HERE
        return True


    def merge1(self, using_author):
        '''''
        Merge authors:
        Fullname - Fullname
        '''''
        retids = []
        for master_author in self.authors:
            if master_author.fullname == using_author.fullname:
                retids.append(master_author.id)
        return retids


    def merge2(self, using_author):
        '''''
        Merge authors:
        Fullname with less frequent surname - Fullname
        '''''
        retids = []
        for master_author in self.authors:
            if master_author.search_fullname == using_author.fullname:
                retids.append(master_author.id)
        return retids

    '''''
    def merge3(self, master_author, using_author):
        using_author.extract_abbreviations()
        using_abbrevs = using_author.abbreviations
        if using_abbrevs:
            master_parts = master_author.search_fullname.split(' ')
            using_parts = using_author.fullname.split(' ')
            found = []
            for part in using_parts:
                if part in master_parts:
                    found.append(True)
                else:
                    found.append(False)

            proportion = (sum(found) / len(using_parts))
            if proportion > .5:
                abbrev_found = []
                for mpart, foundpart in zip(master_parts, found):
                    if not foundpart:
                        letter = mpart[0]
                        if letter in using_abbrevs:
                            abbrev_found.append(True)
                        else:
                            abbrev_found.append(False)
                abbrevs_accurate = len(abbrev_found) - sum(abbrev_found)
                if abbrevs_accurate == 0:
                    return True
            
        return False

    
    def merge4(self, master_author, using_author):
        pass
    '''''
    

class Author:
    def __init__(self, *args, **kwargs) -> None:
        '''''
        Storage for authors

        dict - config of variables in the data
        {
            'id': #(row corresponding to id variable),
            etc.
        }
        '''''
        self.id = kwargs['id']
        if 'fullname' in kwargs:
            self.fullname = self.clean_name(kwargs['fullname'])
        elif 'surname' in kwargs:
            self.surname = self.clean_name(kwargs['surname'])
            self.name = self.clean_name(kwargs['name'])
            self.fullname = f'{self.name} {self.surname}'

        else:
            raise Exception('No name specified for the author')
        
        self.search_surname = ''
        self.check_surname = []
        
        self.search_fullname = ''


    def clean_name(self, name:str):
        '''''
        Make names uniform: replace special characters and double whitespaces
        '''''
        cleaned_name = name.upper().strip()
        cleaned_name = re.sub(' +', ' ', cleaned_name)
        cleaned_name = unicodedata.normalize('NFD', cleaned_name).encode('ascii', 'ignore')
        cleaned_name = cleaned_name.decode('UTF-8')
        cleaned_name = re.sub('[^a-zA-Z ]', '', cleaned_name)

        return cleaned_name


    def construct_search_name(self):
        '''''
        Create a filtered fullname for merging using the less common surname and forenames
        '''''
        parts = self.surname.split(' ')
        length = len(parts)
        if length == 1:
            self.search_surname = self.surname
        else:
            parts_common = [i in FREQ_NAMES for i in parts]
            for part, common in zip(parts, parts_common):
                if common:
                    self.check_surname.append(part)
                else:
                    if self.search_surname:
                        self.search_surname = f'{self.search_surname} {part}'
                    else:
                        self.search_surname = part

        self.search_fullname = f'{self.name} {self.search_surname}'

        self.extract_abbreviations()
        self.extract_starting_letters()

        
    def extract_abbreviations(self):
        '''''
        Extract the abbreviations from fullname
        '''''
        self.abbreviations = []
        for part in self.fullname.split(' '):
            if len(part) == 1:
                self.abbreviations.append(part)
            if '.' in part:
                if len(part) == 2:
                    part = part.replace('.', '')
                    self.abbreviations.append(part)
                    self.fullname = re.sub(' +', ' ', self.fullname)


    def extract_starting_letters(self):
        '''''
        Extract the starting letters from the parts of fullname
        '''''
        self.starting_letters = []
        for part in self.fullname.split(' '):
            try:
                self.starting_letters.append(part[0])
            except:
                pass
    

def import_database(config, csvr=None, batch_size=1_000_000):
    '''''
    Import authors from a database

    config: dict - config of variables in the file
    csvr: csv.Reader with the filestream already open
    batch_size: number of observations in each batch
    '''''
    end_of_file = False
    data = []
    if not csvr:
        with open(config['location'], 'r', encoding='utf-8') as fs:
            csvr = csv.reader(fs, delimiter=config['delimiter'])
            # skip the first line with variables
            csvr.__next__()
            for line in csvr:
                author_id = line[config['id']]
                if 'surname' in config:
                    surname = line[config['surname']]
                    name = line[config['name']]
                    author_data = {
                        'id': author_id,
                        'surname': surname,
                        'name': name
                    }
                elif 'fullname' in config:
                    fullname = line[config['fullname']]
                    author_data = {
                        'id': author_id,
                        'fullname': fullname
                    }
                data.append(Author(**author_data))
        end_of_file = True
    else:
        for _ in range(batch_size):
            try:
                line = csvr.__next__()
            except (EOFError, StopIteration):
                end_of_file = True
                break
            author_id = line[config['id']]
            if 'surname' in config:
                surname = line[config['surname']]
                name = line[config['name']]
                author_data = {
                    'id': author_id,
                    'surname': surname,
                    'name': name
                }
            elif 'fullname' in config:
                fullname = line[config['fullname']]
                author_data = {
                    'id': author_id,
                    'fullname': fullname
                }
            data.append(Author(**author_data))

    return Database(set(data)), end_of_file


if __name__ == '__main__':
    # import master data
    clock_start = perf_counter()
    master_config = {
        'location': Path('/home/economics/ecudpb/data/teseo_final.csv'), # cluster
        #'location': Path('D://data/candidates.csv'), # local PC
        'delimiter': ',',
        'id': 0,
        'surname': 3,
        'name': 2
    }
    master_database, master_import_complete = import_database(master_config)
    # add storage to databse
    storage_location = Path('/home/economics/ecudpb/data//merged_authors.csv') # cluster
    #storage_location = Path('D://data/merged_authors.csv') # local PC
    master_database.add_storage(Storage(storage_location, extract_config=['master_id', 'using_id', 'merge_type'], batch_size= 1_000))
    # setup export file
    master_database.storage.init_export_file()
    # generate the sets of names used to filter in the merge
    master_database.generate_master_names()

    for author in master_database.authors:
        author.construct_search_name()
    
    clock_finish = perf_counter()
    master_import = clock_finish - clock_start
    print(f'Master data imported in {master_import:.4f}')


    # import using data
    using_config = {
        'location': Path('/home/economics/ecudpb/data/authors_data_filtered.csv'), # cluster
        #'location': Path('D://data/authors_head.csv'), # local PC
        'delimiter': ';',
        'id': 0,
        'fullname': 2
    }

    # perform merge procedure
    # initialise threads
    clock_start = perf_counter()

    end_of_file = False
    num = 1
    while not end_of_file:
        with open(using_config['location'], 'r', encoding='utf-8') as fs:
            csvr = csv.reader(fs, delimiter=using_config['delimiter'])
            while not end_of_file:
                # read in 1M batch
                using_database, end_of_file = import_database(using_config, csvr, batch_size=500_000)
                master_database.merge_authors(using_database)
                print(f'Batch {num} merged')
                num += 1
    
    # export leftover matches stored in memory
    master_database.storage.export_batch()

    clock_finish = perf_counter()
    clock_merge = clock_finish - clock_start
    print(f'Merge process completed in {clock_merge:.4f}')

    print(f'Search process 1 avg {master_database.timer1_length / master_database.timer1_count:.4f}')
    print(f'Merge process 1 avg {master_database.timer3_length / master_database.timer3_count:.4f}')
    print(f'Search process 2 avg {master_database.timer2_length / master_database.timer2_count:.4f}')