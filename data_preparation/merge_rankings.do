* 4f) Merge university rankings

cd "$data_folder"
clear
use "author_panel"

merge m:1 aff_inst_id using "openalex_data/institutions.dta"
keep if _merge == 3
drop _merge

recast str200 inst_name
merge m:1 inst_name using "rankings/merge", keepusing(university_matched)
drop if _merge == 2
drop _merge

merge m:1 university_matched using "rankings/rankings"
drop if _merge == 2
drop _merge
drop university_matched 


cd "$data_folder"
save "author_panel", replace