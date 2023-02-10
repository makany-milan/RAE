clear
cd "$data_folder"
import delimited using "openalex_data/institutions_data.csv", delimiter(";") encoding(utf-8) bindquotes(strict) maxquotedrows(unlimited)
rename inst_id aff_inst_id
save "openalex_data/institutions", replace


use "panel"
merge m:1 aff_inst_id using "openalex_data/institutions.dta"
drop if _merge == 2
drop _merge