* Estimate models

clear
cd "$data_folder"
use "sample"


* For the estimation of high dimensional fixed effects we can use the zigzag estimator.
* Guimarães, P., Portugal, P., 2010A Simple Feasible Procedure to fit Models with High-dimensional Fixed EffectsThe Stata Journal 10, 628–649 https://doi.org/10.1177/1536867X1101000406
* When using the GLOBAL_CLASS fixed effects we can use the xireg option in stata

* ZigZag Estimator
*
* ESTIMATE FOR WOMEN
capture drop y
capture drop temp 
capture drop fe1 fe2

gen y = total_aif  if female == 1

generate double temp=0 if female == 1
generate double fe1=0 if female == 1
generate double fe2=0 if female == 1

local rss1=0
local dif=1
local i=0

* demean variables

while abs(`dif')>epsdouble() {
	quietly {
		regress y fe1 fe2 total_exp_*
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
		egen double fe2=mean(temp), by(GLOBAL_CLASS)
		local i=`i'+1
		
		if mod(`i', 50) == 0{
				noisily: di "Iteration `i' - dif = `dif'"
		}
	}
}

display "Total Number of Iterations --> `i'"
display "R-SQUARED: `e(r2)'"


predict fem_prod, xb
predict fem_prod_se, stdp

rename fe1 fe1_female
rename fe2 fe2_female
replace fe1_female = . if female == 0
replace fe2_female = . if female == 0




* ESTIMATE FOR MEN
capture drop y
capture drop temp 
capture drop fe1 fe2

gen y = total_aif  if female == 0

generate double temp=0 if female == 0
generate double fe1=0 if female == 0
generate double fe2=0 if female == 0

local rss1=0
local dif=1
local i=0

* demean variables

while abs(`dif')>epsdouble() {
	quietly {
		regress y fe1 fe2 total_exp_*
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
		egen double fe2=mean(temp), by(GLOBAL_CLASS)
		local i=`i'+1
		
		if mod(`i', 50) == 0{
				noisily: di "Iteration `i' - dif = `dif'"
		}
	}
}

display "Total Number of Iterations --> `i'"
display "R-SQUARED: `e(r2)'"

predict male_prod, xb
predict male_prod_se, stdp

rename fe1 fe1_male
rename fe2 fe2_male
replace fe1_male = . if female == 1
replace fe2_male = . if female == 1

*/


replace fe1_female = . if missing(female)
replace fe2_female = . if missing(female)
replace fe1_male = . if missing(female)
replace fe2_male = . if missing(female)

cd "$data_folder"
save sample_fe, replace

* same with institution level fixed effects
capture drop y
capture drop temp 
capture drop fe1 fe2
gen y = total_aif  if female == 1

generate double temp=0 if female == 1
generate double fe1=0 if female == 1
generate double fe2=0 if female == 1

local rss1=0
local dif=1
local i=0

* demean variables

while abs(`dif')>epsdouble() {
	quietly {
		regress y fe1 fe2 total_exp_*
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
		egen double fe2=mean(temp), by(aff_inst_id)
		local i=`i'+1
		
		if mod(`i', 50) == 0{
				noisily: di "Iteration `i' - dif = `dif'"
		}
	}
}

display "Total Number of Iterations --> `i'"
display "R-SQUARED: `e(r2)'"


predict inst_lvl_fem_prod, xb
predict inst_lvl_fem_prod_se, stdp

rename fe1 inst_lvl_fe1_female
rename fe2 inst_lvl_fe2_female
replace inst_lvl_fe1_female = . if female == 0
replace inst_lvl_fe2_female = . if female == 0




* ESTIMATE FOR MEN
capture drop y
capture drop temp 
capture drop fe1 fe2

gen y = total_aif  if female == 0

generate double temp=0 if female == 0
generate double fe1=0 if female == 0
generate double fe2=0 if female == 0

local rss1=0
local dif=1
local i=0

* demean variables

while abs(`dif')>epsdouble() {
	quietly {
		regress y fe1 fe2 total_exp_*
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
		egen double fe2=mean(temp), by(aff_inst_id)
		local i=`i'+1
		
		if mod(`i', 50) == 0{
				noisily: di "Iteration `i' - dif = `dif'"
		}
	}
}

display "Total Number of Iterations --> `i'"
display "R-SQUARED: `e(r2)'"

predict inst_lvl_male_prod, xb
predict inst_lvl_male_prod_se, stdp

rename inst_lvl_fe1 fe1_male
rename inst_lvl_fe2 fe2_male
replace inst_lvl_fe1_male = . if female == 1
replace inst_lvl_fe2_male = . if female == 1

*/


replace inst_lvl_fe1_female = . if missing(female)
replace inst_lvl_fe2_female = . if missing(female)
replace inst_lvl_fe1_male = . if missing(female)
replace inst_lvl_fe2_male = . if missing(female)


cd "$data_folder"
save sample_fe, replace

