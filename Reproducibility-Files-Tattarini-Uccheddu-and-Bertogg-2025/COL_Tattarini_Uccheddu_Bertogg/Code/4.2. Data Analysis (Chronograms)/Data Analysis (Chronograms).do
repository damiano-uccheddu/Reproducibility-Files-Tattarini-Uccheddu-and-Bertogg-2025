*-----------------------------------------------------------------------------------------------* 
*>> Preliminary operations 
*-----------------------------------------------------------------------------------------------* 

cls

*>> Log 
capture log close 
log using "$share_logfile_common/Data Analysis (Chronograms).log", replace

* ======================================================================= * 
*	Color palette for colorblindness 
* ======================================================================= * 
/* 
cap program drop colorpalette_ColorBlindAdj
program colorpalette_ColorBlindAdj
syntax [, n(str) ] // n() not used
c_local P #000000, #ffb6db, #006ddb, #b66dff, #6db6ff, #920000, #FF8247, #24ff24, #ffff6d, #b6dbff,
c_local N cb_black, cb_light_pink, cb_blue, cb_purple, cb_light_blue, cb_dark_red, cb_orange, cb_bright_green, cb_yellow, cb_sky_blue,
c_local class qualitative
end


*>> Check 
colorpalette ColorBlindAdj, rows(6)
colorcheck
colorpalette ColorBlindAdj, nograph
return list
 */

************************************************************************************************* 
* Chronograms for Men                                                                           * 
************************************************************************************************* 

*>> How many clusters for men? 
global number "6" // set a macro 
global clnum "1 2 3 4 5 6" // 6 7 8 9 10 11 12 13 14 15

*-----------------------------------------------------------------------------------------------* 
*>> Family
*-----------------------------------------------------------------------------------------------* 

*>> Start a loop 
foreach number in $number {
	foreach clnum in $clnum {

*	Open the dataset with the family histories and merge 
use "$share_all_out/cluster_men_`number'.dta", clear 
merge 1:1 mergeid using "$share_all_out/SHARE_for_SA_Men_Family.dta", nogen

*	Generate random uniform numbers
set seed 732511691
generate ord=runiform()

*	Keep only the cluster of interest
keep if cluster_`number' == `clnum'

*>> Sequence index plots
*	Reshape long 
reshape long familystate_@, i(mergeid) j(year)

*>> We have some clusters where we don't have a specific state (e.g., "Children, No partner"); this causes problems with the colors of the graphs
*	Temporary alignment (especially if the clusters are small)
gen double rand = runiform()
sort rand

forvalues i = 1/4 { // from 1 to 4 because the family variable has 4 category
	replace familystate_ = `i' in `i'
}

drop rand

*	Produce the sequence index plot 
sqset familystate_ mergeid year
sqindexplot, rbar gapinclude 		///
color() 							/// 
	order(ord) 						///
	fysize(100) 					///
	ytitle("Cluster `clnum'") 		///
	xlab(15 20 25 30 35 40 45 49, labsize(vsmall)) xtitle("Age (15-49 years)", size(vsmall)) 		/// 
	scheme(c_blind_family) legend(size(medlarge) row(2)) name("m_sqindex_cb_fam_`clnum'", replace) overplot(40)
 
*	Save the graph
graph save "$figures_out_common/sqindexplot_men_fert_`clnum'", replace

*>> Produce the chronogram 
sqpercentageplot, 	 					///
baropts(color()) 	/// 
	fysize(100) 						///
	ytitle("Cluster `clnum'") 			///
	xlab(15 20 25 30 35 40 45 49, labsize(vsmall)) xtitle("Age (15-49 years)") 		/// 
		ylab(				/// 
		0 	"0%" 			/// 
		25 	"25%"			/// 
		50 	"50%"			/// 
		75 	"75%" 			/// 
		100 "100%"			/// 
		, labsize(vsmall)) 	/// 
	scheme(c_blind_family_reversed) legend(size(medlarge) row(2)) name("m_chrono_cb_fam_rvs_`clnum'", replace) 
	gr_edit xaxis1.title.style.editstyle size(vsmall) editcopy

*	Save the graph
graph save "$figures_out_common/chrono_men_fert_`clnum'", replace

	}
}

