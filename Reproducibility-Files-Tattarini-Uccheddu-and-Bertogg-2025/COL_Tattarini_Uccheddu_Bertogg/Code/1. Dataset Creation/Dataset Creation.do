
*-----------------------------------------------------------------------------------------------* 
*>> Open the log file
*-----------------------------------------------------------------------------------------------* 

cls 
cap log close 
log using "$share_logfile_common/Data Creation.log", replace



*-----------------------------------------------------------------------------------------------* 
*>> Extract & Recode Variables from CV_R
*-----------------------------------------------------------------------------------------------* 

global w "1 2 3 4 5 6 7 8 9"
foreach w in $w {
	di as result "Wave: " as txt "`w'"
	use "${share_w`w'_in}/sharew`w'_rel9-0-0_cv_r.dta", clear 	// Open the dataset  
	gen wave=`w'												// Create wave id 

	fre wave 

	*	Save
	save "${share_w`w'_out}/sharew`w'_cv_r.dta", replace 
}


*-----------------------------------------------------------------------------------------------* 
*>> Extract & Recode Variables from CH
*-----------------------------------------------------------------------------------------------* 

* Define waves
global w "1 2 4 5 6 7 8 9"

foreach w in $w {
	di as result "Wave: " as txt "`w'"
	use "${share_w`w'_in}/sharew`w'_rel9-0-0_ch.dta", clear   // Open the datasets
	gen wave=`w'                                              // Create wave id 

	*>> Contacts between parents and children 
	* 	Initialize the ch_contact variable to missing (.)
	gen ch_contact = . 

	* 	Label the ch_contact variable
	label variable ch_contact "Child contact frequency"

	* 	Define labels for ch_contact values
	label define ch_contact_lbl 				/// 
			0 "Childless" 						/// 
			1 "Children, No Regular Contact" 	/// 
			2 "Children, With Regular Contact"
	label values ch_contact ch_contact_lbl

	* 	Loop through each possible child variable (up to 20)
	forvalues i = 1/20 {
		
		* 	Construct the variable names based on the wave
		local varname1 "ch014_`i'"
		local varname2 "ch014_REG_`i'" // for wave 7

		* 	Check if the default variable name exists
		capture confirm variable `varname1'
		if _rc == 0 {
				local current_var `varname1'
			}
			else {

				* Check if the alternative variable name exists
				capture confirm variable `varname2'
				if _rc == 0 {
					local current_var `varname2'
				}
		}

		* 	Proceed if a valid variable name was identified
		if "`current_var'" != "" {

			* Recode contact frequency into a binary form (1 for regular contact, 0 otherwise)
			recode `current_var' (4/7 = 0) (1/3 = 1)  (else = .), gen(regular_contact_`i')
		 
			* Update ch_contact
				* Set to 0 in the "Data analysis" do-file
				// replace ch_contact = 0 if nchild_rounded == 0 & ch_contact == . 
				
				* Set to 1 if there are children but no regular contact
				replace ch_contact = 1 if regular_contact_`i' == 0 & ch_contact == .

				* Set to 2 if there is at least one child with regular contact
				replace ch_contact = 2 if regular_contact_`i' == 1 & ch_contact == .
		}
	}

	* Drop intermediate variables if they are no longer needed
	drop regular_contact_*

	* Save
	save "${share_w`w'_out}/sharew`w'_ch.dta", replace 
}


 
*-----------------------------------------------------------------------------------------------* 
*>> Extract & Recode Variables from GV_IMPUTATIONS
*-----------------------------------------------------------------------------------------------* 

*>> Wave 3 (SHARELIFE) doesn't have this module -> I have exluded this wave from the loop

