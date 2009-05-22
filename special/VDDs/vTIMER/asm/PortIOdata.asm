
Public VTIMER_Ports_PITCounterIOhookTable
Public VTIMER_Ports_PITModeIOhookTable
Public VTIMER_Ports_KeyboardIOhookTable

; -----------------------------------------------------------------------------

; I/O Hook Tables for VDHInstallIOhook()
VTIMER_Ports_PITCounterIOhookTable:
   dd offset VTIMER_InOnPITCounter, offset VTIMER_OutOnPITCounter
   dd 0, 0, 0

VTIMER_Ports_PITModeIOhookTable:
   dd offset VTIMER_InOnPITMode, offset VTIMER_OutOnPITMode
   dd 0, 0, 0

VTIMER_Ports_KeyboardIOhookTable:
   dd offset VTIMER_InOnKeyboard, offset VTIMER_OutOnKeyboard
   dd 0, 0, 0

