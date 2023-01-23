* Check the accuracy of OpenAlex's XCONCEPT classifications.
cd "$data_folder/concepts"
* create directory to save datasets
capture mkdir "formatted"


* Import OpenAlex concepts
clear
import delimited using concepts_data.csv, varnames(1) encoding(utf-8)
gen econ = 0
replace econ = 1 if strpos(lower(concept_name), "economics")
replace econ = 1 if strpos(lower(description), "economics")
replace econ = 1 if strpos(lower(concept_name), "econometrics")
replace econ = 1 if strpos(lower(description), "econometrics")
replace econ = 1 if strpos(lower(concept_name), "economy")
replace econ = 1 if strpos(lower(description), "economy")
replace econ = 1 if strpos(lower(concept_name), "economic")
replace econ = 1 if strpos(lower(description), "economic")
* 635 concepts associated with economics


* This list can be extended under certain assumptions
* price, market, bargaining, money, finance, industry, etc.
/ *
replace econ = 1 if strpos(lower(concept_name), "business")
replace econ = 1 if strpos(lower(description), "business")
replace econ = 1 if strpos(lower(concept_name), "finance")
replace econ = 1 if strpos(lower(description), "finance")
*/


keep if econ == 1

save "formatted/econ_concepts.dta", replace

cd "$data_folder"
clear
use "journals/formatted/all_journals.dta"

gen openalex_econ = 0

foreach i of num 1/5 {
    rename concept`i' concept_id
	merge m:1 concept_id using "concepts/formatted/econ_concepts.dta", keepusing()
	drop if _merge == 2
	replace openalex_econ = 1 if _merge == 3
	drop _merge
	rename concept_id concept`i'
}

tab econ_journal openalex_econ, cell
br if econ_journal == 0 & openalex_econ == 1