global w "1 2 4 5 6 7 8 9"
foreach w in $w {
	di as result "Wave: " as txt "`w'"
	use "${share_w`w'_in}/sharew`w'_rel9-0-0_gv_imputations.dta", clear // Open the dataset  
	gen wave=`w'															// Create wave id 
 
		*>> Number of children 
			*	Mean value for the number of children (based on the 5 SHARE imputed datasets)
			bys mergeid: egen nchild_mean = mean(nchild) if nchild >= 0
			fre nchild_mean 
			sum nchild_mean 
			
			*	Round the variable
			gen nchild_rounded = round(nchild_mean, 1)
			fre nchild_rounded
			sum nchild_rounded
		 
		*>> Depression 
			*	Mean value for Euro-D (based on the 5 SHARE imputed datasets)
			bys mergeid: egen eurod_mean = mean(eurod) if eurod >= 0
			fre eurod_mean 
			sum eurod_mean 
			
			*	Round the variable
			gen eurod_rounded = round(eurod_mean, 1)
			fre eurod_rounded
			sum eurod_rounded

		*>> Income  
			*	Mean value for income (based on the 5 SHARE imputed datasets)
			bys mergeid: egen income_mean = mean(thinc)
			sum income_mean 
			
		*>> Wealth   
			*	Mean value for income (based on the 5 SHARE imputed datasets)
			bys mergeid: egen wealth_mean = mean(hnetw)
			sum wealth_mean 

	*>> Just keep one dataset 
	keep if implicat == 1
 
	*	Save
	save "${share_w`w'_out}/sharew`w'_gv_imputations.dta", replace 
}


*-----------------------------------------------------------------------------------------------* 
*>> Extract & Recode Variables from HS (childhood health)
*-----------------------------------------------------------------------------------------------* 

/* These variables are only present in the waves 3 and 7 */

*>>	WAVE 3
	use "$share_w3_in/sharew3_rel9-0-0_hs.dta" , clear
	gen wave=3 	// Create wave id 
	gen childhood_health = 1

	*	Keep only variables of interest
	keep 			///
	mergeid 			/// 
	wave 				/// 
	childhood_health 	///
	sl_hs003_ sl_hs004_ sl_hs005_ sl_hs006_ sl_hs007_

	*	Check the variables 
	fre wave sl_hs003_ sl_hs004_ sl_hs005_ sl_hs006_ sl_hs007_

	*	Harmonize the variable names 
	rename sl_hs003_  ch_srh 				// Childhood health status
	rename sl_hs004_  ch_missed_school 		// Childhood health: missed school for 1 month or longer
	rename sl_hs005_  ch_confined_bed 		// Childhood health: confined to bed or home for 1 month or longer
	rename sl_hs006_  ch_hospital_month 	// Childhood health: in hospital for 1 month or longer
	rename sl_hs007_  ch_hospital_3times 	// Childhood in hospital 3 times in 12 months

	fre ch_srh ch_missed_school ch_confined_bed ch_hospital_month ch_hospital_3times 
	desc ch_srh ch_missed_school ch_confined_bed ch_hospital_month ch_hospital_3times 

	*	Dataset Save
	save "$share_w3_out/sharew3_hs.dta", replace 


*>>	WAVE 7
	use "$share_w7_in/sharew7_rel9-0-0_hs.dta" , clear // Open the dataset
	gen wave=7 	// Create wave id 
	gen childhood_health = 1

	*	Harmonize the variable names 
	rename hs003_ ch_srh 			// Childhood health status
	rename hs004_ ch_missed_school 	// Childhood health: missed school for 1 month or longer
	rename hs005_ ch_confined_bed 	// Childhood health: confined to bed or home for 1 month or longer
	rename hs006_ ch_hospital_month // Childhood health: in hospital for 1 month or longer

	*	Keep only variables of interest
	keep			///
	mergeid 			/// Personal identifier
	wave 				/// 
	childhood_health 	///
	ch_srh ch_missed_school ch_confined_bed ch_hospital_month 

	fre wave ch_srh ch_missed_school ch_confined_bed ch_hospital_month
	desc wave ch_srh ch_missed_school ch_confined_bed ch_hospital_month

	*	Dataset Save
	save "$share_w7_out/sharew7_hs.dta", replace 



*-----------------------------------------------------------------------------------------------* 
*>> Extract & Recode Variables from CS (childhood SES)
*-----------------------------------------------------------------------------------------------* 

*	These variables are only present in the waves 3 and 7

