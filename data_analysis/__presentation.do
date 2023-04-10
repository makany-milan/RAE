* share of women
clear
cd "$data_folder"
use "author_panel.dta"

set scheme white_tableau

capture gen female = 1 if inrange(p_female, 0, 1)
replace female = 0 if inrange(p_female, -1, 0)

collapse (mean) female if num_pubs > 0, by(year)
tsset year
twoway tsline female if inrange(year, 1970, 2022), ytitle(Share of women in economics) xtitle(Year)

* share of women by region
clear
cd "$data_folder"
use "author_panel.dta"


* merge countries to regions
merge m:1 inst_country using "regions/regions"

set scheme white_tableau

capture gen female = 1 if inrange(p_female, 0, 1)
replace female = 0 if inrange(p_female, -1, 0)

collapse (first) region (mean) female if num_pubs > 0, by(year region_id)
xtset region_id year
twoway (tsline female if inrange(year, 1990, 2022) & (region=="UK")) /// 
		(tsline female if inrange(year, 1990, 2022) & (region=="US")) ///
		(tsline female if inrange(year, 1990, 2022) & (region=="EU")), ytitle(Share of women in economics) xtitle(Year) legend(label(1 "UK")  label(2 "US") label(3 "EU"))

* number of pubs
clear
cd "$data_folder"
use "author_panel"

set scheme white_tableau

capture gen female = 1 if inrange(p_female, 0, 1)
replace female = 0 if inrange(p_female, -1, 0)

keep if inrange(year, 1990, 2020)

collapse (mean) pubs=year_author_pubs avg_coauthors=avg_coauthors if year_author_pubs > 0, by(female year)
xtset female year
twoway (tsline pubs if female == 1, color(red)) (tsline pubs if female == 0, color(blue)) (tsline avg_coauthors if female == 1, color(red) lp(dash)) (tsline avg_coauthors if female == 0, color(blue) lp(dash)) 


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


