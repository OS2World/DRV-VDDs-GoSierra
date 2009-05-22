Public CONST_TIMERPDD
Public CONST_VTIMERVDD
Public CONST_TIMER_MAIN
Public CONST_TIMER_COPYRIGHT
Public CONST_TIMER_DEBUG
Public CONST_DOS_BACKGROUND_EXEC
Public CONST_HW_NOSOUND
Public CONST_HW_TIMER
Public CONST_XMS_MEMORY_LIMIT

CONST_TIMERPDD               db 'TIMER$', 0
CONST_VTIMERVDD              db 'VTIMER$', 0
CONST_TIMER_MAIN             db 'TIMER', 0
CONST_TIMER_COPYRIGHT        db 'vTIMER v0.9b - (c) by Kiewitz in 2006', 0
                             db ' - Dedicated to Gerd Kiewitz', 0, 0
CONST_TIMER_DEBUG            db 'TIMER_DEBUG', 0
CONST_DOS_BACKGROUND_EXEC    db 'DOS_BACKGROUND_EXECUTION', 0
CONST_HW_NOSOUND             db 'HW_NOSOUND', 0
CONST_HW_TIMER               db 'HW_TIMER', 0
CONST_XMS_MEMORY_LIMIT       db 'XMS_MEMORY_LIMIT', 0

VTIMER_DetectReplacement        equ 0BABE0000h
