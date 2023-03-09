* Limit sample of analysis
* Analyse a specific period, with sufficient number of authors at a given dept.
* Use the largest network of connected departments

clear
cd "$data_folder"
use "author_panel"

global timewindow = 5



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
bys aff_inst_id: egen inst_total_authors_post00 = nvals(author_id)
replace aff_inst_id = -1 if inst_total_authors_post00 < 15
* here some authors will have empty observations
* if there are a few simply infer affiliation there - small lab or miscoded
* treat them as inactive and drop from sample
bys author_id: egen inst_issue = count(aff_inst_id) if aff_inst_id < 0
gen original_issue = 1 if !missing(inst_issue)
gsort author_id -inst_issue
by author_id: replace inst_issue = inst_issue[1] if inst_issue[1] > 7

drop if inst_issue > 7 & !missing(inst_issue)

replace aff_inst_id = . if !missing(original_issue)
replace inst_name = "" if !missing(original_issue)
bys author_id: egen insts_after_drop = nvals(aff_inst_id), missing
drop if insts_after_drop == 1 & aff_inst_id == .
drop inst_issue original_issue


* infer affiliation
cd "$scripts_folder"
do "data_preparation/infer_affiliation.do"

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
by author_id: gen move = 1 if aff_inst_id[_n] != aff_inst_id[_n-1] & _n!=1 & _n!=_N
bys author_id: egen number_of_moves = sum(move)

* drop people that move too frequently
* potentially corrupt observations
keep if number_of_moves <= 5

gen academic_age = .
* generate timeperiods if #moves == 0
bys author_id: egen max_year = max(year)
bys author_id: egen min_year = min(year)
gen before_2010 = 2010-min_year
gen after_2010 = max_year-2010

gsort author_id +year
* if enough observations take 2010 as median
by author_id: replace t_period = 1 if inrange(year, 2007, 2010) & before_2010 >= ($timewindow -1) & after_2010 >= $timewindow & number_of_moves == 0
by author_id: replace t_period = 2 if inrange(year, 2011, 2014) & before_2010 >= ($timewindow -1) & after_2010 >= $timewindow & number_of_moves == 0
by author_id: replace academic_age = reltime[_n+before_2010] if before_2010 >= ($timewindow -1) & after_2010 >= $timewindow & number_of_moves == 0


* if not enough observations take the closes available mean to 2010
* before_2010 has to be larger than (timewindow-1) -> go up
* after_2010 has to be smaller than (timewindow) -> go down
gen med_year = .

gen move_up = ($timewindow - 1) - (2010-min_year) if before_2010 < ($timewindow -1) & number_of_moves == 0
replace med_year = 2010+move_up if before_2010 < ($timewindow -1)

gen move_down = ($timewindow) - (max_year-2010) if after_2010 < $timewindow & number_of_moves == 0
replace med_year = 2010-move_down if after_2010 < $timewindow

drop move_up move_down
* generate timeframe around median year
by author_id: replace t_period = 1 if inrange(year, (med_year - ($timewindow - 1)), med_year) & !missing(med_year) & missing(t_period) & number_of_moves == 0
by author_id: replace t_period = 2 if inrange(year, (med_year+1), (med_year+4)) & !missing(med_year) & missing(t_period) & number_of_moves == 0

/*
* alternative solution
by author_id: gen t1s = med_year- ($timeframe - 1)
by author_id: gen t1e = med_year
by author_id: gen t2s = med_year + 1
by author_id: gen t2e = med_year + 4
* generate timeframe around median year
by author_id: replace t_period = 1 if inrange(year, t1s, t1e) & !missing(med_year) & missing(t_period)
by author_id: replace t_period = 1 if inrange(year, t2s, t2e) & !missing(med_year) & missing(t_period)
*/


* generate timeperiods if #moves == 1
* sort database
gsort author_id +year


by author_id: gen year_of_move = year if move == 1 & number_of_moves == 1
gsort author_id -year_of_move
by author_id: replace year_of_move = year_of_move[1] if number_of_moves == 1