*-----------------------------------------------------------------------------------------------* 
*>> Employment
*-----------------------------------------------------------------------------------------------* 

*>> Start a loop 
foreach number in $number {
	foreach clnum in $clnum {

*	Open the dataset with the family histories and merge 
use "$share_all_out/cluster_men_`number'.dta", clear 
merge 1:1 mergeid using "$share_all_out/SHARE_for_SA_Men_Employment.dta", nogen

*	Generate random uniform numbers
set seed 732511691
generate ord=runiform()

*	Keep only the cluster of interest
keep if cluster_`number' == `clnum'

*>> Sequence index plots
*	Reshape long 
reshape long workstate_@, i(mergeid) j(year)

*>> We have some clusters where we don't have a specific state (e.g., "Children, No partner"); this causes problems with the colors of the graphs
*	Temporary alignment
gen double rand = runiform()
sort rand

forvalues i = 1/6 { // from 1 to 6 because the workstate variable has 6 categories
	replace workstate_ = `i' in `i'
}

drop rand

*	Produce the sequence index plot 
sqset workstate_ mergeid year
sqindexplot, rbar gapinclude 										///
color() 		/// 
	order(ord) 						///
	fysize(100) 					///
	ytitle("Cluster `clnum'") ///
	xlab(15 20 25 30 35 40 45 49, labsize(vsmall)) xtitle("Age (15-49 years)", size(vsmall)) 		/// 
	scheme(c_blind_employment) legend(size(medlarge) row(2)) name("m_sqindex_cb_emp_`clnum'", replace) overplot(40)
 
*	Save the graph
graph save "$figures_out_common/sqindexplot_men_emp_`clnum'", replace

*>> Produce the chronogram 
sqpercentageplot, 	 										///
baropts(color()) 	/// 
	fysize(100) 						///
	ytitle("Cluster `clnum'") 			///
	xlab(15 20 25 30 35 40 45 49, labsize(vsmall)) xtitle("Age (15-49 years)") 		/// 
		ylab(				/// 
		0 	"0%" 			/// 
		25 	"25%"			/// 
		50 	"50%"			/// 
		75 	"75%" 			/// 
		100 "100%"			/// 
		, labsize(vsmall)) 	/// 
	scheme(c_blind_employment_reversed) legend(size(medlarge) row(2)) name("m_chrono_cb_emp_rvs_`clnum'", replace) 
	gr_edit xaxis1.title.style.editstyle size(vsmall) editcopy

*	Save the graph
graph save "$figures_out_common/chrono_men_emp_`clnum'", replace

	}
}



************************************************************************************************* 
* Chronograms for Women                                                                         * 
************************************************************************************************* 

*>> How many clusters for women? 
global number "9" // set a macro 
global clnum "1 2 3 4 5 6 7 8 9" // 9 10 11 12 13 14 15

*-----------------------------------------------------------------------------------------------* 
*>> Family
*-----------------------------------------------------------------------------------------------* 

