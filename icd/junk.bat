del icd.lib
lib32s icd.lib < cicd.dat
svs +d -o icd.exe icd.obj ibmrot.obj icd.lib summasii\position.lib paradise\video.lib fjdl3400\print.lib \svs\lib\libp28.lib
dir icd.exe
