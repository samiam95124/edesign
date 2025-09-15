ml /c /Cx /Flpixel.lst pixel.asm
rem svs -c +d drawa.pas
rem svs -c +d drawb.pas
svs -c +d drawc.pas
ml /c /Cx /Fldrawa.lst drawa.asm
ml /c /Cx /Fldrawb.lst drawb.asm
svs -c +d test.pas
svs -stack 200k +d test.obj pixel.obj drawa.obj drawb.obj drawc.obj ..\ibmrot.obj \svs\lib\libp28.lib
dir test.exe