*>> Start a loop 
foreach number in $number {
	foreach clnum in $clnum {

*	Open the dataset with the family histories and merge 
use "$share_all_out/cluster_women_`number'.dta", clear 
merge 1:1 mergeid using "$share_all_out/SHARE_for_SA_women_Family.dta", nogen

*	Generate random uniform numbers
set seed 732511691
generate ord=runiform()

*	Keep only the cluster of interest
keep if cluster_`number' == `clnum'

*>> Sequence index plots
*	Reshape long 
reshape long familystate_@, i(mergeid) j(year)

*>> We have some clusters where we don't have a specific state (e.g., "Children, No partner"); this causes problems with the colors of the graphs
*	Temporary alignment (especially if the clusters are small)
gen double rand = runiform()
sort rand

forvalues i = 1/4 { // from 1 to 4 because the family variable has 4 category
	replace familystate_ = `i' in `i'
}

drop rand

*	Produce the sequence index plot 
sqset familystate_ mergeid year
sqindexplot, rbar gapinclude 					///
color() 		/// 
	order(ord) 						///
	fysize(100) 					///
	ytitle("Cluster `clnum'") ///
	xlab(15 20 25 30 35 40 45 49, labsize(vsmall)) xtitle("Age (15-49 years)", size(vsmall)) 		/// 
	scheme(c_blind_family) legend(size(medlarge) row(2)) name("w_sqindex_cb_fam_`clnum'", replace) overplot(40)

*	Save the graph
graph save "$figures_out_common/sqindexplot_women_fert_`clnum'", replace

*>> Produce the chronogram 
sqpercentageplot, 	 					///
baropts(color()) 	/// 
	fysize(100) 						///
	ytitle("Cluster `clnum'") 			///
	xlab(15 20 25 30 35 40 45 49, labsize(vsmall)) xtitle("Age (15-49 years)") 		/// 
		ylab(				/// 
		0 	"0%" 			/// 
		25 	"25%"			/// 
		50 	"50%"			/// 
		75 	"75%" 			/// 
		100 "100%"			/// 
		, labsize(vsmall)) 	/// 
	scheme(c_blind_family_reversed) legend(size(medlarge) row(2)) name("w_chrono_cb_fam_rvs_`clnum'", replace) 
	gr_edit xaxis1.title.style.editstyle size(vsmall) editcopy

*	Save the graph
graph save "$figures_out_common/chrono_women_fert_`clnum'", replace

	}
}

*-----------------------------------------------------------------------------------------------* 
*>> Employment
*-----------------------------------------------------------------------------------------------* 

*>> Start a loop 
foreach number in $number {
	foreach clnum in $clnum {

*	Open the dataset with the family histories and merge 
use "$share_all_out/cluster_women_`number'.dta", clear 
merge 1:1 mergeid using "$share_all_out/SHARE_for_SA_women_Employment.dta", nogen

*	Generate random uniform numbers
set seed 732511691
generate ord=runiform()

*	Keep only the cluster of interest
keep if cluster_`number' == `clnum'

*>> Sequence index plots
*	Reshape long 
reshape long workstate_@, i(mergeid) j(year)

*>> We have some clusters where we don't have a specific state (e.g., "Children, No partner"); this causes problems with the colors of the graphs
*	Temporary alignment
gen double rand = runiform()
sort rand

forvalues i = 1/6 { // from 1 to 6 because the workstate variable has 6 categories
	replace workstate_ = `i' in `i'
}

drop rand


*	Produce the sequence index plot 
sqset workstate_ mergeid year
sqindexplot, rbar gapinclude 										///
color() 		/// 	
	order(ord) 						///
	fysize(100) 					///
	ytitle("Cluster `clnum'") ///
	xlab(15 20 25 30 35 40 45 49, labsize(vsmall)) xtitle("Age (15-49 years)", size(vsmall)) 		/// 
	scheme(c_blind_employment) legend(size(medlarge) row(2)) name("w_sqindex_cb_emp_`clnum'", replace) overplot(40)

*	Save the graph
graph save "$figures_out_common/sqindexplot_women_emp_`clnum'", replace

*>> Produce the chronogram 
sqpercentageplot, 	 										///
baropts(color()) 	/// 
	fysize(100) 						///
	ytitle("Cluster `clnum'") 			///
	xlab(15 20 25 30 35 40 45 49, labsize(vsmall)) xtitle("Age (15-49 years)") 		/// 
		ylab(				/// 
		0 	"0%" 			/// 
		25 	"25%"			/// 
		50 	"50%"			/// 
		75 	"75%" 			/// 
		100 "100%"			/// 
		, labsize(vsmall)) 	/// 
	scheme(c_blind_employment_reversed) legend(size(medlarge) row(2)) name("w_chrono_cb_emp_rvs_`clnum'", replace) 
	gr_edit xaxis1.title.style.editstyle size(vsmall) editcopy

*	Save the graph
graph save "$figures_out_common/chrono_women_emp_`clnum'", replace

	}
}