*>>	WAVE 3
	use "$share_w3_in/sharew3_rel9-0-0_cs.dta" , clear
	gen wave=3 	// Create wave id 
	gen childhood_health = 1

	*	Keep only variables of interest
	keep				///
	mergeid 			/// 
	wave 				/// 
	childhood_health 	///
	sl_cs010_			/// Relative position to others when ten: mathematically
	sl_cs010a_			/// Relative position to others when ten: language
	sl_cs008_   		/// Number of books when ten
	sl_cs002_   		/// Rooms when ten years old
	sl_cs009_   		// Occupation of main breadwinner when ten

	*	Check the variables 
	fre wave sl_cs008_ sl_cs002_ sl_cs009_

	*	Harmonize the variable names 
	rename sl_cs008_ 	ch_books 			// Number of books when ten
	rename sl_cs002_ 	ch_rooms 			// Rooms when ten years old
	rename sl_cs009_ 	ch_pa_occupation 	// Occupation of main breadwinner when ten
	rename sl_cs010_  	ch_math     		// Relative position to others when ten: mathematically
	rename sl_cs010a_ 	ch_language     	// Relative position to others when ten: language

	fre wave ch_books ch_rooms ch_pa_occupation

	*	Dataset Save
	save "$share_w3_out/sharew3_cs.dta", replace 


*>>	WAVE 7
	use "$share_w7_in/sharew7_rel9-0-0_cc.dta" , clear // Open the dataset
	gen wave=7 	// Create wave id 
	gen childhood_health = 1

	*	Keep only variables of interest
	keep				///
	cc002_				/// Rooms when ten years old
	cc008_				/// Number of books when ten
	cc009isco			///	ISCO code: Occupation of main breadwinner when ten
	cc010_				/// Relative position to others when ten: mathematically
	cc010a_				/// Relative position to others when ten: language
	childhood_health 	///
	mergeid				/// Personal identifier
	wave				// 

	*>> Harmonize occupation of main breadwinner when ten // missing cases, SHARE team still have to work on this
	iscogen ch_pa_occupation = major(cc009isco)

	*	Harmonize the variable names 
	rename cc008_ 	ch_books 	// Number of books when ten
	rename cc002_ 	ch_rooms 	// Rooms when ten years old
	rename cc010_	ch_math		// Relative position to others when ten: mathematically
	rename cc010a_	ch_language	// Relative position to others when ten: language

	fre wave ch_books ch_rooms ch_pa_occupation
	desc wave ch_books ch_rooms ch_pa_occupation

	*	Dataset Save
	save "$share_w7_out/sharew7_cc.dta", replace 


*-----------------------------------------------------------------------------------------------* 
*>> Extract & Recode Variables from GV_ISCED
*-----------------------------------------------------------------------------------------------* 

*	Wave  3 has no information on education -> I have exluded this wave from the loop

global w "1 2 4 5 6 7 8 9"
foreach w in $w {
	di as result "Wave: " as txt "`w'"
	use "${share_w`w'_in}/sharew`w'_rel9-0-0_gv_isced.dta", clear 	// Open the dataset  
	gen wave=`w'													// Create wave id 

	*	Personal identifier & keep variables	
	keep 		///
	wave 			/// 
	mergeid			/// Person identifier (fix across modules and waves)
	isced1997_r 	/// Respondent: ISCED-97 coding of education 		

	fre wave isced1997_r  

	*	Save
	save "${share_w`w'_out}/sharew`w'_gv_isced.dta", replace 
}

*-----------------------------------------------------------------------------------------------* 
*>> Extract & Recode Variables from AC
*-----------------------------------------------------------------------------------------------* 

*	Wave  3 has no information on this -> I have exluded this wave from the loop

global w "1 2 4 5 6 7 8 9"
foreach w in $w {
	di as result "Wave: " as txt "`w'"
	use "${share_w`w'_in}/sharew`w'_rel9-0-0_ac.dta", clear 	// Open the dataset  
	gen wave=`w'												// Create wave id 

	fre wave  

	*	Save
	save "${share_w`w'_out}/sharew`w'_ac.dta", replace 
}


*-----------------------------------------------------------------------------------------------* 
*>> Extract & Recode Variables from CF
*-----------------------------------------------------------------------------------------------* 

*	Wave  3 has no information on cognitive functioning -> I have exluded this wave from the loop

global w "1 2 4 5 6 7 8 9"
foreach w in $w {
	di as result "Wave: " as txt "`w'"
	use "${share_w`w'_in}/sharew`w'_rel9-0-0_cf.dta", clear 	// Open the dataset  
	gen wave=`w'														// Create wave id 

*	Check for proxy interview variable 
cap confirm variable cf719_
if _rc {
	di as error "Variable cf719_ is missing in Wave `w'"
}
else {
	tab cf719_, miss
}

