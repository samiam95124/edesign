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
