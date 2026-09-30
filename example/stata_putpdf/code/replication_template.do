version 18.0
* This file lives in code/. Move to the project root, then build output/.
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

do "code/analysis_core.do"

capture putpdf clear
putpdf begin

putpdf paragraph, halign(center)
putpdf text ("Advanced Econometric Methods:sample"), bold font("Arial", 18)
putpdf paragraph, halign(center)
putpdf text ("Student ID: Your Student ID"), font("Arial", 11)
putpdf paragraph, halign(center)
putpdf text ("Your Name"), font("Arial", 11)

putpdf paragraph
putpdf text ("Question 1"), bold font("Arial", 16)
putpdf paragraph
putpdf text ("1.1 Scatter plot"), bold font("Arial", 13)
putpdf paragraph
putpdf text ("The simulated data show a positive association between X and Y. The line is the least-squares fit.")
putpdf paragraph, halign(center)
putpdf image "output/figures/scatter.png", width(5.5)
putpdf paragraph, halign(center)
putpdf text ("Figure 1. Simulated outcome (Y) and predictor (X).")

putpdf paragraph
putpdf text ("1.2 Event-study"), bold font("Arial", 13)
putpdf paragraph
putpdf text ("Treatment is assigned to 60 of 120 units. Outcomes include unit and time effects, a rising treatment effect after period 0, and random noise. Period -1 is the reference period. The plot shows two-way fixed-effects estimates and 95% confidence intervals; pre-treatment estimates should be near zero.")
putpdf paragraph, halign(center)
putpdf image "output/figures/event_study.png", width(5.5)
putpdf paragraph, halign(center)
putpdf text ("Figure 2. Event-study estimates from simulated data.")

putpdf paragraph
putpdf text ("Question 2"), bold font("Arial", 16)
putpdf paragraph
putpdf text ("2.1 Penguin figure"), bold font("Arial", 13)
putpdf paragraph
putpdf text ("Palmer Penguins measurements by sex and species. Records with missing sex or plotted measurements are omitted.")
putpdf paragraph, halign(center)
putpdf image "output/figures/penguins.png", width(6)
putpdf paragraph, halign(center)
putpdf text ("Figure 3. Penguin measurements. Source: Horst, Hill, and Gorman (2020).")

putpdf pagebreak
putpdf paragraph
putpdf text ("2.2 Table"), bold font("Arial", 13)
putpdf paragraph
putpdf text ("Mean bill length, bill depth, flipper length, and body mass by species and sex. Each mean uses available observations for that measurement.")
putpdf paragraph, halign(center)
putpdf text ("Table 1. Penguin summary statistics by species and sex."), bold
putpdf table table1 = data(species sex bill_length_mm bill_depth_mm flipper_length_mm body_mass_g), varnames
putpdf table table1(1,1) = ("Species")
putpdf table table1(1,2) = ("Sex")
putpdf table table1(1,3) = ("Bill length (mm)")
putpdf table table1(1,4) = ("Bill depth (mm)")
putpdf table table1(1,5) = ("Flipper length (mm)")
putpdf table table1(1,6) = ("Body mass (g)")
putpdf table table1(.,3/6), nformat(%7.1f)

