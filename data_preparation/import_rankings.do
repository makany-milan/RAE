* 4e) Import university rankings

clear
cd "$data_folder"
use "works"

merge m:1 aff_inst_id using "openalex_data/institutions.dta", keepusing(inst_name)
keep if _merge == 3

collapse (first) inst_name, by(aff_inst_id)

rename inst_name university


export delimited using "rankings/master_data.csv", replace

* run python script to merge data
* this script does not have to be executed every time.
/*
cd "$scripts_folder"
python script data_preparation/merge_universities.py, args(--folder "$data_folder/universities")
*/

clear
* save rankings in dta
cd "$data_folder"
import delimited using "rankings/using_data.csv", varnames(1)
keep university country_name qs_econ_2021_rank the_ec_rank qs_overall_2022_rank the_ec_rank cwur_worldrank qs_size qs_faculty_student_ratio_score qs_econ_citations the_ec_industry_income the_citations the_research_rank
rename university university_matched
recast str200 university_matched
save "rankings/rankings", replace


* save merge file
clear
cd "$data_folder"
import delimited using "rankings/merge.csv", varnames(1)
drop if match_score == .
* keep only high probability matches
keep if match_score > .9
* some manual corrections
drop if university == "Samford University"
ren university inst_name
save "rankings/merge", replace