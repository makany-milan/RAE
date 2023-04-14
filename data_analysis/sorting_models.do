* Sorting analysis

clear
cd "$data_folder"
use "sample_fe"

* fix some potential issues
* this step has also been added to "estimate_fixed_effects.do"
replace fe1_female = . if missing(female)
replace fe2_female = . if missing(female)
replace fe1_male = . if missing(female)
replace fe2_male = . if missing(female)

* basic regressions
areg avg_aif b5.GLOBAL_CLASS, absorb(author_id) cluster(author_id)


set scheme white_tableau



* create tag for more period dynamic model
egen author_global_class_tag = tag(author_id GLOBAL_CLASS)

corr fe1_female fe2_female
corr fe1_male fe2_male

corr fe1_female fe2_female if author_global_class_tag
corr fe1_male fe2_male if author_global_class_tag

* specify how many classes to put authors in
global percentiles = 5
xtile pf = fe1_female, n($percentiles)
xtile pm = fe1_male, n($percentiles)

* Some sorting measures for author classes
capture drop sorting
gen sorting = .
* store correlations for all quantiles
foreach x of numlist 1/$percentiles {
	corr fe1_female fe2_female if pf == `x'
	replace sorting = `r(rho)' if pf ==`x' & female == 1
	corr fe1_male fe2_male if pm == `x'
	replace sorting = `r(rho)' if pm ==`x' & female == 0
}

twoway (scatter sorting pm if female == 0, color(blue)) (scatter sorting pf if female == 1, color(red))

* develop counterfactual scenarios

gen fe1 = fe1_female if female == 1
replace fe1 = fe1_male if female == 0

gen fe2 = fe2_female if female == 1
replace fe2 = fe2_male if female == 0

gen prod = fem_prod
replace prod = male_prod if female == 0

ttest prod, by(female) uneq

* counterfactual 1) women have the same department fixed effects as men
gen cf_fe2 = fe2_male
gsort GLOBAL_CLASS cf_fe2
bys GLOBAL_CLASS: replace cf_fe2 = cf_fe2[1]

gen cf_prod = prod - fe2 + cf_fe2

ttest cf_prod, by(female) uneq
* the mean for women is actually smaller
* informative in a policy sense? think more about this - include ?

* counterfactual 2) women are similarly distributed across department classes

* calculate probabilities of type(i) belonging to class(k) for men
* the resulting matrix will have conditional probabilities in each row
* corresponding to the probabilities that a given type (ROWS) belongs to a given class (COLUMNS)

