*-----------------------------------------------------------------------------------------------* 
*>> Preliminary operations 
*-----------------------------------------------------------------------------------------------* 

*>> Clear the screen 
cls 

*>> Close the log 
capture log close 

*>> Open new log file 
log using 	"$share_logfile_common/Data Cleaning (MCSA).log", replace

*>> Open the dataset 
use 		"$share_all_out/SHARE_for_SA.dta", clear 

*>> Describe the dataset 
desc, short 
sort mergeid age 

*>> Describe the missing cases
mdesc

*>> Check the variables needed to create the sequences 
fre familystate_ workstate_ 

*-----------------------------------------------------------------------------------------------* 
*>> Reshape wide 
*-----------------------------------------------------------------------------------------------* 

*>> Select the needed variables
keep mergeid country gender age workstate_ familystate_ 

*>> Reshape wide 
reshape wide	/// 
workstate_ 		/// 
familystate_ 	/// 
, i(mergeid) j(age)

*>> Sort the dataset 
sort gender mergeid, stable 


* ======================================================================= * 
* 	Create the sequences 
* ======================================================================= * 

*>> Define country codes and other labels
local countries 		"13 14 16 17"
local country_labels 	"SE NL IT FR"
local status 			"Family Employment"

*>> Check the sample size
fre gender 

*>> Loop for men (1) and women (2)
foreach g in 1 2 {

	*>> Loop for type (Family, Employment)
	foreach t in `status' {
	
		preserve

			*	Select gender
			keep if gender == `g'  
			
			*	Differentiate between Family and Employment
			if "`t'" == "Family" {
				keep mergeid country familystate_*	
			}
			else {
				keep mergeid country workstate_*
			}

			sort mergeid
			missings dropvars, force
			compress

			*	Save the dataset for All Countries
			local gender_label = cond(`g' == 1, "Men", "Women")
			save "$share_all_out/SHARE_for_SA_`gender_label'_`t'.dta", replace
		
		restore

		*>> Loop for each country
		local i = 1

		foreach c in `countries' {
			local label: word `i' of `country_labels'
			
			preserve
			
				*	Filter for gender and country
				keep if gender == `g' & country == `c'
				
				*	Differentiate between Family and Employment
				if "`t'" == "Family" {
					keep mergeid country familystate_*
				}
				else {
					keep mergeid country workstate_*
				}
				sort mergeid
				missings dropvars, force
				compress

				*	Save the dataset
				save "$share_all_out/SHARE_for_SA_`gender_label'_`t'_`label'.dta", replace
			
			restore
			
			local ++i
		}
	}
}



*----	[ XX. Close                                   ]----------------------------------------------------------* 

*>> Close the log 
log close 

