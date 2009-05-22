@echo off
alp.exe -D:Flat sbemu.asm
if errorlevel 1 goto End
icc /C /Ms testemu.c
if errorlevel 1 goto End
ilink testemu.obj sbemu.obj testemu.def
:End