putpdf paragraph
putpdf text ("2.3 Regression"), bold font("Arial", 13)
putpdf paragraph
putpdf text ("We estimate an OLS model of bill length on species, sex, and flipper length. The coefficients are conditional associations, not causal effects. Adelie and female penguins are the reference categories.")
putpdf paragraph, halign(center)
putpdf text ("Bill length")
putpdf text ("i"), script(sub)
putpdf text (" = ")
putpdf text ("β"), italic
putpdf text ("0"), script(sub)
putpdf text (" + ")
putpdf text ("β"), italic
putpdf text ("1"), script(sub)
putpdf text (" 1{Chinstrap")
putpdf text ("i"), script(sub)
putpdf text ("} + ")
putpdf text ("β"), italic
putpdf text ("2"), script(sub)
putpdf text (" 1{Gentoo")
putpdf text ("i"), script(sub)
putpdf text ("}")
putpdf paragraph, halign(center)
putpdf text ("+ ")
putpdf text ("β"), italic
putpdf text ("3"), script(sub)
putpdf text (" 1{Male")
putpdf text ("i"), script(sub)
putpdf text ("} + ")
putpdf text ("β"), italic
putpdf text ("4"), script(sub)
putpdf text (" Flipper length")
putpdf text ("i"), script(sub)
putpdf text (" + ")
putpdf text ("ε"), italic
putpdf text ("i"), script(sub)
putpdf paragraph, halign(center)
putpdf text ("Table 2. OLS estimates of bill length (mm)."), bold
estimates restore penguin_model
local b_chin : display %6.3f _b[2.species_id]
local se_chin : display %6.3f _se[2.species_id]
local p_chin = 2 * ttail(e(df_r), abs(_b[2.species_id] / _se[2.species_id]))
local star_chin = cond(`p_chin' < .01, "***", cond(`p_chin' < .05, "**", cond(`p_chin' < .10, "*", "")))
local b_gentoo : display %6.3f _b[3.species_id]
local se_gentoo : display %6.3f _se[3.species_id]
local p_gentoo = 2 * ttail(e(df_r), abs(_b[3.species_id] / _se[3.species_id]))
local star_gentoo = cond(`p_gentoo' < .01, "***", cond(`p_gentoo' < .05, "**", cond(`p_gentoo' < .10, "*", "")))
local b_male : display %6.3f _b[2.sex_id]
local se_male : display %6.3f _se[2.sex_id]
local p_male = 2 * ttail(e(df_r), abs(_b[2.sex_id] / _se[2.sex_id]))
local star_male = cond(`p_male' < .01, "***", cond(`p_male' < .05, "**", cond(`p_male' < .10, "*", "")))
local b_flipper : display %6.3f _b[flipper_length_mm]
local se_flipper : display %6.3f _se[flipper_length_mm]
local p_flipper = 2 * ttail(e(df_r), abs(_b[flipper_length_mm] / _se[flipper_length_mm]))
local star_flipper = cond(`p_flipper' < .01, "***", cond(`p_flipper' < .05, "**", cond(`p_flipper' < .10, "*", "")))
local b_cons : display %6.3f _b[_cons]
local se_cons : display %6.3f _se[_cons]
local p_cons = 2 * ttail(e(df_r), abs(_b[_cons] / _se[_cons]))
local star_cons = cond(`p_cons' < .01, "***", cond(`p_cons' < .05, "**", cond(`p_cons' < .10, "*", "")))
putpdf table table2 = (7,3), width(100%)
putpdf table table2(1,1) = ("Bill length (mm)"), colspan(3) bold halign(center)
putpdf table table2(2,1) = ("Predictor")
putpdf table table2(2,2) = ("Coefficient")
putpdf table table2(2,3) = ("Std. error")
putpdf table table2(3,1) = ("Chinstrap (reference: Adelie)")
putpdf table table2(3,2) = ("`b_chin'`star_chin'")
putpdf table table2(3,3) = ("`se_chin'")
putpdf table table2(4,1) = ("Gentoo (reference: Adelie)")
putpdf table table2(4,2) = ("`b_gentoo'`star_gentoo'")
putpdf table table2(4,3) = ("`se_gentoo'")
putpdf table table2(5,1) = ("Male (reference: female)")
putpdf table table2(5,2) = ("`b_male'`star_male'")
putpdf table table2(5,3) = ("`se_male'")
putpdf table table2(6,1) = ("Flipper length (mm)")
putpdf table table2(6,2) = ("`b_flipper'`star_flipper'")
putpdf table table2(6,3) = ("`se_flipper'")
putpdf table table2(7,1) = ("Constant")
putpdf table table2(7,2) = ("`b_cons'`star_cons'")
putpdf table table2(7,3) = ("`se_cons'")
putpdf table table2(2,.), bold
putpdf paragraph
putpdf text ("Outcome mean: " + string(penguin_outcome_mean, "%5.2f") + " mm; N: " + string(penguin_sample_n, "%9.0f") + "; R-squared: " + string(penguin_r2, "%5.3f") + ". Complete cases; conventional OLS standard errors in parentheses.")
putpdf paragraph
putpdf text ("*, **, and *** indicate p < 0.10, p < 0.05, and p < 0.01, respectively.")
putpdf paragraph
putpdf text ("Source: Horst, A. M., Hill, A. P., & Gorman, K. B. (2020). palmerpenguins: Palmer Archipelago (Antarctica) penguin data (R package version 0.1.0) [Data set]. Zenodo. https://doi.org/10.5281/zenodo.3960218")
putpdf save "output/replication_report.pdf", replace
exit, clear
