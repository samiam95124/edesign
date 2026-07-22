ml /c /Cx /Flpixel.lst pixel.asm
ml /c /Cx /Fldrawa.lst drawa.asm
ml /c /Cx /Fldrawb.lst drawb.asm
svs -stack 200k +d idle.pas pixel.obj drawa.obj drawb.obj ..\ibmrot.obj \svs\lib\libp28.lib
dir idle.exe
