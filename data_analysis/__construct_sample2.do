* Limit sample of analysis
* Analyse a specific period, with sufficient number of authors at a given dept.
* Use the largest network of connected departments

clear
cd "$data_folder"
use "author_panel"

		merge m:1 aff_inst_id using "openalex_data/institutions.dta"
		drop if _merge == 2
		drop _merge


		gen female = 1 if inrange(p_female, 0, 1)
		replace female = 0 if inrange(	p_female, -1, 0)

		* limit sample to post 2000
		keep if inrange(year, 2005, 2015)

		* keep author if they have at least 3 published works in the timeframe
		* this filters out inactive authors
		bys author_id: egen au_total_pubs_post00 = sum(year_author_pubs)
		keep if au_total_pubs_post00 >= 3

		* keep if institution has at least 15 active authors in the timeframe
		bys aff_inst_id: egen inst_total_authors_post00 = nvals(author_id)
		replace aff_inst_id = -1 if inst_total_authors_post00 < 15
		* here some authors will have empty observations
		* if there are a few simply infer affiliation there - small lab or miscoded
		* treat them as inactive and drop from sample
		bys author_id: egen inst_issue = count(aff_inst_id) if aff_inst_id < 0
		gen original_issue = 1 if !missing(inst_issue)
		gsort author_id -inst_issue
		by author_id: replace inst_issue = inst_issue[1] if inst_issue[1] > 7

		drop if inst_issue > 7 & !missing(inst_issue)

		replace aff_inst_id = . if !missing(original_issue)
		replace inst_name = "" if !missing(original_issue)
		bys author_id: egen insts_after_drop = nvals(aff_inst_id), missing
		drop if insts_after_drop == 1 & aff_inst_id == .
		drop inst_issue original_issue


		* infer affiliation
		cd "$scripts_folder"
		do "data_preparation/infer_affiliation.do"

		* drop authors observed only for a few years
		capture drop max_age
		capture drop min_age
		capture drop timeframe
		bys author_id: egen max_age = max(reltime)
		bys author_id: egen min_age = min(reltime)
		gen timeframe = max_age - min_age
		drop if timeframe < 5

gen t_period = year

* get rid of inactive authors
bys author_id: egen inactive = count(aif) if aif == 0
bys author_id: gen prop_inactive = inactive / timeframe

hist prop_inactive

		gen academic_age = reltime

		cd "$data_folder"
		save "sample", replace


cd "$scripts_folder"
do "data_analysis/find_largest_connected_set.do"
