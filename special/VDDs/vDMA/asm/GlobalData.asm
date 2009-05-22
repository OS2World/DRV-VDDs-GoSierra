; Please note: DMA-Length always means Value+1 (0 means 1 byte to transfer, etc)
;               On 16-bit DMA, 0 means actually 2 bytes!!)
;  DMA-CurLength means transfer units left on DMA and 0FFFFh means End-Of-Transfer
;  DMA-Offset means relative Base-address and word-size on 16-bit DMA

PDMAslotStruc                  Struc
   DMAno            db ?        ; DMA Channel Number
   DMAmask          db ?
   DMAbitMask       db ?
   PortPage         db ?        ; Port to set Page
   PortAddress      db ?        ; Port to set Address
   PortLength       db ?        ; Port to set Length
   PortMode         db ?        ; Port to set Mode
   PortFlipFlop     db ?        ; Port to reset FlipFlop
   PortMask         db ?        ; Port to set Mask-State
   PortWriteMasks   db ?        ; Port to read/write Mask-State of 4 channels
   TransportSize    dd ?        ; [0.92+] Bytes to copy for 5 msec duration
   TransportTrigger dd ?        ; [0.92+] Bytes before trigger
   Flags            db ?        ; Bit 0   - Channel Enabled
                                ; Bit 1   - Gets VDMA CallOuts
                                ; Bit 2   - Timed Call Back used
                                ; Bit 3   - Rape-Fill (special DMA-method)
                                ; Bit 4   - InCopyEvent (Timed Call Back!)
                                ; Bit 5   - Terminal Count experienced
   Mode             db ?        ; Bit 0-1 - Transfer Type
                                ; Bit 2   - Auto-Init Mode
                                ; Bit 3   - Address decrement
                                ; Bit 4-5 - Transfer Mode
   PhysicalAddress  dd ?        ; Physical Buffer of actual DMA-buffer
                                ;  This is the *DMA* Physical Address
                                ;  On 16-bit DMA this will be the WORD address!
   PhysicalEnd      dd ?        ; Physical Ptr to end of Buffer
   LinearAddress    dd ?        ; Linear address of actual DMA-buffer
   VirtualAddress   dd ?        ; Virtual address of VDM-buffer (application)
   TransferSize     dd ?        ; Size of transfer in bytes
   TransferLeft     dd ?        ; Left byte count, where DMA currently is
   OwnedBy          dd ?        ; VDM-Handle of Session that owns this DMA-Slot
   ContextHookHndl  dd ?        ; Context-Hook-Handle for CopyEvent
   TriggerLastLeft  dd ?        ; Last current position during copy
   TriggerSize      dd ?        ; Size from LastPos, till we start copying again
   CopyPos          dd ?        ; Byte-Offset of last copy process
PDMAslotStruc                  EndS
PDMAslot_Length                  equ       64
PDMAslot_LengthShift             equ        6

; Wait-For-Trigger Description:
;===============================
; If this flag is set, VDMA engine will wait for specified trigger. Otherwise
;  it will call ProcessPCopyEvent on *every* Timer interrupt.
; Also ProcessPCopyEvent will change. When the flag is set, it will use CopyPos
;  for managing copy, otherwise it will use CurLength to calculate offset.

PDMAslot_Flags_ChannelEnabled    equ 00000001b ;Opposite of "masked"
PDMAslot_Flags_ChannelEnabledNOT equ 11111000b ;remove CallOut/Timed as well
PDMAslot_Flags_GetsCallOut       equ 00000010b
PDMAslot_Flags_TimedCallBack     equ 00000100b
PDMAslot_Flags_RapeFill          equ 00001000b
PDMAslot_Flags_RapeFillNOT       equ 11110111b
PDMAslot_Flags_InCopyEvent       equ 00010000b
PDMAslot_Flags_TerminalCount     equ 00100000b ;will get transfered to VDMA-Slot
PDMAslot_Flags_TerminalCountNOT  equ 11011111b

PDMAslot_Mode_TransferType       equ 00000011b
PDMAslot_Mode_AutoInit           equ 00000100b
PDMAslot_Mode_AddrDecrement      equ 00001000b
PDMAslot_Mode_Transfer           equ 00110000b

TimedCallBackHookStruc         Struc
   Duration        dd ?
   CurCountdown    dd ?
   CodePtr         dd ?
TimedCallBackHookStruc         EndS
TimedCallBackHook_Length         equ       12

; -----------------------------------------------------------------------------

Public TRIGGER_VTIMERReplacement

Public VDMA_VTIMERentry
Public VDMA_TimedCallBacks

