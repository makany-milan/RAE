* Generate institution panel
bys year aff_inst_id: egen nauthors = nvals(author_id)

collapse (first) authors=nauthors (sum) aif=aif top5=top5 (count) pubs = author_id, by(aff_inst_id year)

xtset aff_inst_id year
* this step should not make a difference
tsfill

gsort aff_inst_id +year

* merge uni name
cd "$data_folder"
merge m:1 aff_inst_id using "openalex_data/institutions.dta", keepusing(inst_name)
drop if _merge == 2
drop _merge

* merge region class
cd "$data_folder"
merge m:1 aff_inst_id using "classes/global-regional-classes", keepusing(GLOBAL_CLASS REGION_CLASS)
* nothing should get dropped here realistically
drop if _merge == 2
drop _merge


cd "$data_folder"
save "inst_panel", replace
