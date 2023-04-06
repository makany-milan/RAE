* generate relative time t=1: time of first publication
gsort author_id +year
by author_id: gen first_pub = year[1]
by author_id: gen reltime = (year - first_pub) + 1

* some corrupt observations
* some reltime values are unrealistic - data issues is reltime above 75 ?
drop if reltime > 75