mat probs_male = J($percentiles, 10, .)
foreach y of numlist 1/$percentiles {
	* count total men in a given type
	qui: count if pm == `y'
	local total_intype = `r(N)'
	* fill matrix with relevant probabilities
	foreach x of numlist 1/10{
		qui: count if pm == `y' & GLOBAL_CLASS == `x'
		local type_inclass = `r(N)'
		local val = `type_inclass' / `total_intype'
		mat probs_male[`y', `x'] =  `val'
	}
}

* might aswell do same for women
mat probs_female = J($percentiles, 10, .)
foreach y of numlist 1/$percentiles {
	* count total men in a given type
	qui: count if pf == `y'
	local total_intype = `r(N)'
	* fill matrix with relevant probabilities
	foreach x of numlist 1/10{
		qui: count if pf == `y' & GLOBAL_CLASS == `x'
		local type_inclass = `r(N)'
		local val = `type_inclass' / `total_intype'
		mat probs_female[`y', `x'] =  `val'
	}
}

* Plot distribution of highest productivity types
* stack male female top types
mat top_types = probs_male[$percentiles, 1..10] \ probs_female[$percentiles, 1..10]
* this also gives us a way to visualise probabilities
plotmatrix, mat(top_types) legend(off)

* create new matrix with cumulative probabilities for women
mat cum_probs_female = J($percentiles, 10, .)
foreach y of numlist 1/$percentiles {
	* count total men in a given type
	qui: count if pf == `y'
	local total_intype = `r(N)'
	* fill matrix with relevant probabilities
	foreach x of numlist 1/10{
		qui: count if pf == `y' & GLOBAL_CLASS == `x'
		local type_inclass = `r(N)'
		local val = `type_inclass' / `total_intype'
		if `x' == 1 {
			mat cum_probs_female[`y', `x'] =  `val'
		}
		else {
			local inx = `x'-1
			local val = cum_probs_female[`y', `inx'] +`val'
			mat cum_probs_female[`y', `x'] = `val'
		}
	}
}
* create new matrix with cumulative probabilities for men
mat cum_probs_male = J($percentiles, 10, .)
foreach y of numlist 1/$percentiles {
	* count total men in a given type
	qui: count if pm == `y'
	local total_intype = `r(N)'
	* fill matrix with relevant probabilities
	foreach x of numlist 1/10{
		qui: count if pm == `y' & GLOBAL_CLASS == `x'
		local type_inclass = `r(N)'
		local val = `type_inclass' / `total_intype'
		if `x' == 1 {
			mat cum_probs_male[`y', `x'] =  `val'
		}
		else {
			local inx = `x'-1
			local val = cum_probs_male[`y', `inx'] +`val'
			mat cum_probs_male[`y', `x'] = `val'
		}
	}
}



capture program drop simulate_counterfactual
program simulate_counterfactual, eclass
	quietly {
		* generate new counterfactual class and productivity variables
		* observe new gender gap
		capture drop cf_prod
		capture drop cf_class
		capture drop rand
		gen cf_prod = .
		gen cf_class = .
		* decision
		* set counterfactual at author or observation level
		* current count is at observation level - continue to do that way
		*bys author_id: gen rand =  runiform()
		gen rand = runiform()
		foreach pers_type of numlist 1/$percentiles {
			foreach glob_class of numlist 1/10 {
				if `glob_class' == 10 {
					* if it hasnt been classified yet and fits the type group that means assign to group 10
					replace cf_class = 10 if female == 1 & pf == `pers_type' & missing(cf_class)
				}
				else {
					replace cf_class = `glob_class' if female == 1 & `pers_type' == pf & missing(cf_class) & rand < cum_probs_male[`pers_type', `glob_class']
				}
				
			}
		}	
		* same randomisation for men ?
		foreach pers_type of numlist 1/$percentiles {
			foreach glob_class of numlist 1/10 {
				if `glob_class' == 10 {
					* if it hasnt been classified yet and fits the type group that means assign to group 10
					replace cf_class = 10 if female == 0 & pm == `pers_type' & missing(cf_class)
				}
				else {
					replace cf_class = `glob_class' if female == 0 & `pers_type' == pm & missing(cf_class) & rand < cum_probs_male[`pers_type', `glob_class']
				}
				
			}
		}	
	}
end

* compare output gap
ttest prod, by(female)
ttest cf_prod, by(female)


* sorting graphs
*bys pf:su fe1_female
*bys pm: su fe1_male

bys GLOBAL_CLASS pm : egen numerator = nvals(author_id) if !missing(pm)
bys GLOBAL_CLASS : egen denominator = nvals(author_id) if !missing(pm)

bys GLOBAL_CLASS pf : egen numerator_f = nvals(author_id) if !missing(pf)
bys GLOBAL_CLASS : egen denominator_f = nvals(author_id) if !missing(pf)
replace numerator = numerator_f if missing(numerator)
replace denominator = denominator_f if missing(denominator)

gen share = numerator / denominator

gen percentile = pm
replace percentile = pf if percentile == .

collapse (mean) share, by(GLOBAL_CLASS female percentile)
drop if share == .
reshape wide share, i(GLOBAL_CLASS female) j(percentile)
graph bar share*, over(GLOBAL_CLASS) by(female) stack percent




