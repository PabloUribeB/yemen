/*************************************************************************
 *************************************************************************			       	
		 Power calculations by simulation plots
			 
1) Created by: Pablo Uribe
			   DIME - World Bank
			   puribebotero@worldbank.org
				
2) Date: May 14, 2024

3) Objective: Plot t-distributions from power calculations by simulation

4) Output:	- Power.png
*************************************************************************
*************************************************************************/


****************************************************************************
* Global directory, parameters and assumptions:
****************************************************************************
global main "C:\Users\Pablo Uribe\Dropbox\Arlen\4. Pablo"
global data "${main}\01 Data"
global figures "${main}\04 Figures"

* Make sure packages are installed
cap which labvars
if _rc ssc install labvars

cap which grc1leg
if _rc ssc install grc1leg

set scheme white_tableau

****************************************************************************
* Plotting
****************************************************************************
use "${data}\simulation_results.dta", clear
			
labvars tval_g_cfn tval_g_cfw tval_g_all tval_g_pure 			///
tval_cfn_cfw tval_cfw_cfwc tval_cfn_pure tval_cfwc_pure 					///
"Geobundling vs CfN-only (subd. FE)" 									 	///
"Geobundling vs CfW-only" "Geobundling vs all controls" 					///
"Geobundling vs pure controls" "CfN-only vs CfW-only" 						///
"CfW-only vs CfW controls" "CfN-only vs pure controls" "CfW-controls vs pure controls"


forval scenario = 1/6{

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

	preserve
	
	keep if scenario == `scenario'
	
	** t-distributions with critical values
	set graphics off
	local i = 1
	foreach comparison in g_cfn g_cfw g_all g_pure cfn_cfw cfw_cfwc cfn_pure cfwc_pure{ // Loop through each of the comparisons
		
		local critical = 1.7
		local vallab : variable label tval_`comparison' // Get the labels for titling
		
		qui sum reject_`comparison' if type == 1
		local power_0 = r(mean) * 100
		local power_0: dis round(`power_0',.1)

		qui sum reject_`comparison' if type == 2
		local power_1 = r(mean) * 100
		local power_1: dis round(`power_1',.1)
		
		qui sum reject_`comparison' if type == 0
		local power_2 = r(mean) * 100
		local power_2: dis round(`power_2',.1)
		
		qui sum reject_`comparison' if type == 3
		local power_3 = r(mean) * 100
		local power_3: dis round(`power_3',.1)
		
		* Density plots
		tw (kdensity tval_`comparison' if type == 1, lcolor(dknavy)) 					///
		(kdensity tval_`comparison' if type == 2, lcolor(dkorange))						///
		(kdensity tval_`comparison' if type == 0, lcolor(green))						///
		(kdensity tval_`comparison' if type == 3, lcolor(purple)),						///
		xline(`critical' -`critical', lcolor(gray)) xtitle(t-stat) ytitle(Density) 		///
		legend(title(Scenarios, size(small))											///
		order(1 "Default" 2 "Alternative-40" 3 "Alternative-mixed" 4 "Alternative-m2")	///
		position(bottom) rows(1) si(vsmall)) saving(`comparison', replace) 				///
		subtitle(`vallab', size(small))	ylabel(,labs(tiny)) 							///
		note("Power default = `power_0'%; Power alt-40 = `power_1'%;" "Power alt-mix = `power_2'%; Power alt-mix2 = `power_3'%", s(vsmall))
		
		local ++i
	}


	set graphics on

	grc1leg g_cfn.gph g_cfw.gph g_all.gph g_pure.gph cfn_cfw.gph cfw_cfwc.gph 				///
	cfn_pure.gph cfwc_pure.gph, 															///
	legendfrom(g_cfn.gph) rows(2) imargin(medium) xcommon									///
	title(Power simulations (Geo=${geo_effect}; CfN=${cfn_effect}; CfW=${cfw_effect}; 		///
	CfW-controls=${cfw_spillover}), size(small))											///
	subtitle(Distribution of t-stats, size(vsmall)) saving(s`scenario', replace)			///
	note("{it:Note:} Default is 28 pure controls (PC) and 40 surveys per village. Alternative-40 is taking 8 PC to CfN with same number of surveys. Alternative-mixed is doing the same with the PC but varying number of surveys per treatment" "(30 in controls, 50 CfW, 60 Geo, and 40 CfN. Alternative-m2 is the same but decreasing CfW to 40. Dashed lines represent an arbitrarily chosen critical value of 1.7 ({&alpha} = 0.1). Number of simulations = 1000.", s(tiny)) 

	graph display, xsize(9)
	
	graph export "${figures}\Power_fixed_s`scenario'.png", replace // Save final graph



	foreach comparison in g_cfn g_cfw g_all g_pure cfn_cfw cfw_cfwc cfn_pure cfwc_pure s`scenario'{ // erase temp graphs
		erase `comparison'.gph
	}
	restore
}
******************************************************************************
******************************************************************************


/* RANDOM VS FIXED (OLD)

** t-distributions with critical values (1.96)
set graphics off
local i = 1
foreach comparison in g_all g_pure g_cfn g_cfw cfw_cfwc cfw_cfn{ // Loop through each of the sample sizes
	
	local vallab : variable label tval_`comparison' // Get the labels for titling
	
	if `i' == 1{
		local critical = 2.01
	}
	else if `i' == 2{
		local critical = 2.045
	}
	else{
		local critical = 2.03
	}
	
	qui sum reject_`comparison' if type == 0
	local power_0 = r(mean) * 100
	local power_0: dis round(`power_0',.1)

	qui sum reject_`comparison' if type == 1
	local power_1 = r(mean) * 100
	local power_1: dis round(`power_1',.1)

	* Density plots
	tw (kdensity tval_`comparison' if type == 0, lcolor(dknavy)) 					///
	(kdensity tval_`comparison' if type == 1, lcolor(dkorange)),					///
	xline(`critical' -`critical', lcolor(gray)) xtitle(t-stat) ytitle(Density) 		///
	legend(title(Scenarios, size(medsmall))											///
	order(1 "Random assignment to PC" 2 "Fixed assignment") position(bottom) 		///
	rows(1) si(small)) saving(`comparison', replace) subtitle(`vallab')				///
	note("Power under random = `power_0'%; Power under fixed = `power_1'%", s(vsmall))
	
	local ++i
}


set graphics on

grc1leg g_cfn.gph g_cfw.gph g_all.gph g_pure.gph cfw_cfwc.gph cfw_cfn.gph, 				///
legendfrom(g_cfn.gph) rows(2) imargin(medium) xcommon									///
title(Power simulations, size(medium)) subtitle(Distribution of t-stats, size(small)) 	///
note("{it:Note:} Dashed lines are critical values. Critical value when comparing against a treatment = 2.03 (35 DF); When comparing against all controls = 2.01 (49 DF);" "When comparing against pure controls = 2.045 (29 DF); Number of simulations = 1000.", s(vsmall)) 

graph export "${figures}\Power.png", replace // Save final graph



foreach comparison in g_cfn g_cfw g_all g_pure cfw_cfwc cfw_cfn{ // erase temp graphs
	erase `comparison'.gph
}