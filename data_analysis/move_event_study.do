* summary statistics on mobility and move event study

clear
cd "$data_folder"
use "sample"

set scheme white_tableau

* merge institution latent types
merge m:1 aff_inst_id using "classes/global-regional-classes", keepusing(GLOBAL_CLASS REGION_CLASS region)
keep if _merge == 3
drop _merge

bys author_id: egen author_moves = count(move)


* generate event time if #moves == 1
* sort database
gsort author_id +year
* generate year of move
by author_id: gen year_of_move = year if move == 1 & number_of_moves == 1
gsort author_id -year_of_move
by author_id: replace year_of_move = year_of_move[1] if number_of_moves == 1

* generate academic age of move
by author_id: gen age_of_move = academic_age if move == 1 & number_of_moves == 1
gsort author_id -age_of_move
by author_id: replace age_of_move = age_of_move[1] if number_of_moves == 1

gen event_time = year - year_of_move
gen move_type = 1 if inrange(age_of_move, 1, 3)
replace move_type = 2 if inrange(age_of_move, 4, 10)
replace move_type = 3 if inrange(age_of_move, 11, .)


gsort author_id -prop_inactive 
by author_id: replace prop_inactive = prop_inactive[1]

drop if prop_inactive > .5

collapse (mean) wprod=wprod (p90) wprod_90=wprod (p10) wprod_10=wprod, by(event_time female move_type)
drop if female == .
drop if event_time == .

drop if move_type == 1

twoway (line wprod event_time if female == 0, color(blue)) (line wprod event_time if female == 1, color(red)), xline(0) by(move_type)

xtset (female move_type) event_time
twoway (tsline wprod if female == 0 & inrange(event_time, -5, 10), color(blue)) (tsline wprod if female == 1 & inrange(event_time, -5, 10), color(red)), xline(0)