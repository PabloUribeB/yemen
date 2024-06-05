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

global questions FC1_d FC5_d FC8_d

foreach quest in $questions{
	cap mkdir "${figures}\\`quest'"
	cap mkdir "${figures}\\`quest'\betas"
}




global comparisons beta1_1 beta2_1 beta3_1 beta4_1 beta2_2 beta4_2 		///
beta1_1_c beta2_1_c beta3_1_c beta4_1_c beta2_2_c beta4_2_c 

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
			
labvars tval_beta1_1 tval_beta2_1 tval_beta3_1 tval_beta4_1 tval_beta2_2 	///
		tval_beta4_2 tval_beta1_1_c tval_beta2_1_c tval_beta3_1_c 			///
		tval_beta4_1_c tval_beta2_2_c tval_beta4_2_c						///
		"1: CfN subdistrict" "2: CfW village" 								///
		"3: At least 1 CfW subd." "4: Geobundling" "2: CfW village" 		///
		"4: Geobundling" "1: CfN subdistrict" "2: CfW village" 				///
		"3: At least 1 CfW subd." "4: Geobundling" "2: CfW village" 		///
		"4: Geobundling"

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
		
		keep if scenario == `scenario' & question == "`quest'"
		
		
		****************************************************************
		**# 				t-stat distributions					  **
		****************************************************************
		
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
			subtitle({&beta}`vallab', size(small))	ylabel(,labs(tiny)) 								///
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
			subtitle({&beta}`vallab', size(small))	ylabel(,labs(tiny)) 									///
			note("Power alt-40 = `power_0'%; Power alt-50 = `power_1'%;" "Power alt-60 = `power_2'%", s(vsmall))
			
			local ++i
		}
		
		
		

		set graphics on

		
		***** National level regression 1
		grc1leg beta1_1_nat.gph beta2_1_nat.gph beta3_1_nat.gph beta4_1_nat.gph, 			///
		legendfrom(beta1_1_nat.gph) rows(2) imargin(medium) xcommon							///
		title(Power simulations (Geo=${geo_effect}; CfN=${cfn_effect}; CfW=${cfw_effect}; 	///
		CfW-controls=${cfw_spillover}), size(small))										///
		subtitle(Distribution of t-stats, size(vsmall)) 									///
		note("{it:Note:} In all specifications, 8 PCs are switched to CfN. The number after Alternative corresponds to the number of surveys" "that are carried out in each village. Dashed lines represent an arbitrarily chosen critical value of 1.7 ({&alpha} = 0.1)." "Number of simulations = 1000. Question: `detail'", s(tiny)) 
		
		graph export "${figures}\\`quest'\Power_s`scenario'_national_1.png", replace // Save final graph


		grc1leg beta1_1_c_nat.gph beta2_1_c_nat.gph beta3_1_c_nat.gph beta4_1_c_nat.gph,	///
		legendfrom(beta1_1_c_nat.gph) rows(2) imargin(medium) xcommon						///
		title(Power simulations (Geo=${geo_effect}; CfN=${cfn_effect}; CfW=${cfw_effect}; 	///
		CfW-controls=${cfw_spillover}), size(small))										///
		subtitle(Distribution of t-stats, size(vsmall)) 									///
		note("{it:Note:} In all specifications, 8 PCs are switched to CfN. The number after Alternative corresponds to the number of surveys" "that are carried out in each village. Dashed lines represent an arbitrarily chosen critical value of 1.7 ({&alpha} = 0.1)." "Number of simulations = 1000. Question: `detail'", s(tiny)) 
		
		graph export "${figures}\\`quest'\Power_s`scenario'_national_controls_1.png", replace // Save final graph
		

		***** Governorate level regression 1
		grc1leg beta1_1_gov.gph beta2_1_gov.gph beta3_1_gov.gph beta4_1_gov.gph, 			///
		legendfrom(beta1_1_gov.gph) rows(2) imargin(medium) xcommon							///
		title(Power simulations (Geo=${geo_effect}; CfN=${cfn_effect}; CfW=${cfw_effect}; 	///
		CfW-controls=${cfw_spillover}), size(small))										///
		subtitle(Distribution of t-stats, size(vsmall)) 									///
		note("{it:Note:} In all specifications, 8 PCs are switched to CfN. The number after Alternative corresponds to the number of surveys" "that are carried out in each village. Dashed lines represent an arbitrarily chosen critical value of 1.7 ({&alpha} = 0.1)." "Number of simulations = 1000. Question: `detail'", s(tiny)) 
		
		graph export "${figures}\\`quest'\Power_s`scenario'_gov_1.png", replace // Save final graph


		grc1leg beta1_1_c_gov.gph beta2_1_c_gov.gph beta3_1_c_gov.gph beta4_1_c_gov.gph,	///
		legendfrom(beta1_1_c_gov.gph) rows(2) imargin(medium) xcommon						///
		title(Power simulations (Geo=${geo_effect}; CfN=${cfn_effect}; CfW=${cfw_effect}; 	///
		CfW-controls=${cfw_spillover}), size(small))										///
		subtitle(Distribution of t-stats, size(vsmall)) 									///
		note("{it:Note:} In all specifications, 8 PCs are switched to CfN. The number after Alternative corresponds to the number of surveys" "that are carried out in each village. Dashed lines represent an arbitrarily chosen critical value of 1.7 ({&alpha} = 0.1)." "Number of simulations = 1000. Question: `detail'", s(tiny))  
		
		graph export "${figures}\\`quest'\Power_s`scenario'_gov_controls_1.png", replace // Save final graph
		
		
		
		***** National level regression 2
		grc1leg beta2_2_nat.gph beta4_2_nat.gph, 											///
		legendfrom(beta2_2_nat.gph) rows(1) imargin(medium) xcommon							///
		title(Power simulations (Geo=${geo_effect}; CfN=${cfn_effect}; CfW=${cfw_effect}; 	///
		CfW-controls=${cfw_spillover}), size(small))										///
		subtitle(Distribution of t-stats, size(vsmall))										///
		note("{it:Note:} In all specifications, 8 PCs are switched to CfN. The number after Alternative corresponds to the number of surveys" "that are carried out in each village. Dashed lines represent an arbitrarily chosen critical value of 1.7 ({&alpha} = 0.1)." "Number of simulations = 1000. Question: `detail'", s(tiny)) 
		
		graph export "${figures}\\`quest'\Power_s`scenario'_national_2.png", replace // Save final graph


		grc1leg beta2_2_c_nat.gph beta4_2_c_nat.gph,										///
		legendfrom(beta2_2_c_nat.gph) rows(1) imargin(medium) xcommon						///
		title(Power simulations (Geo=${geo_effect}; CfN=${cfn_effect}; CfW=${cfw_effect}; 	///
		CfW-controls=${cfw_spillover}), size(small))										///
		subtitle(Distribution of t-stats, size(vsmall)) 									///
		note("{it:Note:} In all specifications, 8 PCs are switched to CfN. The number after Alternative corresponds to the number of surveys" "that are carried out in each village. Dashed lines represent an arbitrarily chosen critical value of 1.7 ({&alpha} = 0.1)." "Number of simulations = 1000. Question: `detail'", s(tiny)) 
		
		graph export "${figures}\\`quest'\Power_s`scenario'_national_controls_2.png", replace // Save final graph
		
		
		***** Governorate level regression 2
		grc1leg beta2_2_gov.gph beta4_2_gov.gph, 											///
		legendfrom(beta2_2_gov.gph) rows(1) imargin(medium) xcommon							///
		title(Power simulations (Geo=${geo_effect}; CfN=${cfn_effect}; CfW=${cfw_effect}; 	///
		CfW-controls=${cfw_spillover}), size(small))										///
		subtitle(Distribution of t-stats, size(vsmall))										///
		note("{it:Note:} In all specifications, 8 PCs are switched to CfN. The number after Alternative corresponds to the number of surveys" "that are carried out in each village. Dashed lines represent an arbitrarily chosen critical value of 1.7 ({&alpha} = 0.1)." "Number of simulations = 1000. Question: `detail'", s(tiny))  
		
		graph export "${figures}\\`quest'\Power_s`scenario'_gov_2.png", replace // Save final graph


		grc1leg beta2_2_c_gov.gph beta4_2_c_gov.gph,										///
		legendfrom(beta2_2_c_gov.gph) rows(1) imargin(medium) xcommon						///
		title(Power simulations (Geo=${geo_effect}; CfN=${cfn_effect}; CfW=${cfw_effect}; 	///
		CfW-controls=${cfw_spillover}), size(small))										///
		subtitle(Distribution of t-stats, size(vsmall)) 									///
		note("{it:Note:} In all specifications, 8 PCs are switched to CfN. The number after Alternative corresponds to the number of surveys" "that are carried out in each village. Dashed lines represent an arbitrarily chosen critical value of 1.7 ({&alpha} = 0.1)." "Number of simulations = 1000. Question: `detail'", s(tiny)) 
		
		graph export "${figures}\\`quest'\Power_s`scenario'_gov_controls_2.png", replace // Save final graph
		
		
		
		foreach comparison in beta1_1_nat beta2_1_nat beta3_1_nat beta4_1_nat beta2_2_nat	///
		beta4_2_nat beta1_1_c_nat beta2_1_c_nat beta3_1_c_nat beta4_1_c_nat beta2_2_c_nat 	///
		beta4_2_c_nat beta1_1_gov beta2_1_gov beta3_1_gov beta4_1_gov beta2_2_gov 			///
		beta4_2_gov beta1_1_c_gov beta2_1_c_gov beta3_1_c_gov beta4_1_c_gov beta2_2_c_gov 	///
		beta4_2_c_gov{ // erase temp graphs
			
			erase `comparison'.gph
			
		}
		
		
		
		
		****************************************************************
		**# 				Betas distributions						  **
		****************************************************************
		
		
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
			tw (kdensity `comparison' if type == 1, lcolor(dknavy)) 						///
			(kdensity `comparison' if type == 2, lcolor(dkorange))							///
			(kdensity `comparison' if type == 0, lcolor(green)) if errors == "national",	///
			xtitle({&beta}) ytitle(Density) legend(title(Scenarios, size(small))			///
			order(1 "Alternative-40" 2 "Alternative-50" 3 "Alternative-60")					///
			position(bottom) rows(1) si(vsmall)) saving(`comparison'_nat, replace) 			///
			subtitle({&beta}`vallab', size(small))	ylabel(,labs(tiny)) 					///
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
			tw (kdensity `comparison' if type == 1, lcolor(dknavy)) 							///
			(kdensity `comparison' if type == 2, lcolor(dkorange))								///
			(kdensity `comparison' if type == 0, lcolor(green)) if errors == "gov_specific",	///
			xtitle({&beta}) ytitle(Density) legend(title(Scenarios, size(small))				///
			order(1 "Alternative-40" 2 "Alternative-50" 3 "Alternative-60")						///
			position(bottom) rows(1) si(vsmall)) saving(`comparison'_gov, replace) 				///
			subtitle({&beta}`vallab', size(small))	ylabel(,labs(tiny)) 						///
			note("Power alt-40 = `power_0'%; Power alt-50 = `power_1'%;" "Power alt-60 = `power_2'%", s(vsmall))
			
			local ++i
		}
		
		


		set graphics on


		***** National level regression 1
		grc1leg beta1_1_nat.gph beta2_1_nat.gph beta3_1_nat.gph beta4_1_nat.gph, 			///
		legendfrom(beta1_1_nat.gph) rows(2) imargin(medium) xcommon							///
		title(Power simulations (Geo=${geo_effect}; CfN=${cfn_effect}; CfW=${cfw_effect}; 	///
		CfW-controls=${cfw_spillover}), size(small))										///
		subtitle(Distribution of {&beta}'s, size(vsmall)) 									///
		note("{it:Note:} In all specifications, 8 PCs are switched to CfN. The number after Alternative corresponds to the number of surveys" "that are carried out in each village. Dashed lines represent an arbitrarily chosen critical value of 1.7 ({&alpha} = 0.1)." "Number of simulations = 1000. Question: `detail'", s(tiny)) 
		
		graph export "${figures}\\`quest'\betas\Power_s`scenario'_national_1.png", replace // Save final graph


		grc1leg beta1_1_c_nat.gph beta2_1_c_nat.gph beta3_1_c_nat.gph beta4_1_c_nat.gph,	///
		legendfrom(beta1_1_c_nat.gph) rows(2) imargin(medium) xcommon						///
		title(Power simulations (Geo=${geo_effect}; CfN=${cfn_effect}; CfW=${cfw_effect}; 	///
		CfW-controls=${cfw_spillover}), size(small))										///
		subtitle(Distribution of {&beta}'s, size(vsmall)) 									///
		note("{it:Note:} In all specifications, 8 PCs are switched to CfN. The number after Alternative corresponds to the number of surveys" "that are carried out in each village. Dashed lines represent an arbitrarily chosen critical value of 1.7 ({&alpha} = 0.1)." "Number of simulations = 1000. Question: `detail'", s(tiny))  
		
		graph export "${figures}\\`quest'\betas\Power_s`scenario'_national_controls_1.png", replace // Save final graph
		

		***** Governorate level regression 1
		grc1leg beta1_1_gov.gph beta2_1_gov.gph beta3_1_gov.gph beta4_1_gov.gph, 			///
		legendfrom(beta1_1_gov.gph) rows(2) imargin(medium) xcommon							///
		title(Power simulations (Geo=${geo_effect}; CfN=${cfn_effect}; CfW=${cfw_effect}; 	///
		CfW-controls=${cfw_spillover}), size(small))										///
		subtitle(Distribution of {&beta}'s, size(vsmall)) 									///
		note("{it:Note:} In all specifications, 8 PCs are switched to CfN. The number after Alternative corresponds to the number of surveys" "that are carried out in each village. Dashed lines represent an arbitrarily chosen critical value of 1.7 ({&alpha} = 0.1)." "Number of simulations = 1000. Question: `detail'", s(tiny)) 
		
		graph export "${figures}\\`quest'\betas\Power_s`scenario'_gov_1.png", replace // Save final graph


		grc1leg beta1_1_c_gov.gph beta2_1_c_gov.gph beta3_1_c_gov.gph beta4_1_c_gov.gph,	///
		legendfrom(beta1_1_c_gov.gph) rows(2) imargin(medium) xcommon						///
		title(Power simulations (Geo=${geo_effect}; CfN=${cfn_effect}; CfW=${cfw_effect}; 	///
		CfW-controls=${cfw_spillover}), size(small))										///
		subtitle(Distribution of {&beta}'s, size(vsmall)) 									///
		note("{it:Note:} In all specifications, 8 PCs are switched to CfN. The number after Alternative corresponds to the number of surveys" "that are carried out in each village. Dashed lines represent an arbitrarily chosen critical value of 1.7 ({&alpha} = 0.1)." "Number of simulations = 1000. Question: `detail'", s(tiny)) 
		
		graph export "${figures}\\`quest'\betas\Power_s`scenario'_gov_controls_1.png", replace // Save final graph
		
		
		
		***** National level regression 2
		grc1leg beta2_2_nat.gph beta4_2_nat.gph, 											///
		legendfrom(beta2_2_nat.gph) rows(1) imargin(medium) xcommon							///
		title(Power simulations (Geo=${geo_effect}; CfN=${cfn_effect}; CfW=${cfw_effect}; 	///
		CfW-controls=${cfw_spillover}), size(small))										///
		subtitle(Distribution of {&beta}'s, size(vsmall))									///
		note("{it:Note:} In all specifications, 8 PCs are switched to CfN. The number after Alternative corresponds to the number of surveys" "that are carried out in each village. Dashed lines represent an arbitrarily chosen critical value of 1.7 ({&alpha} = 0.1)." "Number of simulations = 1000. Question: `detail'", s(tiny))  
		
		graph export "${figures}\\`quest'\betas\Power_s`scenario'_national_2.png", replace // Save final graph


		grc1leg beta2_2_c_nat.gph beta4_2_c_nat.gph,										///
		legendfrom(beta2_2_c_nat.gph) rows(1) imargin(medium) xcommon						///
		title(Power simulations (Geo=${geo_effect}; CfN=${cfn_effect}; CfW=${cfw_effect}; 	///
		CfW-controls=${cfw_spillover}), size(small))										///
		subtitle(Distribution of {&beta}'s, size(vsmall)) 									///
		note("{it:Note:} In all specifications, 8 PCs are switched to CfN. The number after Alternative corresponds to the number of surveys" "that are carried out in each village. Dashed lines represent an arbitrarily chosen critical value of 1.7 ({&alpha} = 0.1)." "Number of simulations = 1000. Question: `detail'", s(tiny)) 
		
		graph export "${figures}\\`quest'\betas\Power_s`scenario'_national_controls_2.png", replace // Save final graph
		
		
		***** Governorate level regression 2
		grc1leg beta2_2_gov.gph beta4_2_gov.gph, 											///
		legendfrom(beta2_2_gov.gph) rows(1) imargin(medium) xcommon							///
		title(Power simulations (Geo=${geo_effect}; CfN=${cfn_effect}; CfW=${cfw_effect}; 	///
		CfW-controls=${cfw_spillover}), size(small))										///
		subtitle(Distribution of {&beta}'s, size(vsmall))									///
		note("{it:Note:} In all specifications, 8 PCs are switched to CfN. The number after Alternative corresponds to the number of surveys" "that are carried out in each village. Dashed lines represent an arbitrarily chosen critical value of 1.7 ({&alpha} = 0.1)." "Number of simulations = 1000. Question: `detail'", s(tiny)) 
		
		graph export "${figures}\\`quest'\betas\Power_s`scenario'_gov_2.png", replace // Save final graph


		grc1leg beta2_2_c_gov.gph beta4_2_c_gov.gph,										///
		legendfrom(beta2_2_c_gov.gph) rows(1) imargin(medium) xcommon						///
		title(Power simulations (Geo=${geo_effect}; CfN=${cfn_effect}; CfW=${cfw_effect}; 	///
		CfW-controls=${cfw_spillover}), size(small))										///
		subtitle(Distribution of {&beta}'s, size(vsmall)) 									///
		note("{it:Note:} In all specifications, 8 PCs are switched to CfN. The number after Alternative corresponds to the number of surveys" "that are carried out in each village. Dashed lines represent an arbitrarily chosen critical value of 1.7 ({&alpha} = 0.1)." "Number of simulations = 1000. Question: `detail'", s(tiny)) 
		
		graph export "${figures}\\`quest'\betas\Power_s`scenario'_gov_controls_2.png", replace // Save final graph
		
		
		
		foreach comparison in beta1_1_nat beta2_1_nat beta3_1_nat beta4_1_nat beta2_2_nat	///
		beta4_2_nat beta1_1_c_nat beta2_1_c_nat beta3_1_c_nat beta4_1_c_nat beta2_2_c_nat 	///
		beta4_2_c_nat beta1_1_gov beta2_1_gov beta3_1_gov beta4_1_gov beta2_2_gov 			///
		beta4_2_gov beta1_1_c_gov beta2_1_c_gov beta3_1_c_gov beta4_1_c_gov beta2_2_c_gov 	///
		beta4_2_c_gov{ // erase temp graphs
			
			erase `comparison'.gph
			
		}
		
		
		restore
	}
	
	local ++counter
}







******************************************************************************
******************************************************************************
