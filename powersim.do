/*************************************************************************
 *************************************************************************			       	
		 Creation of powersim command
			 
1) Created by: Pablo Uribe
			   DIME - World Bank
			   puribebotero@worldbank.org
				
2) Date: May 14, 2024

3) Objective: Build program to perform power calculations by simulation

4) Output:	powersim program
*************************************************************************
*************************************************************************/

capture program drop powersim
program powersim, rclass
    version 18
    * Program arguments
    syntax, pc_selection(string)    ///
			method(string)			///
			sd(real)				///
			path(string)			///
			errors(string)			///
          [ alpha(real 0.05) 		///
			geo_effect(real 0.3) 	///
			cfn_effect(real 0.2)	///
			cfw_effect(real 0.2) 	///
			cfw_spillover(real 0)	///
			survey_cfn(int 40)		///
			survey_cfw(int 40)		///
			survey_cfwc(int 40)		///
			survey_geo(int 40)		///
			survey_pure(int 40) ]	

	* Make sure pc_selection is specified correctly and set to default if unspecified
	if mi("`pc_selection'") local pc_selection "fixed"
	else if ("`pc_selection'" != "fixed" & "`pc_selection'" != "random") {
        display as err "option pc_selection() invalid"
        exit 198
    }
	
	if mi("`method'") local method "default"
	else if ("`method'" != "default" & "`method'" != "alt") {
        display as err "option method() invalid. Should be default or alt"
        exit 198
    }
	
	if mi("`errors'") local method "national"
	else if ("`errors'" != "gov_specific" & "`errors'" != "national") {
        display as err "option method() invalid. Should be national or gov_specific"
        exit 198
    }
	
	if mi("`path'") {
        display as err "path to folder must be specified in path()"
        exit 198
    }
	else if !mi("`path'"){
		global path "`path'"
	}
	
	quietly{
		
		drop _all
		
		use "${path}\cfn_selected_`errors'.dta"
		
		if "`pc_selection'" == "fixed"{ //Choose 1 PC for each stratum (2 in stratum 17)
			tempvar rand n
			gen `rand' = runiform()

			bys strata_id (cfn `rand'): gen `n' = _n

			gen pure_control = (`n' == 1 & cfn == 0)
			
			replace pure_control = 1 if `n' == 2 & strata_id == 17 & cfn == 0 // Assign the remaining PC slot to stratum 17

			gen cfw = (cfn == 0 & pure_control == 0)
		}
		else if "`pc_selection'" == "random"{ //Choose 14 PC randomly across all strata
			tempvar rand n
			gen `rand' = runiform() if cfn == 0

			sort cfn `rand'

			gen `n' = _n if cfn == 0

			gen pure_control = (`n' <= 14)

			gen cfw = (cfn == 0 & pure_control == 0)
		}
		
		scalar g_effect   = `sd' * `geo_effect'
		scalar cn_effect  = `sd' * `cfn_effect'
		scalar cw_effect  = `sd' * `cfw_effect'
		scalar cwc_effect = `sd' * `cfw_spillover'
		
		*expand 2 	if pure_control != 1 // Generate second ramification for CfN and CfW
		expand 2 // Generate second ramification
		
		if "`method'" == "alt"{
			tempvar rand n
			gen `rand' = runiform() if pure_control == 1
			sort cfn cfw `rand'
			gen `n' = _n if cfn == 0 & cfw == 0
			
			drop if `n' <= 8
			
			tempvar rand n
			gen rand = runiform() if cfn == 1
			sort cfw pure_control rand
			
			gen n = _n if pure_control == 0 & cfw == 0
			
			expand 2 if n <= 8
		}
		
		
		if "`errors'" == "gov_specific"{
			
			levelsof strata_id, local(strata)
			local gen gen
			
			foreach id in `strata'{
				
				`gen' epsilon_v0  = rnormal(0, `=sd_village_`id'') if strata_id == `id' // Village-level random component baseline
				
				`gen' epsilon_v1  = rnormal(0, `=sd_village_`id'') if strata_id == `id' // Village-level random component follow-up
				
				local gen replace
			}
		}
		else{
			gen epsilon_v0  = rnormal(0, `=sd_village') // Village-level random component baseline
			gen epsilon_v1  = rnormal(0, `=sd_village') // Village-level random component follow-up
		}
		
		
		gen village_id = _n 	// Cluster variable at the village level
		
		* Randomly assign groups to CfN_only and Geobundling in the CfN arm
		tempvar temp ordering
		gen `temp' 	  	= runiform() if cfn == 1
		egen `ordering' = rank(`temp')
		
		gen 	geo = 1 if inrange(`ordering', 1, 20)
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

		expand `survey_pure' if pure_control == 1 	// Expand in PC
		expand `survey_cfwc' if cfw_control == 1 	// Expand in CfW_control
		expand `survey_cfw'  if cfw_only == 1 		// Expand in CfW_only
		expand `survey_cfn'  if cfn_only == 1 		// Expand in CfN_only
		expand `survey_geo'  if geo == 1 			// Expand in Geobundling

		if "`errors'" == "gov_specific"{
		
			local gen gen
			foreach id in `strata'{
				
				`gen' epsilon_i0 = rnormal(0, `=sd_ind_`id'') if strata_id == `id' // Generate observation-level random component baseline
				
				`gen' epsilon_i1 = rnormal(0, `=sd_ind_`id'') if strata_id == `id' // Generate observation-level random component follow-up
				
				local gen replace
				
			}
			* Generate the outcome variable following specified effects
			
			gen y_ivds0 = epsilon_s + epsilon_d0 + epsilon_v0 + epsilon_i0 // Baseline
			
			gen y_ivds1 = 0.5*y_ivds0 + (cw_effect * cfw_only) + 				///
				(cwc_effect * cfw_control) + (cn_effect * cfn_only) + 			///
				(g_effect * geo) + epsilon_s + epsilon_d1 + epsilon_v1 + epsilon_i1 // Follow-up
		}
		else{
			
			gen epsilon_i0 = rnormal(0, `=sd_ind') // Generate observation-level random component baseline
				
			gen epsilon_i1 = rnormal(0, `=sd_ind') // Generate observation-level random component follow-up
			
			
			* Generate the outcome variable following specified effects
			
			gen y_ivds0 = mu + epsilon_s0 + epsilon_d0 + epsilon_v0 + epsilon_i0 // Baseline
			
			gen y_ivds1 = mu + 0.5*y_ivds0 + (cw_effect * cfw_only) + 			///
				(cwc_effect * cfw_control) + (cn_effect * cfn_only) + 			///
				(g_effect * geo) + epsilon_s1 + epsilon_d1 + epsilon_v1 + epsilon_i1 // Follow-up
			
		}
		
		encode subd_id, gen(en_subd_id)

		
		// Regressions
		
		***** Geobundling vs CfN
		reg y_ivds1 geo i.en_subd_id if geo == 1 | cfn_only == 1, cluster(village_id)

		local reject_g_cfn = cond(r(table)[4,1] < `alpha', 1, 0)
				
		local tval_g_cfn = r(table)[3,1]
		
		* Controls
		reg y_ivds1 geo y_ivds0 i.en_subd_id if geo == 1 | cfn_only == 1, cluster(village_id)

		local reject_g_cfn_c = cond(r(table)[4,1] < `alpha', 1, 0)
				
		local tval_g_cfn_c = r(table)[3,1]


		
		***** Geobundling vs CfW only
		reg y_ivds1 geo i.strata_id if (geo == 1 | cfw_only == 1), cluster(village_id)

		local reject_g_cfw = cond(r(table)[4,1] < `alpha', 1, 0)
				
		local tval_g_cfw = r(table)[3,1]
		
		* Controls
		reg y_ivds1 geo y_ivds0 i.strata_id if (geo == 1 | cfw_only == 1), cluster(village_id)

		local reject_g_cfw_c = cond(r(table)[4,1] < `alpha', 1, 0)
				
		local tval_g_cfw_c = r(table)[3,1]


		
		***** Geobundling vs all controls
		reg y_ivds1 geo i.strata_id if (geo == 1 | cfw_control == 1 | pure_control == 1), cluster(village_id)

		local reject_g_all = cond(r(table)[4,1] < `alpha', 1, 0)
				
		local tval_g_all = r(table)[3,1]
		
		* Controls
		reg y_ivds1 geo y_ivds0 i.strata_id if (geo == 1 | cfw_control == 1 | pure_control == 1), cluster(village_id)

		local reject_g_all_c = cond(r(table)[4,1] < `alpha', 1, 0)
				
		local tval_g_all_c = r(table)[3,1]


		
		***** Geobundling vs pure control
		reg y_ivds1 geo i.strata_id if (geo == 1 | pure_control == 1), cluster(village_id)

		local reject_g_pure = cond(r(table)[4,1] < `alpha', 1, 0)
				
		local tval_g_pure = r(table)[3,1]
		
		* Controls
		reg y_ivds1 geo y_ivds0 i.strata_id if (geo == 1 | pure_control == 1), cluster(village_id)

		local reject_g_pure_c = cond(r(table)[4,1] < `alpha', 1, 0)
				
		local tval_g_pure_c = r(table)[3,1]
			
		
		
		***** CfN vs CfW only
		reg y_ivds1 cfn_only i.strata_id if (cfw_only == 1 | cfn_only == 1), cluster(village_id)

		local reject_cfn_cfw = cond(r(table)[4,1] < `alpha', 1, 0)

		local tval_cfn_cfw = r(table)[3,1]
		
		* Controls
		reg y_ivds1 cfn_only y_ivds0 i.strata_id if (cfw_only == 1 | cfn_only == 1), cluster(village_id)

		local reject_cfn_cfw_c = cond(r(table)[4,1] < `alpha', 1, 0)

		local tval_cfn_cfw_c = r(table)[3,1]
		
			
			
		***** CfW only vs CfW control
		reg y_ivds1 cfw_only i.en_subd_id if (cfw == 1), cluster(village_id)

		local reject_cfw_cfwc = cond(r(table)[4,1] < `alpha', 1, 0)

		local tval_cfw_cfwc = r(table)[3,1]
		
		
		* Controls
		reg y_ivds1 cfw_only y_ivds0 i.en_subd_id if (cfw == 1), cluster(village_id)

		local reject_cfw_cfwc_c = cond(r(table)[4,1] < `alpha', 1, 0)

		local tval_cfw_cfwc_c = r(table)[3,1]
		
		
		
		***** CfN vs pure control
		reg y_ivds1 cfn_only i.strata_id if (cfn_only == 1 | pure_control == 1), cluster(village_id)

		local reject_cfn_pure = cond(r(table)[4,1] < `alpha', 1, 0)
				
		local tval_cfn_pure = r(table)[3,1]
		
		* Controls
		reg y_ivds1 cfn_only y_ivds0 i.strata_id if (cfn_only == 1 | pure_control == 1), cluster(village_id)

		local reject_cfn_pure_c = cond(r(table)[4,1] < `alpha', 1, 0)
				
		local tval_cfn_pure_c = r(table)[3,1]
		
		
		
		***** CfW controls vs pure control
		reg y_ivds1 cfw_control i.strata_id if (cfw_control == 1 | pure_control == 1), cluster(village_id)

		local reject_cfwc_pure = cond(r(table)[4,1] < `alpha', 1, 0)
				
		local tval_cfwc_pure = r(table)[3,1]
		
		* Controls
		reg y_ivds1 cfw_control y_ivds0 i.strata_id if (cfw_control == 1 | pure_control == 1), cluster(village_id)

		local reject_cfwc_pure_c = cond(r(table)[4,1] < `alpha', 1, 0)
				
		local tval_cfwc_pure_c = r(table)[3,1]

	}
	
	// RETURN RESULTS
    return scalar reject_g_cfn 	   = `reject_g_cfn'
	return scalar reject_g_cfw 	   = `reject_g_cfw'
	return scalar reject_g_all 	   = `reject_g_all'
	return scalar reject_g_pure    = `reject_g_pure'
	return scalar reject_cfw_cfwc  = `reject_cfw_cfwc'
	return scalar reject_cfn_cfw   = `reject_cfn_cfw'
	return scalar reject_cfn_pure  = `reject_cfn_pure'
	return scalar reject_cfwc_pure = `reject_cfwc_pure'
	
	return scalar tval_g_cfn 	  = `tval_g_cfn'
	return scalar tval_g_cfw 	  = `tval_g_cfw'
	return scalar tval_g_all 	  = `tval_g_all'
	return scalar tval_g_pure 	  = `tval_g_pure'
	return scalar tval_cfw_cfwc   = `tval_cfw_cfwc'
	return scalar tval_cfn_cfw    = `tval_cfn_cfw'
	return scalar tval_cfn_pure   = `tval_cfn_pure'
	return scalar tval_cfwc_pure  = `tval_cfwc_pure'
	
	return scalar reject_g_cfn_c     = `reject_g_cfn_c'
	return scalar reject_g_cfw_c     = `reject_g_cfw_c'
	return scalar reject_g_all_c     = `reject_g_all_c'
	return scalar reject_g_pure_c    = `reject_g_pure_c'
	return scalar reject_cfw_cfwc_c  = `reject_cfw_cfwc_c'
	return scalar reject_cfn_cfw_c   = `reject_cfn_cfw_c'
	return scalar reject_cfn_pure_c  = `reject_cfn_pure_c'
	return scalar reject_cfwc_pure_c = `reject_cfwc_pure_c'
	
	return scalar tval_g_cfn_c 	  	= `tval_g_cfn_c'
	return scalar tval_g_cfw_c 	  	= `tval_g_cfw_c'
	return scalar tval_g_all_c 	  	= `tval_g_all_c'
	return scalar tval_g_pure_c 	= `tval_g_pure_c'
	return scalar tval_cfw_cfwc_c   = `tval_cfw_cfwc_c'
	return scalar tval_cfn_cfw_c    = `tval_cfn_cfw_c'
	return scalar tval_cfn_pure_c   = `tval_cfn_pure_c'
	return scalar tval_cfwc_pure_c  = `tval_cfwc_pure_c'
	
	
end

