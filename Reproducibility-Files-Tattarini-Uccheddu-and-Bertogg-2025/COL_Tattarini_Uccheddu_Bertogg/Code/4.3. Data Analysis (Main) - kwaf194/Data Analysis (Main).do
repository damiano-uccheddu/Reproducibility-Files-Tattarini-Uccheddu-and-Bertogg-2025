
cls 
capture log close
log using "$share_logfile_kwaf194/Data Analysis (main).log", replace 
set more off
set scheme white_tableau
pause on


* --------------------------------------------------------------------------------------------------------------------------- *
* > 
* > Prepare the dataset for the analysis
* > 
* --------------------------------------------------------------------------------------------------------------------------- *

*>> Merge life course clusters with remaining variables 
use 						"$share_all_out/SHARE_w1_w9_panel.dta"	, clear 	// panel dataset
merge m:1 mergeid using 	"$share_all_out/cluster_men_6.dta"		, nogen  	// men's life courses  
merge m:1 mergeid using 	"$share_all_out/cluster_women_9.dta"	, nogen  	// women's life courses


*	Numerical pid
egen pid = group(mergeid)

*	Xtset the data 
xtset 	pid wave 
sort 	pid wave, stable

*	Initial check 
fre wave 


* ======================================================================= * 
*	Keep only the variables of interest
* ======================================================================= * 

keep  				///
ac002d1 			///
ac002d4 			///
ac002d5 			///
ac002d6 			///
ac002d7 			///
ac003_1 			///
ac003_4 			///
ac003_5 			///
ac003_6 			///
ac003_7 			///
ac035d1 			///
ac035d4 			///
ac035d5 			///
ac035d6 			///
ac035d7 			///
ac036_1 			///
ac036_4 			///
ac036_5 			///
ac036_6 			///
ac036_7 			///
adl 				///
age_int 			///
cf* 				///
ch* 				///
cluster* 			///
country 			///
coupleid* 			/// 
eurod* 				///
fam_resp 			///
fluency* 			///
gali*  				///
gender 				///
hhsize 				///
iadl 				///
income_mean 		///
int_month 			///
int_year 			/// 
isced 				///
mergeid 			///
nalm* 				///
naly* 				///
nchild_rounded 		///
numeracy* 			///
orienti* 			///
partnerinhh 		/// 
ph* 				///
pid 				///
SHARELIFE 			///
wave 	 			///
wealth_mean 		///
wllft 				///
wllft_f 			///
wllst 				///
wllst_f 			///
yrbirth 			/// 



* --------------------------------------------------------------------------------------------------------------------------- *
* > 
* > Dependent variables creation
* > 
* --------------------------------------------------------------------------------------------------------------------------- * 


* ======================================================================= * 
*	Dependent variable(s) 
* ======================================================================= * 

*>> Numeracy 
fre numeracy*
fre fluency*
fre orienti*

foreach var of varlist numeracy fluency orienti {
	recode `var' (-99 -2 -1 = .)
	replace `var' = . if `var'_f != 3
}

 

*>> Check the items 
foreach var of 	varlist 	///
							///
				wllft 		///
				wllft_f 	/// non-imputed values == 3
				wllst 		///
				wllst_f 	/// non-imputed values == 3
{
	tab `var' wave, miss
	recode `var' (-99 -2 -1   = .) 
}
 

*>> Ten Words List Learning
	*	Weighted scores for the two cognitive tests (immediate and delayed)
	gen w_immediate_recall 	= 0.5 * wllft if wllft_f == 3 // only regular obs.
	gen w_delayed_recall 	= 0.5 * wllst if wllst_f == 3 // only regular obs.

	*	Create the composite (sum) Memory score 
	gen memory_score = wllft + wllst 	/// 
										if wllft_f == 3 & wllst_f == 3 			// only regular obs.
	
	*	Create an alternative score by adding a weight of 50% for each of the memory tests
	gen memory_score_alternative = 	w_immediate_recall + w_delayed_recall 	/// 
										if wllft_f == 3 & wllst_f == 3 			// only regular obs.

*>> Check how many missing
fre memory_score numeracy fluency orienti
 


* --------------------------------------------------------------------------------------------------------------------------- *
* > 
* > Independent variables creation
* > 
* --------------------------------------------------------------------------------------------------------------------------- * 

* ======================================================================= * 
*	Practice effects (Vivot et al. 2016)
* ======================================================================= * 

*>> Memory score
*	Number of tests per individual --> 	i.e., how many times the cognitive assessment was 
										// ...administered to the same individual

	foreach var of 	varlist 			///
					memory_score 	/// 
	{
		
		preserve
		
				*	drop if the outcome is missing 
				drop if memory_score >= . 
				drop if wllft_f 		!= 3
				drop if wllst_f 		!= 3
				
				*	Create a count variable 
				bys  mergeid (wave): gen ntests_`var' = _n

				*	Check 
				desc, short 
				fre ntests_`var'
				sum ntests_`var'

				*	Save a temporary dataset 
				save "$share_all_out/temp.dta", replace 

		restore

			*	Merge using the temporary dataset (keep only the new count variable[s])
			merge 1:1 _all using "$share_all_out/temp.dta", nogen keepusing(ntests_*)

			*	Check 
			list mergeid wave wllft wllst memory_score ntests_* in 95909/95960, sepby(pid)

			*	Delete the temporrary dataset 
			erase "$share_all_out/temp.dta"
	}

*>> Fluency and Numeracy 
*	Number of tests per individual --> 	i.e., how many times the cognitive assessment was 
										// ...administered to the same individual

	foreach var of 	varlist 					///
					fluency numeracy orienti 	/// 
	{
		
		preserve
		
				*	drop if the outcome is missing 
				drop if `var' >= . 
				drop if `var'_f 		!= 3
				
				*	Create a count variable 
				bys  mergeid (wave): gen ntests_`var' = _n

				*	Check 
				desc, short 
				fre ntests_`var'
				sum ntests_`var'

				*	Save a temporary dataset 
				save "$share_all_out/temp.dta", replace 

		restore

			*	Merge using the temporary dataset (keep only the new count variable[s])
			merge 1:1 _all using "$share_all_out/temp.dta", nogen keepusing(ntests_*)

			*	Check 
			list mergeid wave `var' ntests_* in 95909/95960, sepby(pid)

			*	Delete the temporrary dataset 
			erase "$share_all_out/temp.dta"
	}




* ======================================================================= * 
*>> Describe the missing cases:
* ======================================================================= * 

preserve 
foreach var of varlist memory_score fluency numeracy orienti ///
{
	recode `var' (-2 -1 = .)
	tab `var' wave, miss col nofre

}
restore 


* ======================================================================= * 
*	Childhood variables 
* ======================================================================= * 
 
*	Missing 
foreach var of varlist  ///
	ch_books         	/// Number of books when ten
	ch_math 			/// Relative position to others when ten: mathematically
	ch_language 		/// Relative position to others when ten: language
	ch_confined_bed  	/// Childhood health: confined to bed or home for 1 month or longer
	ch_hospital_month	/// Childhood health: in hospital for 1 month or longer
	ch_missed_school 	/// Childhood health: missed school for 1 month or longer
	ch_rooms         	/// Rooms when ten years old
	ch_srh 				/// Childhood health status
	ch_pa_occupation 	/// Occupation of the main breadwinner in the household when ten
{
	recode `var' (-1 -2 = .)
	replace ch_pa_occupation = . if inlist(ch_pa_occupation, 0, 10, 11) 
	replace ch_math = . if inlist(ch_math, 9) 	// i.e., "Not applicable: did not go to school"
	replace ch_srh 	= . if inlist(ch_srh, 6) 	// i.e., "Health varied a great deal (spontaneous)"
}
 
