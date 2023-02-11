# Gender differences in sorting: Measurement and decomposition of productivity in academia

## Work in progress - the codes in this repository get updated on a regular basis as the research progresses.

-------
Codes in this repository are used to complete disseratation in Economics (BSc) at the University of Warwick.
The codes in the repository are used by the author to extract, process, and analyse the publications and affiliations of academics. It is publicly provided for replication and evaluation purposes.

----------

## Data Sources
| Source | Official Description |
| ------ | ----------- | 
| [OpenAlex](https://openalex.org/) | OpenAlex is a free and open catalog of the world's scholarly papers, researchers, journals, and institutions — along with all the ways they're connected to one another.|
| [Web of Science Master Journal List](https://mjl.clarivate.com/collection-list-downloads) | The Master Journal List is an invaluable tool to help you to find the right journal for your needs across multiple indices hosted on the Web of Science platform.|
| [Web of Science Journal Citation Reports](https://jcr.clarivate.com/jcr/browse-journals) | The Journal Citation Reports provides data on Journal Article Influence Scores and Journal Impact factor. This data can be useful to construct a measure of publication quality.|
| [EconLit](https://www.aeaweb.org/econlit/journal_list.php) | EconLit provides the coverage most needed by scholars to make new discoveries, develop important insights, and contribute valuable research to the economics community.|
| [QS Rankings](https://www.topuniversities.com/university-rankings)| QS Top Universities overall and economics specific university rankings |
| [CWUR Rankings](https://cwur.org/)| CWUR overall and economics specific university rankings |
| [THE Rankings](https://www.timeshighereducation.com/world-university-rankings)| Times Higher Education overall university rankings |
| [Processed Data](https://drive.google.com/drive/folders/1V2oDuHfGY-sSDt4ECUGdFOV_83uO-ACO?usp=share_link) | Google Drive link to all the raw data files used for the analysis. Extracted and pre-processed from OpenAlex, journal data from WoS and EconLit. The data extraction is replicable and modifiable by altering the codes in */data_collection/* |


## Repository Structure


0) Research Proposal / Outline - ***/proposal/***
    - Propose a research question, identify key data source, and discuss identification

**Make sure to change all file and folder paths when running the code**

1) Data Extraction - ***Python*** - ***/data_collection/***
    - Transforming the data provided by OpenAlex to an analysable format.
    - Currenltly using "csv" files to store data.
    - Potentially transferring to MySQL AWS database in the future.
    - *It is strongly advised to use a cluster computer for extracting publication data from the OpenAlex database.*
2) Data Processing, Filtering - ***Stata & Python*** - ***/data_processing/***
    - Identify economics journals in the OpenAlex database.
    - Identify authors that have published in economics journals in the past.
    - Filter the publication database to economics authors
3) Build a Panel Database - ***Stata*** - ***/data_preparation/***
    - Develop a running measure of contribution
    - Identify cross-institution movements
    - Assing gender to authors
    - Infer affiliations for missing years
    - Merge affiliations
4) Data Analysis - ***Stata*** - ***/data_analysis/***
    - Identify individual and institution effects
5) Presentations & Working Paper - ***/presentations-paper/***
