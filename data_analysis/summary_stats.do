* Summary statistics

* Table for men and women
* General summary statistics
clear
cd "$data_folder"
use "sample"

keep if inrange(year, 2000, 2020)
keep if !missing(female)

* Quality and quantity metrics
* 	Quantity - Average publications per year 
*	Quality - Average aif per publication
* Collaboration metrics
*	Average number of coauthors
*	Total institutions

collapse (first) female (mean) academic_age year_author_pubs avg_aif avg_coauthors insts, by(author_id)

* report mean, sd
eststo fem: qui estpost summarize academic_age year_author_pubs avg_aif avg_coauthors insts if female == 1
eststo male: qui estpost summarize academic_age year_author_pubs avg_aif avg_coauthors insts if female == 0

* test for difference
eststo diff: qui estpost ttest academic_age year_author_pubs avg_aif avg_coauthors insts, by(female) unequal 

* report table
*esttab fem male diff, ///
*cells("mean(pattern(1 1 0) fmt(2)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(2)) p(pattern(0 0 1) fmt(3))") label
cd "$data_folder"
esttab male fem diff using "graphs/gender_su_table", ///
cells("mean(pattern(1 1 0) fmt(2)) sd(pattern(1 1 0) par) p(pattern(0 0 1) fmt(3))") ///
mtitles("Male" "Female" "") collabels("Mean" "SD" "P-value") ///
coef(academic_age "Academic Age" year_author_pubs "Publications" avg_aif "AIS" avg_coauthors "Coauthors" insts "Affiliations") ///
wide label nonumbers tex replace


* By GLOBAL_CLASS

clear
cd "$data_folder"
use "sample"

collapse (mean) year_author_pubs avg_aif total_aif, by(GLOBAL_CLASS)

twoway (connected year_author_pubs GLOBAL_CLASS) (connected avg_aif GLOBAL_CLASS), title("") ylabel(0(0.2)1.2) xlabel(#10, valuelabel) ytitle("") xtitle("") legend(ring(0) label(1 "Quantity") label(2 "Quality")) name("quant_qual", replace)
graph export "$data_folder\graphs\avg_research_qual_quant_class.png", as(png) name("quant_qual") replace


* By class and gender
clear
cd "$data_folder"
use "sample"

collapse (mean) year_author_pubs avg_aif total_aif, by(GLOBAL_CLASS female)

twoway (connected year_author_pubs GLOBAL_CLASS if female == 1, color(red) lpattern(solid)) (connected avg_aif GLOBAL_CLASS if female == 1 , color(red) lpattern(dash)) ///
		(connected year_author_pubs GLOBAL_CLASS if female == 0, color(blue) lpattern(solid)) (connected avg_aif GLOBAL_CLASS if female == 0, color(blue) lpattern(dash)), title("") /// 
		ylabel(0(0.2)1.2) xlabel(#10, valuelabel) ytitle("") xtitle("") legend(ring(0) label(1 "Female") label(3 "Male") order(1 3)) name("quant_qual_gender", replace)
graph export "$data_folder\graphs\avg_research_qual_quant_gender_class.png", as(png) name("quant_qual_gender") replace



clear
cd "$data_folder"
use "sample"

*keep if inrange(year, 2000 , 2020)
collapse (mean) year_author_pubs avg_aif total_aif female, by(GLOBAL_CLASS year)

twoway (connected female year if GLOBAL_CLASS == 1) (connected female year if GLOBAL_CLASS == 3) (connected female year if GLOBAL_CLASS == 5) ///
		(connected female year if GLOBAL_CLASS == 10), legend(label(1 "Class P10") label(2 "Class P30") label(3 "Class P50") label(4 "Class P100")) ///
       legend(order(1 3 2 4)) ytitle("Share of women") name("share_of_women_by_class", replace)
graph export "$data_folder\graphs\share_of_women_by_class.png", as(png) name("share_of_women_by_class") replace


clear
cd "$data_folder"
use "sample"

keep if inrange(year, 2000 , 2020)
collapse (mean) year_author_pubs avg_aif total_aif female, by(GLOBAL_CLASS)

twoway (connected female GLOBAL_CLASS)
graph export "$data_folder\graphs\share_of_women_by_class.png", as(png) name("share_of_women_by_class") replace



* By REGION_CLASS
/*
clear
cd "$data_folder"
use "sample"

collapse (mean) year_author_pubs avg_aif total_aif, by(REGION_CLASS)

twoway (connected year_author_pubs REGION_CLASS if inrange(REGION_CLASS, 1, 4)) (connected year_author_pubs REGION_CLASS if inrange(REGION_CLASS, 5, 8)) ///
		 (connected avg_aif REGION_CLASS if inrange(REGION_CLASS, 1, 4)) (connected avg_aif REGION_CLASS if inrange(REGION_CLASS, 5, 8))

*/
		 
* By gender

clear
cd "$data_folder"
use "sample"

keep in inrange(year, 2000, 2020)
keep if !missing(female)

collapse (mean) year_author_pubs avg_aif total_aif, by(female)

twoway (connected year_author_pubs female) (connected avg_aif female)


* Gender Dynamics

clear
cd "$data_folder"
use "sample"

collapse (mean) year_author_pubs avg_aif total_aif, by(female year)

twoway (connected year_author_pubs year if female == 1, color(red))  (connected year_author_pubs year if female == 0, color(blue))
	
twoway (connected avg_aif year if female == 1, color(red)) (connected avg_aif year if female == 0, color(blue))


clear
cd "$data_folder"
use "sample"

* ttest for quantity and quality
ttest year_author_pubs, by(female) uneq
ttest avg_aif, by(female) uneq


