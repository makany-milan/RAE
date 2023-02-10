* 4a) Assign gender

* Compile list of names from SSA database

program normalise_name
	* This is very similar to what the script clean_names.py does without generating a new variable
	* For consistency's sake use the Python code whenever possible beforehand.
	args varname
	replace `varname' = ustrupper(ustrnormalize(`varname', "nfd" ))
	end

clear
cd $data_folder
capture erase "$data_folder/gender/frequency_gender_ssa"
local files: dir "$data_folder/gender/ssa_names" files "*.txt"

foreach file in `files' {
	clear
	qui {
		import delimited using "gender/ssa_names/`file'", delimiter(",") varnames(nonames)
		rename v1 name
		rename v2 gender
		rename v3 frequency
		
		gen female_forename_frequency = frequency if gender == "F"
		gen male_forename_frequency = frequency if gender == "M"
		
		capture append using "gender/ssa_temp"
		
		save "gender/ssa_temp", replace
	}
}

normalise_name name

collapse (sum) female_forename_frequency (sum) male_forename_frequency, by(name)

replace female_forename_frequency = 0 if female_forename_frequency == .
replace male_forename_frequency = 0 if male_forename_frequency == .
gen p_female = (female_forename_frequency - male_forename_frequency) / (female_forename_frequency + male_forename_frequency)

gen name_mergevar = name

capture erase "gender/ssa_temp.dta"
cd $data_folder
save "gender/frequency_gender_ssa", replace
