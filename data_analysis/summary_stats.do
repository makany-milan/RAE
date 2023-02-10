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

* keep one observations per author
*bys author_id (year): gen unique_fe = _n

* time series
collapse (mean) jif_ma3=jif_ma3 wjif_ma3=wjif_ma3 jci_ma3=jci_ma3 wjci_ma3=wjci_ma3 jifwsc_ma3=jifwsc_ma3 wjifwsc_ma3=wjifwsc_ma3 citations_ma3=citations_ma3 wcitations_ma3=wcitations_ma3 top5s_ma3=top5s_ma3 wtop5s_ma3=wtop5s_ma3 (p5) jif_ma3_p5=jif_ma3 wjif_ma3_p5=wjif_ma3 jci_ma3_p5=jci_ma3 wjci_ma3_p5=wjci_ma3 jifwsc_ma3_p5=jifwsc_ma3 wjifwsc_ma3_p5=wjifwsc_ma3 citations_ma3_p5=citations_ma3 wcitations_ma3_p5=wcitations_ma3 top5s_ma3_p5=top5s_ma3 wtop5s_ma3_p5=wtop5s_ma3 (p95) jif_ma3_p95=jif_ma3 wjif_ma3_p95=wjif_ma3 jci_ma3_p95=jci_ma3 wjci_ma3_p95=wjci_ma3 jifwsc_ma3_p95=jifwsc_ma3 wjifwsc_ma3_p95=wjifwsc_ma3 citations_ma3_p95=citations_ma3 wcitations_ma3_p95=wcitations_ma3 top5s_ma3_p95=top5s_ma3 wtop5s_ma3_p95=wtop5s_ma3, by(reltime)
