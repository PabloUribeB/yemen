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
global data "${main}\01 Data\randomization_inference"
global figures "${main}\04 Figures\RI"
global real_data 	"${main}\Other stuff\ICC"

global questions FC1_d FC5_d FC8_d

foreach quest in $questions{
	cap mkdir "${figures}\\`quest'"
}


global comparisons g_cfnw g_cfn g_cfw g_all g_pure cfn_all cfw_all cfw_pure ///
g_cfnw_c g_cfn_c g_cfw_c g_all_c g_pure_c cfn_all_c cfw_all_c cfw_pure_c

* Make sure packages are installed
cap which labvars
if _rc ssc install labvars

cap which grc1leg
if _rc ssc install grc1leg

set scheme white_tableau
graph set window fontface "Calibri"


****************************************************************************
**# Plotting
****************************************************************************
use "${data}\simulation_results_RI.dta", clear


local counter = 1
local detail "Not eating enough due to lack of money."
foreach quest in $questions{
	
	if `counter' == 2{
		local detail "Ate less food than thought."
	}
	else if `counter' == 3{
		local detail "Went without eating for a whole day."
	}
		
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
			local max = 10
		}
		else if  `scenario' == 3 {
			global cfn_effect 0.23
			global cfw_effect 0.1
			global geo_effect 0.6
			global cfw_spillover 0
			local max = 15
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
			local max = 10
		}

		preserve
		
		keep if scenario == `scenario' & question == "`quest'"
		
		** t-distributions with critical values (national errors)
		set graphics off
		
		** National-level errors
		qui count if type == 1 & errors == "national" & onetail_pval <= 0.1
		local share_0 = r(N) / 100
		local share_0: dis %04.2f `share_0'

		qui count if type == 2 & errors == "national" & onetail_pval <= 0.1
		local share_1 = r(N) / 100
		local share_1: dis %04.2f `share_1'
		
		qui count if type == 0 & errors == "national" & onetail_pval <= 0.1
		local share_2 = r(N) / 100
		local share_2: dis %04.2f `share_2'
		
		* Density plots
		tw (kdensity onetail_pval if type == 1, lcolor(dknavy)) 							///
		(kdensity onetail_pval if type == 2, lcolor(dkorange))								///
		(kdensity onetail_pval if type == 0, lcolor(green)) if errors == "national",		///
		xline(0.05, lwidth(7) lc(gs12) lp(solid)) 											///
		xline(0.1, lcolor(black) lpattern(dash)) xtitle(One-tailed p-value) 				///
		ytitle(Density) legend(title(Scenarios, size(small))								///
		order(1 "Alternative-40" 2 "Alternative-50" 3 "Alternative-60")						///
		position(bottom) rows(1) si(vsmall)) saving(nat, replace) 							///
		subtitle(National-level errors, size(small)) ylabel(,labs(small) format(%04.2f))	///
		xlabel(0(.1)1, format(%03.1f)) 														///
		note("{bf:Share of 90% p-values:}" "Alt. 40 = `share_0'; Alt. 50 = `share_1'; Alt. 60 = `share_2'", s(vsmall))


		
		** Governorate-specific errors
		qui count if type == 1 & errors == "gov_specific" & onetail_pval <= 0.1
		local share_0 = r(N) / 100
		local share_0: dis %04.2f `share_0'

		qui count if type == 2 & errors == "gov_specific" & onetail_pval <= 0.1
		local share_1 = r(N) / 100
		local share_1: dis %04.2f `share_1'
		
		qui count if type == 0 & errors == "gov_specific" & onetail_pval <= 0.1
		local share_2 = r(N) / 100
		local share_2: dis %04.2f `share_2'
		
		* Density plots
		tw (kdensity onetail_pval if type == 1, lcolor(dknavy)) 						 	///
		(kdensity onetail_pval if type == 2, lcolor(dkorange))							 	///
		(kdensity onetail_pval if type == 0, lcolor(green)) if errors == "gov_specific", 	///
		xline(0.05, lwidth(7) lc(gs12) lp(solid)) 									 		///
		xline(0.1, lcolor(black) lpattern(dash)) xtitle(One-tailed p-value) 			 	///
		xtitle(One-tailed p-value) ytitle(Density) legend(title(Scenarios, size(small))	 	///
		order(1 "Alternative-40" 2 "Alternative-50" 3 "Alternative-60")					 	///
		position(bottom) rows(1) si(vsmall)) saving(gov, replace) 						 	///
		subtitle(Governorate-level errors, size(small))	ylabel(,labs(small) format(%04.2f)) ///
		xlabel(0(.1)1, format(%03.1f)) 														///
		note("{bf:Share of 90% p-values:}" "Alt. 40 = `share_0'; Alt. 50 = `share_1'; Alt. 60 = `share_2'", s(vsmall))
		
		
		

		set graphics on

		grc1leg nat.gph gov.gph, 																///
		legendfrom(nat.gph) rows(1) imargin(medium) xcommon										///
		title(Randomization inference (Geo=${geo_effect}; CfN=${cfn_effect}; CfW=${cfw_effect}; ///
		CfW-controls=${cfw_spillover}), size(small))											///
		subtitle(Distribution of p-values, size(vsmall)) saving(s`scenario', replace)		///
		note("{it:Note:} All regressions include the outcome at baseline as control. The number after Alternative corresponds to the number of surveys that are carried out in each village. Number of main regression simulations = 100." "Number of randomization inference simulations for each main regression = 100. Question: `detail'", s(tiny)) 

		*graph display, xsize(9)
		
		graph export "${figures}\\`quest'\RI_s`scenario'.png", replace width(1800) height(1200) // Save final graph
		
		
		
		foreach comparison in nat gov s`scenario'{ // erase temp graphs
			
			erase `comparison'.gph
			
		}
		
		restore
		
	}

	local ++counter
}
******************************************************************************
******************************************************************************
