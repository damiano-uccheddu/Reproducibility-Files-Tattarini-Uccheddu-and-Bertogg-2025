*>> Log file
capture log close 
log using "$share_logfile_common/Data Cleaning (general).log", replace


*>> Open the imputed SHARE job episodes panel dataset. 
use "$JEP_out/JEPonly_situation_impu.dta", clear 

* 	Sort the dataset
sort mergeid age* 

*	Rename the wave variable 
rename jep_w wave 

* 	Keep only useful variables 
keep 	situation_impu_re 	/// https://crowold.github.io/posts/2023/01/blogpost_jep/
		nchildren 	 		/// Having children is coded in an inclusive way, including biological, step-, and adopted children
		age_youngest 		/// The variable is missing when nchildren == 0
		withpartner	 		///
		gender				/// 
		mergeid 			/// 
		age 				///
		working_hours 		///
		wave 


*-----------------------------------------------------------------------------------------------* 
*>> Create the states: Family 
*-----------------------------------------------------------------------------------------------* 


*>> Cohabitation
rename withpartner withpartner_temp
recode withpartner_temp 		(0 	= 1 "Not Cohabiting"	)	/// 
				 				(1 	= 2 "Cohabiting"		)	/// 
				 				(else = .						), gen(withpartner)
fre withpartner


*	Family (Cohabitation + Fertility)
gen familystate_ = . 
replace familystate_ = 1 if nchildren == 0 & withpartner == 1 	// "No children, No partner"
replace familystate_ = 2 if nchildren >= 1 & withpartner == 1	// "Children, No partner"
replace familystate_ = 3 if nchildren == 0 & withpartner == 2	// "No children, Partner"
replace familystate_ = 4 if nchildren >= 1 & withpartner == 2	// "Children, Partner"

* 	Attribute the Labels
label define lab_family			///
   1 "No children, No partner"     	/// 
   2 "Children, No partner"     	/// 
   3 "No children, Partner"     	/// 
   4 "Children, Partner"  

label values familystate_ lab_family

* 	Check the new and the old variables 
tab familystate_ withpartner, miss
tab nchildren familystate_, miss


*-----------------------------------------------------------------------------------------------* 
*>> Create the states: Employment
*-----------------------------------------------------------------------------------------------* 


*>> Employment
fre situation_impu_re 
recode situation_impu_re	(1 4 								= 0 "Employed or Self_Employed") 	/// 
							(2 3 								= 3 "Unemployed") 					/// 
							(6 									= 4 "Home or family work") 			/// 
							(9 10 								= 5 "In education or training")  	/// 
							(5 7 8 11 12 13 14 15 16 17 97 		= 6 "Other")						/// 
																									///
							/// "Other" category:
							/// 
							/// Sick or disabled ; Leisure, travelling or doing nothing ; 
							/// Retired from work ; Military services, war prisoner or equivalent ; 
							/// Managing your assets ; Voluntary or community work ; 
							/// Forced labour or in jail ; Exiled or banished ; 
							/// Labor camp ; Concentration camp ; Other
							(else = . ), gen(workstate_)


* 	Check the new and the old variable 
tab situation_impu_re workstate_, miss 
tab situation_impu_re workstate_, miss col nofre

*>> Full_Time and Part_Time 
replace workstate_ = 1 if working_hours == 1 & workstate_ == 0 // Always Full_Time
replace workstate_ = 2 if working_hours == 2 & workstate_ == 0 // Always Part_Time

tab situation_impu_re workstate_, miss 

capture lab drop workstate_lab
label define workstate_lab 					/// 
0 "Employed (but missing working hours)" 	/// 
1 "Working Full_Time (FT)"					/// 
2 "Working Part_Time (PT)"					/// 
3 "Unemployed" 								/// 
4 "Home or Family Work" 					/// 
5 "In Education"			  				/// 
6 "Other" 
label values workstate_ workstate_lab
lab var workstate_ "Work situation"

// list mergeid workstate_ working_hours age, sepby(mergeid) 
// browse if mergeid=="Ih-318213-01" // check at age 24 & 25

*>> Replace if changes in working hours 
*	In case of "Changed once from Full_Time to Part_Time", Full_Time is assigned before the change to Part_Time 
bys mergeid: replace 	workstate_ 			=  1 	/// Working Full_Time 
if 						working_hours 		== 3 	/// Changed once from Full_Time to Part_Time
& 						workstate_ 			== 0 	/// Employed (but missing working hours) 
& 						workstate_[_n-1] 	== 1 	//  Working Full_Time at time t-1

*	In case of "Changed once from Part_Time to Full_Time", Part_Time is assigned before the change to Part_Time 
bys mergeid: replace 	workstate_ 			=  2 	/// Working Part_Time
if 						working_hours 		== 4 	/// Changed once from Part_Time to Full_Time
& 						workstate_ 			== 0 	/// Employed (but missing working hours) 
& 						workstate_[_n-1] 	== 2 	//  Working Part_Time at time t-1

