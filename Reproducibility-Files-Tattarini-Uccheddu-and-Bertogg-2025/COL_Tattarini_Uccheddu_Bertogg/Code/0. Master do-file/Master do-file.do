*	Reproducibility file 
*	
*	Tattarini, Giulia, Damiano Uccheddu, and Ariane Bertogg. ‘Staying Sharp: 
*	Gendered Work–Family Life Courses and Later-Life Cognitive Functioning across 
*	Four European Welfare States’. American Journal of Epidemiology, 
*	Oxford University Press, 29 August 2025, kwaf194. 
*	https://doi.org/10.1093/aje/kwaf194.

 
*-----------------------------------------------------------------------------------------------* 
*>> Stata version, installed packages, and other settings
*-----------------------------------------------------------------------------------------------* 

*>> Preliminary operations 
cls
clear
clear matrix
set max_memory .
set logtype text
set more off

*	Debug mode 
pause on 

*	Stata version 
version 18.5 

*	Timer 
display "$S_TIME  $S_DATE"
timer clear
timer on 1

capture program drop timestamp_start
program define timestamp_start
display "$S_TIME  $S_DATE"
timer clear
timer on 1
end

capture program drop timestamp_stop
program define timestamp_stop
display "$S_TIME  $S_DATE"
timer off 1
timer list 1
end

*>> Install packages 
/* 
ssc install fre 		, replace 
ssc install iscogen		, replace  
ssc install missings	, replace 
ssc install sq			, replace
ssc install schemepack	, replace
ssc install palettes, replace
ssc install colrspace, replace
ssc install estout		, replace
ssc install outreg2		, replace
net install st0666.pkg 	, replace 
ssc install mdesc		, replace 
net install gr0002_3.pkg, from(http://www.stata-journal.com/software/sj4-3) replace // Lean mainstream schemes
net install grc1leg2.pkg, from (http://digital.cgdev.org/doc/stata/MO/Misc/) replace // grc1leg2
ssc install sadi, replace
ssc install carryforward, replace 
*/



*-----------------------------------------------------------------------------------------------* 
*>> Macro's for file save locations 
*-----------------------------------------------------------------------------------------------* 

*>> Set username macro
global username "`c(username)'"

*>> Global macro (insert here the working folder where the replication material is stored)
global working_folder 	"C:/Users/$username/Dropbox/_Projects/COL_Tattarini_Uccheddu_Bertogg/Data analysis/Reproducibility code/COL_Tattarini_Uccheddu_Bertogg/Code"
global output_folder 	"A:/Encrypted datasets/Derived/COL_Tattarini_Uccheddu_Bertogg"

*>> Dataset input (insert here the paths where the data is stored)
global share_w1_in 		"A:/Encrypted datasets/Source/SHARE/Release 9.0.0/sharew1_rel9-0-0_ALL_datasets_stata"
global share_w2_in 		"A:/Encrypted datasets/Source/SHARE/Release 9.0.0/sharew2_rel9-0-0_ALL_datasets_stata"
global share_w3_in 		"A:/Encrypted datasets/Source/SHARE/Release 9.0.0/sharew3_rel9-0-0_ALL_datasets_stata"
global share_w4_in 		"A:/Encrypted datasets/Source/SHARE/Release 9.0.0/sharew4_rel9-0-0_ALL_datasets_stata"
global share_w5_in 		"A:/Encrypted datasets/Source/SHARE/Release 9.0.0/sharew5_rel9-0-0_ALL_datasets_stata"
global share_w6_in 		"A:/Encrypted datasets/Source/SHARE/Release 9.0.0/sharew6_rel9-0-0_ALL_datasets_stata"
global share_w7_in 		"A:/Encrypted datasets/Source/SHARE/Release 9.0.0/sharew7_rel9-0-0_ALL_datasets_stata"
global share_w8_in 		"A:/Encrypted datasets/Source/SHARE/Release 9.0.0/sharew8_rel9-0-0_ALL_datasets_stata"
global share_w9_in 		"A:/Encrypted datasets/Source/SHARE/Release 9.0.0/sharew9_rel9-0-0_ALL_datasets_stata"
global JEP_in			"A:/Encrypted datasets/Source/SHARE/Release 9.0.0/sharewX_rel9-0-0_gv_job_episodes_panel_stata"