*	Simple recode 
foreach var of varlist  		///
	ch_confined_bed 			/// Childhood health: confined to bed or home for 1 month or longer
	ch_hospital_month 			/// Childhood health: in hospital for 1 month or longer
	ch_missed_school 			/// Childhood health: missed school for 1 month or longer
{
	recode `var' (5 = 0)
}

*	Labels (yes/no)
cap drop label drop yesno_lab
label define yesno_lab 	///
   0 "No"  				///
   1 "Yes" 
label values ch_missed_school ch_confined_bed ch_hospital_month yesno_lab


*>> Number of rooms (recode)
recode ch_room 	(0 1 2 = 0 	"Less than 2") 	/// 
				(3 = 1 		"3") 			/// 
				(4 = 2 		"4") 			/// 
				(5 = 3 		"5") 			/// 
				(6/max = 4 "More than 6"), gen(ch_rooms_new)
tab ch_rooms ch_rooms_new, miss

drop ch_rooms 
rename ch_rooms_new ch_rooms
fre ch_rooms 


* ======================================================================= * 
*	Time variables 
* ======================================================================= * 

*>> Cohort 
recode yrbirth 	(1800/1945 	= 0 "<=1945") 	///
				(1946/1955 	= 1 "1946-1955") ///
				(1956/1967 	= 2 "1956-1967")	///
				(else 		= .), gen(cohort)

* ======================================================================= * 
*	Gender/Sex
* ======================================================================= * 

*>> Recode the variable 
fre gender 
rename gender gender_old 
recode gender_old (1 = 0 "Men") (2 = 1 "Women"), gen(gender)
tab gender_old gender, miss 
drop gender_old

* ======================================================================= * 
*	Education 
* ======================================================================= * 

cap drop 	edu
gen 		edu = . 
replace		edu = 0 if inlist(isced, 0, 1, 2)
replace		edu = 1 if inlist(isced, 3, 4)
replace		edu = 2 if inlist(isced, 5, 6)
fre edu 


* ======================================================================= * 
*	Depression 
* ======================================================================= * 

*>> Identify highly depressed people (scoring high on Euro-D, 2+ SD above the mean), 
	// which corresponds to at least 7 out of 12 symptoms of depression on the EURO-D scale)
	// We do this because depression impairs recall abilities (see also https://doi.org/10.1007/s10433-023-00751-4)

	// Check: 
		// - https://doi.org/10.1007/s10433-023-00751-4
		// - http://dx.doi.org/10.1016/S0140-6736(15)60461-5
		// - https://doi.org/10.1016/j.neurobiolaging.2011.09.010
 



	*	Calculate mean and SD
	sum eurod_mean if eurod_mean >= 0 & eurod_mean < ., detail

	*	Compute the cutoff point
	local cutoff = r(mean) + 2 * r(sd)

	*	Create a new variable indicating high depression scores
	gen high_depression = (eurod_mean >= `cutoff') if eurod_mean >= 0 & eurod_mean < . // important here to consider the missings 

	*	Check 
	fre high_depression 
  

* ======================================================================= * 
*	Work-family life course clusters
* ======================================================================= * 

*>> Men 
* 	Create/recode/order the clusters 
gen lcmen = . 
replace lcmen = cluster_6 if gender == 0

*>> Women 
* 	Create/recode/order the clusters 
gen lcwomen = . 
replace lcwomen = cluster_9 if gender == 1


*>> Labels 
* Define value labels for men's latent class categories
label define lcmen_lbl ///
	1 "Partnered Fathers, FT Work" ///
	2 "Late-Partnered Fathers, FT Work" ///
	3 "Single Men, FT Work" ///
	4 "Partnered Fathers, Weak LM attachment" ///
	5 "Partnered Men, FT Work" ///
	6 "Single Fathers, FT Work"

* Define value labels for women's latent class categories
label define lcwomen_lbl ///
	1 "Partnered Mothers, Unpaid Caregiver" ///
	2 "Partnered Mothers, FT Work" ///
	3 "Partnered Mothers, Little (Un)paid Work" ///
	4 "Single Mothers, FT Work" ///
	5 "Single Women, FT Work" ///
	6 "Partnered Mothers, PT Work" ///
	7 "Partnered Mothers, Unemployed" ///
	8 "Partnered Women, Discontinued FT Work" ///
	9 "Single Mothers, PT Work"

* Assign the labels to the respective variables
label values lcmen lcmen_lbl
label values lcwomen lcwomen_lbl



* --------------------------------------------------------------------------------------------------------------------------- *
* > 
* > Interpolate the retrospective data
* > 
* --------------------------------------------------------------------------------------------------------------------------- *

/* We have to interpolate SHARELIFE data (from both waves 3 and 7) into the regular panel data from SHARE,
essentially filling in gaps in the panel data with information from the SHARELIFE data. 
We need this for creating the complete dataset for analysis.  */

*	Check 
count 

*	Rename the variables of interest 
rename ch_books				ch_books_old
rename ch_confined_bed		ch_confined_bed_old
rename ch_hospital_month	ch_hospital_month_old
rename ch_language			ch_language_old
rename ch_math				ch_math_old
rename ch_missed_school		ch_missed_school_old
rename ch_pa_occupation		ch_pa_occupation_old
rename ch_rooms				ch_rooms_old
rename ch_srh				ch_srh_old
rename lcmen 				lcmen_old 
rename lcwomen 				lcwomen_old 

*	Check 
local retro_vars  			///
	ch_books 				///
	ch_confined_bed 		///
	ch_hospital_month 		///
	ch_language 			///
	ch_math 				///
	ch_missed_school 		///
	ch_pa_occupation 		///
	ch_rooms 				///
	ch_srh 					///
	lcmen  					///
	lcwomen
list pid mergeid wave `retro_vars' in 1/100, sepby(pid)


* ======================================================================= * 
*	Fill down/expand observations...
*	...with respect to the (retrospective) time variables
*	See here: https://stats.oarc.ucla.edu/stata/faq/how-can-i-fill-downexpand-observations-with-respect-to-a-time-variable/
* ======================================================================= * 

*	Loop
foreach var of varlist 		///
	ch_books_old			///
	ch_confined_bed_old		///
	ch_hospital_month_old	///
	ch_language_old 		///
	ch_math_old 			///
	ch_missed_school_old	///
	ch_pa_occupation_old	///
	ch_rooms_old			///
	ch_srh_old				///
	lcmen_old 				///
	lcwomen_old 			///
{ 

	*>> 1st step
	sort pid wave, stable  
	tsset pid wave
	tsfill, full // This fill in gaps in panel data with new observations containing missing values ("dummy observations" below)
	bysort pid: carryforward `var', gen(`var'_step1)

	*>> 2nd step 
	gsort pid - wave
	bysort pid: carryforward `var'_step1, gen(`var'_step2)
}

