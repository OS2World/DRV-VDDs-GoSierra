@echo off
set INCLUDE=%INCLUDE%;%INCLUDE_DDK%
set LIB=%LIB%;%LIB_DDK%;%LIB_WATCOM%

wasm -3p -bt=os2 -mf -zq asm\main.asm
wcc386 test /3s/bt=os2/d0/hc/oi/s/wx/zfp/zgp/zq/zu
if errorlevel 1 goto End
wlink n test.exe @test.def
del test.obj
del test.map
:End
