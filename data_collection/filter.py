import csv
from threading import Lock
from threading import Thread
import unicodedata
import re
import time
from pathlib import Path


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


    def open_file(self):
        self.ifs = open(self.file_location, 'r', encoding='utf-8')
        self.csvr = csv.reader(self.ifs, delimiter=';', quotechar='\"')
        self.export_config = self.csvr.__next__()
        self.init_export_file()
        

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


    def init_export_file(self):
        # this step overwrites the original file in this location
        with open(self.export_file_location, 'w', encoding='utf-8', newline='') as efs:
            csvw = csv.writer(efs, delimiter=';', quotechar='\"')
            csvw.writerow(self.export_config)
        

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


def remove_duplicates(names):
    return list(dict.fromkeys(names))


if __name__ == '__main__':
    wd = Path().cwd()
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