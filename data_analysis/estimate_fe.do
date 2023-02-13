* estimate fixed effects
* Guimarães, P., Portugal, P., 2010. A Simple Feasible Procedure to fit Models with High-dimensional Fixed Effects. The Stata Journal 10, 628–649. https://doi.org/10.1177/1536867X1101000406

* fe1: individual fixed effects: author_id
* fe2: department fixed effects: aff_inst_id

gen double temp = 0
gen double alpha_i = 0
gen double phi_k = 0
local rss1 = 0
local dif = 1
local i = 0

while abs(`dif')>epsdouble() {
    qui {
	    reg y alpha_i phi_k
	}
}