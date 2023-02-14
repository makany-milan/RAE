clear
cd "$data_folder"
import delimited using "openalex_data/institutions_data.csv", delimiter(";") encoding(utf-8) bindquotes(strict) maxquotedrows(unlimited) asdouble
rename inst_id aff_inst_id

save "openalex_data/institutions", replace
