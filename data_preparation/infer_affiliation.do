* 3b) Infer affiliation for missing observations

cd "$data_folder"
clear
use "works"

* replace affiliation for those where we only observe 1 institution
gsort author_id -aff_inst_id
by author_id: replace aff_inst_id = aff_inst_id[1] if missing(aff_inst_id) & mover == 0 //  28.29% missing

* fill institutions where the empty observations are not between moves

bys author_id (year): gen author_paper_n = _n
gen aff_inst_id_inf = aff_inst_id
format aff_inst_id_inf %12.0g
* for empty observations look in both directions to see whether value is filled or empty
gen above_id = -1 if aff_inst_id != .
gen below_id = -1 if aff_inst_id != .


* loop through all potential values
qui: su num_pubs
local max_dist = ceil((`r(max)'- 1) / 2)
*local max_dist = 5 // short loop for debugging purposes

* sort database
gsort author_id +author_paper_n

nois _dots 0, title(Finding nearest observations with affiliation) reps(`max_dist')
foreach dist of numlist 1/`max_dist' {
	quietly by author_id: replace below_id = author_paper_n[_n-`dist'] if !missing(aff_inst_id[_n-`dist']) & missing(below_id)
	quietly by author_id: replace above_id = author_paper_n[_n+`dist'] if !missing(aff_inst_id[_n+`dist']) & missing(above_id)
	*show iteration
	nois _dots `dist' 0
}


order above_id below_id aff_inst_id_inf aff_inst_id

mdesc above_id below_id


replace above_id = . if above_id == -1
replace below_id = . if below_id == -1

* sort database
gsort author_id +author_paper_n

* fill head observations where below_id is empty
by author_id: replace aff_inst_id_inf = aff_inst_id[above_id] if missing(below_id) & !missing(above_id)
* fill tail observations where below_id is empty
by author_id: replace aff_inst_id_inf = aff_inst_id[below_id] if !missing(below_id) & missing(above_id)

* fill those values where the above and below id is the same
by author_id: replace aff_inst_id_inf = aff_inst_id[below_id] if aff_inst_id[above_id] == aff_inst_id[below_id] & missing(aff_inst_id_inf)

* 10.02% left on the boundaries
* split halfway the boundaries where the time of move is ambigous
* split below halfway
by author_id: replace aff_inst_id_inf = aff_inst_id[below_id] if aff_inst_id[above_id] != aff_inst_id[below_id] & author_paper_n < ((above_id + below_id)/2) & missing(aff_inst_id_inf)
* split above halfway
by author_id: replace aff_inst_id_inf = aff_inst_id[above_id] if aff_inst_id[above_id] != aff_inst_id[below_id] & author_paper_n > ((above_id + below_id)/2) & missing(aff_inst_id_inf)
* classify halfway to either direction with p=.5
gen above_or_below = uniform() if missing(aff_inst_id_inf) & aff_inst_id[above_id] != aff_inst_id[below_id]

by author_id: replace aff_inst_id_inf = aff_inst_id[below_id] if above_or_below < .5 & missing(aff_inst_id_inf)
by author_id: replace aff_inst_id_inf = aff_inst_id[above_id] if above_or_below > .5 & missing(aff_inst_id_inf)

drop above_or_below above_id below_id author_paper_n aff_inst_id_inf


replace aff_inst_id = aff_inst_id_inf if missing(aff_inst_id)
* confirm that there are no missing institutions
assert !missing(aff_inst_id)

cd "$data_folder"
save "works", replace

* WHAT TO DO WITH THOSE OBSERVATIONS WHERE THERE IS A SEEMINGLY RANDOM MOVE IN THE MIDDLE
* OF A CONSISTENT INSTITUTION


