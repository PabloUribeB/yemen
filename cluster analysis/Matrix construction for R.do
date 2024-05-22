global data "C:\Users\Pablo Uribe\Dropbox\Arlen\4. Pablo\01 Data"

use "${data}\data_Yemen.dta", clear

foreach var of varlist PovertyIndex-fatal_rate_2023{
	ereplace `var' = std(`var')
}


collapse (mean) PovertyIndex-fatal_rate_2023, by(strataID)

rename (PovertyIndex-fatal_rate_2023) covar#, addnumber

save "${data}\matrix.dta", replace