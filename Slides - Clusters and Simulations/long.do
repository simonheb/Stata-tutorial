***********SOME SETTINGS FOR STATA************
set more off
set matsize 10000
set seed 1234
cap mat drop pvalues

quietly forvalues i=1/5000 {
	noi _dots `i' 0 0 //to display progress

	*****************SIMULATE DATA****************
	clear
	set obs 20 //20 schools
	gen school_id = _n
	gen school_unobservable = rnormal()^2 //Chi-squared

	expand 20 //20 classes per school = 400 classes
	gen class_unobservable = rnormal()^2 //Chi-squared
	sort school_id, stable
	gen class_id = _n
	gen treatment = mod(_n,2) //classes in odd rows are treated even rows are control


	expand 10 //20 students per  class =  8000 students
	
	gen testscores = class_unobservable + school_unobservable + 0*treatment + runiform()

	sort *_id, stable
	
	*****************ANALYZE DATA****************
	//plain difference in means
	regress testscores treatment
	quietly testparm treatment
	local pvalue1 = `r(p)'
	
	//adjusting standard errors
	regress testscores treatment, cluster(class_id)
	quietly testparm treatment
	local pvalue2 = `r(p)'

	//adding strata FEs
	regress testscores treatment i.school_id, cluster(class_id)
	testparm treatment
	local pvalue3 = `r(p)'

	//what if our sample was much smaller? (only one school, 8 classes, 80 students)
	keep if class_id<=10
	
	regress testscores treatment , cluster(class_id)
	testparm treatment
	local pvalue4 = `r(p)'
	
	//net describe ritest, from(https://raw.githubusercontent.com/simonheb/ritest/master/)
	//net install ritest
	//quietly ritest treatment _b[treatment], cluster(class_id) r(200): regress testscores treatment
	//mat pvals = r(p)
	//local pvalue5 = pvals[1,1]
	
	//ssc install clustse
	//cgmwildboot testscores treatment, cluster(class_id) bootcluster(class_id) reps(200) null(0)
	//testparm treatment
	//local pvalue6 = `r(p)'
		
	mat pvalues=nullmat(pvalues)\(`pvalue1',`pvalue2',`pvalue3',`pvalue4',0`pvalue5',0`pvalue6')
}
clear
set obs 1000
svmat pvalues
set graphics off
hist pvalues1, name(a, replace) start(0) width(0.1)
hist pvalues2, name(b, replace) start(0) width(0.1)
hist pvalues3, name(c, replace) start(0) width(0.1)
hist pvalues4, name(d, replace) start(0) width(0.1)
hist pvalues5, name(e, replace) start(0) width(0.1)
hist pvalues6, name(f, replace) start(0) width(0.1)
set graphics on
graph combine a b c d e f
