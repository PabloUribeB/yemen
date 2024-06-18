capture program drop inner
program inner, rclass
    version 18
    * Program arguments
    syntax, in_path(string)
			
			
	if mi("`in_path'") {
        display as err "path to RI folder must be specified in in_path()"
        exit 198
    }
	else if !mi("`in_path'"){
		global in_path "`in_path'"
	}
		
	quietly{
	
		drop _all

		gen strata_id = .

		* Create the strata IDs
		set obs 17
		local nums "11 14 15 16 17 18 20 21 22 23 26 27 29 30 31 19 25"
		
		local counts = 1
		foreach value in `nums'{
			replace strata_id = `value' in `counts'
			local ++counts
		}
		
		* Create observations equivalent to the number of subdistricts in each stratum
		expand 2 if inlist(strata_id, 11, 15, 21, 22, 27, 29, 30)

		expand 3 if inlist(strata_id, 16, 20, 25)

		expand 4 if inlist(strata_id, 14, 18, 23, 31, 19)

		expand 5 if strata_id == 26

		expand 6 if strata_id == 17
			
		* Assign one subdistrict from each stratum to CfN
		bys strata_id: gen cfn = (_n == 1)

		* Those with more than 4 subdistricts get 2 assigned to PC, and stratum 18 (4 subdist.) also gets a second one assigned to PC
		bys strata_id (cfn): replace cfn = 1 if _n == 1 & (_N > 4 | strata_id == 18)

		* Group the 7 strata with just one subdistrict remaining to three clusters based on results from cluster analysis
		replace strata_id = 1 if inlist(strata_id, 15, 30)
		replace strata_id = 2 if inlist(strata_id, 21, 22)
		replace strata_id = 3 if inlist(strata_id, 11, 27, 29)

		* Subdistrict ID
		bys strata_id: gen subd_id = string(strata_id) + "-" + "00" + string(_n)
		
		
		tempvar rand n
		gen `rand' = runiform()

		bys strata_id (cfn `rand'): gen `n' = _n

		gen pure_control = (`n' == 1 & cfn == 0)
		
		replace pure_control = 1 if `n' == 2 & strata_id == 17 & cfn == 0 // Assign the remaining PC slot to stratum 17

		gen cfw = (cfn == 0 & pure_control == 0)
				
				
		** 8 CfN subdistricts will have 3 villages, while 12 of them will only have 2
		tempvar rand n
		gen `rand' = runiform() if cfn == 1
		gsort -cfn `rand'

		gen `n' = _n if cfn == 1

		gen 	division = 8  if `n' <= 8
		replace division = 12 if inrange(`n', 9, 20)


		** 8 PC subdistricts will have 1 village, while 6 of them will have 2
		tempvar rand n
		gen `rand' = runiform() if pure_control == 1
		gsort -pure_control `rand'

		gen `n' = _n if pure_control == 1

		replace division = 8 if `n' <= 8
		replace division = 6 if inrange(`n', 9, 14)


		expand 3 // Generate 3 villages in each subcounty
		
		
		sort subd_id, stable
		
		gen village_id = _n 	// Cluster variable at the village level
		
		encode subd_id, gen(en_subd_id)
		
		* Randomly assign groups to CfN_only and Geobundling in the CfN arm
		tempvar temp ordering
		bys subd_id: gen `temp' = runiform() if cfn == 1
		bys subd_id: egen `ordering' = rank(`temp')
		
		gen 	geo = 1 if (`ordering' == 1 & inlist(division, 8, 12) & cfn == 1)
		replace geo = 0 if geo != 1

		gen 	cfn_only = 1 if geo == 0 & cfn == 1
		replace cfn_only = 0 if mi(cfn_only)

		* Randomly assign groups to CfW_only and CfW_control in the CfW arm
		tempvar temp ordering
		bys subd_id: gen `temp' 	  = runiform() if cfw == 1
		bys subd_id: egen `ordering'  = rank(`temp')
		
		gen 	cfw_only = 1 if `ordering' == 1
		replace cfw_only = 0 if cfw_only != 1

		gen 	cfw_control = 1 if cfw_only == 0 & cfw == 1
		replace cfw_control = 0 if mi(cfw_control)

		replace cfw = 0 if cfw_control == 1
		replace cfw = 1 if geo == 1

		
		* Merge with "observed" data that has errors and Ys
		merge 1:m subd_id village_id using "${in_path}\base", keep(3) nogen
				
		* Run regression with new random treatment assignment
		reg y_ivds1 cfw geo y_ivds0 i.en_subd_id, cluster(village_id)

		local beta_inner = r(table)[1,2] // Save geobundling beta
	}
				
	return scalar beta_inner = `beta_inner'

end