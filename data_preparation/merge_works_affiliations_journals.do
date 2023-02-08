* Merge publications with journals and affiliations

clear
cd "$data_folder"
use "works.dta"

* merge to affiliations based on publication and author
merge 1:1 paper_id author_id using "affiliations/affiliations.dta", update // 18.21% has affiliation
drop if _merge == 2
drop year _merge


* merge to affiliations based on year and author
* here this only merges authors who have no within year institution conflict
rename pub_year year
merge m:1 author_id year using "affiliations/affiliations_fix_year.dta", update
drop if _merge == 2
drop _merge


* check if there are any issues with inferring the institution
gen issue = 1 if aff_inst_id != aff_inst_id_inferred & aff_inst_id != . & aff_inst_id_inferred  != .
assert issue != 1
// there are no issues
drop issue

* replace value of aff_inst_id to the inferred values
replace aff_inst_id = aff_inst_id_inferred if aff_inst_id == .
drop aff_inst_id_inferred

* infer the value of institution based on years before and after

* replace moves and mover variables for missing obs
* infer from values of other publications
gsort author_id -mover

by author_id: replace mover = mover[1] if missing(mover)
by author_id: replace moves = moves[1] if missing(moves)

* drop authors without affiliations
drop if mover == . //  8.65%

* confirm that there are no authors left without affiliation

bys author_id: egen n_inst = nvals(aff_inst_id), missing
assert n_inst != .
drop n_inst


* merge publications to journals
merge m:1 journal_id using "journals/econ_journals.dta", update
drop if _merge == 2

* find proportion of publications in economics journals
replace econ_journal = 0 if econ_journal == . // overall 17.19%
drop _merge


* merge all journals
merge m:1 journal_id using "journals/formatted/all_journals.dta", update
drop if _merge == 2
drop _merge


save "works", replace