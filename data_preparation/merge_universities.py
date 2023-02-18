import csv
from difflib import SequenceMatcher
from argparse import ArgumentParser
from pathlib import Path
import re


BLACKLIST = ['the ', '(', ')', 'of ', 'and ', '& ', ', ', \
             'u of ', 'in ', 'university', 'college', 'student', \
             'universidad ', 'uni ', 'studied']
ABBREVIATION_BLACKLIST = ['diploma', 'masters', 'cat 1', 'cat 2', 'cat 3' \
                          'cat 4', 'cat 5', 'deemed to be', 'university']


class University:
    def __init__(self, university):
        self.name = university
        self.stripped_name = self.strip_uni_string(self.name)
        self.stripped_list = self.strip_uni_list(self.name)

        self.abbreviation_in_name = '(' in self.name
        if self.abbreviation_in_name:
           self.find_abbreviation()
        
        self.match = ''
        self.score = 0

        self.close_matches = []
        self.close_match_scores = []

    def find_abbreviation(self):
        self.abbreviation = self.name.split('(')[1].replace(')', '').strip().upper()
        self.stripped_name = self.stripped_name.replace(self.abbreviation, '')
        for part in self.abbreviation.split(' '):
            try:
                self.stripped_list.remove(part)
            except ValueError:
                pass
        self.abbreviation_in_name, self.abbreviation = self.strip_abbreviation()

    def get_similarity(self, insts):
        for inst in insts:
            inst_name = inst.stripped_name
            inst_parts = inst.stripped_list

            # String similarity evaluation
            exact_match, score = self.evaluate_exact_match(inst_name)
            if exact_match:
                self.match = inst
                self.score = 1
                return True
            else:
                if score >= .75:
                    self.close_matches.append(inst)
                    self.close_match_scores.append(score)
            
            # List similarity evaluation
            exact_match, score = self.evaluate_list_similarity(inst_parts, inst_name)
            if exact_match:
                self.match = inst
                self.score = 1
                return True
            else:
                if score >= .75:
                    self.close_matches.append(inst)
                    self.close_match_scores.append(score)
            
        if self.close_matches:
            return self.evaluate_similarity_scores()
        else:
            return False

    def evaluate_list_similarity(self, inst_parts, inst_name):
        matched = 0
        match_value = 0
        master_parts = len(self.stripped_list)
        master_length = len(self.stripped_name)
        using_parts = len(inst_parts)
        using_length = len(inst_name)


        if master_parts == using_parts:
            for part in self.stripped_list:
                if part in inst_parts:
                    matched += 1
                    match_value += len(part)
            if matched == master_parts:
                return True, 1
            else:
                score = match_value / master_length
        elif master_parts < using_parts:
            for part in self.stripped_list:
                if part in inst_parts:
                    matched += 1
                    match_value += len(part)
            if matched == master_parts:
                score = match_value / using_length
                return False, score
            else:
                score = match_value / master_length
        elif master_parts > using_parts :
            matched = 0
            match_value = 0
            for part in inst_parts:
                if part in self.stripped_list:
                    matched += 1
                    match_value += len(part)
            if matched == using_parts:
                score = match_value / master_length
                return False, score
            else:
                score = match_value / using_length
        return False, score
            
    def evaluate_exact_match(self, inst_name):
        if inst_name == self.stripped_name:
            return True, 1
        
        sm = SequenceMatcher(None, self.stripped_name, inst_name)
        similarity = sm.ratio()
        if similarity == 1:
            return True, similarity
        else:
            if self.abbreviation_in_name:
                sm = SequenceMatcher(None, self.abbreviation, inst_name)
                similarity = sm.ratio()
                if similarity == 1:
                    return True, similarity
                else:
                    return False, similarity
            else:
                return False, similarity

    def evaluate_similarity_scores(self):
        highest_score = 0
        best_match = ''
        for match, score in zip(self.close_matches, self.close_match_scores):
            if score > highest_score:
                highest_score = score
                best_match = match
        if highest_score > 0.95:
            self.match = best_match
            self.score = highest_score
            return True
        else:
            self.match = best_match
            self.score = highest_score
            return False

    def strip_abbreviation(self):
        valid_abbreviation = ''
        for phrase in ABBREVIATION_BLACKLIST:
            valid_abbreviation = valid_abbreviation.replace(phrase, '')
        for phrase in BLACKLIST:
            valid_abbreviation = valid_abbreviation.replace(phrase, '')
        # Remove any trailing whitespace
        valid_abbreviation = valid_abbreviation.strip()
        if valid_abbreviation != '':
            return True, valid_abbreviation
        else:
            return False, valid_abbreviation

    def strip_uni_list(self, uni):
        uni = uni.strip().upper()
        uni = re.sub('[^A-Za-z0-9]+', '', uni)
        # Remove common words with no explenatory power
        for phrase in BLACKLIST:
            uni = uni.replace(phrase, '')
        # Remove any leftover trailing whitespace
        uni = uni.strip()
        uni = uni.replace('  ', ' ')
        # Remove any word shorter than 3 letters
        # This will potentially get rid of foreign equivalents of useless words
        # while not removing any important information.
        uni = uni.split(' ')
        for part in uni:
            if len(part) < 2:
                uni.remove(part)
        return uni

    def strip_uni_string(self, uni):
        uni = uni.strip().upper()
        uni = re.sub('[^A-Za-z0-9]+', '', uni)
        # Remove common words with no explenatory power
        for phrase in BLACKLIST:
            uni = uni.replace(phrase, '')
        # Remove any leftover trailing whitespace
        uni = uni.strip()
        uni = uni.replace('  ', ' ')
        # Remove any word shorter than 3 letters
        # This will potentially get rid of foreign equivalents of useless words
        # while not removing any important information.
        uni = uni.split(' ')
        for part in uni:
            if len(part) < 2:
                uni.remove(part)
        return ' '.join(uni)