*	Sort again the dataset 
sort pid wave, stable  

*	Rename the variables just created  
rename ch_books_old_step2			ch_books
rename ch_confined_bed_old_step2	ch_confined_bed
rename ch_hospital_month_old_step2	ch_hospital_month
rename ch_language_old_step2		ch_language
rename ch_math_old_step2			ch_math
rename ch_missed_school_old_step2	ch_missed_school
rename ch_pa_occupation_old_step2 	ch_pa_occupation
rename ch_rooms_old_step2			ch_rooms
rename ch_srh_old_step2				ch_srh
rename lcmen_old_step2 				lcmen
rename lcwomen_old_step2 			lcwomen

*	Check
list pid mergeid wave `retro_vars' in 1/100, sepby(pid)
count 

*>> Drop the dummy/fake observations created with "tsfill, full"
drop if mergeid == "" 	// this doesn't count as missing data from the analytical 
						// dataset because we are just removing the dummy observations 
						// created with the "tsfill, full" command.
						//
						// --> (259,119 observations deleted)
*	Check 
count 


* --------------------------------------------------------------------------------------------------------------------------- *
* > 
* > Sample selection (second step)
* > 
* --------------------------------------------------------------------------------------------------------------------------- * 

*>> Check variables 
fre  					///
ch_books  				///
ch_confined_bed  		///
ch_hospital_month  		///
ch_missed_school  		///
ch_rooms  				///
ch_srh 					///
memory_score 			///
cohort  				///
country  				///
gender  				///
lcmen 					///
lcwomen 				///
ntests_memory_score 	///
wave  					///

xtdes 
*>> Drop individuals without life histories 
drop if lcmen 	>= . & lcwomen 	== . 
drop if lcwomen >= . & gender 	== 1
drop if lcmen 	>= . & gender 	== 0
xtdes
count 

*>> Sample used for the sequence analysis
xtdes 
bys gender: xtdes 
fre gender 
 

*>> Eligibility
drop if age_int<50
xtdes 

*>> Drop individuals with missing in childhood conditions (SES and health)
drop if ch_books 			>= .
drop if ch_confined_bed 	>= .
drop if ch_hospital_month 	>= .
drop if ch_language			>= .
drop if ch_math				>= .
drop if ch_missed_school 	>= .
drop if ch_rooms 			>= .
drop if ch_srh 				>= .

*>> Drop when the outcome is missing 
drop if memory_score 		>= .
drop if ntests_memory_score	>= . 
drop if wllft_f 		!= 3
drop if wllst_f 		!= 3

*>> Other variables 
drop if cohort 					>= . 
drop if country 				>= . 
drop if gender 					>= .
drop if mergeid 				== ""
drop if wave 					>= . 

*>> Describe the dataset (panel)
xtdes

*>> Chronic conditions affecting brain health 
		* 	Flag individuals with...
		bysort pid: egen max_alzheimers 			= max(ph006d16 	== 1) // ...Alzheimer's, dementia, or senility across any wave
		bysort pid: egen max_brain_cancer_ph008d1 	= max(ph008d1 	== 1) // ...brain cancer diagnosed in ph008d1 across any wave
		bysort pid: egen max_brain_cancer_ph080d1 	= max(ph080d1 	== 1) // ...brain cancer diagnosed in ph080d1 across any wave

		* 	Combine the flags into a single indicator for any of the conditions
		gen flag_alzheimers 	= max_alzheimers
		gen flag_brain_cancer 	= max_brain_cancer_ph008d1 | max_brain_cancer_ph080d1

		* 	Drop all observations for individuals flagged for any of the conditions
		drop if flag_alzheimers 	== 1
		xtdes

		drop if flag_brain_cancer 	== 1
		xtdes

		* 	Drop the auxiliary variables
		drop max_alzheimers max_brain_cancer_ph008d1 max_brain_cancer_ph080d1 flag_alzheimers flag_brain_cancer

		*>> Drop highly depressed people 
		drop if high_depression == 1
		xtdes 

*>> Check the sample size 
xtdes, pattern(40)
xtdes if gender == 0, pattern(40)
xtdes if gender == 1, pattern(40)


 
* ======================================================================= * 
*	Descriptive statistics 
* ======================================================================= * 

cls

*>> Continuous variables 
sum memory_score ntests_memory_score wllft wllst
bys gender: sum memory_score ntests_memory_score wllft wllst

*>> Categorical variables 
foreach var of varlist 	/// 
ch_books 				///
ch_confined_bed 		///
ch_hospital_month 		///
ch_language 			///
ch_math 				///
ch_missed_school 		///
ch_rooms 				///
ch_srh 					///
cohort 					///
country 				///
gender 					///
lcmen 					///
lcwomen 				///
wllft					///
wllst					///
{
	// For the whole sample 
	fre `var' 
	// For men
	fre `var' if gender == 0
	// For women
	fre `var' if gender == 1
}

 

*>> Life course clusters 
cls 

* Define local macros for the variables
local variables "country cohort"

* Loop over gender codes
foreach gend of numlist 0/1 {
	
	* Define the variable name based on the gender code
	local gender `gend'
	if `gender' == 0 {
		local gvar "lcmen"
	}
	else if `gender' == 1 {
		local gvar "lcwomen"
	}
	
	* Loop over variables to tabulate against
	foreach var of local variables {
		
		* Display heading for clarity
		di "======================================="
		di "Tabulating `gvar' by `var' for gender `gender'..."
		di "======================================="
		
		* Execute tabulate command without conditions
		tabulate `gvar' `var' if gender == `gend' & `gvar' != ., missing
		di "------------------------------------------------"
		
		* Execute tabulate command with column percentages
		tabulate `gvar' `var' if gender == `gend' & `gvar' != ., col nofreq missing
		di "------------------------------------------------"
		
	}
}




* --------------------------------------------------------------------------------------------------------------------------- *
* > 
* > Regression analysis
* > 
* --------------------------------------------------------------------------------------------------------------------------- *

*>> Loop start 
foreach var of varlist memory_score {

* ======================================================================= * 
*	Macros
* ======================================================================= * 

*>> Macro for the tables 
*	Men
global savetab_men outreg2 using "$tables_out_kwaf194/`var'_men.xls", 								/// 
sideway ci noparen cttop(full) noobs noni nor2 excel label dec(3) alpha(0.001, 0.01, 0.05) 	///
addstat(N. of observations, e(N), Number of groups, e(N_g), Sigma_u, e(sigma_u), Sigma_e, e(sigma_e), Rho, e(rho))

*	Women
global savetab_women outreg2 using "$tables_out_kwaf194/`var'_women.xls", 							/// 
sideway ci noparen cttop(full) noobs noni nor2 excel label dec(3) alpha(0.001, 0.01, 0.05) 	///
addstat(N. of observations, e(N), Number of groups, e(N_g), Sigma_u, e(sigma_u), Sigma_e, e(sigma_e), Rho, e(rho))


