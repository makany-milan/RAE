* 5b) Construct Classes

* potential improvements
* use KNN for those that are in the bottom ranks to construct additional bins

collapse (first) inst_name qs_econ_2021_rank qs_overall_2022_rank qs_econ_citations qs_faculty_student_ratio_score qs_size cwur_worldrank the_ec_rank the_ec_industry_income the_research_rank the_citations inst_country (count) authors=author_id (sum) aif top5 (mean) female, by(aff_inst_id)

gsort +qs_econ_2021_rank

cd "$data_folder"

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


*
* 10 global classes - percentiles
gen GLOBAL_CLASS = .
la de glob_classes 1 "P10" 2 "P20" 3 "P30" 4 "P40" 5 "P50" 6 "P60" 7 "P70" 8 "P80" 9 "P90" 10 "P100"
la val GLOBAL_CLASS glob_classes

count if !missing(global_rank)
local total_nonmis = `r(N)'

sort global_rank
replace GLOBAL_CLASS = int(10*(global_rank-1)/`total_nonmis')+1 if !missing(global_rank)
replace GLOBAL_CLASS = GLOBAL_CLASS[-1] if global_rank == global_rank[-1]

* potentially some corrupt observations
replace GLOBAL_CLASS = . if !inrange(GLOBAL_CLASS, 1, 10)


*assert GLOBAL_CLASS != .


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

local loop_var = 0
* loop through regions and generate variables
foreach regi in "US" "UK" "EU" "NA" "REST" {
    count if !missing(global_rank)
	local total_nonmis = `r(N)'

	sort global_rank
	replace GLOBAL_CLASS = int(10*(global_rank-1)/`total_nonmis')+1 if !missing(region_rank) & region == "`regi'"
	
	* add label
	la de region_classes 1+(`loop_var'*5) "`regi'-P20" 2+(`loop_var'*5) "`regi'-P40" 3+(`loop_var'*5) "`regi'-P60" 4+(`loop_var'*5) "`regi'-P80" 5+(`loop_var'*5) "`regi'-P100", add
	
	local loop_var = `loop_var'+1
}

la val REGION_CLASS region_classes

assert REGION_CLASS != .

save "classes/global-regional-classes", replace



