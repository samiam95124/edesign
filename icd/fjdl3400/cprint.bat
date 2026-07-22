rem 
rem Compile Fujitsu DL3400 printer module
rem 

rem Compile HLL version of DUAL routines.
rem These are commented out to use the ASM version.

svs -c +d printer.pas 

rem assemble modules
rem NOTE: this module only required with the HLL version of
rem version of printer.pas. It may be omitted with use
rem of printer.asm

ml /c /Cx /Flprtout.lst prtout.asm

rem Assemble ASM version of DUAL routines.
rem These are commented out to use the HLL version.

rem ml /c /Cx /Flprinter.lst printer.asm

del print.lib
lib32s print.lib < cprint.dat
