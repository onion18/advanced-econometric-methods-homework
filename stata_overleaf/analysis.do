version 18.0
clear all
set more off
set varabbrev off

capture mkdir "tables"
capture mkdir "figures"
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
* graph export "figures/figure_main.pdf", replace

* esttab coefficient-label example:
* esttab model1 model2 using "tables/table_main.tex", replace ///
*     coeflabels(educ "Years of education" ///
*                treatpost "Treatment x Post") ///
*     b(3) se(3) booktabs

* Public-PC tip: put required .ado and .sthlp files in the local ado folder.
