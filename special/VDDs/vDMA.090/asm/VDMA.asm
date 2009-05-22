
; -----------------------------------------------------------------------------

; Will update VDMA.CurLength, may only be called by routines from PortIO.asm
;  Expects SI == requested VDMA-Slot
VDMA_UpdateCurLength            Proc Near
   test    [esi+VDMAslotStruc.Flags], VDMAslot_Flags_ChannelEnabled
   jz      Done
      test    [esi+VDMAslotStruc.Flags], VDMAslot_Flags_ChannelVirtual
      jnz     ProcessCurPos
         push    [esi+VDMAslotStruc.PhysicalSlotPtr]
         call    PDMA_UpdateCurLength
         add     esp, 4
         jmp     ProcessCurPos

     ProcessCurPos:
      ; AX - DMA-Count of how many bytes left,
      ;  Bit 16 of EAX -> Terminal Count was experienced (goes into VDMA-Slot)
      mov     [esi+VDMAslotStruc.CurLength], ax
      shr     eax, 17           ; Shifting Terminal Count into Carry
      jnc     NoTerminalCount      
      or      [esi+VDMAslotStruc.Flags], VDMAslot_Flags_TerminalCount
      test    [esi+VDMAslotStruc.Mode], VDMAslot_Mode_AutoInit
      jnz     NoTerminalCount
      ; And disable Channel, when using SingleInit-Mode...
      push    esi               ; ESI-VMDA-Slot, is Parameter for TransferStop
         call    VDMA_TransferStopped
      pop     esi               ; we restore the register instead of add esp,4
     NoTerminalCount:
  Done:
   ret
VDMA_UpdateCurLength            EndP
