
Public VCMOS_AddrPort_IOhookTable
Public VCMOS_DataPort_IOhookTable

; -----------------------------------------------------------------------------

; I/O Hook Tables for VDHInstallIOhook()
VCMOS_AddrPort_IOhookTable:
   dd offset VCMOS_InOnAddress, offset VCMOS_OutOnAddress
   dd 0, 0, 0
VCMOS_DataPort_IOhookTable:
   dd offset VCMOS_InOnData, offset VCMOS_OutOnData
   dd 0, 0, 0
