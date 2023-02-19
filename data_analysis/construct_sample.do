* Limit sample of analysis
* Analyse a specific period, with sufficient number of authors at a given dept.
* Use the largest network of connected departments

clear
cd "$data_folder"
use "author_panel"

global timewindow = 4

merge m:1 aff_inst_id using "openalex_data/institutions.dta"
drop if _merge == 2
drop _merge


* limit sample to post 2000
keep if inrange(year, 2000, 2020)
* keep author if they have at least 3 published works in the timeframe
* this filters out inactive authors
bys author_id: egen au_total_pubs_post00 = sum(year_author_pubs)
keep if au_total_pubs_post00 >= 3


* keep if institution has at least 15 active authors in the timeframe
bys aff_inst_id: egen inst_total_authors_post00 = nvals(author_id) if year >= 2000
replace aff_inst_id = -1 if inst_total_authors_post00 <= 15
* here some authors will have empty observations
* if there are a few simply infer affiliation there - small lab or miscoded
* treat them as inactive and drop from sample
bys author_id: egen inst_issue = count(aff_inst_id) if aff_inst_id < 0
drop if inst_issue > 5
replace aff_inst_id = . if !missing(inst_issue)
drop inst_issue

* infer affiliation
cd "$scripts_folder"
do "data_preparation/infer_affiliation.do" 

count if author_id == 2386324
assert `r(N)' == 21

* only keep authors observed for at least timewindow*2 years
capture drop max_age
capture drop min_age
capture drop timeframe
bys author_id: egen max_age = max(reltime)
bys author_id: egen min_age = min(reltime)
gen timeframe = max_age - min_age
keep if timeframe >= $timewindow * 2
drop timeframe min_age max_age

gen female = 1 if inrange(p_female, 0, 1)
replace female = 0 if inrange(p_female, -1, 0)

* create two period model
gen t_period = .

* regenerate move variables
capture drop move number_of_moves
gsort author_id +year
by author_id: gen move = 1 if aff_inst_id[_n] != aff_inst_id[_n-1] & _n != 1 & _n != _N
bys author_id: egen number_of_moves = sum(move)

* generate timeperiods if #moves == 0
bys author_id: egen max_year = max(year)
bys author_id: egen min_year = min(year)
gen before_2010 = 2010-min_year
gen after_2010 = max_year-2011

gsort author_id +year
* if enough observations take 2010 as median
by author_id: replace t_period = 1 if inrange(year, 2007, 2010) & before_2010 > ($timewindow - 1) & after_2010 > ($timewindow - 1) & number_of_moves == 0
by author_id: replace t_period = 2 if inrange(year, 2011, 2014) & before_2010 > ($timewindow - 1) & after_2010 > ($timewindow - 1) & number_of_moves == 0

err
* if not enough observations take the closes available mean to 2010
* before_2010 has to be larger than (timewindow-1) -> go up
* after_2010 has to be smaller than (timewindow-1) -> go down

* generate distance from move if #moves == 1
gen move_dist = .
local max_dist = 20
* sort database
gsort author_id +year

nois _dots 0, title(Finding nearest observations with a move) reps(`max_dist')
foreach dist of numlist 1/`max_dist' {
	quietly by author_id: replace move_dist = (year[_n] - year[_n-`dist']) if move[_n-`dist'] == 1 & missing(move_dist[_n]) & number_of_moves == 1
	quietly by author_id: replace move_dist = (year[_n] - year[_n+`dist']) if move[_n+`dist'] == 1 & missing(move_dist[_n]) & number_of_moves == 1
	*show iteration
	nois _dots `dist' 0
}

edit move year aff_inst_id author_id move_dist number_of_moves

cd "$data_folder"
save "sample", replace
