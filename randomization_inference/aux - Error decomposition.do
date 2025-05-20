global main 		"C:\Users\Pablo Uribe\Dropbox\Arlen\4. Pablo"
global real_data 	"${main}\Other stuff\ICC"

global questions FC1_d FC5_d FC8_d

quietly{

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

	foreach quest in $questions{

		levelsof HH7, local(strata)
		
		foreach id in `strata'{

			qui mixed `quest' || stratum: || HH1: if HH7 == `id', stddev

			matrix b = e(b)

			scalar mu_`id'_`quest' 			= exp(b[1, 1])
			scalar sd_village_`id'_`quest'  = exp(b[1, 3])
			scalar sd_ind_`id'_`quest'  	= exp(b[1, 4])
			scalar sd_subd_`id'_`quest' 	= exp(b[1, 2])
			
		}

		mixed `quest' || HH7: || stratum: || HH1: , stddev

		matrix b = e(b)

		scalar mu_`quest' 			= exp(b[1, 1])
		scalar sd_strata_`quest' 	= exp(b[1, 2])
		scalar sd_subd_`quest' 		= exp(b[1, 3])
		scalar sd_village_`quest'  	= exp(b[1, 4])
		scalar sd_ind_`quest'  		= exp(b[1, 5])


		sum `quest'
		scalar sd_`quest'  = r(sd)
	}

}