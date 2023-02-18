* Merge rankigns to list of universities

clear
cd "$data_folder"
use "works"

merge m:1 aff_inst_id using "openalex_data/institutions.dta", keepusing(inst_name)
keep if _merge == 3

collapse (first) inst_name, by(aff_inst_id)

rename inst_name university

capture mkdir "universities"

export delimited using "universities/master_data.csv", replace

* run python script to merge data
* this script does not have to be executed every time.
/*
cd "$scripts_folder"
python script data_preparation/merge_universities.py, args(--folder "$data_folder/universities")
*/