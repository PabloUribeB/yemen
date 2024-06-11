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

		use "${in_path}\main.dta"
					
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
		gen `temp' 	  	= runiform() if cfw == 1
		egen `ordering' = rank(`temp')

		gen 	cfw_only = 1 if inrange(`ordering', 1, 20)
		replace cfw_only = 0 if cfw_only != 1

		gen 	cfw_control = 1 if cfw_only == 0 & cfw == 1
		replace cfw_control = 0 if mi(cfw_control)

		replace cfw = 0 if cfw_control == 1
		replace cfw = 1 if geo == 1

		merge 1:m subd_id village_id using "${in_path}\base"

		encode subd_id, gen(en_subd_id)
					

		reg y_ivds1 cfw geo y_ivds0 i.en_subd_id, cluster(village_id)

		local beta_inner = r(table)[1,2]
	}
				
	return scalar beta_inner = `beta_inner'

end