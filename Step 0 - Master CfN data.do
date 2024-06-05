/*************************************************************************
 *************************************************************************			       	
		 Simulated CfN beneficiaries (fixed) dataset creation
			 
1) Created by: Pablo Uribe
			   DIME - World Bank
			   puribebotero@worldbank.org
				
2) Date: May 14, 2024

3) Objective: Use user-built programs to perform power calculations by simulation

4) Output:	- cfn_selected.dta
*************************************************************************
*************************************************************************/	


****************************************************************************
* Global directory, parameters and assumptions:
****************************************************************************
global main "C:\Users\Pablo Uribe\Dropbox\Arlen\4. Pablo"
global data "${main}\01 Data"
global real_data "${main}\Other stuff\ICC"

global questions FC1_d FC5_d FC8_d

version 18
set seed 2408

****************************************************************************
**# Real data error decomposition
****************************************************************************

import spss using "${real_data}\hh.sav", clear

*ssc install asgen


/*
FC1 not eating enough for lack of money
FC2 Unable to eat healthy and nutritious food for lack of money
FC4 Skip a meal
FC5 Ate less than thought
FC6 Ran out of food
FC7 Hungry but did not eat
FC8 Went without eating for whole day
*/

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

keep *_d HH1 HH7 high_income stratum

replace HH7 = 1 if inlist(HH7, 15, 30)
replace HH7 = 2 if inlist(HH7, 21, 22)
replace HH7 = 3 if inlist(HH7, 11, 27, 29)

foreach quest in $questions{

	levelsof HH7, local(strata)

	foreach id in `strata'{
		
		qui sum `quest' if HH7 == `id'
		scalar mu_`id'_`quest' = r(mean)
	}



	levelsof HH7, local(strata)

	foreach id in `strata'{
		
		qui mixed `quest' || stratum: || HH1: if HH7 == `id', stddev

		matrix b = e(b)

		*scalar sd_strata_`id'_`quest' 	= exp(b[1, 2])
		scalar sd_subd_`id'_`quest' 	= exp(b[1, 2])
		
	}


	mixed `quest' || HH7: || stratum: || HH1: , stddev

	matrix b = e(b)

	scalar mu_`quest'			= exp(b[1, 1])
	scalar sd_strata_`quest' 	= exp(b[1, 2])
	scalar sd_subd_`quest' 		= exp(b[1, 3])
}

****************************************************************************
**# Data simulation (governorate-specific)
****************************************************************************

drop _all

gen strata_id = .

* Create the strata IDs
input
	11
	14
	15
	16
	17
	18
	20
	21
	22
	23
	26
	27
	29
	30
	31
	19
	25
end

* Create observations equivalent to the number of subdistricts in each stratum
expand 2 if inlist(strata_id, 11, 15, 21, 22, 27, 29, 30)

expand 3 if inlist(strata_id, 16, 20, 25)

expand 4 if inlist(strata_id, 14, 18, 23, 31, 19)

expand 5 if strata_id == 26

expand 6 if strata_id == 17

* Assign one subdistrict from each stratum to CfN
bys strata_id: gen cfn = (_n == 1)

* Those with more than 4 subdistricts get 2 assigned to PC, and stratum 18 (4 subdist.) also gets a second one assigned to PC
bys strata_id (cfn): replace cfn = 1 if _n == 1 & (_N > 4 | strata_id == 18)

* Group the 7 strata with just one subdistrict remaining to three clusters based on results from cluster analysis
replace strata_id = 1 if inlist(strata_id, 15, 30)
replace strata_id = 2 if inlist(strata_id, 21, 22)
replace strata_id = 3 if inlist(strata_id, 11, 27, 29)

* Subdistrict ID
bys strata_id: gen subd_id = string(strata_id) + "-" + "00" + string(_n)

levelsof strata_id, local(sim_local)

foreach quest in $questions{

	* Create the strata random component
	local gen gen
	foreach id in `sim_local'{
		`gen' epsilon_s_`quest' = mu_`id'_`quest' if strata_id == `id'
		local gen replace
	}



	bys strata_id: ereplace epsilon_s_`quest' = mean(epsilon_s_`quest') // has to be constant within strata


	levelsof strata_id, local(sim_local2)

	* Create the strata random component
	local gen gen
	foreach id in `sim_local2'{
		
		`gen' epsilon_d0_`quest' = rnormal(0, sd_subd_`id'_`quest') if strata_id == `id' // Subdistrict-level random component baseline
		
		`gen' epsilon_d1_`quest' = rnormal(0, sd_subd_`id'_`quest') if strata_id == `id' // Subdistrict-level random component follow-up
		
		local gen replace
		
	}
}

compress

save "${data}\cfn_selected_gov_specific.dta", replace // Save dta. This will be called in each simulation



****************************************************************************
**# Data simulation (national)
****************************************************************************

drop _all

gen strata_id = .

* Create the strata IDs
input
	11
	14
	15
	16
	17
	18
	20
	21
	22
	23
	26
	27
	29
	30
	31
	19
	25
end


foreach quest in $questions{

	* Create the strata random component
	gen epsilon_s0_`quest' = rnormal(0, mu_`quest')
	gen epsilon_s1_`quest' = rnormal(0, mu_`quest')

}

* Create observations equivalent to the number of subdistricts in each stratum
expand 2 if inlist(strata_id, 11, 15, 21, 22, 27, 29, 30)

expand 3 if inlist(strata_id, 16, 20, 25)

expand 4 if inlist(strata_id, 14, 18, 23, 31, 19)

expand 5 if strata_id == 26

expand 6 if strata_id == 17

* Assign one subdistrict from each stratum to CfN
bys strata_id: gen cfn = (_n == 1)

* Those with more than 4 subdistricts get 2 assigned to PC, and stratum 18 (4 subdist.) also gets a second one assigned to PC
bys strata_id (cfn): replace cfn = 1 if _n == 1 & (_N > 4 | strata_id == 18)

* Group the 7 strata with just one subdistrict remaining to three clusters based on results from cluster analysis
replace strata_id = 1 if inlist(strata_id, 15, 30)
replace strata_id = 2 if inlist(strata_id, 21, 22)
replace strata_id = 3 if inlist(strata_id, 11, 27, 29)

* Subdistrict ID
bys strata_id: gen subd_id = string(strata_id) + "-" + "00" + string(_n)


foreach quest in $questions{
	
	bys strata_id: ereplace epsilon_s0_`quest' = mean(epsilon_s0_`quest') // has to be constant within strata
	bys strata_id: ereplace epsilon_s1_`quest' = mean(epsilon_s1_`quest') // has to be constant within strata


	* Create the strata random component
	gen epsilon_d0_`quest' = rnormal(0, sd_subd_`quest') // Subdistrict-level random component baseline
	gen epsilon_d1_`quest' = rnormal(0, sd_subd_`quest') // Subdistrict-level random component follow-up
	
}


compress

save "${data}\cfn_selected_national.dta", replace // Save dta. This will be called in each simulation




********************************************************************************
********************************************************************************