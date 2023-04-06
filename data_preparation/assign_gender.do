* Assign gender to Economists

capture program drop normalise_name
program normalise_name
	* This is very similar to what the script clean_names.py does without generating a new variable
	args varname
	replace `varname' = ustrupper(ustrnormalize(`varname', "nfd" ))
	
	* Mark observations with polluting characters and words - ONLY FOR SPANISH NAMES
	* gen polluting_ = regexm("`varname'", `"[^a-zA-Z0-9_ ]"')
	* replace polluting_name = 1 if strpos("`varname'", " DE")
	
	* Remove whitespaces, etc.
	foreach i of numlist 1/10{
		replace `varname' = subinstr(`varname',"  ", " ", .)
	}
	
	replace `varname' = strtrim(`varname')
	replace `varname' = stritrim(`varname')
	end

* Construct name frequency file

clear
cd "$data_folder"

local data_compiled = fileexists("$data_folder/gender/frequency_gender_ssa.dta")
if !`data_compiled' {
	* remove function to avoid errors
	program drop normalise_name
	cd "$scripts_folder"
	do "data_preparation/compile_ssa_names"
	* call itself once data is compiled
	do "data_preparation/assign_gender"
}

* Import all potential economists from OpenAlex

clear
cd "$data_folder"
import delimited using "openalex_data/openalex-econ_authors.csv", encoding(utf-8) delimiter(";") bindquotes(strict)
keep author_id author_name

* Drop corrupt observations
* drop empty observations
drop if author_name == "N/A"
drop if missing(author_name)
* remove special characters, etc.
split author_name, gen(name_part_)


gen name_last_part = .
* normalise name
unab vars: name_part_*
* remove surenames from the list of merged values
local loop = 1
foreach v of local vars {
	local repl = `loop' - 1
	replace `v' = "" if strpos("`v'", ".") & length("`v'") < 3
	replace name_last_part = `repl' if `v' == "" & missing(name_last_part)
	if `loop' == 1 {
		drop if `v' == "" & missing(name_last_part)
	}
	else {
		replace name_part_`repl' = "" if `v' == "" & missing(name_last_part)
	}
	local loop = `loop' + 1
}

* delete observations without name
drop if name_last_part == 0
drop if author_name == "N/A"
drop if name_last_part == 1 & length(name_part_1) <= 3

* merge to each part of the name
unab vars: name_part_*
local loop = 1
foreach v of local vars {
	gen name_mergevar = `v'
	normalise_name name_mergevar
	merge m:1 name_mergevar using "gender/frequency_gender_ssa", keepusing(p_female)
	drop if _merge == 2
	drop _merge
	rename p_female p_female_`loop'
	local loop = `loop' + 1
	drop name_mergevar
}

* merge probabilities
unab p: p_female_*
egen p_female = rmean(`p')

drop name_* p_female_*

save "openalex_data/authors", replace

* save those observations where prediction is high
gen high_prob = 1 if (p_female > .9 | p_female < -.9) & !missing(p_female)

keep if high_prob == 1
drop high_prob

save "openalex_data/authors_gender", replace


* Get neural network prediction for gender
* Create list of names not matched to SSA
