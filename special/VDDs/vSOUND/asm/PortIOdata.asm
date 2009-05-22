
Public VSOUND_Ports_IOhookTable

; -----------------------------------------------------------------------------

; I/O Hook Table for VDHInstallIOhook()
VSOUND_Ports_IOhookTable:
   dd offset VSOUND_InOnSB, offset VSOUND_OutOnSB
   dd 0, 0, 0

VSOUND_Ports_FunctionTable:
   dd offset VSOUND_Ports_InNOP,            offset VSOUND_Ports_OutNOP
   dd offset VSOUND_Ports_InNOP,            offset VSOUND_Ports_OutNOP
   dd offset VSOUND_Ports_InNOP,            offset VSOUND_Ports_OutNOP
   dd offset VSOUND_Ports_InNOP,            offset VSOUND_Ports_OutNOP
   dd offset VSOUND_Ports_InMixerAddress,   offset VSOUND_Ports_OutMixerAddress
   dd offset VSOUND_Ports_InMixerData,      offset VSOUND_Ports_OutMixerData
   dd offset VSOUND_Ports_InNOP,            offset VSOUND_Ports_OutReset
   dd offset VSOUND_Ports_InNOP,            offset VSOUND_Ports_OutNOP
   dd offset VSOUND_Ports_InNOP,            offset VSOUND_Ports_OutNOP
   dd offset VSOUND_Ports_InNOP,            offset VSOUND_Ports_OutNOP
   dd offset VSOUND_Ports_InData,           offset VSOUND_Ports_OutNOP
   dd offset VSOUND_Ports_InNOP,            offset VSOUND_Ports_OutNOP
   dd offset VSOUND_Ports_InWriteReady,     offset VSOUND_Ports_OutData
   dd offset VSOUND_Ports_InNOP,            offset VSOUND_Ports_OutNOP
   dd offset VSOUND_Ports_InDataAvail8bit,  offset VSOUND_Ports_OutNOP
   dd offset VSOUND_Ports_InDataAvail16bit, offset VSOUND_Ports_OutNOP

; =============================================================================
;  ELiTE Table for quick Soundblaster Command emulation
; =============================================================================
VSOUND_Ports_CMDlengthTable:
   dd offset VSOUND_Ports_CMDnulTable,      offset VSOUND_Ports_CMDlength1x
   dd offset VSOUND_Ports_CMDlength2x,      offset VSOUND_Ports_CMDnulTable
   dd offset VSOUND_Ports_CMDlength4x,      offset VSOUND_Ports_CMDnulTable
   dd offset VSOUND_Ports_CMDnulTable,      offset VSOUND_Ports_CMDlength7x
   dd offset VSOUND_Ports_CMDlength8x,      offset VSOUND_Ports_CMDnulTable
   dd offset VSOUND_Ports_CMDnulTable,      offset VSOUND_Ports_CMDnulTable
   dd offset VSOUND_Ports_CMDnulTable,      offset VSOUND_Ports_CMDnulTable
   dd offset VSOUND_Ports_SBcommandEx,      offset VSOUND_Ports_CMDnulTable

