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

* Old productivity variables
/*
gen avg_cite_journal = journal_cited_by_count / journal_works_count

gen prod = (citations/avg_cite_journal) * aif
gen log_prod = log(prod)

gen wprod = (citations/avg_cite_journal) * waif
gen log_wprod = log(prod)
*/


* Quality
* Average quality of publications in a given year
*gen avg_aif = aif/year_author_pubs