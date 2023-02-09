* 5a) Generate summary statistics and descriptive graphs

clear
cd "$data_folder"
use "panel"

xtset author_id reltime

twfe jif_ma3, ids(author_id aff_inst_id) maxit(2000)
rename fe1 jif_author_fe
rename fe2 jif_inst_fe

* keep one observations per author
*bys author_id (year): gen unique_fe = _n
