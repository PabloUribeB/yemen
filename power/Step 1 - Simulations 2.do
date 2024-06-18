/*************************************************************************
 *************************************************************************			       	
		 Power calculations by simulation
			 
1) Created by: Pablo Uribe
			   DIME - World Bank
			   puribebotero@worldbank.org
				
2) Date: May 14, 2024

3) Objective: Use user-built programs to perform power calculations by simulation
			  for the 'aggregated' regressions

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
global data 		"${main}\01 Data"
global real_data 	"${main}\Other stuff\ICC"
global do_files 	"C:\Users\Pablo Uribe\Documents\GitHub\wb\yemen\power"

global reps 1000 // Enter desired number of Monte-Carlo simulations

global questions FC1_d FC5_d FC8_d

global stats reject_beta1_1 	= r(reject_beta1_1)		///
			 reject_beta2_1 	= r(reject_beta2_1)		///
			 reject_beta3_1 	= r(reject_beta3_1)		///
			 reject_beta4_1 	= r(reject_beta4_1)		///
			 tval_beta1_1 		= r(tval_beta1_1)		///
			 tval_beta2_1 		= r(tval_beta2_1)		///
			 tval_beta3_1 		= r(tval_beta3_1)		///
			 tval_beta4_1 		= r(tval_beta4_1)		///
			 reject_beta1_1_c	= r(reject_beta1_1_c)	///
			 reject_beta2_1_c	= r(reject_beta2_1_c)	///
			 reject_beta3_1_c	= r(reject_beta3_1_c)	///
			 reject_beta4_1_c	= r(reject_beta4_1_c)	///
			 tval_beta1_1_c 	= r(tval_beta1_1_c)		///
			 tval_beta2_1_c 	= r(tval_beta2_1_c)		///
			 tval_beta3_1_c 	= r(tval_beta3_1_c)		///
			 tval_beta4_1_c 	= r(tval_beta4_1_c)		///
			 reject_beta2_2 	= r(reject_beta2_2)		///
			 reject_beta4_2 	= r(reject_beta4_2)		///
			 tval_beta2_2 		= r(tval_beta2_2)		///
			 tval_beta4_2 		= r(tval_beta4_2)		///
			 reject_beta2_2_c	= r(reject_beta2_2_c)	///
			 reject_beta4_2_c	= r(reject_beta4_2_c)	///
			 tval_beta2_2_c 	= r(tval_beta2_2_c)		///
			 tval_beta4_2_c 	= r(tval_beta4_2_c)		///
			 beta1_1 			= r(beta1_1)			///
			 beta2_1 			= r(beta2_1)			///
			 beta3_1 			= r(beta3_1)			///
			 beta4_1 			= r(beta4_1)			///
			 beta1_1_c 			= r(beta1_1_c)			///
			 beta2_1_c 			= r(beta2_1_c)			///
			 beta3_1_c 			= r(beta3_1_c)			///
			 beta4_1_c 			= r(beta4_1_c)			///
			 beta2_2 			= r(beta2_2)			///
			 beta4_2 			= r(beta4_2)			///
			 beta2_2_c 			= r(beta2_2_c)			///
			 beta4_2_c 			= r(beta4_2_c)
			
			

			
* Call the program
do "${do_files}\powersim 2.do"



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
					pc_selection(fixed) path(${data}) geo_effect(${geo_effect}) 	///
					cfn_effect(${cfn_effect}) cfw_effect(${cfw_effect}) 			///
					cfw_spillover(${cfw_spillover}) alpha(0.1) sd(`=sd_`quest'') 	///
					survey_cfn(40) survey_cfw(40) survey_cfwc(40) survey_geo(40)	///
					survey_pure(40) errors(`error') question(`quest')

			tempfile fixed_alt40
			save `fixed_alt40', replace
			
			
			simulate ${stats}, reps(${reps}): powersim, 							///
					pc_selection(fixed) path(${data}) geo_effect(${geo_effect}) 	///
					cfn_effect(${cfn_effect}) cfw_effect(${cfw_effect}) 			///
					cfw_spillover(${cfw_spillover}) alpha(0.1) sd(`=sd_`quest'') 	///
					survey_cfn(50) survey_cfw(50) survey_cfwc(50) survey_geo(50)	///
					survey_pure(50) errors(`error') question(`quest')

			tempfile fixed_alt50
			save `fixed_alt50', replace
			
			
			simulate ${stats}, reps(${reps}): powersim, 							///
					pc_selection(fixed) path(${data}) geo_effect(${geo_effect}) 	///
					cfn_effect(${cfn_effect}) cfw_effect(${cfw_effect}) 			///
					cfw_spillover(${cfw_spillover}) alpha(0.1) sd(`=sd_`quest'') 	///
					survey_cfn(60) survey_cfw(60) survey_cfwc(60) survey_geo(60)	///
					survey_pure(60) errors(`error') question(`quest')

			
			append using `fixed_alt40' `fixed_alt50', gen(type)

			label def types 0 "alt_60" 1 "alt_40" 2 "alt_50", replace
			label val type types

			gen errors = "`error'"
			gen question = "`quest'"
			gen scenario =  `scenario'
			
			compress
			
			save "${data}\simulation_results_s`scenario'_`error'_`quest'.dta", replace // Save monte-carlo simulation results

		}
	}

}

use "${data}\simulation_results_s2_national_FC1_d.dta", clear

append using "${data}\simulation_results_s2_gov_specific_FC1_d.dta" 	///
			"${data}\simulation_results_s3_national_FC1_d.dta" 			///
			"${data}\simulation_results_s3_gov_specific_FC1_d.dta" 		///
			"${data}\simulation_results_s6_national_FC1_d.dta" 			///
			"${data}\simulation_results_s6_gov_specific_FC1_d.dta" 		///
			"${data}\simulation_results_s2_national_FC5_d.dta" 			///
			"${data}\simulation_results_s2_gov_specific_FC5_d.dta" 		///
			"${data}\simulation_results_s3_national_FC5_d.dta" 			///
			"${data}\simulation_results_s3_gov_specific_FC5_d.dta" 		///
			"${data}\simulation_results_s6_national_FC5_d.dta" 			///
			"${data}\simulation_results_s6_gov_specific_FC5_d.dta" 		///
			"${data}\simulation_results_s2_national_FC8_d.dta" 			///
			"${data}\simulation_results_s2_gov_specific_FC8_d.dta" 		///
			"${data}\simulation_results_s3_national_FC8_d.dta" 			///
			"${data}\simulation_results_s3_gov_specific_FC8_d.dta" 		///
			"${data}\simulation_results_s6_national_FC8_d.dta" 			///
			"${data}\simulation_results_s6_gov_specific_FC8_d.dta" 


compress

save "${data}\simulation_results.dta", replace


foreach quest in $questions{
	
	foreach scenario in 2 3 6{
		
		foreach error in national gov_specific{
			
			erase "${data}\simulation_results_s`scenario'_`error'_`quest'.dta"
			
		}
	}
}



********************************************************************************
********************************************************************************
