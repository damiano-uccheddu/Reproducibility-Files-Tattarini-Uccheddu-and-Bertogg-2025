
* ------------------------------------------------------------------------------------------------ *
* > 
* > The code below is based on the do-file by Carla Rowold: 
* > https://crowold.github.io/files/2023-01-25-blogpost_jep/fill_missings_JEP_2301.do
* > 
* > Webpage archived here: 
* > https://web.archive.org/web/20250811145917/https://crowold.github.io/files/2023-01-25-blogpost_jep/fill_missings_JEP_2301.do 
* > 	
* > Unlike the original code, this code is adapted for the Job Episodes Panel Release 8.0.0 (instead of the original 7.1.0)
* > 	
* > Additionally, I have modified rows 47 (formerly 18) and 64 (formerly 35) to accommodate the new paths, and added row 25 (log file). 
* > 
* > 	I sincerely thank Carla Rowold for identifying this issue in the SHARE dataset, for her valuable contribution, 
* > 	and for generously sharing the code with the scientific community. Any remaining shortcomings and mistakes, 
* > 	of course, remain my responsibility. 
* > 
* > 	Damiano Uccheddu
* > 
* ------------------------------------------------------------------------------------------------ * 



*>> Log file 
log using "$share_logfile_common/Data missingness fill (JEP).log", replace


/* Code to fill missings on situation var in Job Episode Panel based on variables re035, re039a etc
	- based on the Jep Episodes Panel Release 7.1.0 (i.e. combining waved 3 and 7)
	- person-year spell format
	- only filling missing information on situation for years after the year of the last job
	- 23/10/2022, Carla Rowold */

	
	*first set directory 
		*global datapath_w3 "yourpath\Release 7.1.0\sharew3_rel7-1-0_ALL_datasets_stata" // wave 3 (SHARElife)
		*global datapath_w7 "yourpath\Release 7.1.0\sharew7_rel7-1-1_ALL_datasets_stata" // wave 7 (mostly SHARElife)
		*global datapath_jep "yourpath\Release 7.1.0\sharewX_rel7-1-0_gv_job_episodes_panel_stata" // job_episodes_panel
		*global temp "yourpath\temps"

	
*************************
	*1. count missings	on sitation var 
				*************************		
	use "$JEP_in/sharewX_rel9-0-0_gv_job_episodes_panel.dta", clear // --> (!) This row has been modified to accomodate the new path
				
		bys mergeid: egen countnonmiss_sit= count(situation)
			label var countnonmiss_sit "Number of nonmissing observations on situation var per respondent before imputation"
		bys mergeid: egen years_observed= count(age)
			label var years_observed "Year observed per respondent"
		gen countmiss_sit=years_observed-countnonmiss_sit
			label var countmiss_sit "Number of missing observations on situation var per respondent before imputation"

	save "$temp/imputation_temp", replace	
	
	
*************************
	*2. merge raw retrospective data
						*************************		
	
	*rename variables in wave 7 so that variable names of waves 3 and 7 are identical
		use "$share_w3_in/sharew3_rel9-0-0_re", clear // --> (!) This row has been modified to accomodate the new path
		 rename sl_* * //remove prefix 
				
		save "$share_w3_out/sharew3_rel9-0-0_re_renamed", replace
	
	use "$temp/imputation_temp", clear	
	merge m:1 mergeid using "$share_w3_out/sharew3_rel9-0-0_re_renamed", generate (_merge_sharelifew3) keep(match master)
	merge m:1 mergeid using "$share_w7_in/sharew7_rel9-0-0_re", generate (_merge_sharelifew7) update keep(master 3 4 5) keepusing(re*) 
				
				