* ======================================================================= * 
*	Graph combine 
* ======================================================================= * 

*>> Men 
*	Part 1
	*	Combine multiple graphs for men's employment data into a single graph
	grc1leg2 										///
			"$figures_out_common/chrono_men_emp_1" 			///
			"$figures_out_common/sqindexplot_men_emp_1" 	///
			"$figures_out_common/chrono_men_emp_2" 			///
			"$figures_out_common/sqindexplot_men_emp_2" 	///
			"$figures_out_common/chrono_men_emp_3" 			///
			"$figures_out_common/sqindexplot_men_emp_3" 	///
	, col(2) name(men_emp_part_1, replace) title(Employment)  legendfrom("$figures_out_common/sqindexplot_men_emp_1")
 
	*	Combine multiple graphs for men's family data into a single graph
	grc1leg2 ///
			"$figures_out_common/chrono_men_fert_1" 		///
			"$figures_out_common/sqindexplot_men_fert_1"	///
			"$figures_out_common/chrono_men_fert_2" 		///
			"$figures_out_common/sqindexplot_men_fert_2"	///
			"$figures_out_common/chrono_men_fert_3" 		///
			"$figures_out_common/sqindexplot_men_fert_3"	///
	, col(2) name(men_fert_part_1, replace) title(Family)   legendfrom("$figures_out_common/sqindexplot_men_fert_1")

	*	Combine the men's employment and family graphs into a single graph
	graph combine men_fert_part_1 men_emp_part_1, imargin(0 0 0 0)

	*	Edit the size of the legend keys in the first graph
	foreach n of numlist 1 2 3 4 {
		gr_edit plotregion1.graph1.legend.plotregion1.key[`n'].xsz.editstyle 6.0 editcopy
		gr_edit plotregion1.graph1.legend.plotregion1.key[`n'].ysz.editstyle 3 editcopy
	}

	*	Edit the size of the legend keys in the second graph
	foreach n of numlist 1 2 3 4 5 6 {
		gr_edit plotregion1.graph2.legend.plotregion1.key[`n'].xsz.editstyle 6.0 editcopy
		gr_edit plotregion1.graph2.legend.plotregion1.key[`n'].ysz.editstyle 3 editcopy
	}

	*	Graph save
	graph save "$figures_out_common/Sequences_men_part_1", replace
 

*	Part 2 
	*	Combine multiple graphs for men's employment data into a single graph
	grc1leg2 										///
			"$figures_out_common/chrono_men_emp_4" 			///
			"$figures_out_common/sqindexplot_men_emp_4" 	///
			"$figures_out_common/chrono_men_emp_5" 			///
			"$figures_out_common/sqindexplot_men_emp_5" 	///
			"$figures_out_common/chrono_men_emp_6" 			///
			"$figures_out_common/sqindexplot_men_emp_6" 	///
	, col(2) name(men_emp_part_2, replace) title(Employment)  legendfrom("$figures_out_common/sqindexplot_men_emp_4")

	*	Combine multiple graphs for men's family data into a single graph
	grc1leg2 ///
			"$figures_out_common/chrono_men_fert_4" 		///
			"$figures_out_common/sqindexplot_men_fert_4"	///
			"$figures_out_common/chrono_men_fert_5" 		///
			"$figures_out_common/sqindexplot_men_fert_5"	///
			"$figures_out_common/chrono_men_fert_6" 		///
			"$figures_out_common/sqindexplot_men_fert_6"	///
	, col(2) name(men_fert_part_2, replace) title(Family)  legendfrom("$figures_out_common/sqindexplot_men_fert_4")

	*	Combine the men's employment and family graphs into a single graph
	graph combine men_fert_part_2 men_emp_part_2, imargin(0 0 0 0)

	*	Edit the size of the legend keys in the first graph
	foreach n of numlist 1 2 3 4 {
		gr_edit plotregion1.graph1.legend.plotregion1.key[`n'].xsz.editstyle 6.0 editcopy
		gr_edit plotregion1.graph1.legend.plotregion1.key[`n'].ysz.editstyle 3 editcopy
	}

	*	Edit the size of the legend keys in the second graph
	foreach n of numlist 1 2 3 4 5 6 {
		gr_edit plotregion1.graph2.legend.plotregion1.key[`n'].xsz.editstyle 6.0 editcopy
		gr_edit plotregion1.graph2.legend.plotregion1.key[`n'].ysz.editstyle 3 editcopy
	}

	*	Graph save
	graph save "$figures_out_common/Sequences_men_part_2", replace


*>> Women 
*	Part 1
	*	Combine multiple graphs for women's employment data into a single graph
	grc1leg2 										///
			"$figures_out_common/chrono_women_emp_1" 		///
			"$figures_out_common/sqindexplot_women_emp_1" 	///
			"$figures_out_common/chrono_women_emp_2" 		///
			"$figures_out_common/sqindexplot_women_emp_2" 	///
			"$figures_out_common/chrono_women_emp_3" 		///
			"$figures_out_common/sqindexplot_women_emp_3" 	///
	, col(2) name(women_emp_part_1, replace) title(Employment)  legendfrom("$figures_out_common/sqindexplot_women_emp_1")

	*	Combine multiple graphs for women's family data into a single graph
	grc1leg2 ///
			"$figures_out_common/chrono_women_fert_1" 		///
			"$figures_out_common/sqindexplot_women_fert_1"	///
			"$figures_out_common/chrono_women_fert_2" 		///
			"$figures_out_common/sqindexplot_women_fert_2"	///
			"$figures_out_common/chrono_women_fert_3" 		///
			"$figures_out_common/sqindexplot_women_fert_3"	///
	, col(2) name(women_fert_part_1, replace) title(Family)  legendfrom("$figures_out_common/sqindexplot_women_fert_1")

	*	Combine the women's employment and family graphs into a single graph
	graph combine women_fert_part_1 women_emp_part_1, imargin(0 0 0 0)

	*	Edit the size of the legend keys in the first graph
	foreach n of numlist 1 2 3 4 {
		gr_edit plotregion1.graph1.legend.plotregion1.key[`n'].xsz.editstyle 6.0 editcopy
		gr_edit plotregion1.graph1.legend.plotregion1.key[`n'].ysz.editstyle 3 editcopy
	}

	*	Edit the size of the legend keys in the second graph
	foreach n of numlist 1 2 3 4 5 6 {
		gr_edit plotregion1.graph2.legend.plotregion1.key[`n'].xsz.editstyle 6.0 editcopy
		gr_edit plotregion1.graph2.legend.plotregion1.key[`n'].ysz.editstyle 3 editcopy
	}

	*	Graph save
	graph save "$figures_out_common/Sequences_women_part_1", replace
 

*	Part 2 
	*	Combine multiple graphs for women's employment data into a single graph
	grc1leg2 										///
			"$figures_out_common/chrono_women_emp_4" 		///
			"$figures_out_common/sqindexplot_women_emp_4" 	///
			"$figures_out_common/chrono_women_emp_5" 		///
			"$figures_out_common/sqindexplot_women_emp_5" 	///
			"$figures_out_common/chrono_women_emp_6" 		///
			"$figures_out_common/sqindexplot_women_emp_6" 	///
	, col(2) name(women_emp_part_2, replace) title(Employment)  legendfrom("$figures_out_common/sqindexplot_women_emp_4")

	*	Combine multiple graphs for women's family data into a single graph
	grc1leg2 ///
			"$figures_out_common/chrono_women_fert_4" 		///
			"$figures_out_common/sqindexplot_women_fert_4"	///
			"$figures_out_common/chrono_women_fert_5" 		///
			"$figures_out_common/sqindexplot_women_fert_5"	///
			"$figures_out_common/chrono_women_fert_6" 		///
			"$figures_out_common/sqindexplot_women_fert_6"	///
	, col(2) name(women_fert_part_2, replace) title(Family)  legendfrom("$figures_out_common/sqindexplot_women_fert_4")

	*	Combine the women's employment and family graphs into a single graph
	graph combine women_fert_part_2 women_emp_part_2, imargin(0 0 0 0)

	*	Edit the size of the legend keys in the first graph
	foreach n of numlist 1 2 3 4 {
		gr_edit plotregion1.graph1.legend.plotregion1.key[`n'].xsz.editstyle 6.0 editcopy
		gr_edit plotregion1.graph1.legend.plotregion1.key[`n'].ysz.editstyle 3 editcopy
	}

	*	Edit the size of the legend keys in the second graph
	foreach n of numlist 1 2 3 4 5 6 {
		gr_edit plotregion1.graph2.legend.plotregion1.key[`n'].xsz.editstyle 6.0 editcopy
		gr_edit plotregion1.graph2.legend.plotregion1.key[`n'].ysz.editstyle 3 editcopy
	}

	*	Graph save
	graph save "$figures_out_common/Sequences_women_part_2", replace


*	Part 3 
	*	Combine multiple graphs for women's employment data into a single graph
	grc1leg2 										///
			"$figures_out_common/chrono_women_emp_7" 		///
			"$figures_out_common/sqindexplot_women_emp_7" 	///
			"$figures_out_common/chrono_women_emp_8" 		///
			"$figures_out_common/sqindexplot_women_emp_8" 	///
			"$figures_out_common/chrono_women_emp_9" 		///
			"$figures_out_common/sqindexplot_women_emp_9" 	///
	, col(2) name(women_emp_part_2, replace) title(Employment)  legendfrom("$figures_out_common/sqindexplot_women_emp_7")

	*	Combine multiple graphs for women's family data into a single graph
	grc1leg2 ///
			"$figures_out_common/chrono_women_fert_7" 		///
			"$figures_out_common/sqindexplot_women_fert_7"	///
			"$figures_out_common/chrono_women_fert_8" 		///
			"$figures_out_common/sqindexplot_women_fert_8"	///
			"$figures_out_common/chrono_women_fert_9" 		///
			"$figures_out_common/sqindexplot_women_fert_9"	///
	, col(2) name(women_fert_part_2, replace) title(Family)  legendfrom("$figures_out_common/sqindexplot_women_fert_7")

	*	Combine the women's employment and family graphs into a single graph
	graph combine women_fert_part_2 women_emp_part_2, imargin(0 0 0 0)

	*	Edit the size of the legend keys in the first graph
	foreach n of numlist 1 2 3 4 {
		gr_edit plotregion1.graph1.legend.plotregion1.key[`n'].xsz.editstyle 6.0 editcopy
		gr_edit plotregion1.graph1.legend.plotregion1.key[`n'].ysz.editstyle 3 editcopy
	}

	*	Edit the size of the legend keys in the second graph
	foreach n of numlist 1 2 3 4 5 6 {
		gr_edit plotregion1.graph2.legend.plotregion1.key[`n'].xsz.editstyle 6.0 editcopy
		gr_edit plotregion1.graph2.legend.plotregion1.key[`n'].ysz.editstyle 3 editcopy
	}

	*	Graph save
	graph save "$figures_out_common/Sequences_women_part_3", replace


*-----------------------------------------------------------------------------------------------* 
*>> Close 
*-----------------------------------------------------------------------------------------------* 

capture log close 


