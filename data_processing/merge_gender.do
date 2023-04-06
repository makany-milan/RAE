* merge gender

cd "$data_folder"

merge m:1 author_id using "openalex_data/authors_gender" // 67.41%
drop if _merge == 2
drop _merge
