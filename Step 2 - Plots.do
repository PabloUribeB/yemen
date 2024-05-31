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
global data "${main}\01 Data\comparisons"
global figures "${main}\04 Figures"


global comparisons g_cfnw g_cfn g_cfw g_all g_pure cfn_all cfw_all cfw_pure ///
g_cfnw_c g_cfn_c g_cfw_c g_all_c g_pure_c cfn_all_c cfw_all_c cfw_pure_c

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
			
labvars tval_g_cfnw tval_g_cfn tval_g_cfw tval_g_all tval_g_pure 		///
		tval_cfn_all tval_cfw_all tval_cfw_pure tval_g_cfnw_c 			///
		tval_g_cfn_c tval_g_cfw_c tval_g_all_c tval_g_pure_c 			///
		tval_cfn_all_c tval_cfw_all_c tval_cfw_pure_c					///
		"Geobundling vs CfN+CfW-only"									///
		"Geobundling vs CfN-only" "Geobundling vs CfW-only"		 		///
		"Geobundling vs all controls" "Geobundling vs pure controls" 	///
		"CfN-only vs all controls" "CfW-only vs all controls" 			///
		"CfW-only vs pure controls"										///
		"Geobundling vs CfN+CfW-only (with covariate)"					///
		"Geobundling vs CfN-only (with covariate)" 						///
		"Geobundling vs CfW-only (with covariate)"		 				///
		"Geobundling vs all controls (with covariate)" 					///
		"Geobundling vs pure controls (with covariate)" 				///
		"CfN-only vs all controls (with covariate)" 					///
		"CfW-only vs all controls (with covariate)" 					///
		"CfW-only vs pure controls (with covariate)"


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

	preserve
	
	keep if scenario == `scenario'
	
	** t-distributions with critical values (national errors)
	set graphics off
	local i = 1
	foreach comparison in $comparisons { // Loop through each of the comparisons
		
		local critical = 1.7
		local vallab : variable label tval_`comparison' // Get the labels for titling
		
		qui sum reject_`comparison' if type == 1 & errors == "national"
		local power_0 = r(mean) * 100
		local power_0: dis round(`power_0',.1)

		qui sum reject_`comparison' if type == 2 & errors == "national"
		local power_1 = r(mean) * 100
		local power_1: dis round(`power_1',.1)
		
		qui sum reject_`comparison' if type == 0 & errors == "national"
		local power_2 = r(mean) * 100
		local power_2: dis round(`power_2',.1)
		
		* Density plots
		tw (kdensity tval_`comparison' if type == 1, lcolor(dknavy)) 						///
		(kdensity tval_`comparison' if type == 2, lcolor(dkorange))							///
		(kdensity tval_`comparison' if type == 0, lcolor(green)) if errors == "national",	///
		xline(`critical' -`critical', lcolor(gray)) xtitle(t-stat) ytitle(Density) 			///
		legend(title(Scenarios, size(small))												///
		order(1 "Alternative-40" 2 "Alternative-50" 3 "Alternative-60")						///
		position(bottom) rows(1) si(vsmall)) saving(`comparison'_nat, replace) 				///
		subtitle(`vallab', size(small))	ylabel(,labs(tiny)) 								///
		note("Power alt-40 = `power_0'%; Power alt-50 = `power_1'%;" "Power alt-60 = `power_2'%", s(vsmall))
		
		local ++i
	}

	
	** Governorate-specific errors
	local i = 1
	foreach comparison in $comparisons { // Loop through each of the comparisons
		
		local critical = 1.7
		local vallab : variable label tval_`comparison' // Get the labels for titling
		
		qui sum reject_`comparison' if type == 1 & errors == "gov_specific"
		local power_0 = r(mean) * 100
		local power_0: dis round(`power_0',.1)

		qui sum reject_`comparison' if type == 2 & errors == "gov_specific"
		local power_1 = r(mean) * 100
		local power_1: dis round(`power_1',.1)
		
		qui sum reject_`comparison' if type == 0 & errors == "gov_specific"
		local power_2 = r(mean) * 100
		local power_2: dis round(`power_2',.1)

		
		* Density plots
		tw (kdensity tval_`comparison' if type == 1, lcolor(dknavy)) 							///
		(kdensity tval_`comparison' if type == 2, lcolor(dkorange))								///
		(kdensity tval_`comparison' if type == 0, lcolor(green)) if errors == "gov_specific",	///
		xline(`critical' -`critical', lcolor(gray)) xtitle(t-stat) ytitle(Density) 				///
		legend(title(Scenarios, size(small))													///
		order(1 "Alternative-40" 2 "Alternative-50" 3 "Alternative-60")							///
		position(bottom) rows(1) si(vsmall)) saving(`comparison'_gov, replace) 					///
		subtitle(`vallab', size(small))	ylabel(,labs(tiny)) 									///
		note("Power alt-40 = `power_0'%; Power alt-50 = `power_1'%;" "Power alt-60 = `power_2'%", s(vsmall))
		
		local ++i
	}
	
	
	

	set graphics on

	grc1leg g_cfnw_nat.gph g_cfn_nat.gph g_cfw_nat.gph g_all_nat.gph g_pure_nat.gph 	///
	cfn_all_nat.gph cfw_all_nat.gph cfw_pure_nat.gph, 									///
	legendfrom(g_cfnw_nat.gph) rows(2) imargin(medium) xcommon							///
	title(Power simulations (Geo=${geo_effect}; CfN=${cfn_effect}; CfW=${cfw_effect}; 	///
	CfW-controls=${cfw_spillover}), size(small))										///
	subtitle(Distribution of t-stats (National errors), size(vsmall)) 					///
	saving(s`scenario'_nat, replace)													///
	note("{it:Note:} In all specifications, 8 PCs are switched to CfN. The number after Alternative corresponds to the number of surveys that are carried out in each village." "Dashed lines represent an arbitrarily chosen critical value of 1.7 ({&alpha} = 0.1). Number of simulations = 1000.", s(tiny)) 

	graph display, xsize(9)
	
	graph export "${figures}\Power_s`scenario'_national.png", replace // Save final graph


	grc1leg g_cfnw_c_nat.gph g_cfn_c_nat.gph g_cfw_c_nat.gph g_all_c_nat.gph 			///
	g_pure_c_nat.gph cfn_all_c_nat.gph cfw_all_c_nat.gph cfw_pure_c_nat.gph,			///
	legendfrom(g_cfnw_c_nat.gph) rows(2) imargin(medium) xcommon							///
	title(Power simulations (Geo=${geo_effect}; CfN=${cfn_effect}; CfW=${cfw_effect}; 	///
	CfW-controls=${cfw_spillover}), size(small))										///
	subtitle(Distribution of t-stats (National errors), size(vsmall)) 					///
	saving(s`scenario'_nat_c, replace)													///
	note("{it:Note:} In all specifications, 8 PCs are switched to CfN. The number after Alternative corresponds to the number of surveys that are carried out in each village." "Dashed lines represent an arbitrarily chosen critical value of 1.7 ({&alpha} = 0.1). Number of simulations = 1000.", s(tiny)) 

	graph display, xsize(9)
	
	graph export "${figures}\Power_s`scenario'_national_controls.png", replace // Save final graph
	

	grc1leg g_cfnw_gov.gph g_cfn_gov.gph g_cfw_gov.gph g_all_gov.gph g_pure_gov.gph 	///
	cfn_all_gov.gph cfw_all_gov.gph cfw_pure_gov.gph, 									///
	legendfrom(g_cfnw_gov.gph) rows(2) imargin(medium) xcommon							///
	title(Power simulations (Geo=${geo_effect}; CfN=${cfn_effect}; CfW=${cfw_effect}; 	///
	CfW-controls=${cfw_spillover}), size(small))										///
	subtitle(Distribution of t-stats (Governorate-specific errors), size(vsmall))		///
	saving(s`scenario'_gov, replace)													///
	note("{it:Note:} In all specifications, 8 PCs are switched to CfN. The number after Alternative corresponds to the number of surveys that are carried out in each village. Dashed lines represent an arbitrarily chosen critical value of 1.7 ({&alpha} = 0.1). Number of simulations = 1000.", s(tiny)) 

	graph display, xsize(9)
	
	graph export "${figures}\Power_s`scenario'_gov.png", replace // Save final graph


	grc1leg g_cfnw_c_gov.gph g_cfn_c_gov.gph g_cfw_c_gov.gph g_all_c_gov.gph 			///
	g_pure_c_gov.gph cfn_all_c_gov.gph cfw_all_c_gov.gph cfw_pure_c_gov.gph,			///
	legendfrom(g_cfnw_c_gov.gph) rows(2) imargin(medium) xcommon						///
	title(Power simulations (Geo=${geo_effect}; CfN=${cfn_effect}; CfW=${cfw_effect}; 	///
	CfW-controls=${cfw_spillover}), size(small))										///
	subtitle(Distribution of t-stats (National errors), size(vsmall)) 					///
	saving(s`scenario'_gov_c, replace)													///
	note("{it:Note:} In all specifications, 8 PCs are switched to CfN. The number after Alternative corresponds to the number of surveys that are carried out in each village." "Dashed lines represent an arbitrarily chosen critical value of 1.7 ({&alpha} = 0.1). Number of simulations = 1000.", s(tiny)) 

	graph display, xsize(9)
	
	graph export "${figures}\Power_s`scenario'_gov_controls.png", replace // Save final graph
	
	
	
	foreach comparison in g_cfnw_nat g_cfn_nat g_cfw_nat g_all_nat g_pure_nat 	///
	cfn_all_nat cfw_all_nat cfw_pure_nat g_cfnw_c_nat g_cfn_c_nat g_cfw_c_nat 	///
	g_all_c_nat g_pure_c_nat cfn_all_c_nat cfw_all_c_nat cfw_pure_c_nat 		///
	g_cfnw_gov g_cfn_gov g_cfw_gov g_all_gov g_pure_gov cfn_all_gov cfw_all_gov ///
	cfw_pure_gov g_cfnw_c_gov g_cfn_c_gov g_cfw_c_gov g_all_c_gov g_pure_c_gov 	///
	cfn_all_c_gov cfw_all_c_gov cfw_pure_c_gov s`scenario'_nat s`scenario'_gov 	///
	s`scenario'_gov_c s`scenario'_nat_c{ // erase temp graphs
		
		erase `comparison'.gph
		
	}
	
	restore
}
******************************************************************************
******************************************************************************
