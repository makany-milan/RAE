* 4b) Disambiguate IDs

cd "$data_folder"
clear
import delimited using "merge_ids\merged_id_authors.csv", varnames(1) encoding(utf-8)
rename merged_id author_id
save "merge_ids\merged_id_authors", replace

clear
import delimited using "merge_ids\merged_id_institutions.csv", varnames(1) encoding(utf-8)
rename merged_id aff_inst_id
save "merge_ids\merged_id_institutions", replace

clear
import delimited using "merge_ids\merged_id_venues.csv", varnames(1) encoding(utf-8)
rename merged_id journal_id
save "merge_ids\merged_id_venues", replace

clear
import delimited using "merge_ids\merged_id_works.csv", varnames(1) encoding(utf-8)
rename merged_id paper_id
save "merge_ids\merged_id_works", replace


* merge and replace these problematic ids
clear
use "works"


* iterate replacements until no more changes are made
local changes = 1
while `changes' != 0 {
	merge m:1 author_id using "merge_ids\merged_id_authors"
	count if _merge == 3
	local changes = `r(N)'
	drop if _merge == 2
	replace author_id = master_id if _merge == 3
	drop _merge master_id
}

* iterate replacements until no more changes are made
local changes = 1
while `changes' != 0 {
	merge m:1 aff_inst_id using "merge_ids\merged_id_institutions"
	count if _merge == 3
	local changes = `r(N)'
	drop if _merge == 2
	replace aff_inst_id = master_id if _merge == 3
	drop _merge master_id
}


* iterate replacements until no more changes are made
local changes = 1
while `changes' != 0 {
	merge m:1 journal_id using "merge_ids\merged_id_venues"
	count if _merge == 3
	local changes = `r(N)'
	drop if _merge == 2
	replace journal_id = master_id if _merge == 3
	drop _merge master_id
}


* iterate replacements until no more changes are made
local changes = 1
while `changes' != 0 {
	merge m:1 paper_id using "merge_ids\merged_id_works"
	count if _merge == 3
	local changes = `r(N)'
	drop if _merge == 2
	replace paper_id = master_id if _merge == 3
	drop _merge master_id
}

save "works", replace