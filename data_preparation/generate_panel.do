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

format aff_inst_id %12.0g
format author_id %12.0g

* merge uni name
cd "$data_folder"
merge m:1 aff_inst_id using "openalex_data/institutions.dta", keepusing(inst_name)
drop if _merge == 2
drop _merge

bys author_id: egen insts = nvals(aff_inst_id)
* get rid of NBER, CEPR, IFO, Catalyst, IFS, IMF
replace aff_inst_id = . if inlist(aff_inst_id, 1321305853, 4210140326, 1279858714, 1340728805, 1309678057, 4210088027, 4210132957, 47987569, 889315371, 4210099736, 4210129476, 139607695, 1310145890, 197518295, 4210166604) & insts > 1
* merge FED branches
replace aff_inst_id = 1317239608 if strpos(lower(inst_name), "federal reserve")
* some manual corrections
replace aff_inst_id = 111979921 if aff_inst_id == 4210100400
replace aff_inst_id = 1334329717 if aff_inst_id == 55633929
replace aff_inst_id = 7947594 if aff_inst_id == 2802397601

* replace small institutions that could be errors
bys aff_inst_id: replace aff_inst_id = . if _N < 5

drop insts inst_name
bys author_id: egen insts = nvals(aff_inst_id)
* get rid of people with only NBER, CEPR, IFO, Catalyst affiliation
drop if insts == .
drop insts

* Infer affiliation for missing observations
cd "$scripts_folder"
do "data_preparation/infer_affiliation.do" 


* filter out anomalies in affiliation
* some people move back and forth in 1 year - replace these affiliations
gsort author_id +year
by author_id: gen move = 1 if aff_inst_id[_n] != aff_inst_id[_n-1] & _n != 1 & _n != _N
by author_id: gen anomaly = 1 if move == 1 & (aff_inst_id[_n] != aff_inst_id[_n-1] & aff_inst_id[_n] != aff_inst_id[_n+1])
replace aff_inst_id = . if anomaly == 1
* if the institutions surrounding the obs is the same replace to that
by author_id: replace aff_inst_id = aff_inst_id[_n-1] if anomaly == 1 & missing(aff_inst_id) & (aff_inst_id[_n-1] == aff_inst_id[_n+1])
* if the institutions surrounding the obs is not the same replace with p=1/2
gen repprob = runiform() if anomaly == 1

by author_id: replace aff_inst_id = aff_inst_id[_n-1] if anomaly == 1 & missing(aff_inst_id) & repprob < .5
by author_id: replace aff_inst_id = aff_inst_id[_n+1] if anomaly == 1 & missing(aff_inst_id) & repprob > .5

capture drop num_pubs 
capture drop author_paper_n
capture drop aff_inst_id_inf
capture drop below_id
capture drop above_id
* Infer affiliation for missing observations
cd "$scripts_folder"
do "data_preparation/infer_affiliation.do" 

drop repprob anomaly move

* some people have multiple affiliations and they seem like they are switching back and forth
gsort author_id +year
by author_id: gen move = 1 if aff_inst_id[_n] != aff_inst_id[_n-1] & _n != 1 & _n != _N
bys author_id: egen number_of_moves = sum(move)
bys author_id: egen max_age = max(reltime)
bys author_id: gen avg_year_per_move = (max_age / number_of_moves)
bys author_id: egen insts = nvals(aff_inst_id)
* get rid of authors who seem to move super frequently
drop if avg_year_per_move < 5


capture drop num_pubs 
capture drop author_paper_n
capture drop aff_inst_id_inf
capture drop below_id
capture drop above_id
* replace federal reserve insts
* Infer affiliation for missing observations
cd "$scripts_folder"
do "data_preparation/infer_affiliation.do" 


* look at people who might move back and forth frequently
* these people have moved somewhere and back at least once
count if number_of_moves> insts

* merge uni name
cd "$data_folder"
merge m:1 aff_inst_id using "openalex_data/institutions.dta", keepusing(inst_name)
keep if _merge == 3
drop _merge

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

cd "$data_folder"
save "inst_panel", replace