*	Personal identifier & keep variables	
keep 		///
wave 			/// 
mergeid			/// Person identifier (fix across modules and waves)
cf* 			/// Information on proxy interviews (and other CF variables)

	*	Save
	save "${share_w`w'_out}/sharew`w'_cf.dta", replace 
}


*-----------------------------------------------------------------------------------------------* 
*>> Extract & Recode Variables from PH
*-----------------------------------------------------------------------------------------------* 

*	Wave  3 has no information on physical health -> I have exluded this wave from the loop

global w "1 2 4 5 6 7 8 9"
foreach w in $w {
	di as result "Wave: " as txt "`w'"
	use "${share_w`w'_in}/sharew`w'_rel9-0-0_ph.dta", clear 	// Open the dataset  
	gen wave=`w'														// Create wave id 

*	Personal identifier & keep variables	
cap keep		///
wave 			/// Wave 
mergeid			/// Person identifier (fix across modules and waves)
ph006d16 		/// Alzheimer's disease, dementia, senility: ever diagnosed/currently having
ph008d1 		/// Cancer in: brain
ph009_16 		/// Age alzheimer's disease
ph080d1 		/// Cancer in which organs: brain

	*	Save
	save "${share_w`w'_out}/sharew`w'_ph.dta", replace 
}




*-----------------------------------------------------------------------------------------------* 
*>> Merge modules per wave
*-----------------------------------------------------------------------------------------------* 


*>> Wave 1
*	Macro
global w "1 2 3 4 5 6 7 8 9"

*	Loop start 
foreach w in $w {
	*	Display
	noi di as result "Wave: " as txt "`w'"

	*	Open the dataset 
	cap noi use "${share_w`w'_out}/sharew`w'_cv_r.dta", clear 	// Open the dataset  

	*	Merge module GV_ISCED
	cap noi merge 1:1 mergeid using "${share_w`w'_out}/sharew`w'_gv_isced.dta"
	cap noi fre _merge 
	cap noi drop _merge

	*	Merge module GV_IMPUTATIONS
	cap noi merge 1:1 mergeid using "${share_w`w'_out}/sharew`w'_gv_imputations.dta"
	cap noi fre _merge 
	cap noi drop _merge

	*	Merge module HS
	cap noi merge 1:1 mergeid using "${share_w`w'_out}/sharew`w'_hs.dta"
	cap noi fre _merge 
	cap noi drop _merge

	*	Merge module AC
	cap noi merge 1:1 mergeid using "${share_w`w'_out}/sharew`w'_ac.dta"
	cap noi fre _merge 
	cap noi drop _merge

	*	Merge module CC
	cap noi merge 1:1 mergeid using "${share_w`w'_out}/sharew`w'_cc.dta"
	cap noi fre _merge 
	cap noi drop _merge

	*	Merge module CH
	cap noi merge 1:1 mergeid using "${share_w`w'_out}/sharew`w'_ch.dta"
	cap noi fre _merge 
	cap noi drop _merge
	
	*	Merge module CF
	cap noi merge 1:1 mergeid using "${share_w`w'_out}/sharew`w'_cf.dta"
	cap noi fre _merge 
	cap noi drop _merge
	
	*	Merge module CS
	cap noi merge 1:1 mergeid using "${share_w`w'_out}/sharew`w'_cs.dta"
	cap noi fre _merge 
	cap noi drop _merge	

	*	Merge module PH
	cap noi merge 1:1 mergeid using "${share_w`w'_out}/sharew`w'_ph.dta"
	cap noi fre _merge 
	cap noi drop _merge

	*	Sort by pid
	sort mergeid 

	*	Save
	save "${share_w`w'_out}/sharew`w'_merged.dta", replace 
}



*-----------------------------------------------------------------------------------------------* 
*>> Append waves to panel long format
*-----------------------------------------------------------------------------------------------* 

