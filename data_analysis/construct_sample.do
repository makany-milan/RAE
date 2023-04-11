* Construct sample for analysis

clear
cd "$data_folder"
use "author_panel"

* format variables
format author_id %12.0g
format aff_inst_id %12.0g


* Merge to authors
	merge m:1 author_id using "openalex_data/authors.dta", keepusing(author_name)
	drop if _merge == 2
	drop _merge

* Restrict the time period analysed
	keep if inrange(year, 1980, 2020)

* Restrict the type of institutions
	* keep if institution has at least 15 active authors in the timeframe
	bys aff_inst_id: egen inst_total_authors_post00 = nvals(author_id)
	replace aff_inst_id = . if inst_total_authors_post00 < 15

	* here some authors will have empty observations
	* if there are a few simply infer affiliation there - small lab or miscoded
	* if a large proportion, treat them as inactive and drop from sample
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

	* infer affiliation for those that had corrupt observations
	cd "$scripts_folder"
	do "construct_panel/infer_affiliation.do"
	
	
* Restrict the type of authors
	* keep authors that we can observe in a ranked institution for the sample period
	gen missing_rank = 1 if missing(GLOBAL_CLASS)
	bys author_id (missing_rank): replace missing_rank = missing_rank[1]
	drop if missing_rank == 1
	drop missing_rank
	/*
	* keep author if they have at least 3 published works in the timeframe
	* this filters out inactive authors
	bys author_id: egen au_total_pubs_post00 = sum(year_author_pubs)
	keep if au_total_pubs_post00 >= 3

	* drop authors observed only for a few years
	capture drop max_age
	capture drop min_age
	capture drop timeframe
	bys author_id: egen max_age = max(reltime)
	bys author_id: egen min_age = min(reltime)
	gen timeframe = max_age - min_age
	drop if timeframe < 5
	*/
	
	

* Generate variables
	gen academic_age = reltime
	gen academic_age_sq = reltime^2
	replace year_author_pubs=0 if year_author_pubs==.
	replace total_aif = 0 if missing(total_aif)
	*replace avg_aif = 0 if missing(avg_aif)


cd "$data_folder"
save "sample", replace