* 4c) Generate author-year & inst-year panels

* author panel
clear
cd "$data_folder"
use "works"

capture gen author2= author_id

collapse (first) aff_inst_id=aff_inst_id reltime=reltime (sum) aif=aif waif=waif jif=jif wjif=wjif jci=jci wjci=wjci jifwsc=jifwithoutselfcites wjifwsc=wjifwsc citations=citations wcitations=wcitations top5s=top5 wtop5s=wtop5 wpubs=wpubs (count) year_author_pubs=author2 (mean) avg_coauthors=number_of_authors, by(author_id year)
xtset author_id year
tsfill

foreach lvar of varlist aif jif wjif jci wjci jifwsc wjifwsc citations wcitations top5s wtop5s {
	replace `lvar' = 0 if missing(`lvar')
	gen `lvar'_ma3 = (l1.`lvar' + `lvar' + f1.`lvar') / 3
}

gsort author_id +year
by author_id: replace reltime = _n


* Infer affiliation for missing observations
cd "$scripts_folder"
do "data_preparation/infer_affiliation.do" 


cd "$data_folder"
save "author_panel", replace


* institution panel
clear
cd "$data_folder"
use "works"

bys year aff_inst_id: egen nauthors = nvals(author_id)

collapse (first) authors=nauthors (sum) aif=aif waif=waif jif=jif wjif=wjif jci=jci wjci=wjci jifwsc=jifwithoutselfcites wjifwsc=wjifwsc citations=citations wcitations=wcitations top5s=top5 wtop5s=wtop5 wpubs=wpubs (count) pubs = author_id, by(aff_inst_id year)

xtset aff_inst_id year
tsfill

gsort aff_inst_id +year

keep if inrange(year, 2000, 2023)
egen inst_tag = tag(aff_inst_id)
bys aff_inst_id: egen max_authors = max(authors)
keep if max_authors > 15


cd "$data_folder"
save "inst_panel", replace


cd "$scripts_folder"
do  "data_preparation/import_institutions"

