@echo off
set INCLUDE=%INCLUDE%;%INCLUDE_DDK%
set LIB=%LIB%;%LIB_DDK%;%LIB_WATCOM%

alp.exe -D:Flat asm\main.asm
rem wasm -3p -bt=os2 -mf -zq asm\main.asm
wcc386 vcompat /3s/bt=os2/d0/hc/oi/s/wx/zfp/zgp/zq/zu
if errorlevel 1 goto End
wcc386 magicvmp /3s/bt=os2/d0/hc/oi/s/wx/zfp/zgp/zq/zu
if errorlevel 1 goto End

link386 /NOE /NOD /M /BATCH @vcompat.lnk
rem /CO
del vcompat.obj
del magicvmp.obj
:End
