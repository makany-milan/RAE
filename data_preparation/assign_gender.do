* 4a) Assign gender

*** COPY CODE FROM WOMEN IN ACADEMIA PROJECT TO MERGE SSA GENDER

clear
cd "$data_folder"
import delimited using "openalex_data/openalex-econ_authors.csv", encoding(utf-8) delimiter(";") bindquotes(strict)
keep author_id author_name
save "openalex_data/authors", replace


*** SPLIT SURNAME FORENAME PYTHON CODE FROM WOMEN IN ACADEMIA