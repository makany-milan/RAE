* 3a) Filter economics authors against an arbitrary threshold

* if ec_prop is undefined use value here
if missing("$ec_prop_cutoff") {
    * using the arbitrary value of 50%
    global ec_prop_cutoff = 0.5
}


* generate proportion of economics works by author
bys author_id: egen ec_prop = mean(econ_journal)

* keep observations of authors who publish in economics
keep if ec_prop > $ec_prop_cutoff

save "works", replace