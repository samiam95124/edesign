rem 
rem Compile Western Digital Paradise video module
rem 

rem compile modules

svs -c +d drawc.pas

rem assemble modules

ml /c /Cx /Flpixel.lst pixel.asm

rem Compile HLL version of DUAL routines.
rem These are commented out to use the ASM version.

rem svs -c +d drawa.pas
rem svs -c +d drawb.pas

rem Assemble ASM version of DUAL routines.
rem These are commented out to use the HLL version.

ml /c /Cx /Fldrawa.lst drawa.asm
ml /c /Cx /Fldrawb.lst drawb.asm

rem If any compiles have been performed, a link is required

del video.lib
lib32s video.lib < cvideo.dat
