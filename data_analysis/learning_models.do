* Estimate heterogeneous experience models

clear
cd "$data_folder"
use "sample"

xi: areg avg_aif academic_age if year > 2000 & female == 1, absorb(author_id) cluster(author_id)
xi: areg avg_aif academic_age if year > 2000 & female == 0, absorb(author_id) cluster(author_id)

xi: areg avg_aif academic_age academic_age_sq if year > 2000, absorb(author_id) cluster(author_id)
xi: areg avg_aif total_exp_* if year > 2000, absorb(author_id) cluster(author_id)
areg avg_aif total_exp_* b5.GLOBAL_CLASS if year > 2000, absorb(author_id) cluster(author_id)

areg avg_aif total_exp_* b5.GLOBAL_CLASS if year > 2000, absorb(author_id) cluster(author_id)
coefplot, omit base keep(total_exp*) xline(0)

forvalues x = 1/10 {
	gen fem_exp_global_`x' = total_exp_global_`x' if female == 1
	replace fem_exp_global_`x' = 0 if female == 0
}

forvalues x = 1/10 {
	gen male_exp_global_`x' = total_exp_global_`x' if female == 0
	replace male_exp_global_`x' = 0 if female == 1
}

areg avg_aif total_exp_* fem_* b5.GLOBAL_CLASS if year > 2000, absorb(author_id) cluster(author_id)
areg avg_aif total_exp_* male_* b5.GLOBAL_CLASS if year > 2000, absorb(author_id) cluster(author_id)
