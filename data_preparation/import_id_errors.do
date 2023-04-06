* Import ID errors

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

