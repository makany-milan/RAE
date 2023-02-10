* 5a) Generate summary statistics and descriptive graphs

clear
cd "$data_folder"
use "panel"


* average number of years
capture ssc install schemepack
set scheme white_tableau
bys author_id (reltime): gen active_years = _N
su active_years if reltime == 1, det

* drop authors with one active year
drop if active_years == 1

* count the number of authors and departments
egen tag = tag(author_id)
egen unique = total(tag)
tab unique
drop tag unique

egen tag = tag(aff_inst_id)
egen unique = total(tag)
tab unique
drop tag unique

* active years
su active_years if reltime==1, det
hist active_years if reltime == 1, bin(75)

* AKM
xtset author_id reltime

twfe jif_ma3, ids(author_id aff_inst_id) maxit(2000)
rename fe1 jif_author_fe
rename fe2 jif_inst_fe
