* 5d) Run TWFE estimation


* felsdvreg
* Cornelissen, T., 2008. The Stata Command Felsdvreg to Fit a Linear Model with Two High-Dimensional Fixed Effects. The Stata Journal 8, 170–189. https://doi.org/10.1177/1536867X0800800202


		clear
		cd "$data_folder"
		use "sample"

		* merge institution latent types
		merge m:1 aff_inst_id using "classes/global-regional-classes", keepusing(GLOBAL_CLASS REGION_CLASS region)
		keep if _merge == 3


/*
gen glob_bottom = 1 if GLOBAL_CLASS == 8
gsort author_id -glob_bottom
bys author_id: replace glob_bottom = glob_bottom[1] if glob_bottom[1] == 1
drop if glob_bottom == 1
*/


*felsdvreg y if female == 1, ivar(author_id) jvar(GLOBAL_CLASS) xb(none) res(none2) mover(mover) mnum(moves_n) pobs(none3) group(group) peff(alpha_i_female) feff(phi_k_female) feffse(phi_k_se_female) cons
*felsdvreg y if female == 0, ivar(author_id) jvar(GLOBAL_CLASS) xb(none) res(none2) mover(mover) mnum(moves_n) pobs(none3) group(group) peff(alpha_i_male) feff(phi_k_male) feffse(phi_k_se_male) cons

*felsdvreg y if female == 1, ivar(author_id) jvar(GLOBAL_CLASS) xb(none) res(none2) mover(mover) mnum(moves_n) pobs(none3) group(group) peff(alpha_i_female) feff(phi_k_female) feffse(phi_k_se_female) cons normalize
*felsdvreg y if female == 0, ivar(author_id) jvar(GLOBAL_CLASS) xb(none) res(none2) mover(mover) mnum(moves_n) pobs(none3) group(group) peff(alpha_i_male) feff(phi_k_male) feffse(phi_k_se_male) cons normalize

/*
1 US-TOP5
2 US-TOP10
3 US-TOP25
4 US-TOP50
5 US-BOTTOM
*/

*felsdvreg y if female == 1 & inrange(REGION_CLASS, 1, 5), ivar(author_id) jvar(REGION_CLASS) xb(none) res(none2) mover(mover) mnum(moves_n) pobs(none3) group(group) peff(alpha_i_female) feff(phi_k_female) feffse(phi_k_se_female) cons normalize
*felsdvreg y if female == 0 & inrange(REGION_CLASS, 1, 5), ivar(author_id) jvar(REGION_CLASS) xb(none) res(none2) mover(mover) mnum(moves_n) pobs(none3) group(group) peff(alpha_i_male) feff(phi_k_male) feffse(phi_k_se_male) cons normalize


* felsdvreg and zigzag seem to be converging to the same values while twfe is off by a large margin

* fe1: individual fixed effects: author_id
* fe2: department fixed effects: aff_inst_id


* ZIGZAG

* Guimarães, P., Portugal, P., 2010A Simple Feasible Procedure to fit Models with High-dimensional Fixed EffectsThe Stata Journal 10, 628–649 https://doi.org/10.1177/1536867X1101000406
*

