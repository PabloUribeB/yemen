/*************************************************************************
 *************************************************************************			       	
		 Randomization inference with simulation
			 
1) Created by: Pablo Uribe
			   DIME - World Bank
			   puribebotero@worldbank.org
				
2) Date: June 10, 2024

3) Objective: Use user-built programs to perform randomization inference with simulation data

4) Output:	- simulation_results.dta


Notes:

Scenario 1: CFN:0.2  CFW:0.2  Geo:0.3  CFW-Control: 0
Scenario 2: CFN:0.2  CFW:0.1  Geo:0.3  CFW-Control: 0
Scenario 3: CFN:0.4  CFW:0.2  Geo:0.6  CFW-Control: 0
Scenario 4: CFN:0.2  CFW:0.2  Geo:0.4  CFW-Control: 0
Scenario 5: CFN:0.2  CFW:0.1  Geo:0.4  CFW-Control: 0
Scenario 6: CFN:0.23 CFW:0.1  Geo:0.4  CFW-Control: 0.03

*************************************************************************
*************************************************************************/	


****************************************************************************
* Global directory, parameters and assumptions:
****************************************************************************

global main 		"C:\Users\Pablo Uribe\Dropbox\Arlen\4. Pablo"
global data_RI 		"${main}\01 Data\randomization_inference"
global real_data 	"${main}\Other stuff\ICC"
global do_files 	"C:\Users\Pablo Uribe\Documents\GitHub\wb\yemen\randomization_inference"

global reps 100 // Enter desired number of Monte-Carlo simulations
global sims 100 // Enter desired number of treatment assignment simulations within each simulation

global questions FC1_d FC5_d FC8_d

global stats 	onetail_pval = r(onetail_pval) 			///
				twotail_pval = r(twotail_pval)

cap mkdir "${data_RI}"
			
* Call the programs
do "${do_files}\inner.do"
do "${do_files}\general.do"

****************************************************************************
**# Real data error decomposition (call it from the do)
****************************************************************************

do "${do_files}\aux - Error decomposition.do"
	
****************************************************************************
* Monte-Carlo simulations
****************************************************************************
foreach quest in $questions{
	
	foreach error in national gov_specific{
		
		foreach scenario in 2 3 6{

			if  `scenario' == 1 {
				global cfn_effect 0.2
				global cfw_effect 0.2
				global geo_effect 0.3
				global cfw_spillover 0
			}
			else if  `scenario' == 2 {
				global cfn_effect 0.2
				global cfw_effect 0.1
				global geo_effect 0.3
				global cfw_spillover 0
			}
			else if  `scenario' == 3 {
				global cfn_effect 0.23
				global cfw_effect 0.1
				global geo_effect 0.6
				global cfw_spillover 0
			}
			else if  `scenario' == 4 {
				global cfn_effect 0.2
				global cfw_effect 0.2
				global geo_effect 0.4
				global cfw_spillover 0
			}
			else if  `scenario' == 5 {
				global cfn_effect 0.2
				global cfw_effect 0.1
				global geo_effect 0.4
				global cfw_spillover 0
			}
			else if  `scenario' == 6 {
				global cfn_effect 0.23
				global cfw_effect 0.1
				global geo_effect 0.5
				global cfw_spillover 0.03
			}

			* Fixed Pure Controls with alt method (40 surveys per village and 20 PCs)
			simulate ${stats}, reps(${reps}): powersim, 							///
					pc_selection(fixed) geo_effect(${geo_effect}) 					///
					cfn_effect(${cfn_effect}) cfw_effect(${cfw_effect}) 			///
					cfw_spillover(${cfw_spillover}) alpha(0.1) sd(`=sd_`quest'') 	///
					survey_cfn(40) survey_cfw(40) survey_cfwc(40) survey_geo(40)	///
					survey_pure(40) errors(`error') question(`quest') sims(${sims})	///
					in_path(${data_RI})

			tempfile fixed_alt40
			qui save `fixed_alt40', replace
			
			
			simulate ${stats}, reps(${reps}): powersim, 							///
					pc_selection(fixed) geo_effect(${geo_effect}) 					///
					cfn_effect(${cfn_effect}) cfw_effect(${cfw_effect}) 			///
					cfw_spillover(${cfw_spillover}) alpha(0.1) sd(`=sd_`quest'') 	///
					survey_cfn(50) survey_cfw(50) survey_cfwc(50) survey_geo(50)	///
					survey_pure(50) errors(`error') question(`quest') sims(${sims})	///
					in_path(${data_RI})

			tempfile fixed_alt50
			qui save `fixed_alt50', replace
			
			
			simulate ${stats}, reps(${reps}): powersim, 							///
					pc_selection(fixed) geo_effect(${geo_effect}) 					///
					cfn_effect(${cfn_effect}) cfw_effect(${cfw_effect}) 			///
					cfw_spillover(${cfw_spillover}) alpha(0.1) sd(`=sd_`quest'') 	///
					survey_cfn(60) survey_cfw(60) survey_cfwc(60) survey_geo(60)	///
					survey_pure(60) errors(`error') question(`quest') sims(${sims})	///
					in_path(${data_RI})

			
			append using `fixed_alt40' `fixed_alt50', gen(type)

			label def types 0 "alt_60" 1 "alt_40" 2 "alt_50", replace
			label val type types

			gen errors = "`error'"
			gen question = "`quest'"
			gen scenario =  `scenario'
			
			compress
			
			save "${data_RI}\simulation_results_s`scenario'_`error'_`quest'.dta", replace // Save monte-carlo simulation results

		}
	}

}

use "${data_RI}\simulation_results_s2_national_FC1_d.dta", clear

append using "${data_RI}\simulation_results_s2_gov_specific_FC1_d.dta" 		///
			"${data_RI}\simulation_results_s3_national_FC1_d.dta" 			///
			"${data_RI}\simulation_results_s3_gov_specific_FC1_d.dta" 		///
			"${data_RI}\simulation_results_s6_national_FC1_d.dta" 			///
			"${data_RI}\simulation_results_s6_gov_specific_FC1_d.dta" 		///
			"${data_RI}\simulation_results_s2_national_FC5_d.dta" 			///
			"${data_RI}\simulation_results_s2_gov_specific_FC5_d.dta" 		///
			"${data_RI}\simulation_results_s3_national_FC5_d.dta" 			///
			"${data_RI}\simulation_results_s3_gov_specific_FC5_d.dta" 		///
			"${data_RI}\simulation_results_s6_national_FC5_d.dta" 			///
			"${data_RI}\simulation_results_s6_gov_specific_FC5_d.dta" 		///
			"${data_RI}\simulation_results_s2_national_FC8_d.dta" 			///
			"${data_RI}\simulation_results_s2_gov_specific_FC8_d.dta" 		///
			"${data_RI}\simulation_results_s3_national_FC8_d.dta" 			///
			"${data_RI}\simulation_results_s3_gov_specific_FC8_d.dta" 		///
			"${data_RI}\simulation_results_s6_national_FC8_d.dta" 			///
			"${data_RI}\simulation_results_s6_gov_specific_FC8_d.dta" 


compress

save "${data_RI}\simulation_results_RI.dta", replace


foreach quest in $questions{
	
	foreach scenario in 2 3 6{
		
		foreach error in national gov_specific{
			
			erase "${data_RI}\simulation_results_s`scenario'_`error'_`quest'.dta"
			
		}
	}
}



********************************************************************************
********************************************************************************
