rem 
rem Compile Summasketch II tablet driver
rem 

rem Compile HLL modules

svs -c +d pointera.pas

rem Assemble ASM modules

ml /c /Cx /Flauxio.lst pointerb.asm

rem If any compiles have been performed, a link is required

del position.lib
lib32s position.lib < cpos.dat