* Check 
// browse if mergeid=="Ih-318213-01" // check at age 24 & 25

*>> Replace when multiple changes in working hours 
*	In case of "multiple changes" Full_Time is assumed before the change to Part_Time and Part_Time thereafter
bys mergeid: replace 	workstate_ 			=  1 	/// Working Full_Time 
if 						working_hours 		== 5 	/// Changed once from Full_Time to Part_Time
& 						workstate_ 			== 0 	/// Employed (but missing working hours) 
& 						workstate_[_n-1] 	== 1 	//  Working Full_Time at time t-1

*	In case of "multiple changes" Part_Time is assumed before the change to Full_Time and Full_Time thereafter
bys mergeid: replace 	workstate_ 			=  2 	/// Working Part_Time
if 						working_hours 		== 5 	/// Changed once from Part_Time to Full_Time
& 						workstate_ 			== 0 	/// Employed (but missing working hours) 
& 						workstate_[_n-1] 	== 2 	//  Working Part_Time at time t-1



* 	Check the new and the old variable 
tab situation_impu_re workstate_, miss 
tab situation_impu_re workstate_, miss col nofre

// 		tab situation_impu_re workstate_, miss 
// 		
// 		                      |              RECODE of situation_impu_re (Situation)
// 		            Situation | Employed   Unemploye  Home or f  In educat      Other          . |     Total
// 		----------------------+------------------------------------------------------------------+----------
// 		              Refusal |         0          0          0          0          0        116 |       116 
// 		           Don't know |         0          0          0          0          0        435 |       435 
// 		Employee or self-empl | 2,967,652          0          0          0          0          0 | 2,967,652 
// 		Unemployed and search |         0     49,829          0          0          0          0 |    49,829 
// 		Unemployed but not se |         0     41,258          0          0          0          0 |    41,258 
// 		Short term job (less  |     4,582          0          0          0          0          0 |     4,582 
// 		     Sick or disabled |         0          0          0          0     47,730          0 |    47,730 
// 		Looking after home or |         0          0    540,437          0          0          0 |   540,437 
// 		Leisure, travelling o |         0          0          0          0      6,376          0 |     6,376 
// 		    Retired from work |         0          0          0          0    784,503          0 |   784,503 
// 		             Training |         0          0          0      6,364          0          0 |     6,364 
// 		         In education |         0          0          0  1,148,065          0          0 | 1,148,065 
// 		Military services, wa |         0          0          0          0     14,793          0 |    14,793 
// 		 Managing your assets |         0          0          0          0      2,900          0 |     2,900 
// 		Voluntary or communit |         0          0          0          0      5,165          0 |     5,165 
// 		Forced labour or in j |         0          0          0          0        733          0 |       733 
// 		   Exiled or banished |         0          0          0          0        419          0 |       419 
// 		           Labor camp |         0          0          0          0        342          0 |       342 
// 		   Concentration camp |         0          0          0          0        153          0 |       153 
// 		                Other |         0          0          0          0     43,446          0 |    43,446 
// 		                    . |         0          0          0          0          0    500,722 |   500,722 
// 		----------------------+------------------------------------------------------------------+----------
// 		                Total | 2,972,234     91,087    540,437  1,154,429    906,560    501,273 | 6,166,020 
// 		
// 		
// 		tab situation_impu_re workstate_, miss col nofre
// 		
// 		                      |              RECODE of situation_impu_re (Situation)
// 		            Situation | Employed   Unemploye  Home or f  In educat      Other          . |     Total
// 		----------------------+------------------------------------------------------------------+----------
// 		              Refusal |      0.00       0.00       0.00       0.00       0.00       0.02 |      0.00 
// 		           Don't know |      0.00       0.00       0.00       0.00       0.00       0.09 |      0.01 
// 		Employee or self-empl |     99.85       0.00       0.00       0.00       0.00       0.00 |     48.13 
// 		Unemployed and search |      0.00      54.70       0.00       0.00       0.00       0.00 |      0.81 
// 		Unemployed but not se |      0.00      45.30       0.00       0.00       0.00       0.00 |      0.67 
// 		Short term job (less  |      0.15       0.00       0.00       0.00       0.00       0.00 |      0.07 
// 		     Sick or disabled |      0.00       0.00       0.00       0.00       5.26       0.00 |      0.77 
// 		Looking after home or |      0.00       0.00     100.00       0.00       0.00       0.00 |      8.76 
// 		Leisure, travelling o |      0.00       0.00       0.00       0.00       0.70       0.00 |      0.10 
// 		    Retired from work |      0.00       0.00       0.00       0.00      86.54       0.00 |     12.72 
// 		             Training |      0.00       0.00       0.00       0.55       0.00       0.00 |      0.10 
// 		         In education |      0.00       0.00       0.00      99.45       0.00       0.00 |     18.62 
// 		Military services, wa |      0.00       0.00       0.00       0.00       1.63       0.00 |      0.24 
// 		 Managing your assets |      0.00       0.00       0.00       0.00       0.32       0.00 |      0.05 
// 		Voluntary or communit |      0.00       0.00       0.00       0.00       0.57       0.00 |      0.08 
// 		Forced labour or in j |      0.00       0.00       0.00       0.00       0.08       0.00 |      0.01 
// 		   Exiled or banished |      0.00       0.00       0.00       0.00       0.05       0.00 |      0.01 
// 		           Labor camp |      0.00       0.00       0.00       0.00       0.04       0.00 |      0.01 
// 		   Concentration camp |      0.00       0.00       0.00       0.00       0.02       0.00 |      0.00 
// 		                Other |      0.00       0.00       0.00       0.00       4.79       0.00 |      0.70 
// 		                    . |      0.00       0.00       0.00       0.00       0.00      99.89 |      8.12 
// 		----------------------+------------------------------------------------------------------+----------
// 		                Total |    100.00     100.00     100.00     100.00     100.00     100.00 |    100.00 