/*
keep if region == "EU"

* ESTIMATE FOR WOMEN
capture drop y
capture drop temp 
capture drop fe1 fe2

gen y = wprod  if female == 1

generate double temp=0 if female == 1 & region == "EU"
generate double fe1=0 if female == 1
generate double fe2=0 if female == 1

local rss1=0
local dif=1
local i=0

* demean variables

while abs(`dif')>epsdouble() {
	quietly {
		regress y fe1 fe2 i.academic_age
		local rss2=`rss1'
		local rss1=e(rss)
		local dif=`rss2'-`rss1'
		capture drop res
		predict double res, res
		replace temp=res+_b[fe1]*fe1, nopromote
		capture drop fe1
		egen double fe1=mean(temp) , by(author_id)
		replace temp=res+_b[fe2]*fe2, nopromote
		capture drop fe2
		egen double fe2=mean(temp) , by(REGION_CLASS)
		local i=`i'+1
		
		if mod(`i', 10) == 0{
				noisily: di "Iteration `i' - dif = `dif'"
		}
	}
}

display "Total Number of Iterations --> `i'"
display "R-SQUARED: `e(r2)'"




rename fe1 fe1_female
rename fe2 fe2_female
replace fe1_female = . if female == 0
replace fe2_female = . if female == 0


* ESTIMATE FOR MEN
capture drop y
capture drop temp 
capture drop fe1 fe2

gen y = wprod if female == 0 & region == "EU"

generate double temp=0 if female == 0
generate double fe1=0 if female == 0
generate double fe2=0 if female == 0

local rss1=0
local dif=1
local i=0

* demean variables

while abs(`dif')>epsdouble() {
	quietly {
		regress y fe1 fe2 i.academic_age
		local rss2=`rss1'
		local rss1=e(rss)
		local dif=`rss2'-`rss1'
		capture drop res
		predict double res, res
		replace temp=res+_b[fe1]*fe1, nopromote
		capture drop fe1
		egen double fe1=mean(temp), by(author_id)
		replace temp=res+_b[fe2]*fe2, nopromote
		capture drop fe2
		egen double fe2=mean(temp), by(REGION_CLASS)
		local i=`i'+1
		
		if mod(`i', 10) == 0{
				noisily: di "Iteration `i' - dif = `dif'"
		}
	}
}

display "Total Number of Iterations --> `i'"
display "R-SQUARED: `e(r2)'"

rename fe1 fe1_male
rename fe2 fe2_male
replace fe1_male = . if female == 1
replace fe2_male = . if female == 1

*/



* ESTIMATE FOR WOMEN
capture drop y
capture drop temp 
capture drop fe1 fe2

gen y = prod  if female == 1 & inrange(REGION_CLASS, )

generate double temp=0 if female == 1
generate double fe1=0 if female == 1
generate double fe2=0 if female == 1

local rss1=0
local dif=1
local i=0

* demean variables

while abs(`dif')>epsdouble() {
	quietly {
		regress y fe1 fe2 i.academic_age
		local rss2=`rss1'
		local rss1=e(rss)
		local dif=`rss2'-`rss1'
		capture drop res
		predict double res, res
		replace temp=res+_b[fe1]*fe1, nopromote
		capture drop fe1
		egen double fe1=mean(temp), by(author_id)
		replace temp=res+_b[fe2]*fe2, nopromote
		capture drop fe2
		egen double fe2=mean(temp), by(REGION_CLASS)
		local i=`i'+1
		
		if mod(`i', 50) == 0{
				noisily: di "Iteration `i' - dif = `dif'"
		}
	}
}

display "Total Number of Iterations --> `i'"
display "R-SQUARED: `e(r2)'"




rename fe1 fe1_female
rename fe2 fe2_female
replace fe1_female = . if female == 0
replace fe2_female = . if female == 0


* ESTIMATE FOR MEN
capture drop y
capture drop temp 
capture drop fe1 fe2

gen y = prod if female == 0

generate double temp=0 if female == 0
generate double fe1=0 if female == 0
generate double fe2=0 if female == 0

local rss1=0
local dif=1
local i=0

* demean variables

while abs(`dif')>epsdouble() {
	quietly {
		regress y fe1 fe2 i.academic_age
		local rss2=`rss1'
		local rss1=e(rss)
		local dif=`rss2'-`rss1'
		capture drop res
		predict double res, res
		replace temp=res+_b[fe1]*fe1, nopromote
		capture drop fe1
		egen double fe1=mean(temp), by(author_id)
		replace temp=res+_b[fe2]*fe2, nopromote
		capture drop fe2
		egen double fe2=mean(temp), by(REGION_CLASS)
		local i=`i'+1
		
		if mod(`i', 50) == 0{
				noisily: di "Iteration `i' - dif = `dif'"
		}
	}
}

display "Total Number of Iterations --> `i'"
display "R-SQUARED: `e(r2)'"

rename fe1 fe1_male
rename fe2 fe2_male
replace fe1_male = . if female == 1
replace fe2_male = . if female == 1

*/

cd "$data_folder"
save "sample_fe", replace
