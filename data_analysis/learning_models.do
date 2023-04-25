* Estimate heterogeneous experience models

clear
cd "$data_folder"
use "sample"

* use lagged values of experience in order to avoid double counting with institution FEs
forvalues x = 1/10 {
	bys author_id (year): gen l1_total_exp_global_`x' = total_exp_global_`x'[_n-1]
}

* very small positive but significant increase past 25th year (?)
areg avg_aif academic_age b10.GLOBAL_CLASS, absorb(author_id) cluster(author_id)

xi: areg avg_aif academic_age academic_age_sq if year > 2000, absorb(author_id) cluster(author_id)
xi: areg avg_aif l1_total_exp_* if year > 2000, absorb(author_id) cluster(author_id)
areg avg_aif total_exp_* b5.GLOBAL_CLASS if year > 2000, absorb(author_id) cluster(author_id)

areg avg_aif l1_total_exp_* b5.GLOBAL_CLASS if year > 2000, absorb(author_id) cluster(author_id)
coefplot, omit base keep(l1_total_exp*) yline(0) vertical nolabels   

areg avg_aif l1_total_exp_* b5.GLOBAL_CLASS if year > 2000 & female == 1, absorb(author_id) cluster(author_id)
estimates store fem 
areg avg_aif l1_total_exp_* b5.GLOBAL_CLASS if year > 2000 & female == 0, absorb(author_id) cluster(author_id)
estimates store male

coefplot (fem, label(Female)) (male, label(Male)), omit base keep(l1_total_exp*) yline(0) nolabels   


* By gender
gen male_academic_age = academic_age * !female
gen male_academic_age_sq = academic_age_sq * !female

xi: areg avg_aif academic_age if year > 2000 & female == 1, absorb(author_id) cluster(author_id)
xi: areg avg_aif academic_age if year > 2000 & female == 0, absorb(author_id) cluster(author_id)

xi: areg avg_aif academic_age male_academic_age if year > 2000, absorb(author_id) cluster(author_id)



* Early career - late career comparison
* These dont really work...
/*
xi: areg avg_aif academic_age academic_age_sq if year > 2000 & reltime < 10, absorb(author_id) cluster(author_id)
xi: areg avg_aif academic_age academic_age_sq if year > 2000 & reltime > 10, absorb(author_id) cluster(author_id)

xi: areg avg_aif total_exp_* if year > 2000 & reltime < 10, absorb(author_id) cluster(author_id)
xi: areg avg_aif total_exp_* if year > 2000 & reltime > 10, absorb(author_id) cluster(author_id)

xi: areg avg_aif academic_age academic_age_sq b5.GLOBAL_CLASS if year > 2000 & reltime < 10, absorb(author_id) cluster(author_id)
xi: areg avg_aif academic_age academic_age_sq b5.GLOBAL_CLASS if year > 2000 & reltime > 10, absorb(author_id) cluster(author_id)

xi: areg avg_aif total_exp_* b5.GLOBAL_CLASS if year > 2000 & reltime < 10, absorb(author_id) cluster(author_id)
xi: areg avg_aif total_exp_* b5.GLOBAL_CLASS if year > 2000 & reltime > 10, absorb(author_id) cluster(author_id)
*/

* Gender difference
forvalues x = 1/10 {
	gen fem_exp_global_`x' = total_exp_global_`x' if female == 1
	replace fem_exp_global_`x' = 0 if female == 0
}

forvalues x = 1/10 {
	gen male_exp_global_`x' = total_exp_global_`x' if female == 0
	replace male_exp_global_`x' = 0 if female == 1
}

areg avg_aif total_exp_* fem_exp_* b5.GLOBAL_CLASS if year > 2000, absorb(author_id) cluster(author_id)

coefplot, omit base keep(total_exp*) xline(0)
coefplot, omit base keep(female_exp*) xline(0)
