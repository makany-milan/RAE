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
				matrix moves`fem'[`i', `j'] = `r(N)'
			}
			else{
			    matrix moves`fem'[`i', `j'] = 0
			}
		}
	}	
}

* Visualise move matrices 
plotmatrix, mat(moves0) nodiag c(blue)
plotmatrix, mat(moves1) nodiag c(red)
