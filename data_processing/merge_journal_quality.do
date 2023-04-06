* Merge journal quality metrics

cd "$data_folder"

merge m:1 issn using "jcr/formatted/jcr-ec-issn"
drop if _merge == 2
drop _merge

merge m:1 eissn using "jcr/formatted/jcr-ec-issn", update
drop if _merge == 2
drop _merge

merge m:1 eissn using "jcr/formatted/jcr-ec-eissn", update
drop if _merge == 2
drop _merge

merge m:1 issn using "jcr/formatted/jcr-ec-eissn", update
drop if _merge == 2
drop _merge