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
			sd(real)				///
			path(string)			///
			in_path(string)			///
			errors(string)			///
			question(string)		///
          [ alpha(real 0.05) 		///
			geo_effect(real 0.3) 	///
			cfn_effect(real 0.2)	///
			cfw_effect(real 0.2) 	///
			cfw_spillover(real 0)	///
			sims(int 500)			///
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
	
	if mi("`errors'") local method "national"
	else if ("`errors'" != "gov_specific" & "`errors'" != "national") {
        display as err "option errors() invalid. Should be national or gov_specific"
        exit 198
    }
	
	if mi("`question'") local method "FC1_d"
	else if !inlist("`question'", "FC1_d", "FC5_d", "FC8_d") {
        display as err "option question() invalid. Should be FC1_d, FC5_d or FC8_d"
        exit 198
    }
	
	if mi("`path'") {
        display as err "path to folder must be specified in path()"
        exit 198
    }
	else if !mi("`path'"){
		global path "`path'"
	}
	
	if mi("`in_path'") {
        display as err "path to RI folder must be specified in in_path()"
        exit 198
    }
	else if !mi("`in_path'"){
		global in_path "`in_path'"
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


		expand 3 if (division == 8 & cfn == 1)
		expand 2 if (division == 12 | (division == 6 & pure_control == 1) | cfw == 1)
		
		
		if "`errors'" == "gov_specific"{ // Governorate-specific errors
			
			levelsof strata_id, local(strata)
			local gen gen
			
			foreach id in `strata'{
				
				`gen' epsilon_v0  = rnormal(0, `=sd_village_`id'_`question'') if strata_id == `id' // Village-level random component baseline
				
				`gen' epsilon_v1  = rnormal(0, `=sd_village_`id'_`question'') if strata_id == `id' // Village-level random component follow-up
				
				local gen replace
			}
		}
		else{ // National-level errors
			gen epsilon_v0  = rnormal(0, `=sd_village_`question'') // Village-level random component baseline
			gen epsilon_v1  = rnormal(0, `=sd_village_`question'') // Village-level random component follow-up
		}
		
		sort subd_id, stable
		
		gen village_id = _n 	// Cluster variable at the village level
		
		encode subd_id, gen(en_subd_id)

		preserve

		keep subd_id village_id cfn cfw division
		compress

		cap save "${in_path}\main.dta"
				
		restore
		
		
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

		expand `survey_pure' if pure_control == 1 	// Expand in PC
		expand `survey_cfwc' if cfw_control == 1 	// Expand in CfW_control
		expand `survey_cfw'  if cfw_only == 1 		// Expand in CfW_only
		expand `survey_cfn'  if cfn_only == 1 		// Expand in CfN_only
		expand `survey_geo'  if geo == 1 			// Expand in Geobundling

		if "`errors'" == "gov_specific"{ // Governorate-specific errors
		
			local gen gen
			foreach id in `strata'{
				
				`gen' epsilon_i0 = rnormal(0, `=sd_ind_`id'_`question'') if strata_id == `id' // Generate observation-level random component baseline
				
				`gen' epsilon_i1 = rnormal(0, `=sd_ind_`id'_`question'') if strata_id == `id' // Generate observation-level random component follow-up
				
				local gen replace
				
			}
			* Generate the outcome variable following specified effects
			
			gen y_ivds0 = epsilon_s_`question' + epsilon_d0_`question' + epsilon_v0 + epsilon_i0 // Baseline
			
			gen y_ivds1 = 0.5*y_ivds0 + (cw_effect * cfw_only) + 				///
				(cwc_effect * cfw_control) + (cn_effect * cfn_only) + 			///
				(g_effect * geo) + epsilon_s_`question' + epsilon_d1_`question' + epsilon_v1 + epsilon_i1 // Follow-up
		}
		else{ // National-level errors
			
			gen epsilon_i0 = rnormal(0, `=sd_ind_`question'') // Generate observation-level random component baseline
				
			gen epsilon_i1 = rnormal(0, `=sd_ind_`question'') // Generate observation-level random component follow-up
			
			
			* Generate the outcome variable following specified effects
			
			gen y_ivds0 = mu_`question' + epsilon_s0_`question' + epsilon_d0_`question' + epsilon_v0 + epsilon_i0 // Baseline
			
			gen y_ivds1 = mu_`question' + 0.5*y_ivds0 + (cw_effect * cfw_only) + 			///
				(cwc_effect * cfw_control) + (cn_effect * cfn_only) + 			///
				(g_effect * geo) + epsilon_s1_`question' + epsilon_d1_`question' + epsilon_v1 + epsilon_i1 // Follow-up
			
		}
		

		replace cfw = 0 if cfw_control == 1
		replace cfw = 1 if geo == 1

		gen cfw_spillover = 0
		replace cfw_spillover = 1 if (cfn_only == 1 | cfw_control == 1)
		
		// Regressions
		
		***** Regression 2		
		
		* Controls
		reg y_ivds1 cfw geo y_ivds0 i.en_subd_id, cluster(village_id)
		
		scalar real_beta = r(table)[1,2]

		keep y_* subd_id village_id

		save "${in_path}\base.dta", replace
	
		simulate beta_inner = r(beta_inner), reps(`sims'): inner, in_path(${in_path})
		
		erase "${in_path}\base.dta"

		count if beta_inner >= real_beta

		local onetail_pval = r(N) / `sims'

		count if abs(beta_inner) >= real_beta

		local twotail_pval = r(N) / `sims'
		
	}
	
	// RETURN RESULTS

	return scalar onetail_pval = `onetail_pval'
	return scalar twotail_pval = `twotail_pval'

end

