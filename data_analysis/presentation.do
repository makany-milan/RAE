* share of women
cd "$data_folder"
use "author_panel"

set scheme white_tableau

capture gen female = 1 if inrange(p_female, 0, 1)
replace female = 0 if inrange(p_female, -1, 0)

keep if inrange(year, 1990, 2022)

collapse (mean) female, by(year)
tsset year
twoway tsline female


* do women get cited more?
clear
cd "$data_folder"
use "author_panel"

capture gen female = 1 if inrange(p_female, 0, 1)
replace female = 0 if inrange(p_female, -1, 0)

keep if inrange(year, 1990, 2022)

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

keep if inrange(year, 1990, 2022)

collapse (mean) aif=aif waif=waif (p10) lbaif=aif lbwaif=waif (p90) ubaif=aif ubwaif=waif, by(female year)

tsline waif aif, by(female)