*****************				
	*3. IMPUTATION 
			*****************			
		/* - based on the raw retrospective data and especially information on what done after last job
			- I impute spells that are missing on situation var and that occur in the years after the last reported job (re035)
			- Spells are filled until there are no missings anymore or until the situation changed again (re039a)
			- If the situation changed, the same procedure is done for the nth situation after the last job nth times
			- new situation var: situation_impu_re
			*/
					
				
	*gen highest year of end of job (i.e. year when last job ends) -> only filling missings after last job ended
			cap drop lastjob_end
			foreach x of numlist 1/20{
				replace re026_`x'=. if re026_`x'== 9997 | re026_`x'<0 //missings on .
				}
			egen lastjob_end=rowmax(re026_*)
			egen lastpaidjob_confirmed=rowmax(re032_*)
				label var lastjob_end "Year the last reported job ended (max value of 032)"
				label var lastpaidjob_confirmed "Max value of 032, eg ever stated that one of the jobs was the last"
				replace lastjob_end=.a if lastjob_end<0 // put on missing if always missing value on what happened in gap after leaving the job 
			
			
	* mark these with missing situation for years later than year of last job -> these years can be filled
			sort mergeid age
			cap drop n1
			bys mergeid: gen n1=_n if year>lastjob_end & situation==.
					
	*key variables for filling the missings	
		*situation in after last job
			tab re035_1 if n1!=., mi
			tab re035_2 if n1!=., mi
		*situation1 changed after last job
			tab re039_1, mi
		*year changing situation after last job				
			tab re039a_1  if n1!=., mi
			tab re039a_2 if n1!=., mi
			foreach x of numlist 1/10{
					replace re039a_`x'=. if re039a_`x'<0 //missings on .
				}
			
	* replace marker which years can be filled (n) =. from year on from which situation changes again
		* for first change in situation
		replace n1=.a if year>=re039a_1 & re039a_1!=. & n1!=. // -> fill up the situation after last job until it changes again
	
	
	***************************************************************
	*3.1 IMPUTATION 1: impute those missing values for which the first situation after job didnt change or until it changed
														***************************************************************

		clonevar situation_impu_re = situation	//clone original situation var
		gen flag_impu_situation_re=1 if n1!=. & n1!=.a & situation_impu_re==.
		replace situation_impu_re=re035_1 if n1!=. & n1!=.a & situation_impu_re==. 
		tab situation_impu_re if n1!=. & n1!=.a
		tab situation if n1!=. & n1!=.a, mi
		
	***************************************************************		
	*3.2 IMPUTATION 2: impute those for which the nth (from second) situation after job didnt change or until it changed		
			* mark these with missing situation for years larger or equal the year of changing the previous situation after last job AND after the year of the last job
														***************************************************************
			
		foreach x of numlist 1/10{
				global y= `x'-1
				dis $y
				}

		foreach x of numlist 2/10{
				global y= `x'-1
				dis $y
				sort mergeid age
				cap drop n`x'
				bys mergeid: gen n`x'=_n if year>=re039a_$y & year>lastjob_end & situation_impu_re==.  & n$y==.a // tracker missings for years larger or equal the year of changing the previous situation after last job
				replace n`x'=.a if year>=re039a_`x' & re039a_`x'!=. & n`x'!=. //replace n =. from year on from which situation changes again
				replace flag_impu_situation_re=`x' if n`x'!=. & n`x'!=.a & situation_impu_re==. // flag for which of the nth imputations
				replace situation_impu_re=re035_`x' if n`x'!=. & n`x'!=.a & situation_impu_re==. //filling missings/ imputations from year the situation changed up to last missing or until the situation changed again
			}

					
*****************				
		*4. Check outcome
				*****************					
			tab situation_impu_re
			tab situation_impu_re if age >15, mi
				
					
		* some flags
			label var flag_impu_situation_re "Tracks whether this spell was filled by what resp. did after last job"
		
			cap drop n_imputations
			egen flag_filling= diff(situation situation_impu_re)
					label var flag_filling "Tracks whether this spell was filled by what resp. did after last job"

			bys mergeid: egen n_imputations= total(flag_filling)
				tab n_imputations
					label var n_imputations "Number of imputations/fillings of the situation var"
		
			
*****************				
		*5. Further checks related variables
				*****************			
		***
		*1. Working or retirement dummies X imputed situation var?
			tab unemployed situation_impu_re if situation==., mi // unemployment variable should be updated too ~ 30,000 spells
			tab retired situation_impu_re if situation==., mi // retired variable should be updated too
			
		*drop all raw data and techniqual variables
			drop re* _merge_sharelifew7 n1 n2 n3 n4 n5 n6 n7 n8 n9 n10
			
		save "$JEP_out/JEPonly_situation_impu.dta", replace
	
	
	
			
				
		
		
		
		
