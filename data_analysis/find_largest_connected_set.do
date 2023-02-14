* Find largest connected set of institutions for men and women

forvalues fem = 0/1 {
    
	clear
	cd "$data_folder"
	use "sample"

	* find largest network of connected institutions
	* should not lose too many observations here due to earlier sample restrictions
	
	keep if female == `fem'
	
	keep aff_inst_id author_id
	* keep one connection per author-institution pair
	bys aff_inst_id author_id: keep if _n == 1

	sort aff_inst_id author_id

	* loop through all observations to construct the network of departments
	bys author_id: gen author_n1 = 1 if _n == 1
	replace author_n1 = 0 if missing(author_n1)
	gsort -author_n1 author_id

	gen network = .

	* count observations where network is missing
	count if missing(network)
	local N = `r(N)'
	local i = 1

	* store the size of networks
	local largest_network = 0
	local networks_size = 0
    
	while `N' != 0 {
		gsort -author_n1 author_id
		local auth_id = author_id[`i']
		if missing(network[`i']) {
			* replace for author
			qui: replace network = `auth_id' if author_id == `auth_id'
			* loop through network
			qui: count if missing(network)
			local prev_miss = `r(N)'
			local curr_miss = 0
			local while_i = 1
			while (`prev_miss' != `curr_miss') {
				qui: count if missing(network)
				local prev_miss = `r(N)'
				* infer network for institutions 
				qui: levelsof aff_inst_id if network==`auth_id', local(net_insts)
				foreach net_inst of local net_insts {
					qui: replace network = `auth_id' if aff_inst_id == `net_inst'
				}
				* infer network for all authors at those institutions
				qui: levelsof author_id if network==`auth_id', local(net_auths)
				foreach net_auth of local net_auths {
					qui: replace network = `auth_id' if author_id == `net_auth'
				}
				* iterate until network is closed
				qui: count if missing(network)
				local curr_miss = `r(N)'
				
				local while_i = `while_i' + 1
				if mod(`while_i', 5) == 0{
					di "Remaining within current network: `curr_miss'"
				}
			}
		}
		qui: count if network == `auth_id'
		local curr_network_size = `r(N)'
		* add current network to total size of all networks
		local networks_size = `networks_size' + `curr_network_size'
		if `curr_network_size' > `largest_network'{
			local largest_network = `curr_network_size'
		}
		* see if the current network is big enough to be the largest
		local relative_size = (`curr_network_size' / _N)
		if `relative_size' > 0.5 {
			local N = 0
			continue, break
		}
		
		* increment iterator
		local i = `i' + 1
		* look at proportion missing
		qui: count if missing(network)
		local N = `r(N)'
		
		if mod(`i', 500) == 0{
			di "Remaining overall: `N'"
		}
		
	}

	bys network: egen insts_in_network = nvals(aff_inst_id)
	egen largest_network = max(insts_in_network)

	keep if insts_in_network == largest_network

	keep author_id aff_inst_id

	gen largest_network = 1

	cd "$data_folder"
	capture mkdir "temp"
	save "temp/largest_network_`fem'", replace
		
		
	}