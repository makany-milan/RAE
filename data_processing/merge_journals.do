* Merge journals
format journal_id %12.0g

cd "$data_folder"

* merge publications to journals
merge m:1 journal_id using "journals/econ_journals.dta", update
drop if _merge == 2
drop _merge

* merge all journals
merge m:1 journal_id using "journals/formatted/all_journals.dta", update
drop if _merge == 2
drop _merge


* find proportion of publications in economics journals
replace econ_journal = 0 if econ_journal == . // overall 17.19%
