* Limit sample of analysis
* Analyse a specific period, with sufficient number of authors at a given dept.
* Use the largest network of connected departments

clear
cd "$data_folder"
use "author_panel"

merge m:1 aff_inst_id using "openalex_data/institutions.dta"
keep if _merge == 3
drop _merge

gen female = 1 if inrange(p_female, 0, 1)
replace female = 0 if inrange(p_female, -1, 0)

* limit sample to post 2000
keep if inrange(year, 2000, 2020)
* keep author if they have at least 3 published works in the timeframe
* this filters out inactive authors
bys author_id: egen au_total_pubs_post00 = sum(year_author_pubs)
keep if au_total_pubs_post00 >= 3

* keep if institution has at least 15 active authors in the timeframe
bys aff_inst_id: egen inst_total_authors_post00 = nvals(author_id) if year >= 2000
keep if inst_total_authors_post00 >= 15

*  282,362 obs

cd "$data_folder"
save "sample", replace

cd "$scripts_folder"
do "data_analysis/find_largest_connected_set.do"


clear
cd "$data_folder"
use "sample"
merge m:1 aff_inst_id author_id using "temp/largest_network_0", nogen update
merge m:1 aff_inst_id author_id using "temp/largest_network_1", nogen update
* keep observations belonging to the largest network

keep if largest_network == 1 // 3130 observations dropped
drop largest_network


cd "$data_folder"
save "sample", replace
