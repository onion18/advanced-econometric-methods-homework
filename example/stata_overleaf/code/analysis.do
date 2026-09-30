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
exit, clear