def import_data(location):
    data = []
    with open(location, 'r', encoding='utf-8') as fs:
        reader = csv.reader(fs)
        for indx, line in enumerate(reader):
            if indx == 0:
                uni_index = line.index('university')
            else:
                uni_name = line[uni_index]
                if uni_name != '':
                    data.append(uni_name)
    return data


def export_data(location, master_data):
    with open(location, 'w', encoding='utf-8', newline='') as fs:
        csvw = csv.writer(fs)
        csvw.writerow(['university', 'match', 'university_matched', 'match_score'])
        for uni in master_data:
            try:
                export_data = [uni.name, uni.match_found, uni.match.name, uni.score]
            except AttributeError:
                export_data = [uni.name, False, '', '']
            csvw.writerow(export_data)


def find_unique_unis(unis):
    uni_names = []
    universities = []
    for uni in unis:
        uni_name = uni.name
        if uni_name not in uni_names:
            uni_names.append(uni_name)
            universities.append(uni)
    return universities


if __name__ == '__main__':
    parser = ArgumentParser()

    
    parser.add_argument('--folder', '-f', action='store', required=True, dest='folder')
    parser.add_argument('--single', '-s', action='store', default=False, dest='single')
    
    #args = parser.parse_args()
    #args_raw = ['--folder', 'C:\\Users\\Milan\\OneDrive\\Desktop\\Study\\universities']
    args = parser.parse_args()

    path = Path(args.folder)
    export_loc = (path / 'merge.csv').resolve()

    if args.single:
        master_file_loc = (path / 'master_data.csv').resolve()
    else:
        master_file_loc = (path / 'master_data.csv').resolve()
        using_file_loc = (path / 'using_data.csv').resolve()

    if args.single:
        master_import = import_data(master_file_loc)
        master_data = []
        for data in master_import:
            master_data.append(University(data))

        master_data = find_unique_unis(master_data)
        ex_data = []
        found = []
        for indx, uni in enumerate(master_data):
            match = uni.get_similarity(found)
            if match:
                uni.match_found = match
                found.append(uni.match)
                ex_data.append(uni)
            else:
                use_data = master_data
                use_data.pop(indx)
                match = uni.get_similarity(use_data)
                uni.match_found = match
                ex_data.append(uni)
                if match:
                    uni.match_found = match
                    found.append(uni.match)
        export_data(export_loc, ex_data)
    else:
        master_import = import_data(master_file_loc)
        using_import = import_data(using_file_loc)
        master_data = []
        using_data = []
        for data in master_import:
            master_data.append(University(data))
        for data in using_import:
            using_data.append(University(data))
        
        master_data = find_unique_unis(master_data)
        ex_data = []
        found = []
        counter = 0

        for indx, uni in enumerate(master_data):
            match = uni.get_similarity(found)
            counter += 1
            if counter % 25  == 0:
                print(counter)
            if match:
                uni.match_found = match
                found.append(uni.match)
                ex_data.append(uni)
            else:
                use_data = using_data
                match = uni.get_similarity(use_data)
                uni.match_found = match
                ex_data.append(uni)
                if match:
                    uni.match_found = match
                    found.append(uni.match)
        export_data(export_loc, ex_data)