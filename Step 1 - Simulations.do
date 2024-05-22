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

global stats reject_g_cfn = r(reject_g_cfn) 											///
			reject_g_cfw = r(reject_g_cfw) reject_g_all = r(reject_g_all) 				///
			reject_g_pure = r(reject_g_pure) reject_cfn_cfw = r(reject_cfn_cfw)			///
			reject_cfw_cfwc = r(reject_cfw_cfwc) 										///
			reject_cfn_pure = r(reject_cfn_pure) reject_cfwc_pure = r(reject_cfwc_pure)	///
			tval_g_cfn = r(tval_g_cfn) 													///
			tval_g_cfw = r(tval_g_cfw) tval_g_all = r(tval_g_all) 						///
			tval_g_pure = r(tval_g_pure) tval_cfn_cfw = r(tval_cfn_cfw)					///
			tval_cfw_cfwc = r(tval_cfw_cfwc) 											///
			tval_cfn_pure = r(tval_cfn_pure) tval_cfwc_pure = r(tval_cfwc_pure)

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

	mixed FC1_d || HH7: || stratum: || HH1: if HH7 == `id', stddev

	matrix b = e(b)

	scalar mu_`id' 			= exp(b[1, 1])
	scalar sd_village_`id' 	= exp(b[1, 4])
	scalar sd_ind_`id' 		= exp(b[1, 5])
	
}

sum FC1_d
scalar sd = r(sd)

****************************************************************************
* Monte-Carlo simulations
****************************************************************************

*forval scenario = 1/6{
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
		global geo_effect 0.4
		global cfw_spillover 0.03
	}

	* Fixed Pure Controls with default method (40 surveys per village and 28 PCs)
	simulate ${stats}, reps(${reps}): powersim, 							///
			pc_selection(fixed) path(${data}) geo_effect(${geo_effect}) 	///
			cfn_effect(${cfn_effect}) cfw_effect(${cfw_effect}) 			///
			cfw_spillover(${cfw_spillover}) alpha(0.1) sd(`=sd') 			///
			survey_cfn(40) survey_cfw(40) survey_cfwc(40) survey_geo(40)	///
			survey_pure(40) method(default)

	tempfile fixed_default
	save `fixed_default', replace


	* Fixed Pure Controls with alt method (40 surveys per village and 20 PCs)
	simulate ${stats}, reps(${reps}): powersim, 							///
			pc_selection(fixed) path(${data}) geo_effect(${geo_effect}) 	///
			cfn_effect(${cfn_effect}) cfw_effect(${cfw_effect}) 			///
			cfw_spillover(${cfw_spillover}) alpha(0.1) sd(`=sd') 			///
			survey_cfn(40) survey_cfw(40) survey_cfwc(40) survey_geo(40)	///
			survey_pure(40) method(alt)

	tempfile fixed_alt40
	save `fixed_alt40', replace

	
	* Fixed Pure Controls with alt method (Diff surveys per village and 20 PCs. CfW 40)
	simulate ${stats}, reps(${reps}): powersim, 							///
			pc_selection(fixed) path(${data}) geo_effect(${geo_effect}) 	///
			cfn_effect(${cfn_effect}) cfw_effect(${cfw_effect}) 			///
			cfw_spillover(${cfw_spillover}) alpha(0.1) sd(`=sd') 			///
			survey_cfn(40) survey_cfw(40) survey_cfwc(30) survey_geo(60)	///
			survey_pure(30) method(alt)

	tempfile fixed_diff
	save `fixed_diff', replace
	
	
	* Fixed Pure Controls with alt method (Diff surveys per village and 20 PCs)
	simulate ${stats}, reps(${reps}): powersim, 							///
			pc_selection(fixed) path(${data}) geo_effect(${geo_effect}) 	///
			cfn_effect(${cfn_effect}) cfw_effect(${cfw_effect}) 			///
			cfw_spillover(${cfw_spillover}) alpha(0.1) sd(`=sd') 			///
			survey_cfn(40) survey_cfw(50) survey_cfwc(30) survey_geo(60)	///
			survey_pure(30) method(alt)

	append using `fixed_default' `fixed_alt40' `fixed_diff', gen(type)

	label def types 0 "fixed_diff" 1 "fixed_default" 2 "fixed_40" 3 "fixed_diff_2", replace
	label val type types

	compress
	
	*save "${data}\simulation_results_s`scenario'.dta", replace // Save monte-carlo simulation results

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

use "${data}\simulation_results_s2.dta", clear

append using "${data}\simulation_results_s6.dta", gen(scenario)

replace scenario = scenario + 1

label val scenario

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
