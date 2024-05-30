/*************************************************************************
 *************************************************************************			       	
		 Power calculations by simulation
			 
1) Created by: Pablo Uribe
			   DIME - World Bank
			   puribebotero@worldbank.org
				
2) Date: May 14, 2024

3) Objective: Use user-built programs to perform power calculations by simulation

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
global do_files 	"C:\Users\Pablo Uribe\Documents\GitHub\wb\yemen"

global reps 1000 // Enter desired number of Monte-Carlo simulations

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
do "${do_files}\powersim.do"



****************************************************************************
**# Real data error decomposition
****************************************************************************

import spss using "${real_data}\hh.sav", clear

*ssc install asgen

global assets HC10E HC11 HC14 HC15 HC17 HC19
global foods FC1 FC2 FC3 FC4 FC5 FC6 FC7 FC8

foreach asset in $assets{
	
	gen `asset'_d = (`asset' == 1)

}

foreach food in $foods{
	
	gen `food'_d = (inlist(`food',2,8,9))
	
}

gen high_income = (inrange(windex5,4,5))

keep if inlist(HH7, 11, 14,	15, 16,	17,	18,	20,	21,	22,	23,	26,	27,	29,	30,	31,	19,	25)

replace HH7 = 1 if inlist(HH7, 15, 30)
replace HH7 = 2 if inlist(HH7, 21, 22)
replace HH7 = 3 if inlist(HH7, 11, 27, 29)

keep *_d HH1 HH7 high_income stratum

levelsof HH7, local(strata)

foreach id in `strata'{

	qui mixed FC1_d || stratum: || HH1: if HH7 == `id', stddev

	matrix b = e(b)

	scalar mu_`id' 			= exp(b[1, 1])
	scalar sd_village_`id' 	= exp(b[1, 3])
	scalar sd_ind_`id' 		= exp(b[1, 4])
	
}

mixed FC1_d || HH7: || stratum: || HH1: , stddev

matrix b = e(b)

scalar mu			= exp(b[1, 1])
scalar sd_village 	= exp(b[1, 4])
scalar sd_ind 		= exp(b[1, 5])


sum FC1_d
scalar sd = r(sd)

****************************************************************************
* Monte-Carlo simulations
****************************************************************************

*forval scenario = 1/6{
foreach error in national gov_specific{
	
	foreach scenario in 2 6{

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
			global cfn_effect 0.4
			global cfw_effect 0.2
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

		/* Fixed Pure Controls with default method (40 surveys per village and 28 PCs)
		simulate ${stats}, reps(${reps}): powersim, 							///
				pc_selection(fixed) path(${data}) geo_effect(${geo_effect}) 	///
				cfn_effect(${cfn_effect}) cfw_effect(${cfw_effect}) 			///
				cfw_spillover(${cfw_spillover}) alpha(0.1) sd(`=sd') 			///
				survey_cfn(40) survey_cfw(40) survey_cfwc(40) survey_geo(40)	///
				survey_pure(40) method(default) errors(`error')

		tempfile fixed_default
		save `fixed_default', replace
		*/

		* Fixed Pure Controls with alt method (40 surveys per village and 20 PCs)
		simulate ${stats}, reps(${reps}): powersim, 							///
				pc_selection(fixed) path(${data}) geo_effect(${geo_effect}) 	///
				cfn_effect(${cfn_effect}) cfw_effect(${cfw_effect}) 			///
				cfw_spillover(${cfw_spillover}) alpha(0.1) sd(`=sd') 			///
				survey_cfn(40) survey_cfw(40) survey_cfwc(40) survey_geo(40)	///
				survey_pure(40) method(alt) errors(`error')

		tempfile fixed_alt40
		save `fixed_alt40', replace
		
		
		simulate ${stats}, reps(${reps}): powersim, 							///
				pc_selection(fixed) path(${data}) geo_effect(${geo_effect}) 	///
				cfn_effect(${cfn_effect}) cfw_effect(${cfw_effect}) 			///
				cfw_spillover(${cfw_spillover}) alpha(0.1) sd(`=sd') 			///
				survey_cfn(50) survey_cfw(50) survey_cfwc(50) survey_geo(50)	///
				survey_pure(50) method(alt) errors(`error')

		tempfile fixed_alt50
		save `fixed_alt50', replace
		
		
		simulate ${stats}, reps(${reps}): powersim, 							///
				pc_selection(fixed) path(${data}) geo_effect(${geo_effect}) 	///
				cfn_effect(${cfn_effect}) cfw_effect(${cfw_effect}) 			///
				cfw_spillover(${cfw_spillover}) alpha(0.1) sd(`=sd') 			///
				survey_cfn(60) survey_cfw(60) survey_cfwc(60) survey_geo(60)	///
				survey_pure(60) method(alt) errors(`error')

		
		/* Fixed Pure Controls with alt method (Diff surveys per village and 20 PCs. CfW 40)
		simulate ${stats}, reps(${reps}): powersim, 							///
				pc_selection(fixed) path(${data}) geo_effect(${geo_effect}) 	///
				cfn_effect(${cfn_effect}) cfw_effect(${cfw_effect}) 			///
				cfw_spillover(${cfw_spillover}) alpha(0.1) sd(`=sd') 			///
				survey_cfn(40) survey_cfw(40) survey_cfwc(30) survey_geo(60)	///
				survey_pure(30) method(alt) errors(`error')

		tempfile fixed_diff
		save `fixed_diff', replace
		
		
		* Fixed Pure Controls with alt method (Diff surveys per village and 20 PCs)
		simulate ${stats}, reps(${reps}): powersim, 							///
				pc_selection(fixed) path(${data}) geo_effect(${geo_effect}) 	///
				cfn_effect(${cfn_effect}) cfw_effect(${cfw_effect}) 			///
				cfw_spillover(${cfw_spillover}) alpha(0.1) sd(`=sd') 			///
				survey_cfn(40) survey_cfw(50) survey_cfwc(30) survey_geo(60)	///
				survey_pure(30) method(alt) errors(`error')

		*/
		
		append using `fixed_alt40' `fixed_alt50', gen(type)

		label def types 0 "alt_60" 1 "alt_40" 2 "alt_50", replace
		label val type types

		gen errors = "`error'"
		
		compress
		
		save "${data}\simulation_results_s`scenario'_`error'.dta", replace // Save monte-carlo simulation results

		/* OLD
		* Random pure controls
		simulate reject_g_cfn = r(reject_g_cfn) reject_g_cfw = r(reject_g_cfw) 			///
				reject_g_all = r(reject_g_all) reject_g_pure = r(reject_g_pure) 		///
				reject_cfw_cfwc = r(reject_cfw_cfwc) reject_cfw_cfn = r(reject_cfw_cfn)	///
				tval_g_cfn = r(tval_g_cfn) tval_g_cfw = r(tval_g_cfw) 					///
				tval_g_all = r(tval_g_all) tval_g_pure = r(tval_g_pure) 				///
				tval_cfw_cfwc=r(tval_cfw_cfwc) tval_cfw_cfn=r(tval_cfw_cfn), 			///
				reps(${reps}): powersim, pc_selection(random) path(${data}) 			///
				geo_effect(0.3) cfn_effect(0.2) cfw_effect(0.2) alpha(0.05) sd(`=sd') 	///
				mu(`=mu') sd_village(`=sd_village') sd_ind(`=sd_ind')

		*/

	}
}

use "${data}\simulation_results_s2_national.dta", clear

append using "${data}\simulation_results_s2_gov_specific.dta" "${data}\simulation_results_s6_national.dta" "${data}\simulation_results_s6_gov_specific.dta", gen(scenario)

label val scenario

replace scenario = 6 if inlist(scenario, 2, 3)
replace scenario = 2 if inlist(scenario, 0, 1)

compress

save "${data}\simulation_results.dta", replace

/*
use "${data}\simulation_results_s1.dta", clear

append using "${data}\simulation_results_s2.dta" "${data}\simulation_results_s3.dta" "${data}\simulation_results_s4.dta" "${data}\simulation_results_s5.dta" "${data}\simulation_results_s6.dta", gen(scenario)

replace scenario = scenario + 1

label val scenario

compress

save "${data}\simulation_results.dta", replace
********************************************************************************
********************************************************************************
