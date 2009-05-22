@echo off
alp.exe -D:Flat sbemu.asm
if errorlevel 1 goto End
icc /C /Q /W2 /DM_I386 /Tdc /Ss+ /Ms /O- /Rn /Gs+ /Gr+ /Gd- /G3 /Sp1 sbvdd.c >make.err
if errorlevel 1 goto End
rem ilink sbvdd.obj sbemu.obj sbvdd.def vdh.lib dtavdd.lib
link386 sbvdd.obj sbemu.obj vdh.lib dtavdd.lib
:End
