* Merge affiliations

format paper_id %12.0g
format author_id %12.0g


cd "$data_folder"

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

* get rid of non-university institutions
merge m:1 aff_inst_id using "openalex_data/institutions", update keepusing(inst_type inst_name)
replace aff_inst_id = . if inst_type != "education"
* merge FED branches if there are any left
replace aff_inst_id = 1317239608 if strpos(lower(inst_name), "federal reserve")
drop inst_type _merge

* get rid of NBER, CEPR, IFO, Catalyst, IFS, IMF
replace aff_inst_id = . if inlist(aff_inst_id, 1321305853, 4210140326, 1279858714, 1340728805, 1309678057, 4210088027, 4210132957, 47987569, 889315371, 4210099736, 4210129476, 139607695, 1310145890, 197518295, 4210166604)
* some manual corrections
replace aff_inst_id = 111979921 if aff_inst_id == 4210100400
replace aff_inst_id = 1334329717 if aff_inst_id == 55633929
replace aff_inst_id = 7947594 if aff_inst_id == 2802397601


* replace moves and mover variables for missing obs
* infer from values of other publications
gsort author_id -mover

by author_id: replace mover = mover[1] if missing(mover)
by author_id: replace moves = moves[1] if missing(moves)

* drop authors without any affiliations
drop if mover == . //  8.65%

* confirm that there are no authors left without affiliation

bys author_id: egen n_inst = nvals(aff_inst_id), missing
assert n_inst != .
drop n_inst