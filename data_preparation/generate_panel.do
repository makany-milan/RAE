* 4c) Generate pub quality author-year panel

clear
cd "$data_folder"
use "works"

* Generate variable for top5 publication
gen top5 = 0
replace top5 = 1 if journal_name == "Quarterly Journal of Economics"
replace top5 = 1 if journal_name == "Econometrica"
replace top5 = 1 if journal_name == "The American Economic Review"
replace top5 = 1 if journal_name == "Journal of Political Economy"
replace top5 = 1 if journal_name == "The Review of Economic Studies"

* 2.52% of all publications in Top5

* generate relative time t=1: time of first publication
gsort author_id +year
by author_id: gen first_pub = year[1]
by author_id: gen reltime = (year - first_pub) + 1

* some corrupt observations
* some reltime values are unrealistic - data issues is reltime above 75 ?
drop if reltime > 75

gen wjif = jif / number_of_authors
gen wjci = jci / number_of_authors
gen wjifwsc = jifwithoutselfcites / number_of_authors
gen wcitations = citations / number_of_authors
gen wtop5 = top5 / number_of_authors

collapse (first)aff_inst_id=aff_inst_id reltime=reltime (sum) jif=jif wjif=wjif jci=jci wjci=wjci jifwsc=jifwithoutselfcites wjifwsc=wjifwsc citations=citations wcitations=wcitations top5s=top5 wtop5s=wtop5, by(author_id year)
xtset author_id year
tsfill

foreach lvar of varlist jif wjif jci wjci jifwsc wjifwsc citations wcitations top5s wtop5s {
	replace `lvar' = 0 if missing(`lvar')
	gen `lvar'_ma3 = (l1.`lvar' + `lvar' + f1.`lvar') / 3
}

gsort author_id +year
by author_id: replace reltime = _n


* Infer affiliation for missing observations
cd "$scripts_folder"
do "data_preparation/infer_affiliation.do" 

cd "$data_folder"
save "panel", replace