*	Append single wave files to one long file:
use          "$share_w1_out/sharew1_merged.dta", clear
append using "$share_w2_out/sharew2_merged.dta"
append using "$share_w3_out/sharew3_merged.dta"
append using "$share_w4_out/sharew4_merged.dta"
append using "$share_w5_out/sharew5_merged.dta"
append using "$share_w6_out/sharew6_merged.dta"
append using "$share_w7_out/sharew7_merged.dta"
append using "$share_w8_out/sharew8_merged.dta"
append using "$share_w9_out/sharew9_merged.dta"



*-----------------------------------------------------------------------------------------------* 
*>> Checks
*-----------------------------------------------------------------------------------------------* 

*>>	Illogical variables 
* 	// Check for deviations within gender or isced across waves: 
	// if gender deviates between waves, one information must be wrong
	// as there is no way to know which is the wrong information, both
	// are set to -99 (i.e. implausible value/suspected wrong)

*>> Gender
sort mergeid
egen 	gender_change = sd(gender), by(mergeid)
ta 		gender_change
replace gender = -99 if gender_change > 0 & gender_change < .
drop 	gender_change 
recode  gender (-99=.)

*>> Year of Birth
egen 	yrbirth_change = sd(yrbirth), by(mergeid)
ta 		yrbirth_change
replace yrbirth = -99 if yrbirth_change > 0 & yrbirth_change < . 
drop	yrbirth_change 
recode  yrbirth (-99=.)

*>> Order variables
order mergeid wave int_year int_month yrbirth mobirth age_int country 


*----	[ XX. Sample selection (first step)           ]----------------------------------------------------------* 

*>> Keep only relevant countries
drop if !inlist(country, 13, 14, 16, 17) // 13 Sweden, 14 Netherlands, 16 Italy, 17 France



* ======================================================================= * 
*	Keep variables 
* ======================================================================= * 
 
