* 4) Import impact factor and other meaasures of journal quality

clear
cd "$data_folder"

import delimited using "jcr/jcr-ec.csv", varnames(2)

* get rid of copyright message in the end
count
drop in `r(N-)'-1
drop in `r(N-)'-1

rename journalname journal_name
keep issn eissn totalcitations jif jci jcipercentile eigenfactor normalizedeigenfactor jifpercentile articleinfluencescore yearjif jifwithoutselfcites
destring totalcitations, replace dpcomma
destring jif, replace i("N/A")
destring jifpercentile, replace i("N/A")
destring articleinfluencescore, replace i("N/A")
destring yearjif, replace i("N/A")
destring jifwithoutselfcites, replace i("N/A")


capture mkdir "jcr/formatted"
save "jcr/formatted/jcr-ec", replace

* merge based on issn
keep if issn != "N/A"
save "jcr/formatted/jcr-ec-issn", replace

* merge based on e-issn
clear
use "jcr/formatted/jcr-ec", replace
keep if eissn != "N/A"
save "jcr/formatted/jcr-ec-eissn", replace


clear
use "works"

merge m:1 issn using "jcr/formatted/jcr-ec-issn"
drop if _merge == 2
drop _merge

merge m:1 eissn using "jcr/formatted/jcr-ec-eissn", update
drop if _merge == 2
drop _merge

save "works", replace

* ISSN and EISSN might be mixed up - merge other way around

* merge based on issn
clear
use "jcr/formatted/jcr-ec", replace
keep if eissn != "N/A"
save "jcr/formatted/jcr-ec-issn", replace

* merge based on e-issn
clear
use "jcr/formatted/jcr-ec", replace
keep if issn != "N/A"
save "jcr/formatted/jcr-ec-eissn", replace

clear
use "works"

merge m:1 eissn using "jcr/formatted/jcr-ec-issn", update
drop if _merge == 2
drop _merge

merge m:1 issn using "jcr/formatted/jcr-ec-eissn", update
drop if _merge == 2
drop _merge
