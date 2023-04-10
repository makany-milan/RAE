* Generate author panel - expand years between first and last observation

* Store original variable
capture gen author2= author_id

/*
* remove some extreme outliers in the data - potentially corrupt observations
drop if num_pubs > 100

bys author_id year: egen pubs_per_year = count(paper_id)
bys author_id: egen maxpubs_per_year = max(pubs_per_year)
drop if maxpubs_per_year > 10
*/

* Here we are taking the first aff_inst_id - this might casue some issues 

collapse (first) aff_inst_id=aff_inst_id reltime=reltime (sum) total_aif=aif total_top5=top5 (mean) avg_aif=aif (count) year_author_pubs=author2 (mean) avg_coauthors=number_of_authors, by(author_id year)
xtset author_id year
tsfill

* we dont need these variables
/*
foreach lvar of varlist aif jif wjif jci wjci jifwsc wjifwsc citations wcitations top5s wtop5s {
	replace `lvar' = 0 if missing(`lvar')
	gen `lvar'_ma3 = (l1.`lvar' + `lvar' + f1.`lvar') / 3
}
*/

gsort author_id +year
by author_id: replace reltime = _n

format aff_inst_id %12.0g
format author_id %12.0g

bys author_id: egen insts = nvals(aff_inst_id)

* replace small institutions that could be errors
bys aff_inst_id: replace aff_inst_id = . if _N < 5

drop insts
bys author_id: egen insts = nvals(aff_inst_id)
bys author_id: egen ninsts = max(insts)
* get rid of people with only NBER, CEPR, IFO, Catalyst affiliation
drop if ninsts == .
drop insts ninsts

* Infer affiliation for missing observations
cd "$scripts_folder"
do "construct_panel/infer_affiliation.do" 


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
do "construct_panel/infer_affiliation.do" 

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
* make sure data is complete
tsfill
* Infer affiliation for missing observations
cd "$scripts_folder"
do "construct_panel/infer_affiliation.do" 


* look at people who might move back and forth frequently
* these people have moved somewhere and back at least once
count if number_of_moves > insts

* merge uni name
cd "$data_folder"
merge m:1 aff_inst_id using "openalex_data/institutions.dta", keepusing(inst_name)
drop if _merge == 2
drop _merge

* merge region class
cd "$data_folder"
merge m:1 aff_inst_id using "classes/global-regional-classes", keepusing(GLOBAL_CLASS REGION_CLASS)
* nothing should get dropped here realistically
drop if _merge == 2
drop _merge

* generate variable for heterogeneous experience
gsort author_id +year
* create temp vars
by author_id: gen tmp_exp1 = 1 if GLOBAL_CLASS == 1
by author_id: gen tmp_exp2 = 1 if GLOBAL_CLASS == 2
by author_id: gen tmp_exp3 = 1 if GLOBAL_CLASS == 3
by author_id: gen tmp_exp4 = 1 if GLOBAL_CLASS == 4
by author_id: gen tmp_exp5 = 1 if GLOBAL_CLASS == 5
by author_id: gen tmp_exp6 = 1 if GLOBAL_CLASS == 6
by author_id: gen tmp_exp7 = 1 if GLOBAL_CLASS == 7
by author_id: gen tmp_exp8 = 1 if GLOBAL_CLASS == 8
by author_id: gen tmp_exp9 = 1 if GLOBAL_CLASS == 9
by author_id: gen tmp_exp10 = 1 if GLOBAL_CLASS == 10

gsort author_id +year
* generate cumulative experience variable
by author_id: gen total_exp_global_1 = sum(tmp_exp1)
by author_id: gen total_exp_global_2 = sum(tmp_exp2)
by author_id: gen total_exp_global_3 = sum(tmp_exp3)
by author_id: gen total_exp_global_4 = sum(tmp_exp4)
by author_id: gen total_exp_global_5 = sum(tmp_exp5)
by author_id: gen total_exp_global_6 = sum(tmp_exp6)
by author_id: gen total_exp_global_7 = sum(tmp_exp7)
by author_id: gen total_exp_global_8 = sum(tmp_exp8)
by author_id: gen total_exp_global_9 = sum(tmp_exp9)
by author_id: gen total_exp_global_10 = sum(tmp_exp10)

drop tmp_exp*


cd "$data_folder"
save "author_panel", replace