*-----------------------------------------------------------------------------------------------* 
*>> Reshape wide 
*-----------------------------------------------------------------------------------------------* 

* 	Drop the variables we don't need anymore
drop withpartner_temp 
drop situation_impu_re
drop working_hours
drop nchildren
drop age_youngest
drop withpartner

*>> Reshape wide (this is necessary for the 1:1 merge and also the sequence analysis)
reshape wide 			///
workstate_@ 			/// 
familystate_@ 				/// 
, i(mergeid) j(age)

*>> Sort the dataset 
sort mergeid

 

*-----------------------------------------------------------------------------------------------* 
*>> Merge with other (health and other) data from SHARE 
*-----------------------------------------------------------------------------------------------* 

*>> Merge the job episodes panel with those participating in wave 3 and 7 
merge 1:m mergeid wave using "$share_all_out/SHARE_w1_w9_panel.dta"

*>> Keep only those participating in wave 3 and 7 
keep if _merge==3

*>> Original sample 
fre gender 			
fre country 		
tab country wave 	
					

*-----------------------------------------------------------------------------------------------*
* Standardization of Sequences 
*-----------------------------------------------------------------------------------------------* 

*>> Reshape in long format 
reshape long 

*>> Sort again 
sort mergeid

*>> Generate an id variable which counts the number of years of age of the individuals 
bys mergeid: gen nr=_n

*>> Compare old and new variable 
compare nr age
fre nr age

*-----------------------------------------------------------------------------------------------* 
*>> Upper bound 
*-----------------------------------------------------------------------------------------------* 

keep if nr<=50 		& workstate_ !=. & familystate_ !=. 
// list mergeid gender situation_impu_re nchildren married age nr, sepby(mergeid)

egen nrmax=max(nr), by(mergeid)  
// list mergeid gender situation_impu_re nchildren married age nr nrmax, sepby(mergeid)
// ta nrmax

keep if nrmax==50 	& workstate_ !=. & familystate_ !=. 
// list mergeid gender situation_impu_re nchildren married age nr nrmax, sepby(mergeid)

*-----------------------------------------------------------------------------------------------* 
*>> Lower bound
*-----------------------------------------------------------------------------------------------* 

*>> Delete the first artificial year  
drop if nr == 1 
replace age = age-1

keep if age>14
// list mergeid gender situation_impu_re nchildren married age nr nrmax, sepby(mergeid)



*-----------------------------------------------------------------------------------------------* 
*>> Drop the missing cases 
*-----------------------------------------------------------------------------------------------* 

*>> Fertility <<*  

* 	I drop the cases in which we don't have information on the fertility histories 
egen npositive = total(familystate_ > 0 & familystate_ < .), by(mergeid)
// list mergeid gender situation_impu_re nchildren married age nr npositive, sepby(mergeid)
 
keep if npositive == 35 // 15+35=50
// list mergeid gender situation_impu_re nchildren married age nr npositive, sepby(mergeid)

drop npositive


*>> Employment <<* 

*>> I drop the cases in which we don't have information on the employment histories 
egen npositive = total(workstate_ > 0 & workstate_ < .), by(mergeid)
// list mergeid gender situation_impu_re nchildren married age nr npositive, sepby(mergeid)

keep if npositive == 35 // 15+35=50
// list mergeid gender situation_impu_re nchildren married age nr npositive, sepby(mergeid)

drop npositive


*>> Drop variables that are all missing 
missings dropvars, force // (Stata Journal, volume 8, number 4: dm89_1) --> here using dm89_2



*-----------------------------------------------------------------------------------------------* 
*>> Other 
*-----------------------------------------------------------------------------------------------* 

*>> Compress the dataset
compress

*>> Remove any notes
notes drop _dta

*>> Describe 
desc, short 


*>> Drop superfluous variables 
drop nr


 
*-----------------------------------------------------------------------------------------------* 
*>> Save the dataset 
*-----------------------------------------------------------------------------------------------* 

*>> Save the dataset
save "$share_all_out/SHARE_for_SA.dta", replace

*>> Close the log file
log close
