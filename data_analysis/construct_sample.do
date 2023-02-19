* Limit sample of analysis
* Analyse a specific period, with sufficient number of authors at a given dept.
* Use the largest network of connected departments

clear
cd "$data_folder"
use "author_panel"

merge m:1 aff_inst_id using "openalex_data/institutions.dta"
keep if _merge == 3
drop _merge

gen female = 1 if inrange(p_female, 0, 1)
replace female = 0 if inrange(p_female, -1, 0)

* limit sample to post 2000
keep if inrange(year, 2000, 2020)
* keep author if they have at least 3 published works in the timeframe
* this filters out inactive authors
bys author_id: egen au_total_pubs_post00 = sum(year_author_pubs)
keep if au_total_pubs_post00 >= 3

* keep if institution has at least 15 active authors in the timeframe
bys aff_inst_id: egen inst_total_authors_post00 = nvals(author_id) if year >= 2000
keep if inst_total_authors_post00 >= 15

* 287,591 obs w/ gender

* create two period model

* regenerate move variables
capture drop move number_of_moves
gsort author_id +year
by author_id: gen move = 1 if aff_inst_id[_n] != aff_inst_id[_n-1] & _n != 1 & _n != _N
bys author_id: egen number_of_moves = sum(move)

* generate distance from move
gen below_dist = .
gen above_dist = .
local max_dist = 20
* sort database
gsort author_id +year

nois _dots 0, title(Finding nearest observations with a move) reps(`max_dist')
foreach dist of numlist 1/`max_dist' {
	quietly by author_id: replace below_dist = (year[_n-`dist'] - year[_n]) if move[_n-`dist'] == 1 & !missing(move[_n-`dist']) & missing(below_dist)
	quietly by author_id: replace above_dist = (year[_n+`dist'] - year[_n]) if move[_n+`dist'] == 1 & !missing(move[_n+`dist']) & missing(above_dist)
	*show iteration
	nois _dots `dist' 0
}

edit move year aff_inst_id author_id below_dist above_dist

cd "$data_folder"
save "sample", replace
