; INT 31h - Pre-Process Handler

public INT31_PreProcessHandler
extern DebugBeep:near

INT31_PreProcessHandler      Proc Near   Uses ebx
   call DebugBeep
   stc                          ; Chain to next handler...
   ret
INT31_PreProcessHandler      EndP
