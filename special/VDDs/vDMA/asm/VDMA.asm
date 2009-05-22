
Public VDMA_TellDMAOwnerStart
Public VDMA_TellDMAOwnerStop

; -----------------------------------------------------------------------------

VDMA_TellDMAOwnerStart          Proc Near   Uses ebx ecx edx esi edi, VDMAptr:dword
   mov     esi, VDMAptr
   mov     eax, [esi+VDMAslotStruc.OwnerFunc]
   or      eax, eax
   jz      NoFunc
   push    0
   push    VDMAAPI_EVENT_VIRTUALSTART
   movzx   edx, [esi+VDMAslotStruc.Mode]
   push    edx
   push    [esi+VDMAslotStruc.BaseAddress]
   push    [esi+VDMAslotStruc.TransferSize]
   call    eax
  NoFunc:
   ret
VDMA_TellDMAOwnerStart          EndP

VDMA_TellDMAOwnerStop           Proc Near   Uses ebx ecx edx esi edi, VDMAptr:dword
   mov     esi, VDMAptr
   push    0
   push    VDMAAPI_EVENT_VIRTUALSTOP
   push    0
   push    0
   push    0
   call    [esi+VDMAslotStruc.OwnerFunc]
   ret
VDMA_TellDMAOwnerStop           EndP

; Will update VDMA.TempDMAleft and VDMA.TransferLeft
;  may only be called by routines from PortIO.asm
;  expects SI == requested VDMA-Slot
VDMA_UpdateTransferLeft         Proc Near
   test    [esi+VDMAslotStruc.Flags], VDMAslot_Flags_ChannelEnabled
   jnz     ChannelEnabled
   mov     ax, 0FFFFh
   jmp     Done

  ChannelEnabled:
   test    [esi+VDMAslotStruc.Flags], VDMAslot_Flags_ChannelIsVirtual
   jnz     ChannelIsVirtual
      push    [esi+VDMAslotStruc.PhysicalSlotPtr]
      call    PDMA_UpdateTransferLeft
      add     esp, 4
      jmp     ProcessCurPos

     ChannelIsVirtual:
      push    esi
         push    0
         push    VDMAAPI_EVENT_VIRTUALGETPOS
         push    0
         push    0
         push    0
         call    [esi+VDMAslotStruc.OwnerFunc]
      pop     esi

  ProcessCurPos:
   ; EAX - Bytes left for transfer (real BYTE count!)
   ;  Bit 31 means terminal count encountered, this will only be reported
   ;                once
   mov     [esi+VDMAslotStruc.TransferLeft], eax
   and     [esi+VDMAslotStruc.TransferLeft], 7FFFFFFFh
   test    eax, 80000000h
   jz      NoTerminalCount
   or      [esi+VDMAslotStruc.Flags], VDMAslot_Flags_TerminalCount
   test    [esi+VDMAslotStruc.Mode], VDMAslot_Mode_AutoInit
   jnz     NoTerminalCount
   ; And disable Channel, when using SingleInit-Mode...
   push    eax
      push    esi            ; ESI-VMDA-Slot, is Parameter for TransferStop
      call    VDMA_TransferStopped
      pop     esi            ; we restore the register instead of add esp,4
   pop     eax
  NoTerminalCount:
   ; Now create TempDMAleft (DMA remaining bytes)
   cmp     [esi+VDMAslotStruc.DMAno], 4
   jb      Is8BitChannel
   shr     eax, 1                        ; WORD instead of BYTE size
  Is8BitChannel:
   dec     eax                           ; 0 means 1 byte, FFFFh means 0

  Done:
   mov     [esi+VDMAslotStruc.TempDMAleft], ax
   ret
VDMA_UpdateTransferLeft         EndP