VSOUND_Ports_CMDfuncTable:
   dd offset VSOUND_Ports_CMDnulTable,      offset VSOUND_Ports_CMDnulTable ;0x
   dd offset VSOUND_Ports_CMDnulTable,      offset VSOUND_Ports_CMDnulTable
   dd offset VSOUND_Ports_CMDnulTable,      offset VSOUND_Ports_CMDfunc14   ;1x
   dd offset VSOUND_Ports_CMDnulTable,      offset VSOUND_Ports_CMDfunc1C
   dd offset VSOUND_Ports_CMDnulTable,      offset VSOUND_Ports_CMDnulTable ;2x
   dd offset VSOUND_Ports_CMDnulTable,      offset VSOUND_Ports_CMDnulTable
   dd offset VSOUND_Ports_CMDnulTable,      offset VSOUND_Ports_CMDnulTable ;3x
   dd offset VSOUND_Ports_CMDnulTable,      offset VSOUND_Ports_CMDnulTable
   dd offset VSOUND_Ports_CMDfunc40,        offset VSOUND_Ports_CMDnulTable ;4x
   dd offset VSOUND_Ports_CMDfunc48,        offset VSOUND_Ports_CMDnulTable
   dd offset VSOUND_Ports_CMDnulTable,      offset VSOUND_Ports_CMDnulTable ;5x
   dd offset VSOUND_Ports_CMDnulTable,      offset VSOUND_Ports_CMDnulTable
   dd offset VSOUND_Ports_CMDnulTable,      offset VSOUND_Ports_CMDnulTable ;6x
   dd offset VSOUND_Ports_CMDnulTable,      offset VSOUND_Ports_CMDnulTable
   dd offset VSOUND_Ports_CMDnulTable,      offset VSOUND_Ports_CMDnulTable ;7x
   dd offset VSOUND_Ports_CMDnulTable,      offset VSOUND_Ports_CMDnulTable
   dd offset VSOUND_Ports_CMDfunc80,        offset VSOUND_Ports_CMDnulTable ;8x
   dd offset VSOUND_Ports_CMDnulTable,      offset VSOUND_Ports_CMDnulTable
   dd offset VSOUND_Ports_CMDfunc90,        offset VSOUND_Ports_CMDnulTable ;9x
   dd offset VSOUND_Ports_CMDnulTable,      offset VSOUND_Ports_CMDnulTable
   dd offset VSOUND_Ports_CMDnulTable,      offset VSOUND_Ports_CMDnulTable ;Ax
   dd offset VSOUND_Ports_CMDnulTable,      offset VSOUND_Ports_CMDnulTable
   dd offset VSOUND_Ports_CMDfuncBx,        offset VSOUND_Ports_CMDfuncBx   ;Bx
   dd offset VSOUND_Ports_CMDfuncBx,        offset VSOUND_Ports_CMDfuncBx
   dd offset VSOUND_Ports_CMDfuncCx,        offset VSOUND_Ports_CMDfuncCx   ;Cx
   dd offset VSOUND_Ports_CMDfuncCx,        offset VSOUND_Ports_CMDfuncCx
   dd offset VSOUND_Ports_CMDfuncD0,        offset VSOUND_Ports_CMDfuncD4   ;Dx
   dd offset VSOUND_Ports_CMDfuncD8,        offset VSOUND_Ports_CMDnulTable
   dd offset VSOUND_Ports_CMDfuncE0,        offset VSOUND_Ports_CMDfuncE4   ;Ex
   dd offset VSOUND_Ports_CMDnulTable,      offset VSOUND_Ports_CMDnulTable
   dd offset VSOUND_Ports_CMDfuncF0,        offset VSOUND_Ports_CMDnulTable ;Fx
   dd offset VSOUND_Ports_CMDnulTable,      offset VSOUND_Ports_CMDnulTable

                          ;  0 1 2 3 4 5 6 7 8 9 A B C D E F
VSOUND_Ports_CMDnulTable: db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
VSOUND_Ports_CMDlength1x: db 1,0,0,0,2,0,0,2,0,0,0,0,0,0,0,0
VSOUND_Ports_CMDlength2x: db 0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0
VSOUND_Ports_CMDlength4x: db 1,2,2,0,0,0,0,0,2,0,0,0,0,0,0,0
VSOUND_Ports_CMDlength7x: db 0,0,0,0,2,0,0,2,0,0,0,0,0,0,0,0
VSOUND_Ports_CMDlength8x: db 2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
VSOUND_Ports_SBcommandEx: db 1,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0

VSOUND_Ports_CMDfunc10:
   dd offset VSB_PlayOneSample,             0
   dd 0,                                    0
VSOUND_Ports_CMDfunc14:
   dd offset VSB_StartLowSpeedDMA8bit,      0
   dd 0,                                    0
VSOUND_Ports_CMDfunc1C:
   dd offset VSB_StartLowSpeedAutoInitDMA8bit, 0
   dd 0,                                    0
VSOUND_Ports_CMDfunc40:
   dd offset VSB_SetSampleRate,             offset VSB_SetExtSampleRate
   dd 0,                                    0
VSOUND_Ports_CMDfunc48:
   dd offset VSB_SetTransferLength,         0
   dd 0,                                    0
VSOUND_Ports_CMDfunc80:
   dd offset VSB_PlaySilentBlock,           0
   dd 0,                                    0
VSOUND_Ports_CMDfunc90:
   dd offset VSB_StartHiSpeedAutoInitDMA8bit, offset VSB_StartHiSpeedDMA8bit
   dd 0,                                    0
VSOUND_Ports_CMDfuncBx:
   dd offset VSB_StartExtDMA16bit,          offset VSB_StartExtDMA16bit
   dd offset VSB_StartExtDMA16bit,          offset VSB_StartExtDMA16bit
VSOUND_Ports_CMDfuncCx:
   dd offset VSB_StartExtDMA8bit,           offset VSB_StartExtDMA8bit
   dd offset VSB_StartExtDMA8bit,           offset VSB_StartExtDMA8bit
VSOUND_Ports_CMDfuncD0:
   dd offset VSB_Pause8bitDMA,              0
   dd 0,                                    0
VSOUND_Ports_CMDfuncD4:
   dd offset VSB_Resume8bitDMA,             offset VSB_Pause16bitDMA
   dd offset VSB_Resume16bitDMA,            0
VSOUND_Ports_CMDfuncD8:
   dd offset VSB_ReadDACOutputStatus,       0
   dd 0,                                    0
VSOUND_Ports_CMDfuncE0:
   dd offset VSB_GetDSPid,                  offset VSB_GetDSPversion
   dd 0,                                    0
VSOUND_Ports_CMDfuncE4:
   dd offset VSB_GetDSPid2,                 0
   dd 0,                                    0
VSOUND_Ports_CMDfuncF0:
   dd 0,                                    0
   dd offset VSB_RaiseIRQline,              0
