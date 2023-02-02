* Merge publications with journals and affiliations

clear
cd "$data_folder"
use "works.dta"

* merge to affiliations based on publication and author
merge 1:1 paper_id author_id using "affiliations/affiliations.dta" // 18.21% has affiliation
drop if _merge == 2
drop year _merge

* merge to affiliations based on year and author
* here this only merges authors who have no within year institution conflict
rename pub_year year
merge m:1 author_id year using "affiliations/affiliations_fix_year.dta"
drop if _merge == 2

* check if there are any issues with inferring the institution
gen issue = 1 if aff_inst_id != aff_inst_id_inferred & aff_inst_id != . & aff_inst_id_inferred  != .
// there are no issues
drop issue

* replace value of aff_inst_id to the inferred values
replace aff_inst_id = aff_inst_id_inferred if aff_inst_id_inferred != .
drop aff_inst_id_inferred

* infer the value of institution based on years before and after


* regenerate moves and mover variables
drop moves mover
* proportion of movers
egen moves = nvals(aff_inst_id), by(author_id)
replace moves = moves - 1
gen mover = moves != 0 // 89.77% of the sample are movers