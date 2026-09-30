version 18.0
* This file lives in code/. Paths below are relative to the project root.
capture confirm file "data/penguins.csv"
if _rc {
    local dofile "`c(filename)'"
    if "`dofile'" != "" {
        mata: st_local("dofile", pathresolve(pwd(), st_local("dofile")))
        mata: st_local("root", pathgetparent(pathgetparent(st_local("dofile"))))
        cd "`root'"
    }
}
clear all
set more off
set varabbrev off

capture mkdir "output"
capture mkdir "output/figures"
capture mkdir "output/tables"

* 1.1: simulated scatter plot
import delimited "data/scatter_simulation.csv", clear
twoway (scatter y x) (lfit y x), ///
    title("Simulated outcome and predictor") ///
    xtitle("Simulated predictor (X)") ytitle("Simulated outcome (Y)") ///
    legend(order(1 "Observations" 2 "Least-squares fit"))
graph export "output/figures/scatter.pdf", replace
graph export "output/figures/scatter.png", width(1600) replace

* 1.2: simulated two-way fixed-effects event study; period -1 is omitted.
import delimited "data/event_study_simulation.csv", clear
generate time_id = period + 6
forvalues k = 2/5 {
    generate event_m`k' = (treated == 1 & period == -`k')
}
generate event_p0 = (treated == 1 & period == 0)
forvalues k = 1/4 {
    generate event_p`k' = (treated == 1 & period == `k')
}
quietly regress y i.unit_id i.time_id event_m5 event_m4 event_m3 event_m2 ///
    event_p0 event_p1 event_p2 event_p3 event_p4
local b_m5 = _b[event_m5]
local s_m5 = _se[event_m5]
local b_m4 = _b[event_m4]
local s_m4 = _se[event_m4]
local b_m3 = _b[event_m3]
local s_m3 = _se[event_m3]
local b_m2 = _b[event_m2]
local s_m2 = _se[event_m2]
local b_p0 = _b[event_p0]
local s_p0 = _se[event_p0]
local b_p1 = _b[event_p1]
local s_p1 = _se[event_p1]
local b_p2 = _b[event_p2]
local s_p2 = _se[event_p2]
local b_p3 = _b[event_p3]
local s_p3 = _se[event_p3]
local b_p4 = _b[event_p4]
local s_p4 = _se[event_p4]
preserve
clear
set obs 9
generate event_time = .
generate estimate = .
generate std_error = .
replace event_time = -5 in 1
replace estimate = `b_m5' in 1
replace std_error = `s_m5' in 1
replace event_time = -4 in 2
replace estimate = `b_m4' in 2
replace std_error = `s_m4' in 2
replace event_time = -3 in 3
replace estimate = `b_m3' in 3
replace std_error = `s_m3' in 3
replace event_time = -2 in 4
replace estimate = `b_m2' in 4
replace std_error = `s_m2' in 4
replace event_time = 0 in 5
replace estimate = `b_p0' in 5
replace std_error = `s_p0' in 5
replace event_time = 1 in 6
replace estimate = `b_p1' in 6
replace std_error = `s_p1' in 6
replace event_time = 2 in 7
replace estimate = `b_p2' in 7
replace std_error = `s_p2' in 7
replace event_time = 3 in 8
replace estimate = `b_p3' in 8
replace std_error = `s_p3' in 8
replace event_time = 4 in 9
replace estimate = `b_p4' in 9
replace std_error = `s_p4' in 9
generate lower = estimate - 1.96 * std_error
generate upper = estimate + 1.96 * std_error
twoway (rcap upper lower event_time) (scatter estimate event_time), ///
    title("Event-study estimates from simulated data") ///
    xtitle("Event time (periods relative to treatment)") ///
    ytitle("Estimated effect on outcome") ///
    xlabel(-5(1)4) xline(-0.5, lpattern(dash) lcolor(gs8)) ///
    yline(0, lpattern(dash) lcolor(gs8)) legend(off)
graph export "output/figures/event_study.pdf", replace
graph export "output/figures/event_study.png", width(1600) replace
restore