Public VDMA_PDMAslots
Public VDMA_PDMAslot0,VDMA_PDMAslot1,VDMA_PDMAslot2,VDMA_PDMAslot3
Public VDMA_PDMAslot4,VDMA_PDMAslot5,VDMA_PDMAslot6,VDMA_PDMAslot7
Public VDMA_pPDMAslot0,VDMA_pPDMAslot1,VDMA_pPDMAslot2,VDMA_pPDMAslot3
Public VDMA_pPDMAslot4,VDMA_pPDMAslot5,VDMA_pPDMAslot6,VDMA_pPDMAslot7

Public PDMA_CopyEventOnDMAptr

Public VDMA_AllowedDMAOwnerFunc
Public VDMA_DMAOwnerFuncs

; -----------------------------------------------------------------------------

TRIGGER_VTIMERReplacement    dd  0       ; is set, if new VTIMER detected

VDMA_VTIMERentry             dd  0       ; Entry-Point of VTIMER$
VDMA_TimedCallBacks          dd  0       ; How many TimedCallbacks are active
VDMA_ForeignTimedHooks       dd  0       ; How many foreign Timed-Hooks active

; All DMA Channels per Instance-Data
VDMA_PDMAslots:
VDMA_PDMAslot0  PDMAslotStruc <0,0,0001b,87h,000h,001h,00Bh,00Ch,00Ah,00Fh,512,320,0,0,0,0,0,0>
VDMA_PDMAslot1  PDMAslotStruc <1,1,0010b,83h,002h,003h,00Bh,00Ch,00Ah,00Fh,512,384,0,0,0,0,0,0>
VDMA_PDMAslot2  PDMAslotStruc <2,2,0100b,81h,004h,005h,00Bh,00Ch,00Ah,00Fh,512,320,0,0,0,0,0,0>
VDMA_PDMAslot3  PDMAslotStruc <3,3,1000b,82h,006h,007h,00Bh,00Ch,00Ah,00Fh,512,320,0,0,0,0,0,0>
VDMA_PDMAslot4  PDMAslotStruc <4,0,0001b,8Fh,0C0h,0C2h,0D6h,0D8h,0D4h,0DEh,1024,640,0,0,0,0,0,0>
VDMA_PDMAslot5  PDMAslotStruc <5,1,0010b,8Bh,0C4h,0C6h,0D6h,0D8h,0D4h,0DEh,1024,640,0,0,0,0,0,0>
VDMA_PDMAslot6  PDMAslotStruc <6,2,0100b,89h,0C8h,0CAh,0D6h,0D8h,0D4h,0DEh,1024,640,0,0,0,0,0,0>
VDMA_PDMAslot7  PDMAslotStruc <7,3,1000b,8Ah,0CCh,0CEh,0D6h,0D8h,0D4h,0DEh,1024,640,0,0,0,0,0,0>

VDMA_pPDMAslot0 dd offset VDMA_PDMAslot0
VDMA_pPDMAslot1 dd offset VDMA_PDMAslot1
VDMA_pPDMAslot2 dd offset VDMA_PDMAslot2
VDMA_pPDMAslot3 dd offset VDMA_PDMAslot3
VDMA_pPDMAslot4 dd offset VDMA_PDMAslot4
VDMA_pPDMAslot5 dd offset VDMA_PDMAslot5
VDMA_pPDMAslot6 dd offset VDMA_PDMAslot6
VDMA_pPDMAslot7 dd offset VDMA_PDMAslot7

PDMA_CopyEventOnDMAptr dd offset PDMA_CopyEventOnDMA0, offset PDMA_CopyEventOnDMA1
                       dd offset PDMA_CopyEventOnDMA2, offset PDMA_CopyEventOnDMA3
                       dd offset PDMA_CopyEventOnDMA4, offset PDMA_CopyEventOnDMA5
                       dd offset PDMA_CopyEventOnDMA6, offset PDMA_CopyEventOnDMA7

; TimedHooks
VDMA_TimedHooks        TimedCallBackHookStruc 8 dup (<0,0,0>)

; This is set by VDD-API (DetectReplacement) and allows VDHRegisterDMAChannel
;  to register with a channel
VDMA_AllowedDMAOwnerFunc     dd  0

; Function-handlers of DMA channel owners (via VDHRegisterDMAChannel)
;  Registered DMA Channels won't be done physically, but 100% virtually
VDMA_DMAOwnerFuncs:
VDMA_DMAOwnerFunc0           dd  0
VDMA_DMAOwnerFunc1           dd  0
VDMA_DMAOwnerFunc2           dd  0
VDMA_DMAOwnerFunc3           dd  0
VDMA_DMAOwnerFunc4           dd  0
VDMA_DMAOwnerFunc5           dd  0
VDMA_DMAOwnerFunc6           dd  0
VDMA_DMAOwnerFunc7           dd  0
