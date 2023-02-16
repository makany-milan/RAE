* share of women
cd "$data_folder"
use "author_panel"

set scheme white_tableau

capture gen female = 1 if inrange(p_female, 0, 1)
replace female = 0 if inrange(p_female, -1, 0)

keep if inrange(year, 1990, 2022)

collapse (mean) female if num_pubs > 0, by(year)
tsset year
twoway tsline female


* do women get cited more?
clear
cd "$data_folder"
use "author_panel"

capture gen female = 1 if inrange(p_female, 0, 1)
replace female = 0 if inrange(p_female, -1, 0)

keep if inrange(year, 1990, 2020)

gen qual_citation = aif * citations
ttest qual_citation, by(female)
gen wqual_citation = waif * citations
ttest wqual_citation, by(female)


* quality of research - analyse citation networks!!
clear
cd "$data_folder"
use "author_panel"

capture gen female = 1 if inrange(p_female, 0, 1)
replace female = 0 if inrange(p_female, -1, 0)

keep if inrange(year, 1990, 2020)

collapse (mean) aif=aif waif=waif (p10) lbaif=aif lbwaif=waif (p90) ubaif=aif ubwaif=waif if waif > 0, by(female year)

twoway (tsline aif if female == 1) (tsline aif if female == 0)

* research output
clear
cd "$data_folder"
use "sample_fe"

collapse (firstnm) phi_fem = phi_k_female phi_male = phi_k_male name=inst_name ,by(aff_inst_id)

twoway (scatter phi_fem phi_male if (inrange(phi_fem, -2, -.5) | inrange(phi_fem, .5, 2)) & (inrange(phi_male, -2, -.5) | inrange(phi_male, .5, 2))) (function y=x, range(-2 2) legend(off)) (scatter phi_fem phi_male if strpos(lower(name), "warwick") | strpos(lower(name), "university of chicago") | strpos(lower(name), "university of belgrade") | strpos(lower(name), "yokohama national university"), mlabel(name))


