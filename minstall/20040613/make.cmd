@echo off
set INCLUDE=%INCLUDE%;%INCLUDE_TOOLKIT%;%INCLUDE_WATCOM%
set LIB=%LIB%;%LIB_TOOLKIT%;%LIB_WATCOM%
\IbmC\bin\icc /Gm+ /W2 /C /Ms minstall.c
if errorlevel 1 goto End
ilink minstall.def minstall.obj ..\..\JimiHelp\stdcode\file.obj ..\..\JimiHelp\stdcode\globstr.obj ..\..\JimiHelp\stdcode\mciini.obj ..\..\JimiHelp\stdcode\msg.obj ..\..\JimiHelp\stdcode\dll.obj ..\..\JimiHelp\asm.32\crcs.obj
copy minstall.exe c:\mmos2
:End