*>> Macros for the regression models
*	Men
global 	xvarsmen 															///
		ib1.lcmen 															/// Life course clusters 
		i.cohort 															/// Time variables 
		i.ch_srh i.ch_missed_school i.ch_confined_bed i.ch_hospital_month 	/// Childhood health
		i.ch_books i.ch_rooms 												/// Childhood SES
		i.ntests_`var' 														/// Practice effects 
		i.ch_math i.ch_language 											/// Relative position to others when ten 
		i.country 															// 	Country

*	Men interaction
global 	xvarsmen_interaction 												///
		ib1.lcmen 															/// Life course clusters 
		i.cohort 															/// Time variables 
		i.ch_srh i.ch_missed_school i.ch_confined_bed i.ch_hospital_month 	/// Childhood health
		i.ch_books i.ch_rooms 												/// Childhood SES
		i.ntests_`var' 														/// Practice effects 
		i.ch_math i.ch_language 											/// Relative position to others when ten 
		i.country 															/// Country
		ib1.lcmen#i.country

*	Women
global 	xvarswomen 															///
		ib2.lcwomen 														/// Life course clusters 
		i.cohort 															/// Time variables 
		i.ch_srh i.ch_missed_school i.ch_confined_bed i.ch_hospital_month 	/// Childhood health
		i.ch_books i.ch_rooms 												/// Childhood SES
		i.ntests_`var' 														/// Practice effects 
		i.ch_math i.ch_language 											/// Relative position to others when ten 
		i.country 															// 	Country

*	Women interaction
global 	xvarswomen_interaction 												///
		ib2.lcwomen 														/// Life course clusters 
		i.cohort 															/// Time variables 
		i.ch_srh i.ch_missed_school i.ch_confined_bed i.ch_hospital_month 	/// Childhood health
		i.ch_books i.ch_rooms 												/// Childhood SES
		i.ntests_`var' 														/// Practice effects 
		i.ch_math i.ch_language 											/// Relative position to others when ten 
		i.country 															/// Country
		ib2.lcwomen#i.country



* ======================================================================= * 
*	Regression models (men)
* ======================================================================= * 

eststo clear

*>> Men (Table 4)
*	Basic model 
eststo: xtreg `var' $xvarsmen 				if gender==0, vce(robust)
$savetab_men replace 	ctitle(`var' men)

di in red "Pairwise comparisons of predictive margins:"
margins lcmen, pwcompare(effects)
margins lcmen, pwcompare(effects) mcompare(bonferroni)

di in red "Binary contrasts:"
binarycontrast lcmen

		*>> Graph the binary contrasts 
preserve

		* Get the matrix and create a temporary dataset
		matrix list r(table) // check the matrix
		matrix b = r(table)
		clear
		set obs 6
		
		* Store estimates and CI
		gen estimate = b[1,_n]
		gen min95 = b[5,_n]
		gen max95 = b[6,_n]
		
		* Create label text (must match original order)
		gen strL labeltext = ""
		local i = 1
		foreach text in `" "Partnered Fathers," "FT Work" "'     ///
						`" "Late-Partnered Fathers," "FT Work" "'  ///
						`" "Single Men," "FT Work" "'             ///
						`" "Partnered Fathers," "Weak LM attachment" "' ///
						`" "Partnered Men," "FT Work" "'          ///
						`" "Single Fathers," "FT Work" "' {
			replace labeltext = `"`text'"' in `i'
			local ++i
		}
		
		* Preserve original order for reference
		gen original_order = _n
		
		* Sort by estimate value (smallest to largest)
		gsort estimate 
		
		* Create numeric y-axis variable (1=smallest estimate)
		gen yaxis = _n
		
		* Create value labels without labmask
		label define yaxis_labels ///
			1 `"`=labeltext[1]'"' ///
			2 `"`=labeltext[2]'"' ///
			3 `"`=labeltext[3]'"' ///
			4 `"`=labeltext[4]'"' ///
			5 `"`=labeltext[5]'"' ///
			6 `"`=labeltext[6]'"'
		label values yaxis yaxis_labels
		
		* Graph with sorted coefficients
		eclplot estimate min95 max95 yaxis, ///
			xline(0) ///
			ylabel(1/6, valuelabel angle(0) labsize(small)) ///
			estopts(msymbol(D) mcolor("0 0 0") msize(medsmall) mlwidth(medthick)) ///
			ciopts(lcolor("0 0 0") lwidth(medthick)) ///
			scheme(white_ptol) ///
			ytitle("") ///
			xlabel(-1.2 -1(.2).8) ///
			xtitle("{bf:Memory score}", size(medium)) ///
			title("", size(large)) ///
			horizontal ///
			plotregion(margin(1 1 1 1))
			
restore

*	Graph save (Figure 2)
graph save 		"$figures_out_kwaf194/Fig_2_binary_contrasts_Men", replace
graph export 	"$figures_out_kwaf194/Fig_2_binary_contrasts_Men.png", as(png) replace
graph export 	"$figures_out_kwaf194/Fig_2_binary_contrasts_Men.svg", as(svg) replace

pause 

*	Interaction models
eststo: xtreg `var' $xvarsmen_interaction 	if gender==0, vce(robust)
$savetab_men 		 	ctitle(`var' men_interaction)

*	Margins
margins rb1.lcmen, over(country) atmeans contrast(nowald effects) saving($figures_out_kwaf194/mm_`var', replace)
est store mm_`var'

*	Figure 3
marginsplot, by(country) byopts(col(1) title("")) horiz recast(scatter) xline(0, lpattern(dot)) ///
	title("") xtitle("Memory score" "{bf:Men}", size()) ///
	ytitle("{bf:Life course type}", size()) ///
	ylabel(1 "{bf:Partnered father, FT Work (ref.)}" 2 "Late-Partnered Father, FT Work" 3 "Single Men, FT Work" ///
		   4 "Partnered Father, Weak LM Attachment" 5 "Partnered Men, FT Work" ///
		   6 "Single Fathers, FT Work", labsize(vsmall)) ///
	xlabel(-2.5(0.5)1.5, labsize(small)) ///
	plotregion(margin(small)) ///
	ysc(reverse) saving("$figures_out_kwaf194/mm_graph_`var'", replace) scheme(white_tableau) xline(0) ///
	plotopts(msymbol(D) mcolor("0 0 0") mlcolor("0 0 0") msize(small) mlwidth(thin)) ///
	ciopts(mcolor("0 0 0") lcolor("0 0 0"))
 

*	Graph save  
graph save 		"$figures_out_kwaf194/`var'_Men", replace
graph export 	"$figures_out_kwaf194/`var'_Men.png", as(png) replace
graph export 	"$figures_out_kwaf194/`var'_Men.svg", as(svg) replace



* ======================================================================= * 
*	Regression models (women)
* ======================================================================= * 

*>> Women (Table 5)
* Ten words list learning
eststo: xtreg `var' $xvarswomen 				if gender==1, vce(robust)
$savetab_women replace 	ctitle(`var' women)

di in red "Pairwise comparisons of predictive margins:"
margins lcwomen, pwcompare(effects)
margins lcwomen, pwcompare(effects) mcompare(bonferroni)

di in red "Binary contrasts:"
binarycontrast lcwomen


*>> Graph the binary contrasts

preserve

	* Get the matrix and create dataset
	matrix list r(table) // check matrix
	matrix b = r(table)
	clear
	set obs 9
	
	* Store estimates and CI
	gen estimate = b[1,_n]
	gen min95 = b[5,_n]
	gen max95 = b[6,_n]
	
	* Create label text (must match original order)
	gen strL labeltext = ""
	local i = 1
	foreach text in `" "Partnered Mothers," "Unpaid Caregiver" "'       ///
					`" "Partnered Mothers," "FT Work" "'                ///
					`" "Partnered Mothers," "Little (Un)paid Work" "'   ///
					`" "Single Mothers," "FT Work" "'                   ///
					`" "Single Women," "FT Work" "'                     ///
					`" "Partnered Mothers," "PT Work" "'                ///
					`" "Partnered Mothers," "Unemployed" "'             ///
					`" "Partnered Women," "Discontinued FT Work" "'     ///
					`" "Single Mothers," "PT Work" "' {
		replace labeltext = `"`text'"' in `i'
		local ++i
	}
	
	* Preserve original order for reference
	gen original_order = _n
	
	* Sort by estimate value (smallest to largest)
	gsort estimate
	
	* Create numeric y-axis variable (1=smallest estimate)
	gen yaxis = _n
	
	* Create value labels
	label define yaxis_labels ///
		1 `"`=labeltext[1]'"' ///
		2 `"`=labeltext[2]'"' ///
		3 `"`=labeltext[3]'"' ///
		4 `"`=labeltext[4]'"' ///
		5 `"`=labeltext[5]'"' ///
		6 `"`=labeltext[6]'"' ///
		7 `"`=labeltext[7]'"' ///
		8 `"`=labeltext[8]'"' ///
		9 `"`=labeltext[9]'"'
	label values yaxis yaxis_labels
	
	* Graph with sorted coefficients
	eclplot estimate min95 max95 yaxis, ///
		xline(0) ///
		ylabel(1/9, valuelabel angle(0) labsize(small)) ///
		estopts(msymbol(D) mcolor("0 0 0") msize(medsmall) mlwidth(medthick)) ///
		ciopts(lcolor("0 0 0") lwidth(medthick)) ///
		scheme(white_ptol) ///
		ytitle("") ///
		xlabel(-1.2 -1(.2).8) ///
		xtitle("{bf:Memory score}", size(medium)) ///
		title("", size(large)) ///
		horizontal ///
		plotregion(margin(1 1 1 1))
		
