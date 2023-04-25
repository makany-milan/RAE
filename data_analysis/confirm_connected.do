* Confirm connected set of classes

* Confirmf that there is movement across all classes in both directions
forvalues fem = 0/1 {
    
	clear
	cd "$data_folder"
	use "sample"

	* find largest network of connected institutions
	* should not lose too many observations here due to earlier sample restrictions
	qui: keep if female == `fem'
	
	keep GLOBAL_CLASS author_id year
	* keep one connection per author-institution pair
	bys GLOBAL_CLASS author_id (year): keep if _n == 1

	gsort author_id +year
	
	qui: su GLOBAL_CLASS
	local maxval = `r(max)'
	local minval = `r(min)'
		
	* define matrix
	matrix moves`fem' = J(10, 10, .)
		
	forval i = `minval'/`maxval' {
	    forval j = `minval'/`maxval' {
		    * we are not interested now in within class mobility
		    if `i' != `j' {
			    qui: capture drop flag
				qui: by author_id: gen flag = 1 if GLOBAL_CLASS[_n+1] == `i' & GLOBAL_CLASS[_n] == `j'
				qui: count if flag == 1
				di "Moves from class `i' to `j': `r(N)'"
				matrix moves`fem'[`j', `i'] = `r(N)'
			}
			else{
			    matrix moves`fem'[`j', `i'] = 0
			}
		}
	}	
}

* NOW WITH WITHIN CLASS MOBILITY
* Visualise move matrices 
plotmatrix, mat(moves0) nodiag c(blue) legend(off) xlabel(1 "P10" 2 "P20" 3 "P30" 4 "P40" 5 "P50" 6 "P60" 7 "P70" 8 "P80" 9 "P90" 10 "P100",nogrid) /// 
				ylabel(0 "P10" -1 "P20" -2 "P30" -3 "P40" -4 "P50" -5 "P60" -6 "P70" -7 "P80" -8 "P90" -9 "P100",nogrid) ytitle("From") xtitle("To") name("male_moves", replace)
graph export "$data_folder\graphs\male_moves.png", as(png) name("male_moves") replace


plotmatrix, mat(moves1) nodiag c(red) legend(off) xlabel(1 "P10" 2 "P20" 3 "P30" 4 "P40" 5 "P50" 6 "P60" 7 "P70" 8 "P80" 9 "P90" 10 "P100",nogrid) /// 
				ylabel(0 "P10" -1 "P20" -2 "P30" -3 "P40" -4 "P50" -5 "P60" -6 "P70" -7 "P80" -8 "P90" -9 "P100",nogrid) ytitle("From") xtitle("To") name("female_moves", replace)
graph export "$data_folder\graphs\female_moves.png", as(png) name("female_moves") replace


forvalues fem = 0/1 {
    
	clear
	cd "$data_folder"
	use "sample"

	* find largest network of connected institutions
	* should not lose too many observations here due to earlier sample restrictions
	qui: keep if female == `fem'
	
	keep GLOBAL_CLASS author_id year aff_inst_id
	* keep one connection per author-institution pair
	bys aff_inst_id author_id (year): keep if _n == 1

	gsort author_id +year
	
	qui: su GLOBAL_CLASS
	local maxval = `r(max)'
	local minval = `r(min)'
		
	* define matrix
	matrix moves`fem' = J(10, 10, .)
		
	forval i = `minval'/`maxval' {
	    forval j = `minval'/`maxval' {
		    * we are not interested now in within class mobility
		    if `i' != `j' {
			    qui: capture drop flag
				qui: by author_id: gen flag = 1 if GLOBAL_CLASS[_n+1] == `i' & GLOBAL_CLASS[_n] == `j'
				qui: count if flag == 1
				di "Moves from class `i' to `j': `r(N)'"
				matrix moves`fem'[`j', `i'] = `r(N)'
			}
			else {
				qui: capture drop flag
				qui: by author_id: gen flag = 1 if GLOBAL_CLASS[_n+1] == `i' & GLOBAL_CLASS[_n] == `j' & aff_inst_id[_n+1] != aff_inst_id[_n]
				qui: count if flag == 1
				di "Moves within class `i': `r(N)'"
				matrix moves`fem'[`j', `i'] = `r(N)'
			}
		}
	}	
}

plotmatrix, mat(moves0) c(blue) legend(off) xlabel(1 "P10" 2 "P20" 3 "P30" 4 "P40" 5 "P50" 6 "P60" 7 "P70" 8 "P80" 9 "P90" 10 "P100",nogrid) /// 
				ylabel(0 "P10" -1 "P20" -2 "P30" -3 "P40" -4 "P50" -5 "P60" -6 "P70" -7 "P80" -8 "P90" -9 "P100",nogrid) ytitle("From") xtitle("To") name("male_moves_within", replace)
graph export "$data_folder\graphs\male_moves_within.png", as(png) name("male_moves_within") replace


plotmatrix, mat(moves1) c(red) legend(off) xlabel(1 "P10" 2 "P20" 3 "P30" 4 "P40" 5 "P50" 6 "P60" 7 "P70" 8 "P80" 9 "P90" 10 "P100",nogrid) /// 
				ylabel(0 "P10" -1 "P20" -2 "P30" -3 "P40" -4 "P50" -5 "P60" -6 "P70" -7 "P80" -8 "P90" -9 "P100",nogrid) ytitle("From") xtitle("To") name("female_moves_within", replace)
graph export "$data_folder\graphs\female_moves_within.png", as(png) name("female_moves_within") replace
