* Summary statistics

* Table for men and women

* Quality and quantity metrics
* 	Average publications per year 
*	Average aif per publication
*	Average aif produced per year


* By GLOBAL_CLASS

clear
cd "$data_folder"
use "sample"

collapse (mean) year_author_pubs avg_aif total_aif, by(GLOBAL_CLASS)

twoway (connected year_author_pubs GLOBAL_CLASS) (connected avg_aif GLOBAL_CLASS)


* By REGION_CLASS
clear
cd "$data_folder"
use "sample"

collapse (mean) year_author_pubs avg_aif total_aif, by(REGION_CLASS)

twoway (connected year_author_pubs REGION_CLASS if inrange(REGION_CLASS, 1, 4)) (connected year_author_pubs REGION_CLASS if inrange(REGION_CLASS, 5, 8)) ///
		 (connected avg_aif REGION_CLASS if inrange(REGION_CLASS, 1, 4)) (connected avg_aif REGION_CLASS if inrange(REGION_CLASS, 5, 8))

* By gender

clear
cd "$data_folder"
use "sample"

collapse (mean) year_author_pubs avg_aif total_aif, by(female)

twoway (connected year_author_pubs female) (connected avg_aif female)

* Gender Dynamics

clear
cd "$data_folder"
use "sample"

collapse (mean) year_author_pubs avg_aif total_aif, by(female year)

keep if inrange(year, 1950, 2020)

twoway (connected year_author_pubs year if female == 1, color(red))  (connected year_author_pubs year if female == 0, color(blue))
	
twoway (connected avg_aif year if female == 1, color(red)) (connected avg_aif year if female == 0, color(blue))


clear
cd "$data_folder"
use "sample"

* ttest for quantity and quality
ttest year_author_pubs, by(female) uneq
ttest avg_aif, by(female) uneq


