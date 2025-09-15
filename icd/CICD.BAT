rem 
rem structure of ICD program:
rem
rem pixel - the pixel set/reset routines and lowest level routines.
rem         These are the routines that are allways coded in assembly,
rem         and do not have high level language equivalents.
rem draw -  Contains various low level display routines. A high level
rem         language version and any number of assembly level versions
rem         of this package exist. Except for speed, they are supposed
rem         to be interchangeable.
rem

rem Compile HLL modules

svs -S common.pas
svs -c +d icd.pas 
svs -c +d icda.pas
svs -c +d icdb.pas
svs -c +d icdc.pas
svs -c +d icdd.pas
svs -c +d icde.pas
svs -c +d icdf.pas
svs -c +d icdg.pas
svs -c +d icdh.pas

rem Assemble modules

ml /c /Cx /Flibmrot.lst ibmrot.asm

rem link icd

del icd.lib
lib32s icd.lib < cicd.dat
svs -stack 200k +d icd.obj ibmrot.obj icd.lib position\position.lib video\video.lib fjdl3400\print.lib \svs\lib\libp28.lib
del icdesign.exe
ren icd.exe icdesign.exe
del icdesign.dbg
ren icd.dbg icdesign.dbg
del icdesign.map
ren icd.map icdesign.map
dir icdesign.exe
