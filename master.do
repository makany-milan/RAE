* Codes used to complete dissertation at Warwick University
* The function of this code is to process and analyse the already compiled data
* on publications from OpenAlex


* Author: Milan Makany
* Email: milan.makany@warwick.ac.uk

clear
clear programs
set varabbrev off



* Procedure Outline
* 1) Collect data from OpenAlex

* 2) Filter authors based on publications in economics journals
*		Use a list of economics journals from Web of Science (WOS) and EconLit
*		Merge to OpenAlex data based on ISSN number where available, otherwise
*		based on the name of the journal.

* 3) Construct a panel data of publications and affiliations on authors that
*	 publish in the field of economics.


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

* General observations: econlit stores a greater amount of journals
* There are journals on web of science (n=120) that econlit does not store
* There are primiarily foreign language publications

* Check the accuracy of OpenAlex XCONCEPT classifications
* If these are accurate, potentially use this classification to include more
* journals in the database
*cd "$scripts_folder"
*do "data_processing/openalex_journal_xconcept_accuracy.do"
* These X-CONCEPTS can be later used to expand the sample.

* Using the matched IDs in OpenAlex
