@echo off
set INCLUDE=%INCLUDE%;%INCLUDE_TOOLKIT%;%INCLUDE_WATCOM%
set LIB=%LIB%;%LIB_TOOLKIT%;%LIB_WATCOM%
h:\IbmC\bin\icc /W2 /C /Ms mmhelpdd.c
if errorlevel 1 goto End
ilink mmhelpdd.obj mmhelpdd.def
if errorlevel 1 goto End
:End
