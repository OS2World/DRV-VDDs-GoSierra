Public CONST_CMOS_MAIN
Public CONST_CMOS_COPYRIGHT
Public CONST_CMOS_WRITEPROTECT
Public CONST_CMOS_INTERRUPT
Public CONST_CMOS_INTERRUPT_NOGO
Public CONST_TIMER0

CONST_CMOS_MAIN:             db 'CMOS', 0
CONST_CMOS_COPYRIGHT:        db 'vCMOS Replacement v0.9b', 0
                             db ' - (c) by Kiewitz in 2002', 0
                             db ' - Dedicated to Gerd Kiewitz', 0, 0
CONST_CMOS_WRITEPROTECT:     db 'CMOS_WRITE_PROTECTION', 0
CONST_CMOS_INTERRUPT:        db 'CMOS_INTERRUPT', 0
CONST_CMOS_INTERRUPT_NOGO:   db 'HRTX was not detected!', 0, 0
CONST_TIMER0                 db 'TIMER0$', 0
