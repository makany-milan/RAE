# Productivity Differences in Economics: The role of institutions, sorting, and experience

## Work in progress - the codes in this repository get updated on a regular basis as the research progresses.

-------
Codes in this repository are used to complete disseratation in Economics (BSc) at the University of Warwick.
The codes in the repository are used by the author to extract, process, and analyse the publications and affiliations of academics. It is publicly provided for replication and evaluation purposes.

----------

## Data Sources
| Source | Official Description |
| ------ | ----------- | 
| **Publications** |
| [OpenAlex](https://openalex.org/) | OpenAlex is a free and open catalog of the world's scholarly papers, researchers, journals, and institutions — along with all the ways they're connected to one another.|
| **Journals** |
| [Web of Science Master Journal List](https://mjl.clarivate.com/collection-list-downloads) | The Master Journal List is an invaluable tool to help you to find the right journal for your needs across multiple indices hosted on the Web of Science platform.|
| [Web of Science Journal Citation Reports](https://jcr.clarivate.com/jcr/browse-journals) | The Journal Citation Reports provides data on Journal Article Influence Scores and Journal Impact factor. This data can be useful to construct a measure of publication quality.|
| [EconLit](https://www.aeaweb.org/econlit/journal_list.php) | EconLit provides the coverage most needed by scholars to make new discoveries, develop important insights, and contribute valuable research to the economics community.|
| [Scopus](https://www.scopus.com/sources.uri) | Scopus is a large, multidisciplinary database of peer-reviewed literature: scientific journals, books, and conference proceedings |
| [scimagojr](https://www.scimagojr.com/) | Metrics based on Scopus, maybe some additional matches? |
| **Gender Data** |
| [Social Security Administration](https://www.ssa.gov/oact/babynames/) | The Social Security Administration (SSA) collects names of babies born the United States since 1879 |
| [World Gender Name Dictionary ](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/MSEGSJ) | This paper revisits the first World Gender Name Dictionary (WGND 1.0), allowing to disambiguate the gender in data naming physical persons (Lax Martínez et al., 2016). |
| **University Rankings** |
| [QS Rankings](https://www.topuniversities.com/university-rankings)| QS Top Universities overall and economics specific university rankings |
| [CWUR Rankings](https://cwur.org/)| CWUR overall and economics specific university rankings |
| [THE Rankings](https://www.timeshighereducation.com/world-university-rankings)| Times Higher Education overall university rankings |
| [Processed Data](https://drive.google.com/drive/folders/1V2oDuHfGY-sSDt4ECUGdFOV_83uO-ACO?usp=share_link) | Google Drive link to all the raw data files used for the analysis. Extracted and pre-processed from OpenAlex, journal data from WoS and EconLit. The data extraction is replicable and modifiable by altering the codes in */data_collection/* |


## Repository Structure

**Make sure to change all file and folder paths when running the code**

0) Research Proposal / Outline - ***/proposal/***

    Early proposal outlining the research question, potential methodology, and expected results.

    - Deadline: 28/11/2022
    - Propose a research question, identify key data source, and discuss identification

1) Data Extraction - ***Python*** - ***/data_collection/***

    Get publication of all potential economists based on publications in a list of economics journals. The list is constructed by combining data from Web of Science (WOS) and EconLit. Some keywords are also used to identify smaller economics journals. Merge to OpenAlex data based on ISSN number where available, otherwise based on the name of the journal.

    - Transforming the data provided by OpenAlex to an analysable format.
    - Currenltly using "csv" files to store data.
    - Potentially transferring to MySQL AWS database in the future.
    - *It is strongly advised to use a cluster computer for extracting publication data from the OpenAlex database.*

2) Data Preparation- ***Stata & Python*** - ***/data_preparation/***

    Import raw data files and save in Stata format for data processing and analysis.

    - Identify economics journals in the OpenAlex database.
    - Identify authors that have published in economics journals in the past.
    - Filter the publication database to economics authors
    - Import csv files, convert to dta

3) Data Processing - ***Stata*** - ***/data_processing/***

    Merge data files, remove corrupt observations to prepare for the construction of the author and department panels.

    - Develop measures of research quality
    - Identify cross-institution movements
    - Assing gender to authors
    - Infer affiliations for missing years
    - Merge affiliations
4) Construct Panel  - ***Stata*** - ***/construct_panel/***

    Construct a panel for authors, departments and department classes to be later used in analysis.

    - Construct panel of authors and departments
    - Construct panel of department class

5) Analysis  - ***Stata*** - ***/data_analysis/***

    Apply relevant sample restrictions, estimate model and report the results for the paper.

    - Construct sample for analysis
    - Estimate fixed effects
    - Report results

6) Presentation ***/presentation/***

    Seminar presentation, reporting summary statistics, methodology, and preliminary results.

    - Deadline: 17/02/2023
    - 8 slides, following the pre-defined structure

7) Working Paper - ***/presentations-paper/***

    Final paper submitted as the BSc dissertation & further improved working papers.

    - Deadline: 27/04/2023
