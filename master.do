* Codes used to complete dissertation at Warwick University
* The function of this code is to process and analyse the already compiled data
* on publications from OpenAlex


* Author: Milan Makany
* Email: milan.makany@warwick.ac.uk

clear
clear programs
set varabbrev off


/*
* Install packages
capture ssc install egenmore
*/


* GLOBAL SETTINGS
* Classifications as economist: what proportion of publications is required to be
* in economics to be treated as an economist
global ec_prop_cutoff = 0.5


* Procedure Outline
* 1) Collect data from OpenAlex

* 2) Filter authors based on publications in economics journals
*		Use a list of economics journals from Web of Science (WOS) and EconLit
*		Merge to OpenAlex data based on ISSN number where available, otherwise
*		based on the name of the journal.

* 3) Construct a panel data of publications and affiliations on authors that
*	 publish in the field of economics.
* 	3a) Infer affiliation for missing observations


* 4) Import impact factor and other meaasures of journal quality

* 5) Analysis


* Define global variables
global scripts_folder = "C:\Users\u2048873\RAE"
global data_folder = "D:\rae_data"

* 1) Collect data from OpenAlex
*		This step was performed in python. The stata integration of python is a 
*		bit unreliable and OS dependent.

* 2) Filter authors based on publications in economics journals
* Import and merge journal data from OpenAlex, WOS, and Econlit

cd "$scripts_folder"
do "data_processing/merge_journal_data.do" // 1,385 journals matched to OpenAlex

* SOME NON-ECONOMICS JOURNALS ARE MISSING

* General observations: econlit stores a greater amount of journals
* There are journals on web of science (n=120) that econlit does not store
* There are primiarily foreign language publications

* Check the accuracy of OpenAlex XCONCEPT classifications
* If these are accurate, potentially use this classification to include more
* journals in the database
*cd "$scripts_folder"
*do "data_processing/openalex_journal_xconcept_accuracy.do"
* These X-CONCEPTS can be later used to expand the sample.

* Identify publications based on matched journal IDs
* see filter.py - filter_econ_authors_journals()

* Extract publications for authors that have published in economics journals
* see filter.py - filter_econ_pubs()

* Extract affiliations for authors that have published in economics journals
* see filter.py - filter_econ_affiliations()

* 3) Construct a panel of publications and affiliations
cd "$scripts_folder"
do "data_preparation/import_works_and_affiliations.do"
* merge to journals and affiliations
cd "$scripts_folder"
do "data_preparation/merge_works_affiliations_journals.do"

* drop useless variables
drop see formerly publisheraddress webofsciencecategories 

* 3a) Filter for economics authors
cd "$scripts_folder"
do "data_preparation/filter_econ_authors.do"

* format variables
format paper_id %12.0g
format journal_id %12.0g
format aff_inst_id %12.0g

* 3b) Infer affiliation for missing observations
cd "$scripts_folder"
do "data_preparation/infer_affiliation.do" 
* WHAT TO DO WITH THOSE OBSERVATIONS WHERE THERE IS A SEEMINGLY RANDOM MOVE IN THE MIDDLE
* OF A CONSISTENT INSTITUTION

cd "$data_folder"
save "works", replace

* 4) Import impact factor and other meaasures of journal quality
cd "$scripts_folder"
do "data_preparation/import_merge_jcr.do" 


* 5) Analysis