restore

*	Graph save (Figure 1)
graph save 		"$figures_out_kwaf194/Fig_1_binary_contrasts_Women", replace
graph export 	"$figures_out_kwaf194/Fig_1_binary_contrasts_Women.png", as(png) replace
graph export 	"$figures_out_kwaf194/Fig_1_binary_contrasts_Women.svg", as(svg) replace

pause 
 

*	Interaction models 
eststo: xtreg `var' $xvarswomen_interaction 	if gender==1, vce(robust)
$savetab_women 		 	ctitle(`var' women_interaction)

*	Margins
	*	Exclude observations specifically for unemployed women in Sweden (due to limited sample size in this subgroup) 
	*	to avoid overly wide confidence intervals in the next graph.
	eststo: xtreg `var' $xvarswomen_interaction 	if gender==1 & !(lcwomen == 7 & country == 13), vce(robust)
	margins rb2.lcwomen if e(sample), over(country) atmeans contrast(nowald effects) saving($figures_out_kwaf194/mw_`var', replace)
	est store mw_`var'

*	Figure 4
marginsplot, by(country) byopts(col(1) title("")) horiz recast(scatter) xline(0, lpattern(dot) lcolor("0 0 0")) ///
	title("") xtitle("Memory score" "{bf:Women}", size()) ///
	ytitle("", size()) ///
	ylabel(1 "Partnered Mothers, Unpaid Caregiver" 2 "{bf:Partnered Mothers, FT Work (ref.)}" 3 "Partnered Mothers, Little (Un)paid Work" ///
		   4 "Single Mothers, FT Work" 5 "Single Women, FT Work" ///
		   6 "Partnered Mothers, PT Work" 7 "Partnered Mothers, Unemployed" 8 "Partnered Women, Discontinued FT Work " ///
		   9 "Single Mothers, PT Work", labsize(vsmall)) ///
	xlabel(-2.5(0.5)1.5, labsize(small)) ///
	plotregion(margin(small)) ///
	ysc(reverse) saving("$figures_out_kwaf194/mw_graph_`var'", replace) scheme(white_tableau) xline(0) ///
	plotopts(msymbol(D) mcolor("0 0 0") mlcolor("0 0 0") msize(small) mlwidth(thin)) ///
	ciopts(mcolor("0 0 0") lcolor("0 0 0"))

*	Graph save  
graph save 		"$figures_out_kwaf194/`var'_Women", replace
graph export 	"$figures_out_kwaf194/`var'_Women.png", as(png) replace 
graph export 	"$figures_out_kwaf194/`var'_Women.svg", as(svg) replace
 

 

* ======================================================================= *
*	Combine the graphs 
* ======================================================================= *

cd "$figures_out_kwaf194"

grc1leg2 "$figures_out_kwaf194/mw_graph_`var'.gph" "$figures_out_kwaf194/mm_graph_`var'.gph" ///
, xcommon ycommon name(g1, replace) fysize(100) fxsize(200) scheme(white_ptol) graphregion(margin(zero)) plotregion(margin(zero))

gr_edit legend.draw_view.setstyle, style(no)
gr_edit plotregion1.graph1.style.editstyle margin(15 15 0 0) editcopy
gr_edit plotregion1.graph2.style.editstyle margin(0 22 0 0) editcopy
gr_edit plotregion1.graph1.Edit , style(indiv_margin(zero)) 
gr_edit plotregion1.graph2.Edit , style(indiv_margin(zero)) 
gr_edit plotregion1.graph1.style.editstyle margin(0 20 0 0) editcopy
gr_edit plotregion1.graph1.style.editstyle margin(0 20 0 0) editcopy
gr_edit plotregion1.graph2.style.editstyle margin(10 5 0 0) editcopy
gr_edit plotregion1.graph2.style.editstyle margin(10 5 0 0) editcopy
gr_edit plotregion1.graph1.style.editstyle margin(5 10 0 0) editcopy
gr_edit plotregion1.graph1.style.editstyle margin(2 13 0 0) editcopy
gr_edit plotregion1.graph1.style.editstyle margin(2 13 0 0) editcopy
gr_edit plotregion1.graph2.style.editstyle margin(7 2 0 0) editcopy
gr_edit plotregion1.graph2.style.editstyle margin(8 2 0 0) editcopy
gr_edit plotregion1.graph2.style.editstyle margin(8 2 0 0) editcopy


graph save "$figures_out_kwaf194/`var'_combined", replace
graph export "$figures_out_kwaf194/`var'_combined.png", as(png) width(2000) height(1000) replace


}






* --------------------------------------------------------------------------------------------------------------------------- *
* > 
* > Additional analyses (peer-review)
* > 
* --------------------------------------------------------------------------------------------------------------------------- *

pause 

* ======================================================================= * 
*	Cohort variables (alternative)
* ======================================================================= * 


*>> Original variable: 

	* cohort -- RECODE of yrbirth (Year of birth)
	* -----------------------------------------------------------------
	*                     |      Freq.    Percent      Valid       Cum.
	* --------------------+--------------------------------------------
	* Valid   0 <=1945    |      23834      46.45      46.45      46.45
	*         1 1946-1955 |      20595      40.14      40.14      86.58
	*         2 1956-1967 |       6884      13.42      13.42     100.00
	*         Total       |      51313     100.00     100.00           
	* -----------------------------------------------------------------


