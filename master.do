* Codes used to complete dissertation at Warwick University
* The research analyses at research output by economists with a focus on gender differences.


* Author: Milan Makany
* Email: milan.makany@warwick.ac.uk

clear
clear programs
* disable variable abbreviations
set varabbrev off, permanently
* set seed for random number generation - replication purposes
set seed 2048873
* set scheme for graphs
set scheme white_tableau

/*
* Install packages
capture ssc install egenmore
capture ssc install TWFE
capture ssc install felsdvreg
capture ssc install schemepack
capture ssc install plotmatrix
*/


* GLOBAL SETTINGS
* Classifications as economist: what proportion of publications is required to be
* in economics to be treated as an economist
global ec_prop_cutoff = 0.333333


* warwick pc
global scripts_folder = "C:\Users\u2048873\RAE"
global data_folder = "D:\rae_data"

*
* home PC
global scripts_folder = "E:\OneDrive\Desktop\RAE"
global data_folder = "D:\GoogleDrive\RAE"
*/

*
* laptop
global scripts_folder = "C:\Users\Milan\OneDrive\Desktop\RAE"
global data_folder = "G:\My Drive\RAE"
*/
/*
* Procedure Outline
* 1) Data Collection
*	Get publication of all potential economists based on publications in 
*	a list of economics journals
*	The list is constructed by combining data from Web of Science (WOS) and EconLit
*	Some keywords are also used to identify smaller economics journals.
*	Merge to OpenAlex data based on ISSN number where available, otherwise
*	based on the name of the journal.
*
*	1a) Constuct list of economics journals
*	1b) Get the publications of authors that have published in an economics journal


* 2) Data preparation
*	Load raw data files to Stata
*	Import raw data files and save in Stata format for data processing and analysis.
*
*	2a) Import raw works file containing all publication data from potential economics authors
*	2b) Import affiliations
*	2c) Import institution data
* 	2d) Import rankings data
*	2e) Import publication quality data
*	2f) Import gender data, train neural network for classification
*	2g) Import ID errors
*	2h) Import regions

* 3) Data processing
*	Merge data files, remove corrupt observations to prepare for the construction
*	of the author and department panels
*
*	3a) Merge works to affiliations and journals
*	3b) Fix ID errors
* 	3c) Merge publication quality data
* 	3d) Filter economists
* 	3f) Create measures of quality & quantity for productivity
* 	3g) Merge rankings
* 	3h) Merge gender
* 	3i) Remove corrupt observations


* 4) Construct a panel of authors and departments
*	4a) Construct panel for authors
*	4b) Construct panel for institutions
*	4c) Construct panel for classes


* 5) Analysis
* 	5a) Construct sample for analysis
*	5b) Confirm connected set of classes
*	5c) Estimate the models
*	5d) Generate summary statistics and descriptive graphs


*

* 1) Data Collection
* ==============================================================================
*
* 1a) Constuct list of economics journals
	* Import and merge journal data from OpenAlex, WOS, and Econlit

	cd "$scripts_folder"
	do "data_collection/merge_journal_data.do" // 1,385 journals matched to OpenAlex

	* General observations: econlit stores a greater amount of journals
	* There are journals on web of science (n=120) that econlit does not store
	* These are primiarily foreign language publications

	* Check the accuracy of OpenAlex XCONCEPT classifications
	* If these are accurate, potentially use this classification to include more
	* journals in the database
	*cd "$scripts_folder"
	*do "data_collection/openalex_journal_xconcept_accuracy.do"
	* These X-CONCEPTS can be later used to expand the sample.
	* Conclusion: X-CONCEPTS are generally unreliable and using them might introduce bias

* 1b) Get the publications of authors that have published in an economics journal
	*	This step was performed in python. The stata integration of python is a 
	*	bit unreliable and OS dependent.
	*	It is advised to run python code separately.
	
	* Identify publications based on matched journal IDs
	* see filter.py - filter_econ_authors_journals()

	* Extract publications for authors that have published in economics journals
	* see filter.py - filter_econ_pubs()

	* Extract affiliations for authors that have published in economics journals
	* see filter.py - filter_econ_affiliations()

* At this stage we have constructed the raw data files.
* ==============================================================================



* 2) Data preparation
* ==============================================================================
*
* 2a) Import raw works file containing all publication data from potential economics authors
	cd "$scripts_folder"
	do "data_preparation/import_works.do"

* 2b) Import affiliations
	cd "$scripts_folder"
	do "data_preparation/import_affiliations.do"

* 2c) Import institution data
	cd "$scripts_folder"
	do "data_preparation/import_institutions.do"

* 2d) Import rankings data
	* This section has been moved off post 3a) 3b)
	* works.dta must contain affiliation data


* 2e) Import publication quality data
	cd "$scripts_folder"
	do "data_preparation/import_journal_quality.do" 

* 2f) Import gender data, train neural network for classification
	cd "$scripts_folder"
	do "data_preparation/assign_gender.do"

* 2g) Import ID errors
	cd "$scripts_folder"
	do "data_preparation/import_id_errors.do"
	
* 2h) Import regions
	cd "$scripts_folder"
	do "data_preparation/construct_regions.do" 


* At this stage we have loaded all raw data files into Stata format.
* 	works.dta - contains all publications from potential economists
*	affiliations/affiliations_fix_year.dta - contains all affiliations where we are certain
*											that the author was at a given institution in a given year

* ==============================================================================


* 3) Data processing
* ==============================================================================
*
	clear
	cd "$data_folder"
	use works
	
* 3a) Merge works to affiliations and journals
	* Affiliations
	cd "$scripts_folder"
	do "data_processing/merge_affiliations.do"
	* Journals
	cd "$scripts_folder"
	do "data_processing/merge_journals.do"


* 3b) Fix ID errors
	cd "$scripts_folder"
	do "data_processing/fix_id_errors.do"

* 3c) Merge publication quality data
	* This step has been moved after 3d) to increase performance
	
* 3d) Filter economists
	cd "$scripts_folder"
	do "data_processing/filter_economists.do"
	
* 3c) Merge publication quality data
	cd "$scripts_folder"
	do "data_processing/merge_journal_quality.do" 

* 3f) Create measures of quality & quantity for productivity
	cd "$scripts_folder"
	do "data_processing/generate_productivity_measures.do" 
	
* Save works file with all modifications
	cd "$data_folder"
	save works, replace
	
* 2d) Import rankings data
	* This step requires a list of institutions from works, hence the save and re-loading of the data
	cd "$scripts_folder"
	do "data_preparation/import_rankings.do"
	
	clear
	cd "$data_folder"
	use works

* 3g) Merge rankings
	cd "$scripts_folder"
	do "data_processing/merge_rankings.do" 

* 3h) Merge gender
	cd "$scripts_folder"
	do "data_processing/merge_gender.do"

* 3i) Remove corrupt observations
	cd "$scripts_folder"
	do "data_processing/remove_corrupt_data.do"
	
	
	* Save works file with all modifications
	cd "$data_folder"
	save works, replace
	* next step will collapse data
	
* 3j) Merge classes
	cd "$scripts_folder"
	do "data_processing/construct_classes.do"


* ==============================================================================



* 4) Construct a panel of authors and departments
* ==============================================================================

* 4a) Construct panel for authors
	clear
	cd "$data_folder"
	use works

	cd "$scripts_folder"
	do "construct_panel/generate_author_panel.do" 

		
* 4b) Construct panel for institutions
	clear
	cd "$data_folder"
	use works
	
	cd "$scripts_folder"
	do "construct_panel/generate_inst_panel.do" 


* 4c) Construct panel for classes - GLOBAL

	clear
	cd "$data_folder"
	use works
	
	cd "$scripts_folder"
	do "construct_panel/generate_class_panel_global.do" 
	
* 4d) Construct panel for classes - REGIONAL

	clear
	cd "$data_folder"
	use works
	
	cd "$scripts_folder"
	do "construct_panel/generate_class_panel_regional.do" 

* ==============================================================================


*/
	

* 5) Analysis
* ==============================================================================


* 5a) Construct sample for analysis
*	Apply additional sample restrictions.
*	i) Time restrictions
*	ii) Keep authors who are only in ranked institutions
*	iii) Minimum publication requirement
	cd "$scripts_folder"
	do "data_analysis/construct_sample.do"


* 5b) Confirm connected set of classes
	cd "$scripts_folder"
	do "data_analysis/confirm_connected.do"

* 5c) Estimate the models
	cd "$scripts_folder"
	do "data_analysis/estimate_fixed_effects.do"
	

* 5d) Generate summary statistics and descriptive graphs
	cd "$scripts_folder"
	do "data_analysis/summary_stats.do" 
	
* 5e) Analyse sorting of academics
	cd "$scripts_folder"
	do "data_analysis/sorting_models.do" 
	
* 5f) Estimate homogeneous and heterogeneous Mincerian models
	cd "$scripts_folder"
	do "data_analysis/learning_models.do" 

* ==============================================================================
