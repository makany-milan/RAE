* Import publications
clear
cd "$data_folder"
import delimited using "openalex_data/openalex-econ_works.csv", delimiter(";") encoding(utf-8) bindquotes(strict) maxquotedrows(unlimited)
* 76.27% of publications are journal articles
keep if work_type == "journal-article"
drop work_type
* remove title of the work - potentially useful later for topic modelling
drop title
* remove doi number - potentially useful for later
drop doi
* remove xconcepts - potentially useful later
drop xconcept*

* there are some duplicate observations - delete
bys paper_id author_id: gen dupe = _n
keep if dupe == 1
drop dupe

bys paper_id: gen number_of_authors = _N

format author_id %12.0g
format paper_id %12.0g
format journal_id %12.0g

save "works.dta", replace