*>> New categorizations
*	(Perelli-Harris and Lyons-Amos, 2015) --> https://doi.org/10.4054/DemRes.2015.33.6
cap drop cohort_alt_1
recode yrbirth 	(1800/1944 	= 0 "<=1944") 			///
				(1945/1954  = 1 "1945-1954")		///
				(1955/1967  = 2 "1955-1967")		///
				(else 		= .), gen(cohort_alt_1)

*	(Van Winkle, 2020) --> https://doi.org/10.1007/s10680-019-09551-y
cap drop cohort_alt_2
recode yrbirth 	(1800/1942 	= 0 "<=1942") 			///
				(1943/1952  = 1 "1943-1952")		///
				(1953/1967  = 2 "1953-1967")		///
				(else 		= .), gen(cohort_alt_2)

*	(Van Winkle and Fasang, 2017) --> https://doi.org/10.1093/sf/sox032
cap drop cohort_alt_3
recode yrbirth 	(1910/1923 	= 0		"1910-1923") 	///
				(1924/1926 	= 1 	"1924-1926")	///
				(1927/1929 	= 2 	"1927-1929")	///
				(1930/1932 	= 3 	"1930-1932")	///
				(1933/1935 	= 4 	"1933-1935")	///
				(1936/1938 	= 5 	"1936-1938")	///
				(1939/1941 	= 6 	"1939-1941")	///
				(1942/1944 	= 7 	"1942-1944")	///
				(1945/1947 	= 8 	"1945-1947")	///
				(1948/1950 	= 9  	"1948-1950")	///
				(1951/1953 	= 10 	"1951-1953")	///
				(1954/1956 	= 11 	"1954-1956")	///
				(1957/1967 	= 12 	"1957-1967")	///
				(else 		= .), gen(cohort_alt_3)


* ======================================================================= * 
*	Regression analysis
* ======================================================================= *

*	Clear the folder
foreach var of varlist memory_score numeracy fluency orienti {
	cap erase "$tables_out_kwaf194/`var'_men_rev.xls"
	cap erase "$tables_out_kwaf194/`var'_men_rev.txt"
	cap erase "$tables_out_kwaf194/`var'_women_rev.txt"
	cap erase "$tables_out_kwaf194/`var'_women_rev.xls"
}


*	Define local (cohort variables)
local cohort_vars cohort cohort_alt_1 cohort_alt_2 cohort_alt_3

*	Define local (dependent variables)
local dep_vars memory_score numeracy fluency orienti

