
VCDROMAPI_DetectReplacement     equ 0BABE0000h

VCOMPATAPI_ReportIRQDetection   equ         1h

VDMAAPI_DetectReplacement       equ 0BABE0000h

; events for VDHRegisterDMAChannel called functionhandler
VDMAAPI_EVENT_VIRTUALSTART      equ 0BABE0001h
VDMAAPI_EVENT_VIRTUALSTOP       equ 0BABE0002h
VDMAAPI_EVENT_VIRTUALGETPOS     equ 0BABE0003h

VSOUNDAPI_SetVCOMPATEntry       equ         1h

VTIMERAPI_StartCallOutDMA       equ         1h
VTIMERAPI_StopCallOutDMA        equ         2h
