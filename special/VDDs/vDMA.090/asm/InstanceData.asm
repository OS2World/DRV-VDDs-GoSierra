VDMAslotStruc                  Struc
   DMAno           db ?         ; DMA Channel Number
   Flags           db ?         ; Bit 0   - Channel Enabled
                                ; Bit 1   - Channel is physical
                                ; Bit 2   - Terminal Count
                                ; Bit 6   - Channel Registered by VDD
                                ; Bit 7   - Channel Virtualized
   FlipFlop        db ?         ; Bit 0   - Flip-Flop Address
                                ; Bit 1   - Flip-Flop Length
                                ; bit 2   - Flip-Flop CurPos
   Mode            db ?         ; Bit 0-1 - Transfer Type
                                ; Bit 2   - Auto-Init Mode
                                ; Bit 3   - Address decrement
                                ; Bit 4-5 - Transfer Mode
   PhysicalSlotPtr dd ?         ; Pointer to corresponding PDMA-Slot
   BaseAddress     dd ?         ; Virtual Base-Address (Byte3=Page)
   TransferLength  dw ?         ; DMA-Length of Block
   CurLength       dw ?         ; Remaining Length in Block
   CurAddress      dw ?
   Filler1         dw ?
   Filler2         dd ?
   Filler3         dd ?
   Filler4         dd ?
VDMAslotStruc                  EndS

VDMAslot_Length                  equ       32
VDMAslot_LengthShift             equ        5

VDMAslot_Flags_ChannelEnabled    equ 00000001b ;Opposite of "masked"
VDMAslot_Flags_ChannelEnabledNOT equ 11111100b ;Will reset IsPhysical as well
VDMAslot_Flags_ChannelIsPhysical equ 00000010b
VDMAslot_Flags_TerminalCount     equ 00000100b
VDMAslot_Flags_TerminalCountNOT  equ 11111011b
VDMAslot_Flags_ChannelRegistered equ 01000000b
VDMAslot_Flags_ChannelVirtual    equ 10000000b

VDMAslot_FlipFlop_Address        equ 00000001b
VDMAslot_FlipFlop_Length         equ 00000010b

VDMAslot_Mode_TransferType       equ 00000011b
VDMAslot_Mode_AutoInit           equ 00000100b
VDMAslot_Mode_AddrDecrement      equ 00001000b
VDMAslot_Mode_Transfer           equ 00110000b

; -----------------------------------------------------------------------------

Public CurVDMHandle

Public VDMA_VDMAslots
Public VDMA_VDMAslot0,VDMA_VDMAslot1,VDMA_VDMAslot2,VDMA_VDMAslot3
Public VDMA_VDMAslot4,VDMA_VDMAslot5,VDMA_VDMAslot6,VDMA_VDMAslot7

; -----------------------------------------------------------------------------

CurVDMHandle                    dd ?         ; Current VDM Handle

; All DMA Channels per Instance-Data
VDMA_VDMAslots:
VDMA_VDMAslot0                  VDMAslotStruc <?,?,?,?,?,?,?>
VDMA_VDMAslot1                  VDMAslotStruc <?,?,?,?,?,?,?>
VDMA_VDMAslot2                  VDMAslotStruc <?,?,?,?,?,?,?>
VDMA_VDMAslot3                  VDMAslotStruc <?,?,?,?,?,?,?>
VDMA_VDMAslot4                  VDMAslotStruc <?,?,?,?,?,?,?>
VDMA_VDMAslot5                  VDMAslotStruc <?,?,?,?,?,?,?>
VDMA_VDMAslot6                  VDMAslotStruc <?,?,?,?,?,?,?>
VDMA_VDMAslot7                  VDMAslotStruc <?,?,?,?,?,?,?>
