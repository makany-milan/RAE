* Generate class panel - GLOBAL

* merge region class
cd "$data_folder"
merge m:1 aff_inst_id using "classes/global-regional-classes", keepusing(GLOBAL_CLASS REGION_CLASS)
* nothing should get dropped here realistically
drop if _merge == 2
drop _merge

bys year GLOBAL_CLASS: egen nauthors = nvals(author_id)


collapse (first) authors=nauthors (sum) aif=aif top5=top5 (count) pubs = author_id, by(GLOBAL_CLASS year)

xtset GLOBAL_CLASS year
* this step should not make a difference
tsfill

gsort GLOBAL_CLASS +year

cd "$data_folder"
save "global_panel", replace