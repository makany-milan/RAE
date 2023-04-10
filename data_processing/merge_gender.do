* merge gender

cd "$data_folder"

merge m:1 author_id using "openalex_data/authors_gender" // 67.41%
drop if _merge == 2
drop _merge

gen female = .
replace female = 1 if inrange(p_female, .8, 1)
replace female = 0 if inrange(p_female, -1, -.8)