* 5a) Generate summary statistics and descriptive graphs

clear
cd "$data_folder"
use "sample_fe"

* sample restrictions moved to "data_analysis/construct_sample"
/*
keep if num_pubs > 5

bys author_id: egen moves = nvals(aff_inst_id)
replace moves = moves - 1

keep if moves > 1

bys aff_inst_id: egen aff_authors = nvals(author_id)
keep if aff_authors > 5

bys aff_inst_id: gen aff_works = _n
keep if aff_works > 100

*keep if inst_country == "US"
*/


* average number of years
set scheme white_tableau
bys author_id (reltime): gen active_years = _N
su active_years if reltime == 1, det

* drop authors with one active year
drop if active_years == 1

* count the number of authors and departments
distinct author_id

distinct aff_inst_id

* active years
su active_years if reltime==1, det
*hist active_years if reltime == 1, bin(75)


/*

xi: reg waif i.author_id i.aff_inst_id if female == 1, cluster(aff_inst_id)


gen inst_fe = .
gen inst_fe_se = .
unab insts: _Iaf*
foreach inst of local insts {
    replace inst_fe = _b[`inst'] if `inst' != 0
	replace inst_fe_se = _se[`inst'] if `inst' != 0
}

gen authors_fe = .
gen authors_fe_se = .
unab authors: _Iau*
foreach au of local authors {
    replace authors_fe = _b[`au'] if `au' != 0
	replace authors_fe_se = _se[`au'] if `au' != 0
}

gen author_significant = 1 if (authors_fe / authors_fe_se) > 1.6
gen inst_significant = 1 if (inst_fe / inst_fe_se) > 1.6


drop _I*

xi: reg waif i.author_id i.aff_inst_id if female == 0, cluster(aff_inst_id)



unab insts: _Iaf*
foreach inst of local insts {
    replace inst_fe = _b[`inst'] if `inst' != 0
	replace inst_fe_se = _se[`inst'] if `inst' != 0
}


unab authors: _Iau*
foreach au of local authors {
    replace authors_fe = _b[`au'] if `au' != 0
	replace authors_fe_se = _se[`au'] if `au' != 0
}

replace author_significant = 1 if (authors_fe / authors_fe_se) > 1.6
replace inst_significant = 1 if (inst_fe / inst_fe_se) > 1.6


drop _I*

bys author_id aff_inst_id: gen author_inst_id = _n
bys aff_inst_id: gen inst_id = _n

twoway (histogram inst_fe if female==1 & author_inst_id == 1, bin(50) color(red)) ///
       (histogram inst_fe if female==0 & author_inst_id == 1, bin(50)), ///
	   legend(order(1 "Female" 2 "Male" ))
*/

* keep one observations per author
*bys author_id (year): gen unique_fe = _n
egen author_inst_tag = tag(author_id aff_inst_id)

corr alpha_i_female phi_k_female if author_inst_tag == 1
corr alpha_i_male phi_k_male if author_inst_tag == 1

* generate significance level for inst fixed effects
gen phi_k_p = 1-normal((phi_k_male / phi_k_se_male ))
replace phi_k_p = 1-normal((phi_k_female / phi_k_se_female )) if missing(phi_k_p)
gen phi_k_significant = 1 if phi_k_p < .1

corr alpha_i_female phi_k_female if author_inst_tag == 1 & phi_k_significant == 1
corr alpha_i_male phi_k_male if author_inst_tag == 1 & phi_k_significant == 1

egen author_tag = tag(author_id)

bys aff_inst_id: gen phi = phi_k_female
bys aff_inst_id: replace phi = phi_k_male if missing(phi)
ttest phi if author_tag == 1, by(female)

bys aff_inst_id: gen share_female = sum(female)/_N
corr share_female phi_k_female if author_tag == 1
* super weak correlation... 

bys aff_inst_id: gen phi_diff = phi - phi_k_male if female == 1
 

corr phi_diff share_female if inrange(phi_diff, -10,10) & inst_tag == 1
scatter share_female phi_diff if inrange(phi_diff, -10,10) & inst_tag == 1


* time series
*collapse (count) n_authors=author_id (mean) waif=waif aif=aif jif_ma3=jif_ma3 wjif_ma3=wjif_ma3 jci_ma3=jci_ma3 wjci_ma3=wjci_ma3 jifwsc_ma3=jifwsc_ma3 wjifwsc_ma3=wjifwsc_ma3 citations_ma3=citations_ma3 wcitations_ma3=wcitations_ma3 top5s_ma3=top5s_ma3 wtop5s_ma3=wtop5s_ma3 (p5) jif_ma3_p5=jif_ma3 wjif_ma3_p5=wjif_ma3 jci_ma3_p5=jci_ma3 wjci_ma3_p5=wjci_ma3 jifwsc_ma3_p5=jifwsc_ma3 wjifwsc_ma3_p5=wjifwsc_ma3 citations_ma3_p5=citations_ma3 wcitations_ma3_p5=wcitations_ma3 top5s_ma3_p5=top5s_ma3 wtop5s_ma3_p5=wtop5s_ma3 (p95) jif_ma3_p95=jif_ma3 wjif_ma3_p95=wjif_ma3 jci_ma3_p95=jci_ma3 wjci_ma3_p95=wjci_ma3 jifwsc_ma3_p95=jifwsc_ma3 wjifwsc_ma3_p95=wjifwsc_ma3 citations_ma3_p95=citations_ma3 wcitations_ma3_p95=wcitations_ma3 top5s_ma3_p95=top5s_ma3 wtop5s_ma3_p95=wtop5s_ma3, by(reltime female)



*twoway (tsline aif if female == 0 & reltime < 50) (tsline aif if female == 1 & reltime < 50), legend(label(1 "Male") label(2 "Female"))
*twoway (tsline waif if female == 0 & reltime < 50) (tsline waif if female == 1 & reltime < 50), legend(label(1 "Male") label(2 "Female"))