* 2.1: Palmer Penguins measurements by sex and species.
import delimited "data/penguins.csv", clear
drop if missing(sex) | missing(flipper_length_mm) | missing(bill_length_mm) | missing(body_mass_g)
twoway ///
    (scatter bill_length_mm flipper_length_mm if species == "Adelie", mcolor(teal) msymbol(O)) ///
    (scatter bill_length_mm flipper_length_mm if species == "Chinstrap", mcolor(cranberry) msymbol(D)) ///
    (scatter bill_length_mm flipper_length_mm if species == "Gentoo", mcolor(magenta) msymbol(T)), ///
    by(sex, cols(2) note("") title("Bill length by flipper length")) ///
    xtitle("Flipper length (mm)") ytitle("Bill length (mm)") ///
    legend(order(1 "Adelie" 2 "Chinstrap" 3 "Gentoo"))
graph export "output/figures/penguins.pdf", replace
graph export "output/figures/penguins.png", width(1800) replace

* 2.2: table of means by species and sex. Missing measurements are excluded
* from their corresponding means; records with missing sex were dropped above.
collapse (mean) bill_length_mm bill_depth_mm flipper_length_mm body_mass_g, by(species sex)
generate sex_order = (sex == "male")
sort species sex_order
replace sex = proper(sex)
label variable bill_length_mm "Bill length (mm)"
label variable bill_depth_mm "Bill depth (mm)"
label variable flipper_length_mm "Flipper length (mm)"
label variable body_mass_g "Body mass (g)"
file open tablefile using "output/tables/table_penguin_summary.tex", write replace
file write tablefile "\begin{tabular}{llrrrr}" _n
file write tablefile "\toprule" _n
file write tablefile "Species & Sex & Bill length (mm) & Bill depth (mm) & Flipper length (mm) & Body mass (g) \\" _n
file write tablefile "\midrule" _n
forvalues i = 1/`=_N' {
    local sp = species[`i']
    local sx = sex[`i']
    local bill: display %6.1f bill_length_mm[`i']
    local depth: display %6.1f bill_depth_mm[`i']
    local flipper: display %6.1f flipper_length_mm[`i']
    local mass: display %6.1f body_mass_g[`i']
    file write tablefile "`sp' & `sx' & `bill' & `depth' & `flipper' & `mass' \\" _n
}
file write tablefile "\bottomrule" _n
file write tablefile "\end{tabular}" _n
file close tablefile

* 2.3: OLS association between bill length and penguin characteristics.
import delimited "data/penguins.csv", clear
encode species, generate(species_id)
encode sex, generate(sex_id)
label variable bill_length_mm "Bill length (mm)"
label variable species_id "Species"
label variable sex_id "Sex"
label variable flipper_length_mm "Flipper length (mm)"
quietly regress bill_length_mm ib1.species_id ib1.sex_id c.flipper_length_mm
scalar penguin_sample_n = e(N)
scalar penguin_r2 = e(r2)
quietly summarize bill_length_mm if e(sample)
scalar penguin_outcome_mean = r(mean)
estimates store penguin_model
local outcome_mean: display %5.2f scalar(penguin_outcome_mean)
file open regnote using "output/tables/penguin_regression_note.tex", write replace
file write regnote "Outcome mean: `outcome_mean' mm. Complete cases; reference categories are Adelie and female. Conventional OLS standard errors in parentheses."
file close regnote
etable, estimates(penguin_model) column(dvlabel) varlabel mstat(N) mstat(r2) ///
    showstars showstarsnote title("OLS estimates of bill length") ///
    export("output/tables/table_penguin_regression.tex", tableonly replace)

* Leave the collapsed data in memory for the Stata putpdf summary table.
import delimited "data/penguins.csv", clear
drop if missing(sex) | missing(flipper_length_mm) | missing(bill_length_mm) | missing(body_mass_g)
collapse (mean) bill_length_mm bill_depth_mm flipper_length_mm body_mass_g, by(species sex)
generate sex_order = (sex == "male")
sort species sex_order
replace sex = proper(sex)
