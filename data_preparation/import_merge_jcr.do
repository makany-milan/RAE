* 4) Import impact factor and other meaasures of journal quality

clear
cd "$data_folder"

capture mkdir "jcr/formatted"

* import all csv files
local counter = 1
local files : dir "$data_folder/jcr" files "*.csv"
foreach x of local files {
	clear
	import delimited using "jcr/`x'", varnames(2)
	
	* get rid of copyright message in the end
	count
	drop in `r(N-)'-1
	drop in `r(N-)'-1
	
	rename journalname journal_name
	rename articleinfluencescore aif
	keep issn eissn totalcitations aif jif jci jcipercentile eigenfactor normalizedeigenfactor jifpercentile yearjif jifwithoutselfcites
	destring totalcitations, replace dpcomma
	destring jif, replace i("N/A")
	destring jci, replace i("N/A")
	destring aif, replace i("N/A")
	destring jifpercentile, replace i("N/A")
	destring jcipercentile, replace i("N/A")
	destring aif, replace i("N/A")
	destring yearjif, replace i("N/A")
	destring jifwithoutselfcites, replace i("N/A")
	
	if `counter' != 1 {
		append using "jcr/formatted/jcr-ec"
	}
	
	save "jcr/formatted/jcr-ec", replace
	local counter = 0
}



* merge based on issn
keep if issn != "N/A"
bys issn: gen dupe = !(_n == 1)
bys dupe: gen _dupe = _n if dupe == 1
replace issn = "" if dupe == 1
bys issn: replace issn = "jcr-dupe" + string(_dupe) if issn == ""
drop dupe _dupe

replace eissn = issn

save "jcr/formatted/jcr-ec-issn", replace

* merge based on e-issn
clear
use "jcr/formatted/jcr-ec", replace
keep if eissn != "N/A"
bys eissn: gen dupe = !(_n == 1)
bys dupe: gen _dupe = _n if dupe == 1
replace eissn = "" if dupe == 1
bys eissn: replace eissn = "jcr-dupe" + string(_dupe) if eissn == ""
drop dupe _dupe

replace issn = eissn

save "jcr/formatted/jcr-ec-eissn", replace


clear
use "works"

merge m:1 issn using "jcr/formatted/jcr-ec-issn"
drop if _merge == 2
drop _merge

merge m:1 eissn using "jcr/formatted/jcr-ec-issn"
drop if _merge == 2
drop _merge

merge m:1 eissn using "jcr/formatted/jcr-ec-eissn", update
drop if _merge == 2
drop _merge

merge m:1 issn using "jcr/formatted/jcr-ec-eissn", update
drop if _merge == 2
drop _merge

save "works", replace
