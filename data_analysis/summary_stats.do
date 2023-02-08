* 5a) Generate summary statistics and descriptive graphs

clear
cd "$data_folder"
use "works"


* Generate variable for top5 publication
gen top5 = 0
replace top5 = 1 if journal_name == "Quarterly Journal of Economics"
replace top5 = 1 if journal_name == "Econometrica"
replace top5 = 1 if journal_name == "The American Economic Review"
replace top5 = 1 if journal_name == "Journal of Political Economy"
replace top5 = 1 if journal_name == "The Review of Economic Studies"

* 2.52% of all publications in Top5

* generate relative time t=1: time of first publication
gsort author_id +year
by author_id: gen reltime = (year - year[1]) +1 

* some reltime values are unrealistic - data issues is reltime above 75 ?


save "works", replace

