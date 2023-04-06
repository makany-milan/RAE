* 4b) Disambiguate IDs

cd "$data_folder"

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
