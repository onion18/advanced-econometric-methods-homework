version 18.0
* This file lives in code/. Move to the project root before reading data/ or writing output/.
capture confirm file "report/report.tex"
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
capture mkdir "output/tables"
capture mkdir "output/figures"
capture mkdir "ado"
adopath ++ "ado"

* Open the file supplied for the current assignment here.

* Replace all placeholders with the variables and specifications requested.

* [Question number and short title]
* Write the code required for this question and export any requested output.
* Copy this block as many times as needed and follow the current assignment's order.

* Reader-friendly label examples:
* label variable wage      "Hourly wage"
* label variable educ      "Years of education"
* label variable treatpost "Treatment x Post"

* Figure example:
* twoway scatter wage educ, ///
*     xtitle("Years of education") ///
*     ytitle("Hourly wage (US dollars)") ///
*     title("Education and hourly wages")
* graph export "output/figures/figure_main.pdf", replace

* esttab coefficient-label example:
* esttab model1 model2 using "output/tables/table_main.tex", replace ///
*     coeflabels(educ "Years of education" ///
*                treatpost "Treatment x Post") ///
*     b(3) se(3) booktabs

* Public-PC tip: put required .ado and .sthlp files in the local ado folder.
