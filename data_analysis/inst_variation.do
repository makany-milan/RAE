cd "$data_folder"
clear

use "inst_panel"

merge m:1 aff_inst_id using "openalex_data/institutions.dta"
keep if _merge == 3
drop _merge

order inst_name year authors

* keep if institution has at least 15 active authors
bys aff_inst_id: egen max_authors = max(authors)
keep if max_authors >= 15