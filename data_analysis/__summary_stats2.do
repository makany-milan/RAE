* 5e) Generate summary statistics and descriptive graphs

		clear
		cd "$data_folder"
		use "sample"

/*
eststo men: qui estpost sum ///
	prod wprod citations wcitations top5s year_author_pubs wpubs avg_coauthors if female == 0
eststo women: qui estpost sum ///
	prod wprod citations wcitations top5s year_author_pubs wpubs avg_coauthors if female == 1
	
esttab men women, cells("mean(pattern(1 1 0) fmt(2)) sd(pattern(1 1 0)) t(pattern(0 0 1) par fmt(2))") tex
*/
		collapse (mean) prod top5s citations wcitations wtop5s wpubs avg_coauthors year_author_pubs female num_pubs , by(aff_inst_id)

		eststo insts: qui estpost sum ///
			 prod citations wcitations top5s year_author_pubs wpubs avg_coauthors female
			
		esttab insts, cells("mean(pattern(1 1 0) fmt(2)) sd(pattern(1 1 0)) t(pattern(0 0 1) par fmt(2))") tex


		clear
		cd "$data_folder"
		use "sample_fe"



		set scheme white_tableau

* count the number of authors and departments
distinct author_id
distinct aff_inst_id

* create tag for more period dynamic model
egen author_global_class_tag = tag(author_id GLOBAL_CLASS)

		corr fe1_female fe2_female
		corr fe1_male fe2_male

		global percentiles = 4


*xtile pf = aif if female == 1, n($percentiles)
*xtile pm = aif if female == 0, n($percentiles)

		xtile pf = fe1_female, n($percentiles)
		xtile pm = fe1_male, n($percentiles)

		bys pf:su fe1_female
		bys pm: su fe1_male


		capture drop sorting
		gen sorting = .
		* store correlations for all quantiles
		foreach x of numlist 1/$percentiles {
			corr fe1_female fe2_female if pf == `x'
			replace sorting = `r(rho)' if pf ==`x' & female == 1
			corr fe1_male fe2_male if pm == `x'
			replace sorting = `r(rho)' if pm ==`x' & female == 0
		}



drop _merge
merge m:1 author_id using openalex_data/authors
drop if _merge == 2
drop p_female

gsort -fe1_female +t_period 
edit author_name inst_name t_period *_female GLOBAL_CLASS if female == 1
gsort -fe1_male +t_period 
edit author_name inst_name t_period *_male GLOBAL_CLASS if female == 0

corr fe1_female fe2_female
corr fe1_male fe2_male


twoway (scatter sorting pm if female == 0, color(blue)) (scatter sorting pf if female == 1, color(red))

/*
* do some visualisations in python - export csv
keep female GLOBAL_CLASS fe1_female fe2_female fe1_male fe2_male pf pm
export delimited using "python-graphs.csv", replace
*/

		bys GLOBAL_CLASS pm : egen numerator = nvals(author_id) if !missing(pm)
		bys GLOBAL_CLASS : egen denominator = nvals(author_id) if !missing(pm)

		bys GLOBAL_CLASS pf : egen numerator_f = nvals(author_id) if !missing(pf)
		bys GLOBAL_CLASS : egen denominator_f = nvals(author_id) if !missing(pf)
		replace numerator = numerator_f if missing(numerator)
		replace denominator = denominator_f if missing(denominator)

		gen share = numerator / denominator

		gen percentile = pm
		replace percentile = pf if percentile == .

		collapse (mean) share, by(GLOBAL_CLASS female percentile)
		drop if share == .
		reshape wide share, i(GLOBAL_CLASS female) j(percentile)
		graph bar share*, over(GLOBAL_CLASS) by(female) stack percent



clear
use "sample_fe"
gen lprod = log(prod)
collapse (mean) lprod (sd) se_prod=prod, by(female REGION_CLASS)
twoway (scatter lprod REGION_CLASS if female == 1, color(red)) (scatter lprod REGION_CLASS if female == 0, color(blue))

