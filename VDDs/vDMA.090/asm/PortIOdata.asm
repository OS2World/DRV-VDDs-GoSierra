
Public VDMA_Ports_IOhookTable

; -----------------------------------------------------------------------------

; I/O Hook Table for VDHInstallIOhook()
VDMA_Ports_IOhookTable:
   dd offset VDMA_InOnDMA, offset VDMA_OutOnDMA
   dd 0, 0, 0

;Table with Ports:
;==================
; 0xh - NOP
; 1xh - Reset Flip/Flop
; 2xh - Page Register
; 3xh - Address Register
; 4xh - CurLength/Length Register
; 5xh - Mask Register
; 6xh - Status/Command Register
; 7xh - Write Request Register
; 8xh - Mode Register
; 9xh - Temporary/Master Clear Register
; Axh - Clear Masks Register
; Bxh - Write Masks Register

; Byte-Table that contains a PortMap -> Base DMA-Channel
VDMA_Ports_ChannelTable:
   ;   0h  1h  2h  3h  4h  5h  6h  7h  8h  9h  Ah  Bh   Ch  Dh   Eh   Fh
   db 30h,40h,31h,41h,32h,42h,33h,43h,60h,70h,50h,80h, 10h,90h,0A0h,0B0h ;000xh
   db  0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h,  0h, 0h,  0h,  0h ;001xh
   db  0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h,  0h, 0h,  0h,  0h ;002xh
   db  0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h,  0h, 0h,  0h,  0h ;003xh
   db  0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h,  0h, 0h,  0h,  0h ;004xh
   db  0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h,  0h, 0h,  0h,  0h ;005xh
   db  0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h,  0h, 0h,  0h,  0h ;006xh
   db  0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h,  0h, 0h,  0h,  0h ;007xh
   db  0h,22h,23h,21h, 0h, 0h, 0h,20h, 0h,26h,27h,25h,  0h, 0h,  0h, 24h ;008xh
   db  0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h,  0h, 0h,  0h,  0h ;009xh
   db  0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h,  0h, 0h,  0h,  0h ;00Axh
   db  0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h,  0h, 0h,  0h,  0h ;00Bxh
   db 34h, 0h,44h, 0h,35h, 0h,45h, 0h,36h, 0h,46h, 0h, 37h, 0h, 47h,  0h ;00Cxh
   db 64h, 0h,74h, 0h,54h, 0h,84h, 0h,14h, 0h,94h, 0h,0A4h, 0h,0B4h,  0h ;00Dxh
   db  0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h,  0h, 0h,  0h,  0h ;00Exh
   db  0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h, 0h,  0h, 0h,  0h,  0h ;00Fxh

VDMA_Ports_FunctionTable:
   dd offset VDMA_Ports_NOP,         offset VDMA_Ports_NOP
   dd offset VDMA_Ports_NOP,         offset VDMA_Ports_ResetFlipFlop
   dd offset VDMA_Ports_InPage,      offset VDMA_Ports_OutPage
   dd offset VDMA_Ports_InAddress,   offset VDMA_Ports_OutAddress
   dd offset VDMA_Ports_InCurLength, offset VDMA_Ports_OutLength
   dd offset VDMA_Ports_NOP,         offset VDMA_Ports_OutMask
   dd offset VDMA_Ports_InStatus,    offset VDMA_Ports_OutCommand
   dd offset VDMA_Ports_NOP,         offset VDMA_Ports_OutWriteRequest
   dd offset VDMA_Ports_NOP,         offset VDMA_Ports_OutMode
   dd offset VDMA_Ports_InTemp,      offset VDMA_Ports_OutMasterClear
   dd offset VDMA_Ports_NOP,         offset VDMA_Ports_OutClearMasks
   dd offset VDMA_Ports_InWriteMasks,offset VDMA_Ports_OutWriteMasks
