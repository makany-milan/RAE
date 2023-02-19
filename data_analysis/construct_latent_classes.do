* 5b) Construct Latent Classes

* potential improvements
* use KNN for those that are in the bottom ranks to construct additional bins

clear
cd "$data_folder"
use "sample"

collapse (first) inst_name qs_econ_2021_rank qs_overall_2022_rank qs_econ_citations qs_faculty_student_ratio_score qs_size cwur_worldrank the_ec_rank the_ec_industry_income the_research_rank the_citations inst_country (count) authors=author_id (sum) aif top5s (mean) max_age avg_coauthors female, by(aff_inst_id)

gsort +qs_econ_2021_rank

capture mkdir "classes"
save "classes/merged_rankings", replace

* merge countries to regions
merge m:1 inst_country using "regions/regions"
* some institutions are without country
* assign to REST for now, consider dropping later
replace region = "REST" if missing(inst_country)
drop if _merge == 2
drop _merge


* create groups of top institutions based on rankings - globally

* generate regional rankings
* qs starts binning above 150 - use THE as primary source
gen global_rank_avg = (qs_econ_2021_rank + the_ec_rank) / 2 if !missing(qs_econ_2021_rank) & !missing(the_ec_rank) & qs_econ_2021_rank < 150
replace global_rank_avg = qs_econ_2021_rank if missing(the_ec_rank)
replace global_rank_avg = the_ec_rank if missing(qs_econ_2021_rank)
* fill the rest
replace global_rank_avg = (qs_econ_2021_rank + the_ec_rank) / 2 if missing(global_rank_avg)

sort global_rank_avg
gen global_rank = _n if !missing(global_rank_avg)

*gsort +global_rank
*edit inst_name global_rank global_rank_avg qs_econ_2021_rank the_ec_rank region

gen GLOBAL_CLASS = .
la de glob_classes 1 "TOP10" 2 "TOP25" 3 "TOP50" 4 "TOP100" 5 "TOP150" 6 "TOP200" 7 "TOP250" 8 "BOTTOM"
la val GLOBAL_CLASS glob_classes


replace GLOBAL_CLASS = 1 if inrange(global_rank, 1, 10)
replace GLOBAL_CLASS = 2 if inrange(global_rank, 11, 25)
replace GLOBAL_CLASS = 3 if inrange(global_rank, 26, 50)
replace GLOBAL_CLASS = 4 if inrange(global_rank, 51, 100)
replace GLOBAL_CLASS = 5 if inrange(global_rank, 101, 150)
replace GLOBAL_CLASS = 6 if inrange(global_rank, 151, 200)
replace GLOBAL_CLASS = 7 if inrange(global_rank, 201, 250)
replace GLOBAL_CLASS = 8 if inrange(global_rank, 251, .)
replace GLOBAL_CLASS = 8 if missing(global_rank)

assert GLOBAL_CLASS != .


* create groups of top institutions based on rankings - regionally

* generate regional rankings
bys region (qs_econ_2021_rank): gen region_rank_qs = _n if !missing(qs_econ_2021_rank)
bys region (the_ec_rank): gen region_rank_the = _n if !missing(the_ec_rank)

gen region_rank_avg = (region_rank_qs + region_rank_the) / 2 if !missing(region_rank_qs) & !missing(region_rank_the) & qs_econ_2021_rank < 150

replace region_rank_avg = region_rank_qs if missing(region_rank_the)
replace region_rank_avg = region_rank_the if missing(region_rank_qs)
* fill the rest
replace region_rank_avg = (region_rank_qs + region_rank_the) / 2 if missing(region_rank_avg)


*order region_rank_qs region_rank_the region_rank_avg, after(inst_name)
*edit inst_name qs_econ_2021_rank the_ec_rank region_rank_qs region_rank_the region_rank_avg region

bys region (region_rank_avg): gen region_rank = _n if !missing(region_rank_avg)

gen REGION_CLASS = .
la de region_classes 1 "US-TOP5" 2 "US-TOP10" 3 "US-TOP25" 4 "US-TOP50" 5 "US-BOTTOM" ///
					6 "UK-TOP5" 7 "UK-TOP10" 8 "UK-TOP25" 9 "UK-TOP50" 10 "UK-BOTTOM" ///
					11 "EU-TOP5" 12 "EU-TOP10" 13 "EU-TOP25" 14 "EU-TOP50" 15 "EU-BOTTOM" ///
					16 "NA-TOP5" 17 "NA-TOP10" 18 "NA-TOP25" 19 "NA-TOP50" 20 "NA-BOTTOM" ///
					21 "REST-TOP5" 22 "REST-TOP10" 23 "REST-TOP25" 24 "REST-TOP50" 25 "REST-BOTTOM"
la val REGION_CLASS region_classes

local loop_var = 0
* loop through regions and generate variables
foreach regi in "US" "UK" "EU" "NA" "REST" {
	replace REGION_CLASS = 1+(`loop_var'*5) if inrange(region_rank, 1, 5) & region == "`regi'"
	replace REGION_CLASS = 2+(`loop_var'*5) if inrange(region_rank, 6, 10) & region == "`regi'"
	replace REGION_CLASS = 3+(`loop_var'*5) if inrange(region_rank, 11, 25) & region == "`regi'"
	replace REGION_CLASS = 4+(`loop_var'*5) if inrange(region_rank, 26, 50) & region == "`regi'"
	replace REGION_CLASS = 5+(`loop_var'*5) if inrange(region_rank, 50, .) & region == "`regi'"
	replace REGION_CLASS = 5+(`loop_var'*5) if missing(region_rank) & region == "`regi'"

	local loop_var = `loop_var'+1
}

assert REGION_CLASS != .


save "classes/global-regional-classes", replace



