* Generate productivity measures

* Quality
* Generate variable for top5 publication
gen top5 = 0
replace top5 = 1 if journal_name == "Quarterly Journal of Economics"
replace top5 = 1 if journal_name == "Econometrica"
replace top5 = 1 if journal_name == "The American Economic Review"
replace top5 = 1 if journal_name == "Journal of Political Economy"
replace top5 = 1 if journal_name == "The Review of Economic Studies"

gen wpubs = 1/number_of_authors

* Generate moving average of variables

