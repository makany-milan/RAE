* Import affiliations
clear
cd "$data_folder"
import delimited using "openalex_data/openalex-econ_affiliations.csv", delimiter(";") encoding(utf-8) bindquotes(strict) maxquotedrows(unlimited)

format aff_inst_id %12.0g
format author_id %12.0g

* drop some corrupt observations
drop if year > 2023

* check the proportion of movers
egen moves = nvals(aff_inst_id), by(author_id)
replace moves = moves - 1 if moves != 0
gen mover = moves != 0 // 77.37% of the sample are movers

assert mover != .
assert moves != .

* remove string variable - potentially check later for consistency
drop aff_inst_str

* there are some duplicate observations - delete
bys paper_id author_id: gen dupe = _n
keep if dupe == 1
drop dupe

capture mkdir "affiliations"
save "affiliations/affiliations.dta", replace


* generate a list of affiliations where we are absolutely certain
* save file for those observations where we do not see within year movement
bys author_id year: egen withinyear = nvals(aff_inst_id)
keep if withinyear == 1
* keep one record of affiliations from multiple publications
bys year author_id: gen dupe = _n
keep if dupe == 1
drop dupe
keep author_id aff_inst_id year moves mover
rename aff_inst_id aff_inst_id_inferred

save "affiliations/affiliations_fix_year.dta", replace