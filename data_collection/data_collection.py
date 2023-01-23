from pathlib import Path
import os

from objs import File, Storage, Author, Work, Institution, Journal, Concept


def extract_data(compressed_files, storage):
    # run data extraction
    for compressed_file in compressed_files:
        compressed_file.add_local_storage(storage)
        extracted = compressed_file.extract_contents()
    return extracted


if __name__ == '__main__':
    # set current working directory
    wd = Path().cwd()
    
    authors = False
    works = False
    institutions = False
    journals = False
    concepts = True

    # set relative path settings for cluster
    #data_dir = (wd / 'openalex-snapshot\data\works').join()
    #export_dir = (wd / 'export').join()

    if authors:
        # set path on local PC
        authors_data_dir = (wd.parent / 'openalex-snapshot/data/authors').resolve()
        export_dir = Path(wd.parent / 'data/')


        # locate items in the working directory
        authors_data_dir_contents = os.scandir(authors_data_dir)
        folders = []
        for item in authors_data_dir_contents:
            if item.is_dir():
                folders.append(item)
        folders = set(folders)

        compressed_files = []
        for folder in folders:
            active_dir = Path(folder.path)
            active_folder_contents = os.scandir(active_dir)
            for item in active_folder_contents:
                if item.is_file():
                    item_path = Path(item.path)
                    compressed_files.append(item_path)
        # initialise File objects into a set
        compressed_files = [Author(f) for f in compressed_files]
        compressed_files = set(compressed_files)

        # initialise storage
        # set up the directory if it does not exist
        if not os.path.exists(export_dir):
            os.mkdir(export_dir)
        # create csv file for local export
        local_export_location = (export_dir / 'authors_data.csv')
        # specify variables
        authors_vars = ['author_id', 'author_orcid_id', 'author_name', 'works_count', 'cited_by_count',
            'x_concepts1', 'x_concepts2', 'x_concepts3', 'x_concepts4', 'x_concepts5', 'x_concepts6', 
            'x_concepts7', 'x_concepts8', 'x_concepts9', 'x_concepts10']
        local_storage = Storage(local_export_location, authors_vars)
        local_storage.init_export_file()

        # create storage for remote export - database, etc.
        # ...

        # extract data from compressed files
        extract_data(compressed_files, local_storage)

    if works:
        # set path on local PC
        works_data_dir = (wd.parent / 'openalex-snapshot/data/works').resolve()
        export_dir = Path(wd.parent / 'data/')


        # locate items in the working directory
        works_data_dir_contents = os.scandir(works_data_dir)
        folders = []
        for item in works_data_dir_contents:
            if item.is_dir():
                folders.append(item)
        folders = set(folders)

        compressed_files = []
        for folder in folders:
            active_dir = Path(folder.path)
            active_folder_contents = os.scandir(active_dir)
            for item in active_folder_contents:
                if item.is_file():
                    item_path = Path(item.path)
                    compressed_files.append(item_path)
        # initialise File objects into a set
        compressed_files = [Work(f) for f in compressed_files]
        compressed_files = set(compressed_files)

        # initialise storage
        # set up the directory if it does not exist
        if not os.path.exists(export_dir):
            os.mkdir(export_dir)
        # create csv file for local export
        local_export_location = (export_dir / 'works_data.csv')
        # specify variables
        works_vars = ['paper_id', 'author_id', 'affiliation' ,'doi', 'title', 'pub_year', 'work_type', 'journal_id', 'citations',
        'first_author', 'middle_author', 'last_author', 'concept1', 'concept2', 'concept3', 'concept4',
        'concept5', 'concept6','concept7', 'concept8','concept9', 'concept10']
        # x_concepts!!!
        local_storage = Storage(local_export_location, works_vars)
        local_storage.init_export_file()
        # create storage for remote export - database, etc.
        # ...

        # extract data from compressed files
        extract_data(compressed_files, local_storage)

    if institutions:
        # set path on local PC
        institutions_data_dir = (wd.parent / 'openalex-snapshot/data/institutions').resolve()
        export_dir = Path(wd.parent / 'data/')


        # locate items in the working directory
        institutions_data_dir_contents = os.scandir(institutions_data_dir)
        folders = []
        for item in institutions_data_dir_contents:
            if item.is_dir():
                folders.append(item)
        folders = set(folders)

        compressed_files = []
        for folder in folders:
            active_dir = Path(folder.path)
            active_folder_contents = os.scandir(active_dir)
            for item in active_folder_contents:
                if item.is_file():
                    item_path = Path(item.path)
                    compressed_files.append(item_path)
        # initialise File objects into a set
        compressed_files = [Institution(f) for f in compressed_files]
        compressed_files = set(compressed_files)

        # initialise storage
        # set up the directory if it does not exist
        if not os.path.exists(export_dir):
            os.mkdir(export_dir)
        # create csv file for local export
        local_export_location = (export_dir / 'institutions_data.csv')
        # specify variables
        authors_vars = ['inst_id', 'inst_name', 'inst_country', 'inst_type', 'inst_url', 'inst_works_count', 'inst_cited_by_count',
        'associated1', 'associated2', 'associated3', 'associated4','associated5', 'associated6','associated7', 'associated8','associated9', 'associated10']
        local_storage = Storage(local_export_location, authors_vars)
        local_storage.init_export_file()

        # create storage for remote export - database, etc.
        # ...

        # extract data from compressed files
        extract_data(compressed_files, local_storage)

    if journals:
        # set path on local PC
        venues_data_dir = (wd.parent / 'openalex-snapshot/data/venues').resolve()
        export_dir = Path(wd.parent / 'data/')


        # locate items in the working directory
        venues_data_dir_contents = os.scandir(venues_data_dir)
        folders = []
        for item in venues_data_dir_contents:
            if item.is_dir():
                folders.append(item)
        folders = set(folders)

        compressed_files = []
        for folder in folders:
            active_dir = Path(folder.path)
            active_folder_contents = os.scandir(active_dir)
            for item in active_folder_contents:
                if item.is_file():
                    item_path = Path(item.path)
                    compressed_files.append(item_path)
        # initialise File objects into a set
        compressed_files = [Journal(f) for f in compressed_files]
        compressed_files = set(compressed_files)

        # initialise storage
        # set up the directory if it does not exist
        if not os.path.exists(export_dir):
            os.mkdir(export_dir)
        # create csv file for local export
        local_export_location = (export_dir / 'journals_data.csv')
        # specify variables
        journals_vars = ['journal_id', 'journal_name', 'issn1', 'issn2', 'journal_works_count', 'journal_cited_by_count',
        'publisher', 'concept1', 'concept2', 'concept3', 'concept4', 'concept5']
        local_storage = Storage(local_export_location, journals_vars, batch_size=25000)
        local_storage.init_export_file()

        # create storage for remote export - database, etc.
        # ...

        # extract data from compressed files
        extract_data(compressed_files, local_storage)

    if concepts:
        # set path on local PC
        venues_data_dir = (wd.parent / 'openalex-snapshot/data/concepts').resolve()
        export_dir = Path(wd.parent / 'data/')


        # locate items in the working directory
        venues_data_dir_contents = os.scandir(venues_data_dir)
        folders = []
        for item in venues_data_dir_contents:
            if item.is_dir():
                folders.append(item)
        folders = set(folders)

        compressed_files = []
        for folder in folders:
            active_dir = Path(folder.path)
            active_folder_contents = os.scandir(active_dir)
            for item in active_folder_contents:
                if item.is_file():
                    item_path = Path(item.path)
                    compressed_files.append(item_path)
        # initialise File objects into a set
        compressed_files = [Concept(f) for f in compressed_files]
        compressed_files = set(compressed_files)

        # initialise storage
        # set up the directory if it does not exist
        if not os.path.exists(export_dir):
            os.mkdir(export_dir)
        # create csv file for local export
        local_export_location = (export_dir / 'concepts_data.csv')
        # specify variables
        concepts_vars = ['concept_id', 'concept_name', 'description', 'concept_works_count', 'concept_cited_by_count',
        'related_concept1', 'related_concept2', 'related_concept3', 'related_concept4', 'related_concept5',
        'related_concept6', 'related_concept7', 'related_concept8', 'related_concept9', 'related_concept10']
        local_storage = Storage(local_export_location, concepts_vars, batch_size=2500)
        local_storage.init_export_file()

        # create storage for remote export - database, etc.
        # ...

        # extract data from compressed files
        extract_data(compressed_files, local_storage)