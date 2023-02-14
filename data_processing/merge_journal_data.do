* Code used to merge OpenAlex journal data with EconLit and WebOfScience data
cd "$data_folder\journals"
* create directory to save datasets
capture mkdir "formatted"


**#
* Import OpenAlex data
clear
import delimited using journals_data.csv, varnames(1) encoding(utf-8)
* For some reason some extra empty variables are imported as well from the CSV
* Drop these variables
drop v1*
rename issn1 issn
rename issn2 eissn
* Some journals are duplicated in the list - the name of some journals 
* also change and thus appear as duplicates.
* Remove duplicate observations
* ? to-do: store journal and try merging based on issn and journal name
* no dupes just empties...
/*
bys issn: gen _dupe = _n
keep if _dupe == 1 & issn == ""
drop _dupe

bys eissn: gen _dupe = _n
keep if _dupe == 1 & issn == ""
drop _dupe
*/
drop if issn == "" & eissn == ""

* Results without ISSN will not get matched during a merge 
* but will avoid errors when performing 1:1 merges
bys issn: replace issn = "opena"+string(_n) if issn == ""
bys eissn: replace eissn = "opena"+string(_n) if eissn == ""

save "formatted/openalex_journals_data.dta", replace


**#
* Import EconLit data
* Save observations with ISSN numbers
clear
import delimited using econlit.csv, varnames(1)
* Some journals are duplicated in the list - the name of some journals 
* also change and thus appear as duplicates.
* Remove duplicate observations

* ? to-do: store journal and try merging based on issn and journal name
bys issn: gen _dupe = _n
keep if _dupe == 1 & issn != ""
drop _dupe

gen eissn = ""
bys eissn: replace eissn = "econl"+string(_n) if eissn == ""

* Results without ISSN will not get matched during a merge 
* but will avoid errors when performing 1:1 merges
bys issn: replace issn = "econl"+string(_n) if issn == ""

save "formatted/econlit.dta", replace


**#
* Import WOS data
* WOS Social
* WOS has no journals without ISSN
clear
import delimited using wos-social.csv, varnames(1) 
assert issn != "" | eissn != ""
* Keep economics journals
keep if strpos(lower(webofsciencecategories), "economics")
* Some journals have either only issn or eissn
* Replace values for these journals
* Results without ISSN will not get matched during a merge 
* but will avoid errors when performing 1:1 merges
bys issn: replace issn = "wos-soc"+string(_n) if issn == ""

bys eissn: replace eissn = "wos-soc"+string(_n) if eissn == ""
* ? to-do: store journal and try merging based on issn and journal name
bys issn: gen _dupe = _n
keep if _dupe == 1 & issn != ""
drop _dupe

save "formatted/wos_social.dta", replace

* WOS Emerging
clear
import delimited using wos-emerging.csv, varnames(1)
assert issn != "" | eissn != ""
* Keep economics journals
keep if strpos(lower(webofsciencecategories), "economics")
* Some journals have either only issn or eissn
* Replace values for these journals
* Results without ISSN will not get matched during a merge 
* but will avoid errors when performing 1:1 merges
bys issn: replace issn = "wos-em"+string(_n) if issn == ""
bys eissn: replace eissn = "wos-em"+string(_n) if eissn == ""

* ? to-do: store journal and try merging based on issn and journal name
bys issn: gen _dupe = _n
keep if _dupe == 1 & issn != ""
drop _dupe

save "formatted/wos_emerging.dta", replace



**#
* Merge EconLit & WOS to OpenAlex based on ISSN

* Combine WOS files
clear
use "formatted/wos_social.dta"
merge 1:1 issn using "formatted/wos_emerging.dta"
* Confirm that all observations are unique
assert _merge != 3
drop _merge
* Merge to EconLit
merge 1:1 issn using "formatted/econlit.dta"
drop _merge
count // 2,025
save "formatted/wos_econlit.dta", replace

* Merge with OpenAlex
clear
use "formatted/openalex_journals_data.dta"
gen econ_journal = 0
merge 1:1 issn using "formatted/wos_econlit.dta", update // 650 matches
drop if _merge == 2
replace econ_journal = 1 if _merge == 3
drop _merge
merge 1:1 eissn using "formatted/wos_econlit.dta", update // 9 matches
drop if _merge == 2
replace econ_journal = 1 if _merge == 3
drop _merge


* Check for cross matches between ISSN and EISSN - Data sources might
* incorrectly store values
rename issn temp
rename eissn issn
merge 1:1 issn using "formatted/wos_econlit.dta", update //  629 matches
* Remove brought over variable
drop eissn
drop if _merge == 2
replace econ_journal = 1 if _merge == 3
drop _merge
* redo renaming
rename issn eissn
rename temp issn


rename eissn temp
rename issn eissn
merge 1:1 eissn using "formatted/wos_econlit.dta", update // 275 matches
* Remove brought over variable
drop issn
drop if _merge == 2
replace econ_journal = 1 if _merge == 3
drop _merge
* redo renaming
rename eissn issn
rename temp eissn


* !!! TODO
* Merge EconLit & WOS to OpenAlex based on journal name

* Mark as economics journals based on journal name
replace econ_journal = 1 if strpos(lower(journal_name), "econom")

save "formatted/all_journals.dta", replace

* Save merged Economics journals
keep if econ_journal == 1 // 1287 journals matched

format journal_id %12.0g

cd "$data_folder"
save "journals/econ_journals.dta", replace

* export a list of journal ids to filter in openalex
* export delimited using "journals/journals.csv"