* drop those people where there are insufficient time periods
drop if inrange(year_of_move, 2000, 2000 + ($timewindow - 2)) & number_of_moves == 1
drop if inrange(year_of_move, (2020 - $timewindow -1), 2020) & number_of_moves == 1

* infer time periods
by author_id: replace t_period = 1 if inrange(year, (year_of_move - $timewindow ), (year_of_move - 1)) & !missing(year_of_move) & missing(t_period) & number_of_moves == 1
by author_id: replace t_period = 2 if inrange(year, (year_of_move), (year_of_move+3)) & !missing(year_of_move) & missing(t_period) & number_of_moves == 1

drop year_of_move

* generate timeperiods if #moves > 1
capture drop time_since_move max_year_since_move
capture drop time_before_move max_year_before_move

gen time_since_move = .
replace time_since_move = 0 if move == 1 & number_of_moves > 1 & !missing(number_of_moves)

gsort author_id +year

by author_id: replace time_since_move = 1 if _n == 1 & number_of_moves > 1 & !missing(number_of_moves)
by author_id: replace time_since_move = time_since_move[_n-1] + 1 if _n != 1 & move != 1 & number_of_moves > 1 & !missing(number_of_moves)
by author_id: egen max_year_since_move = max(time_since_move)


gen dist_from_2010 = abs(year-2010)

gsort author_id -year
gen time_before_move = .
by author_id: replace time_before_move = 1 if _n == 1 & number_of_moves > 1 & !missing(number_of_moves)
by author_id: replace time_before_move = 1 if move == 1 & number_of_moves > 1 & !missing(number_of_moves)
replace time_before_move = 0 if move == 1 & number_of_moves > 1 & !missing(number_of_moves)
by author_id: replace time_before_move = time_before_move[_n-1] + 1 if move != 1 & number_of_moves > 1 & !missing(number_of_moves) & !missing(time_before_move[_n-1])
by author_id: egen max_time_before_move = max(time_before_move)


gen good_move = .
gsort author_id +year
by author_id: replace good_move = 1 if move == 1 & time_since_move[_n-1] >= ($timewindow ) & time_before_move[_n+1] >= ($timewindow - 1) & number_of_moves > 1

gen year_of_move = .
gsort author_id +good_move +dist_from_2010
by author_id: replace year_of_move = year[1] if good_move[1] == 1

gsort author_id +year
by author_id: replace t_period = 1 if inrange(year, (year_of_move - $timewindow ), (year_of_move - 1)) & !missing(year_of_move) & missing(t_period) & number_of_moves > 1
by author_id: replace t_period = 2 if inrange(year, (year_of_move), (year_of_move+3)) & !missing(year_of_move) & missing(t_period) & number_of_moves > 1


gsort author_id -t_period
by author_id: replace academic_age = t_period[3]
by author_id: replace academic_age = t_period[2] if missing(academic_age)
by author_id: replace academic_age = t_period[1] if missing(academic_age)


collapse (first) academic_age female aff_inst_id inst_name qs_econ_2021_rank qs_overall_2022_rank qs_econ_citations qs_faculty_student_ratio_score qs_size cwur_worldrank the_ec_rank the_ec_industry_income the_research_rank the_citations inst_country (mean) wprod log_wprod prod log_prod aif waif jif wjif jci wjci jifwsc wjifwsc citations wcitations top5s wtop5s wpubs year_author_pubs avg_coauthors ,by(author_id t_period)
drop if t_period == .

* get rid of inactive authors
bys author_id: gen inactive = 1 if aif == 0
gsort author_id +inactive
by author_id: replace inactive = 1 if inactive[1] == 1
*by author_id: gen both_inactive = 1 if inactive[1] == 1 & inactive[2] == 1
drop if inactive == 1
drop inactive


count if author_id == 29340645
assert `r(N)' != 0

drop if female == .

count if author_id == 29340645
assert `r(N)' != 0

cd "$data_folder"
save "sample", replace
