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

* generate variable for upward, downward move
gsort author_id +event_time
by author_id: gen pre_move_class = GLOBAL_CLASS if event_time == 0
by author_id: gen post_move_class = GLOBAL_CLASS if event_time == 1
gsort author_id -pre_move_class
by author_id: replace pre_move_class = pre_move_class[1] if number_of_moves == 1
gsort author_id -post_move_class
by author_id: replace post_move_class = post_move_class[1] if number_of_moves == 1

gen move_across = 0 if pre_move_class == post_move_class & number_of_moves == 1
replace move_across = 1 if pre_move_class < post_move_class & number_of_moves == 1
replace move_across = -1 if pre_move_class > post_move_class & number_of_moves == 1

gsort author_id -prop_inactive 
by author_id: replace prop_inactive = prop_inactive[1]

*drop if prop_inactive > .5

tab move_type
tab move_across

snapshot save

*collapse (mean) wprod=wprod (p90) wprod_90=wprod (p10) wprod_10=wprod, by(event_time female move_type)
collapse (mean) prod=year_author_pubs, by(event_time female move_type)
drop if female == .
drop if event_time == .

drop if move_type == 1

twoway (line prod event_time if female == 0, color(blue)) (line prod event_time if female == 1, color(red)), xline(0) by(move_type)
egen panelid = group(female move_type)
xtset (panelid) event_time
twoway (tsline prod if female == 0 & move_type == 2 &inrange(event_time, -5, 10), color(blue)) (tsline prod if female == 1 & move_type == 2 & inrange(event_time, -5, 10), color(red)), xline(0)


snapshot restore 1
snapshot erase _all

collapse (mean) prod=year_author_pubs, by(event_time female move_type)
drop if female == .
drop if event_time == .

drop if move_type == 1

twoway (line prod event_time if female == 0, color(blue)) (line prod event_time if female == 1, color(red)), xline(0) by(move_type)
egen panelid = group(female move_type)
xtset (panelid) event_time
twoway (tsline prod if female == 0 & move_type == 2 & inrange(event_time, -5, 10), color(blue)) (tsline prod if female == 1 & move_type == 2 & inrange(event_time, -5, 10), color(red)), xline(0)