*	Loop over dependent variables
foreach var of local dep_vars {
	
	*	Clear the estimates
	eststo clear
	
	*	Create z-standardized variables
	cap drop `var'_z
	egen `var'_z = std(`var')

	*	Loop over cohort variables
	foreach cohort_var of local cohort_vars {

		*	Table for men
		eststo: xtreg `var'_z i.`cohort_var' i.lcmen i.ch_srh i.ch_missed_school i.ch_confined_bed i.ch_hospital_month ///
			i.ch_books i.ch_rooms i.ntests_`var' i.ch_math i.ch_language i.country if gender == 0 &  `var'<., vce(robust)
		outreg2 using "$tables_out_kwaf194/`var'_men_rev.xls", sideway ci noparen cttop(full) noobs noni ///
			nor2 excel label dec(3) alpha(0.001, 0.01, 0.05) addstat(N. of observations, e(N), Number of groups, e(N_g), Sigma_u, e(sigma_u), Sigma_e, e(sigma_e), Rho, e(rho)) ///
			append ctitle(`var' men, `cohort_var')
			
				binarycontrast lcmen
				pause 

		*	Interaction table for men (country)
		eststo: xtreg `var'_z i.`cohort_var' i.lcmen i.ch_srh i.ch_missed_school i.ch_confined_bed i.ch_hospital_month ///
			i.ch_books i.ch_rooms i.ntests_`var' i.ch_math i.ch_language i.country ib1.lcmen#i.country if gender == 0 &  `var'<., vce(robust)
		outreg2 using "$tables_out_kwaf194/`var'_men_rev.xls", sideway ci noparen cttop(full) noobs noni ///
			nor2 excel label dec(3) alpha(0.001, 0.01, 0.05) addstat(N. of observations, e(N), Number of groups, e(N_g), Sigma_u, e(sigma_u), Sigma_e, e(sigma_e), Rho, e(rho)) ///
			append ctitle(`var' men_interaction, `cohort_var')

		*	Interaction table for men (cohort)
		eststo: xtreg `var'_z i.`cohort_var' i.lcmen i.ch_srh i.ch_missed_school i.ch_confined_bed i.ch_hospital_month ///
			i.ch_books i.ch_rooms i.ntests_`var' i.ch_math i.ch_language i.country ib1.lcmen#i.`cohort_var' if gender == 0 &  `var'<., vce(robust)
		outreg2 using "$tables_out_kwaf194/`var'_men_rev.xls", sideway ci noparen cttop(full) noobs noni ///
			nor2 excel label dec(3) alpha(0.001, 0.01, 0.05) addstat(N. of observations, e(N), Number of groups, e(N_g), Sigma_u, e(sigma_u), Sigma_e, e(sigma_e), Rho, e(rho)) ///
			append ctitle(`var' men_interaction, `cohort_var')

		*	Table for women
		eststo: xtreg `var'_z i.`cohort_var' ib2.lcwomen i.ch_srh i.ch_missed_school i.ch_confined_bed i.ch_hospital_month ///
			i.ch_books i.ch_rooms i.ntests_`var' i.ch_math i.ch_language i.country if gender == 1 &  `var'<., vce(robust)
		outreg2 using "$tables_out_kwaf194/`var'_women_rev.xls", sideway ci noparen cttop(full) noobs noni ///
			nor2 excel label dec(3) alpha(0.001, 0.01, 0.05) addstat(N. of observations, e(N), Number of groups, e(N_g), Sigma_u, e(sigma_u), Sigma_e, e(sigma_e), Rho, e(rho)) ///
			append ctitle(`var' women, `cohort_var')

				binarycontrast lcwomen
				pause

		*	Interaction table for women (country)
		eststo: xtreg `var'_z i.`cohort_var' ib2.lcwomen i.ch_srh i.ch_missed_school i.ch_confined_bed i.ch_hospital_month ///
			i.ch_books i.ch_rooms i.ntests_`var' i.ch_math i.ch_language i.country ib2.lcwomen#i.country if gender == 1 &  `var'<., vce(robust)
		outreg2 using "$tables_out_kwaf194/`var'_women_rev.xls", sideway ci noparen cttop(full) noobs noni ///
			nor2 excel label dec(3) alpha(0.001, 0.05, 0.001) addstat(N. of observations, e(N), Number of groups, e(N_g), Sigma_u, e(sigma_u), Sigma_e, e(sigma_e), Rho, e(rho)) ///
			append ctitle(`var' women_interaction, `cohort_var')

		*	Interaction table for women (cohort)
		eststo: xtreg `var'_z i.`cohort_var' ib2.lcwomen i.ch_srh i.ch_missed_school i.ch_confined_bed i.ch_hospital_month ///
			i.ch_books i.ch_rooms i.ntests_`var' i.ch_math i.ch_language i.country ib2.lcwomen#i.`cohort_var' if gender == 1 &  `var'<., vce(robust)
		outreg2 using "$tables_out_kwaf194/`var'_women_rev.xls", sideway ci noparen cttop(full) noobs noni ///
			nor2 excel label dec(3) alpha(0.001, 0.05, 0.001) addstat(N. of observations, e(N), Number of groups, e(N_g), Sigma_u, e(sigma_u), Sigma_e, e(sigma_e), Rho, e(rho)) ///
			append ctitle(`var' women_interaction, `cohort_var')
	}
}


* --------------------------------------------------------------------------------------------------------------------------- *
* > 
* > Supplementary analyses
* > 
* --------------------------------------------------------------------------------------------------------------------------- * 


* ======================================================================= * 
*>> Time spent in each of the state between age 15 and 49
* ======================================================================= * 

/* The analyses below are done on the full sample (without excluding missing data) */

pause 


*>> Men 

*>> Open the dataset 
use "$share_all_out/SHARE_for_SA.dta", clear 

*	Drop unnecessary varibels 
drop _merge 

*>> Merge with the life course clusters 
merge m:1 mergeid using "$share_all_out/cluster_men_6.dta"

*	Sort the dataset 
sort mergeid age, stable 

*	Select only those with life histories 
keep if _merge == 3

*	Drop this variable again
drop _merge

*>> Reshape wide otherwise the "sadi" command doesn't work 
reshape wide		/// 
familystate_ 		/// 
workstate_ 			/// 
, i(mergeid) j(age)

*>> Sort the dataset 
sort gender mergeid, stable 


	*>> Employment 
		*	Order the variables 
		order 	workstate_15 workstate_16 workstate_17 workstate_18 workstate_19 workstate_20 	/// 15-20
				workstate_21 workstate_22 workstate_23 workstate_24 workstate_25 workstate_26 	/// 21-26
				workstate_27 workstate_28 workstate_29 workstate_30 workstate_31 workstate_32 	/// 27-32
				workstate_33 workstate_34 workstate_35 workstate_36 workstate_37 workstate_38 	/// 33-38
				workstate_39 workstate_40 workstate_41 workstate_42 workstate_43 workstate_44 	/// 39-44
				workstate_45 workstate_46 workstate_47 workstate_48 workstate_49 				// 	45-49

		* 	Calculate cumulated duration in states of a sequence
		cap drop y_workstate* 
		cumuldur workstate_15-workstate_49, cd(y_workstate) nstates(6)

		*	Summarize the variables
		sum y_workstate*

		*	Plot the mean of the years spent in each state
		graph 	bar y_workstate*,  by(cluster_6, 													/// 
				title(	"Mean years spent in different employment states (age 15-49)," 				/// 
						"by life course type (men)", size(small)) note("")) 						///
				legend(order (	1 "Working Full_Time (FT)" 2 "Working Part_Time (PT)" 				/// 
								3 "Unemployed" 4 "Home or Family Work" 5 "In Education" 6 "Other") 	/// 
				rows(2) size(small)) scheme(white_tableau) 
		gr_edit plotregion1.subtitle[5].style.editstyle size(small) editcopy

 

		*	Save the graph 
		graph export 	"$figures_out_kwaf194/y_workstate_men.svg", as(svg) replace

pause 

		*	Summarize the mean of the years spent in each state for each life course cluster
		foreach var of varlist y_workstate* {
			label var `var' "" // remove the variables' labels because they are too long
		}
		table cluster_6, statistic(mean y_workstate*) // Table 


	*>> Family 
		*	Order the variables 
		order 	familystate_15 familystate_16 familystate_17 familystate_18 familystate_19 familystate_20 	/// 15-20
				familystate_21 familystate_22 familystate_23 familystate_24 familystate_25 familystate_26 	/// 21-26
				familystate_27 familystate_28 familystate_29 familystate_30 familystate_31 familystate_32 	/// 27-32
				familystate_33 familystate_34 familystate_35 familystate_36 familystate_37 familystate_38 	/// 33-38
				familystate_39 familystate_40 familystate_41 familystate_42 familystate_43 familystate_44 	/// 39-44
				familystate_45 familystate_46 familystate_47 familystate_48 familystate_49 					// 	45-49

		* 	Calculate cumulated duration in states of a sequence
		cap drop y_family* 
		cumuldur familystate_15-familystate_49, cd(y_family) nstates(4)

		*	Summarize the variables
		sum y_family*

		*	Plot the mean of the years spent in each state
		graph 	bar y_family*,  by(cluster_6, 											/// 
				title(	"Mean years spent in different family states (age 15-49)," 		/// 
						"by life course type (men)", size(small)) note("")) 			///
				legend(order (	1 "No children, No partner" 2 "Children, No partner" 			/// 
								3 "No children, Partner" 4 "Children, Partner") 				/// 
				rows(1) size(small)) scheme(white_tableau) 
		gr_edit plotregion1.subtitle[5].style.editstyle size(small) editcopy

		*	Save the graph 
		graph export 	"$figures_out_kwaf194/y_familystate_men.svg", as(svg) replace

pause 

		*	Summarize the mean of the years spent in each state for each life course cluster
		foreach var of varlist y_family* {
			label var `var' "" // remove the variables' labels because they are too long
		}
		table cluster_6, statistic(mean y_family*) // Table 


*>> Median age at first partnership

	* Drop the variable if it already exists
	cap drop age_first_partner

		* Create a new variable for age at first child
		gen age_first_partner = .

		* Loop over the ages from 15 to 49
		foreach age of numlist 15(1)49 {
			* Check if familystate indicates the presence of a child
			* If familystate_`age' is either 2 or 4 (indicating the presence of a child)
			* and if age_first_partner is still missing for that individual,
			* then replace age_first_partner with the current age
			replace age_first_partner = `age' if (familystate_`age' == 3 | familystate_`age' == 4) & age_first_partner == .
		}

		*	Tabulate the median age at first childbirth by life course cluster
		bys cluster_6: sum age_first_partner, detail 
		table cluster_6, stat(mean age_first_partner) 
		table cluster_6, stat(median age_first_partner) 

pause 

*>> Median age at first childbirth

	* Drop the variable if it already exists
	cap drop age_first_child

		* Create a new variable for age at first child
		gen age_first_child = .

		* Loop over the ages from 15 to 49
		foreach age of numlist 15(1)49 {
			* Check if familystate indicates the presence of a child
			* If familystate_`age' is either 2 or 4 (indicating the presence of a child)
			* and if age_first_child is still missing for that individual,
			* then replace age_first_child with the current age
			replace age_first_child = `age' if (familystate_`age' == 2 | familystate_`age' == 4) & age_first_child == .
		}

		*	Tabulate the median age at first childbirth by life course cluster
		bys cluster_6: sum age_first_child, detail 
		table cluster_6, stat(mean age_first_child) 
		table cluster_6, stat(median age_first_child) 

pause 

*>> Median age at first job

		* Drop the variable if it already exists
		cap drop age_first_job

		* Create a new variable for age at first job
		gen age_first_job = .

		* Loop over the ages from 15 to 49
		foreach age of numlist 15(1)49 {
			* Check if workstate indicates the presence of a job
			* If workstate_`age' is either 1 or 2 (indicating full-time or part-time work)
			* and if age_first_job is still missing for that individual,
			* then replace age_first_job with the current age
			replace age_first_job = `age' if (workstate_`age' == 1 | workstate_`age' == 2) & age_first_job == .
		}

		*	Tabulate the median age at first job by life course cluster
		bys cluster_6: sum age_first_job, detail 
		table cluster_6, stat(mean age_first_job) 
		table cluster_6, stat(median age_first_job) 

pause 


*>> Women 

*>> Open the dataset 
use "$share_all_out/SHARE_for_SA.dta", clear 

*	Drop unnecessary varibels 
drop _merge 

*>> Merge with the life course clusters 
merge m:1 mergeid using "$share_all_out/cluster_women_9.dta"

*	Sort the dataset 
sort mergeid age, stable 

*	Select only those with life histories 
keep if _merge == 3

*	Drop this variable again
drop _merge

*>> Reshape wide otherwise the "sadi" command doesn't work 
reshape wide		/// 
familystate_ 			/// 
workstate_ 			/// 
, i(mergeid) j(age)

*>> Sort the dataset 
sort gender mergeid, stable 


	*>> Employment 
		*	Order the variables 
		order 	workstate_15 workstate_16 workstate_17 workstate_18 workstate_19 workstate_20 	/// 15-20
				workstate_21 workstate_22 workstate_23 workstate_24 workstate_25 workstate_26 	/// 21-26
				workstate_27 workstate_28 workstate_29 workstate_30 workstate_31 workstate_32 	/// 27-32
				workstate_33 workstate_34 workstate_35 workstate_36 workstate_37 workstate_38 	/// 33-38
				workstate_39 workstate_40 workstate_41 workstate_42 workstate_43 workstate_44 	/// 39-44
				workstate_45 workstate_46 workstate_47 workstate_48 workstate_49 				// 	45-49

		* 	Calculate cumulated duration in states of a sequence
		cap drop y_workstate* 
		cumuldur workstate_15-workstate_49, cd(y_workstate) nstates(6)

		*	Summarize the variables
		sum y_workstate*

		*	Plot the mean of the years spent in each state
		graph 	bar y_workstate*,  by(cluster_9, 													/// 
				title(	"Mean years spent in different employment states (age 15-49)," 				/// 
						"by life course type (women)", size(small)) note("")) 						///
				legend(order (	1 "Working Full_Time (FT)" 2 "Working Part_Time (PT)" 				/// 
								3 "Unemployed" 4 "Home or Family Work" 5 "In Education" 6 "Other") 	/// 
				rows(2) size(small)) scheme(white_tableau) 
		gr_edit plotregion1.subtitle[5].style.editstyle size(small) editcopy

		*	Save the graph 
		graph export 	"$figures_out_kwaf194/y_workstate_women.svg", as(svg) replace

pause 

		*	Summarize the mean of the years spent in each state for each life course cluster
		foreach var of varlist y_workstate* {
			label var `var' "" // remove the variables' labels because they are too long
		}
		table cluster_9, statistic(mean y_workstate*) // Table 


	*>> Family 
		*	Order the variables 
		order 	familystate_15 familystate_16 familystate_17 familystate_18 familystate_19 familystate_20 	/// 15-20
				familystate_21 familystate_22 familystate_23 familystate_24 familystate_25 familystate_26 	/// 21-26
				familystate_27 familystate_28 familystate_29 familystate_30 familystate_31 familystate_32 	/// 27-32
				familystate_33 familystate_34 familystate_35 familystate_36 familystate_37 familystate_38 	/// 33-38
				familystate_39 familystate_40 familystate_41 familystate_42 familystate_43 familystate_44 	/// 39-44
				familystate_45 familystate_46 familystate_47 familystate_48 familystate_49 				// 	45-49

		* 	Calculate cumulated duration in states of a sequence
		cap drop y_family* 
		cumuldur familystate_15-familystate_49, cd(y_family) nstates(4)

		*	Summarize the variables
		sum y_family*

		*	Plot the mean of the years spent in each state
		graph 	bar y_family*,  by(cluster_9, 											/// 
				title(	"Mean years spent in different family states (age 15-49)," 	/// 
						"by life course type (women)", size(small)) note("")) 			///
				legend(order (	1 "No children, No partner" 2 "Children, No partner" 			/// 
								3 "No children, Partner" 4 "Children, Partner") 				/// 
				rows(1) size(small)) scheme(white_tableau) 
		gr_edit plotregion1.subtitle[5].style.editstyle size(small) editcopy

		*	Save the graph 
		graph export 	"$figures_out_kwaf194/y_familystate_women.svg", as(svg) replace

pause 

		*	Summarize the mean of the years spent in each state for each life course cluster
		foreach var of varlist y_family* {
			label var `var' "" // remove the variables' labels because they are too long
		}
		table cluster_9, statistic(mean y_family*) // Table 1 


*>> Median age at first partnership

	* Drop the variable if it already exists
	cap drop age_first_partner

		* Create a new variable for age at first child
		gen age_first_partner = .

		* Loop over the ages from 15 to 49
		foreach age of numlist 15(1)49 {
			* Check if familystate indicates the presence of a child
			* If familystate_`age' is either 2 or 4 (indicating the presence of a child)
			* and if age_first_partner is still missing for that individual,
			* then replace age_first_partner with the current age
			replace age_first_partner = `age' if (familystate_`age' == 3 | familystate_`age' == 4) & age_first_partner == .
		}

		*	Tabulate the median age at first childbirth by life course cluster
		bys cluster_9: sum age_first_partner, detail 
		table cluster_9, stat(mean age_first_partner) 
		table cluster_9, stat(median age_first_partner) 

pause 


*>> Median age at first childbirth

	* Drop the variable if it already exists
	cap drop age_first_child

		* Create a new variable for age at first child
		gen age_first_child = .

		* Loop over the ages from 15 to 49
		foreach age of numlist 15(1)49 {
			* Check if familystate indicates the presence of a child
			* If familystate_`age' is either 2 or 4 (indicating the presence of a child)
			* and if age_first_child is still missing for that individual,
			* then replace age_first_child with the current age
			replace age_first_child = `age' if (familystate_`age' == 2 | familystate_`age' == 4) & age_first_child == .
		}

		*	Tabulate the median age at first childbirth by life course cluster
		bys cluster_9: sum age_first_child, detail 
		table cluster_9, stat(mean age_first_child) 
		table cluster_9, stat(median age_first_child) 

pause 

*>> Median age at first job

		* Drop the variable if it already exists
		cap drop age_first_job

		* Create a new variable for age at first job
		gen age_first_job = .

		* Loop over the ages from 15 to 49
		foreach age of numlist 15(1)49 {
			* Check if workstate indicates the presence of a job
			* If workstate_`age' is either 1 or 2 (indicating full-time or part-time work)
			* and if age_first_job is still missing for that individual,
			* then replace age_first_job with the current age
			replace age_first_job = `age' if (workstate_`age' == 1 | workstate_`age' == 2) & age_first_job == .
		}

		*	Tabulate the median age at first job by life course cluster
		bys cluster_9: sum age_first_job, detail 
		table cluster_9, stat(mean age_first_job) 
		table cluster_9, stat(median age_first_job) 



* ======================================================================= * 
*	Closing
* ======================================================================= * 

*>> Log file
capture log close