*>> Log folder
global share_logfile_common 	"C:/Users/$username/Dropbox/_Projects/COL_Tattarini_Uccheddu_Bertogg/Data analysis/Output folder - Common/Log files"
global share_logfile_kwaf194 	"C:/Users/$username/Dropbox/_Projects/COL_Tattarini_Uccheddu_Bertogg/Data analysis/Output folder - kwaf194/Log files"

*>> Other do-files
global dataset_creation 				"$working_folder/1. Dataset Creation"
global dataset_missing_JEP				"$working_folder/2.1. Data missingness fill (JEP)"
global dataset_cleaning_general			"$working_folder/2.2. Data Cleaning (General)"
global dataset_cleaning_MCSQA			"$working_folder/3. Data Cleaning (MCSQA)"
global dataset_analysis_MCSQA			"$working_folder/4.1. Data Analysis (MCSQA)"
global dataset_analysis_MCSQA_Chrono	"$working_folder/4.2. Data Analysis (Chronograms)"
global dataset_analysis_main_kwaf194	"$working_folder/4.3. Data Analysis (Main) - kwaf194"

*>> Dataset output 
global share_w1_out 	"$output_folder/w1"
global share_w2_out 	"$output_folder/w2"
global share_w3_out 	"$output_folder/w3"
global share_w4_out 	"$output_folder/w4"
global share_w5_out 	"$output_folder/w5"
global share_w6_out 	"$output_folder/w6"
global share_w7_out 	"$output_folder/w7"
global share_w8_out 	"$output_folder/w8"
global share_w9_out 	"$output_folder/w9"
global share_all_out 	"$output_folder/W_All" 	// <- Folder for the created datasets
global temp 			"$output_folder/Temp" 	// <- Folder for the temporary datasets
global JEP_out 			"$output_folder/JEP_imputed"

*>> Tables and Figures
*	Common folder 
global tables_out_common 	"C:/Users/$username/Dropbox/_Projects/COL_Tattarini_Uccheddu_Bertogg/Data analysis/Output folder - Common/Tables"
global figures_out_common 	"C:/Users/$username/Dropbox/_Projects/COL_Tattarini_Uccheddu_Bertogg/Data analysis/Output folder - Common/Figures"

*	kwaf194
global tables_out_kwaf194 	"C:/Users/$username/Dropbox/_Projects/COL_Tattarini_Uccheddu_Bertogg/Data analysis/Output folder - kwaf194/Tables"
global figures_out_kwaf194 	"C:/Users/$username/Dropbox/_Projects/COL_Tattarini_Uccheddu_Bertogg/Data analysis/Output folder - kwaf194/Figures"


*-----------------------------------------------------------------------------------------------* 
*>> Do files 
*-----------------------------------------------------------------------------------------------* 

*>> Dataset Creation
do "$dataset_creation/Dataset Creation.do"

*>> Missing imputation 
do "$dataset_missing_JEP/Data missingness fill (JEP).do"

*>> Data Cleaning
do "$dataset_cleaning_general/Data Cleaning (General).do"
do "$dataset_cleaning_MCSQA/Data Cleaning (MCSQA).do"

*>> Data analsyis 
*	Sequence and cluster analysis 
	display in red "Run the file 'Data Analysis (MCSQA).R' in R"
	pause 

*	Chronograms
do "$dataset_analysis_MCSQA_Chrono/Data Analysis (Chronograms).do"

*	Main (Regression analysis)
do "$dataset_analysis_main_kwaf194/Data Analysis (Main)"


*-----------------------------------------------------------------------------------------------* 
*>> Closing 
*-----------------------------------------------------------------------------------------------* 

*>> Timer 
display "$S_TIME  $S_DATE"
timer off 1
timer list 1

*>> Log file
capture log close
