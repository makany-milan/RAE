* Sorting analysis

clear
cd "$data_folder"
use "sample_fe"

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

