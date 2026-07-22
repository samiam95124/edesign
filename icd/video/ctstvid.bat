ml /c /Cx /Flpixel.lst pixel.asm
rem svs -c +d drawa.pas
rem svs -c +d drawb.pas
ml /c /Cx /Fldrawa.lst drawa.asm
ml /c /Cx /Fldrawb.lst drawb.asm
svs -c +d tstvid.pas
svs -stack 200k +d tstvid.obj pixel.obj drawa.obj drawb.obj ..\ibmrot.obj \svs\lib\libp28.lib
dir tstvid.exe
