
Public VLPT_Ports_IOhookTable
Public VLPT_Ports_FunctionTable

; -----------------------------------------------------------------------------

; I/O Hook Table for VDHInstallIOhook()
VLPT_Ports_IOhookTable:
   dd offset VLPT_InOnLPT, offset VLPT_OutOnLPT
   dd 0, 0, 0

VLPT_Ports_FunctionTable:
   dd offset VLPT_Ports_InData,      offset VLPT_Ports_OutData
   dd offset VLPT_Ports_InStatus,    offset VLPT_Ports_OutStatus
   dd offset VLPT_Ports_InControl,   offset VLPT_Ports_OutControl
