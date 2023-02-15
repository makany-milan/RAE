cd "$data_folder"
use "authors_panel"

collapse (mean) female, by(year)
tsset year
twoway line female if inrange(year, 1950, 2020)

clear
cd "$data_folder"
use "authors_panel"

keep if inrange(year, 2000, 2020)

gen qual_citation = aif * citations
ttest qual_citation, by(female)
gen wqual_citation = waif * citations
ttest wqual_citation, by(female)