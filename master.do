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
capture ssc install TWFE
capture ssc install felsdvreg
capture ssc install schemepack
*/


* GLOBAL SETTINGS
* Classifications as economist: what proportion of publications is required to be
* in economics to be treated as an economist
global ec_prop_cutoff = 0.3333


* warwick pc
global scripts_folder = "C:\Users\u2048873\RAE"
global data_folder = "D:\rae_data"

*
* home PC
global scripts_folder = "E:\OneDrive\Desktop\RAE"
global data_folder = "D:\GoogleDrive\RAE"
*/

*
/* laptop
global scripts_folder = "C:\Users\Milan\OneDrive\Desktop\RAE"
global data_folder = "G:\My Drive\RAE"
*/

/*
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
*	4a) Merge journal rankings
*	4b) Disambiguate IDs
*	4c) Generate pub quality author-year panel
* 	4d) Assign gender
* 	4e) Merge university rankings

* 5) Analysis
* 	5a) Generate summary statistics and descriptive graphs




* 1) Collect data from OpenAlex
*		This step was performed in python. The stata integration of python is a 
*		bit unreliable and OS dependent.

* 2) Filter authors based on publications in economics journals
* Import and merge journal data from OpenAlex, WOS, and Econlit

cd "$scripts_folder"
do "data_processing/merge_journal_data.do" // 1,385 journals matched to OpenAlex

* Import OpenAlex institutions
cd "$scripts_folder"
do  "data_preparation/import_institutions"


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

* 4b) Disambiguate IDs
cd "$scripts_folder"
do "data_preparation/fix_id_errors.do" 


* 3a) Filter for economics authors
cd "$scripts_folder"
do "data_preparation/filter_econ_authors.do"

* debug : no issues so far

* 3b) Infer affiliation for missing observations
cd "$data_folder"
clear
use "works"

* FOUND A BUG!!!!
* STATA GENERATES WRONG VALUES FOR INST_ID UNLESS DOUBLE IS SPECIFIES AS DATATYPE
cd "$scripts_folder"
do "data_preparation/infer_affiliation.do"

assert aff_inst_id !=  17866348

cd "$data_folder"
save "works", replace


* WHAT TO DO WITH THOSE OBSERVATIONS WHERE THERE IS A SEEMINGLY RANDOM MOVE IN THE MIDDLE
* OF A CONSISTENT INSTITUTION


* remove observations where journal is missing
drop if missing(journal_name)

* 4a) Import impact factor and other meaasures of journal quality
cd "$scripts_folder"
do "data_preparation/import_merge_jcr.do" 



* Generate top5 and co-author weighed variables
cd "$scripts_folder"
do "data_preparation/gen_weighed_vars.do" 


* 4c) Generate pub quality author-year panel
cd "$scripts_folder"
do "data_preparation/generate_panel.do" 


* 4d) Assign gender
cd "$scripts_folder"
do "data_preparation/assign_gender.do"


* 4e) Merge university rankings


* 5) Analysis


*/

* Construct sample for analysis
cd "$scripts_folder"
do "data_analysis/construct_sample.do" 

* Run TWFE estimation
cd "$scripts_folder"
do "data_analysis/estimate_fe.do" 

* 5a) Generate summary statistics and descriptive graphs
cd "$scripts_folder"
do "data_analysis/summary_stats.do" 



/*
* format variables
format author_id %12.0g
format paper_id %12.0g
format journal_id %12.0g
format aff_inst_id %12.0g
*/