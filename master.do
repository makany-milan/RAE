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
*		This step was performed in python. The stata integration of python is a 
*		bit unreliable and OS dependent.


* 2) Filter authors based on publications in economics journals
*		Use a list of economics journals from Web of Science (WOS) and EconLit
*		Merge to OpenAlex data based on ISSN number where available, otherwise
*		based on the name of the journal.

do data_processing/merge_journal_data


* 3) Construct a panel data of publications and affiliations on authors that
*	 publish in the field of economics.
