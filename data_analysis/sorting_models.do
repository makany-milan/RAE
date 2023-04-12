* Sorting analysis

clear
cd "$data_folder"
use "sample_fe"

set scheme white_tableau

* create tag for more period dynamic model
egen author_global_class_tag = tag(author_id GLOBAL_CLASS)

corr fe1_female fe2_female
corr fe1_male fe2_male

corr fe1_female fe2_female if author_global_class_tag
corr fe1_male fe2_male if author_global_class_tag

* sorting graphs
global percentiles = 4
xtile pf = fe1_female, n($percentiles)
xtile pm = fe1_male, n($percentiles)
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