keep 				///
ac002d1 			/// Activities last month: voluntary or charity work
ac002d4 			/// Activities last month: attended educational or training course
ac002d5 			/// Activities last month: gone to sport, social or other kind of club
ac002d6 			/// Activities last month: taken part in religious organization
ac002d7 			/// Activities last month: taken part in political or community organization
ac003_1 			/// How often in last 4 weeks: voluntary/charity work
ac003_4 			/// How often in last 4 weeks: attended educational/training course
ac003_5 			/// How often in last 4 weeks: sport/social/other club
ac003_6 			/// How often in last 4 weeks: taken part religious organization
ac003_7 			/// How often in last 4 weeks: taken part political/community-rel. org.
ac035d1 			/// Activities in last year: done voluntary or charity work
ac035d4 			/// Activities in last year: attended an educational or training course
ac035d5 			/// Activities in last year: gone to a sport, social or other kind of club
ac035d6 			/// Activities in last year: taken part in activities of a religious organization
ac035d7 			/// Activities in last year: taken part in a political or community-related organiza
ac036_1 			/// How often done voluntary/charity work the last 12 months
ac036_4 			/// How often attended an educational or training course the last 12 months
ac036_5 			/// How often gone to a sport/social/other kind of club the last 12 months
ac036_6 			/// How often taken part in activities of a religious organization the last 12 months
ac036_7 			/// How often taken part in a political/community-related organization the last 12 months
adl 				/// Limitations with activities of daily living
age_int 			/// Age of respondent at the time of interview
book10 				/// How many books at 10 years - Flag
book10_f 			/// How many books at 10 years - Flag
cf* 				/// All the information about proxy interviews in the CF module
ch021_          	/// Number of grandchildren
ch022_          	/// Has great-grandchildren
ch_* 				/// Other children's variables
ch_books 			/// Number of books when ten
ch_confined_bed 	/// Childhood health: confined to bed or home for 1 month or longer
ch_hospital_3times	/// Childhood in hospital 3 times in 12 months
ch_hospital_month 	/// Childhood health: in hospital for 1 month or longer
ch_missed_school 	/// Childhood health: missed school for 1 month or longer
ch_rooms 			/// Rooms when ten years old
childhood_health	///                  
cjs 				/// Current job situation
country 			/// Country identifier
coupleid* 			/// Couple identifier
diseas15 			/// Number of childhood diseases at 15 years - Flag
diseas15_f 			/// Number of childhood diseases at 15 years - Flag
eurod 				/// EURO depression scale
eurod* 				/// Euro-D depression scale	(and related variables)
eurod_f 			/// EURO depression scale - Flag
fam_resp 			/// Family respondent
fluency 			/// Score of verbal fluency test
fluency_f 			/// Score of verbal fluency test - Flag
gali 				/// Limitation with activities
gali_f 				/// Limitation with activities - Flag
gender 				/// RECODE of gender_old (Male or female)
health15 			/// Childhood health at 15 years - Flag
health15_f 			/// Childhood health at 15 years - Flag
hhsize 				/// Household size 
iadl 				/// Limitations with instrumental activities of daily living
illness15 			/// Number of childhood illnesses at 15 years - Flag
illness15_f 		/// Number of childhood illnesses at 15 years - Flag
income_mean 		/// Income 
int_month 			/// Month of interview 
int_year 			/// Year of interview 
isced 				/// Education 
lang10 				/// Childhood language performance at 10 years - Flag
lang10_f 			/// Childhood language performance at 10 years - Flag
math10 				/// Childhood maths performance at 10 years - Flag
math10_f 			/// Childhood maths performance at 10 years - Flag
memory 				/// Score of memory test
memory_f 			/// Score of memory test - Flag
mergeid 			/// Person identifier (fix across modules and waves)
mstat* 				/// 
nalm 				/// Number of activities last month
nalm_f 				/// Number of activities last month - Flag
naly 				/// Number of activities last year
naly_f 				/// Number of activities last year - Flag
nchild* 			/// Number of children variables 
numeracy 			/// Score of first numeracy test
numeracy2 			/// Score of second numeracy test
numeracy2_f 		/// Score of second numeracy test - Flag
numeracy_f 			/// Score of first numeracy test - Flag
orienti 			/// Score of orientation in time test
orienti_f 			/// Score of orientation in time test - Flag
partnerinhh 		/// Partner in household
people10 			/// People in childhood home at 10 years - Flag
people10_f 			/// People in childhood home at 10 years - Flag
ph006d16 			/// Alzheimer's disease, dementia, senility: ever diagnosed/currently having
ph008d1 			/// Cancer in: brain
ph009_16 			/// Age alzheimer's disease
ph080d1 			/// Cancer in which organs: brain
reading 			/// Self-rated reading skills - Flag
reading_f 			/// Self-rated reading skills - Flag
room10 				/// Rooms in childhood home at 10 years - Flag
room10_f 			/// Rooms in childhood home at 10 years - Flag
SHARELIFE 			/// Individual indicator of SHARELIFE interview
undersq 			/// Respondent understood questions - Flag
undersq_f 			/// Respondent understood questions - Flag
vacc15 				/// Received vaccinations at 15 years - Flag
vacc15_f 			/// Received vaccinations at 15 years - Flag
wave 				/// Wave 
wealth_mean 		/// Wealth 
wllft 				/// Score of words list learning test - trial 1
wllft 				/// Ten words list learning first trial total
wllft_f 			/// Score of words list learning test - trial 1 - Flag
wllst 				/// Score of words list learning test - trial 2
wllst 				/// Ten words list learning delayed recall total
wllst_f 			/// Score of words list learning test - trial 2 - Flag
writing 			/// Self-rated writing skills - Flag
writing_f 			///	Self-rated writing skills - Flag
yrbirth 			/// Birth year 



*-----------------------------------------------------------------------------------------------* 
*>> Final operations 
*-----------------------------------------------------------------------------------------------* 

	   
*>> Final Sort
sort mergeid wave // sorting by personal ID and time points

*>> Check for possible duplicate cases
isid mergeid wave

*>> Drop variables that are all missing (Stata Journal, volume 8, number 4: dm89_1) --> here using dm89_2
missings dropvars, force 

*>> Compress dataset
compress

*>> Remove any notes
notes drop _dta

*-----------------------------------------------------------------------------------------------* 
*>> Final Save
*-----------------------------------------------------------------------------------------------* 

*>> Save the dataset
save "$share_all_out/SHARE_w1_w9_panel.dta", replace


*-----------------------------------------------------------------------------------------------* 
*>> Close 
*-----------------------------------------------------------------------------------------------* 

*>> Timer
display "$S_TIME  $S_DATE"
timer off 1
timer list 1

*>> Log file
log close
