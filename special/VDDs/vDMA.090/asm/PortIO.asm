
; "Masking" means in term of DMA - Disabling. Which means, if one masks
;  DMA-Channel 1, it will get disabled (for setup). When unmasked, it will
;  get enabled and DMA transfer will start.

Public VDMA_OutOnDMA
Public VDMA_InOnDMA

; -----------------------------------------------------------------------------

; This routine gets control, when a byte (AL) is OUTed to a DMA-port (DX)
VDMA_OutOnDMA                   Proc Near   Uses ebx ecx edx esi edi
;  int 3      ; FOR DEBUGGING!!!
   movzx   ebx, dl
   movzx   ebx, bptr [VDMA_Ports_ChannelTable+ebx]
   mov     esi, ebx
   and     ebx, 0F0h
   jz      VDMA_OOD_Nop
   and     esi, 007h
   shr     bl, 1                         ; BL = OpCode*8
   shl     esi, VDMAslot_LengthShift
   mov     ebx, [VDMA_Ports_FunctionTable+ebx+4]
   add     esi, offset VDMA_VDMAslots
   call    ebx
  VDMA_OOD_Nop:
   ret
VDMA_OutOnDMA                   EndP

; This routine gets control, when a byte (AL) is READ from a DMA-port (DX)
VDMA_InOnDMA                    Proc Near   Uses ebx ecx edx esi edi
   movzx   ebx, dl
   movzx   ebx, bptr [VDMA_Ports_ChannelTable+ebx]
   mov     esi, ebx
   and     ebx, 0F0h
   jz      VDMA_IOD_Nop
   and     esi, 007h
   shr     ebx, 1                        ; EBX = OpCode*8
   shl     esi, VDMAslot_LengthShift
   mov     ebx, [VDMA_Ports_FunctionTable+ebx]
   add     esi, offset VDMA_VDMAslots
;  push    edx ; FOR DEBUGGING!!!
      call    ebx
;  pop     edx
;  int 3
   ret
  VDMA_IOD_Nop:
   mov     al, 0FFh             ; Reply with 0FFh (std reply from empty ports)
   ret
VDMA_InOnDMA                    EndP

; The following routines will be called with ESI == Corresponding DMA-Slot

VDMA_Ports_NOP                  Proc Near
   mov     al, 0FFh             ; Standard reply from empty ports
   ret
VDMA_Ports_NOP                  EndP

; Any write clears Byte Flip-Flop for Address/CurPos-Registers
VDMA_Ports_ResetFlipFlop        Proc Near
   mov     ecx, 4
  VDMAPRFF_Loop:
      mov     [esi+VDMAslotStruc.FlipFlop], 0
      add     esi, VDMAslot_Length
   dec     ecx
   jnz     VDMAPRFF_Loop
   ret
VDMA_Ports_ResetFlipFlop        EndP

VDMA_Ports_InPage               Proc Near
   mov     al, bptr [esi+VDMAslotStruc.BaseAddress+2]
   ret
VDMA_Ports_InPage               EndP

VDMA_Ports_OutPage              Proc Near
   mov     bptr [esi+VDMAslotStruc.BaseAddress+2], al
   ret
VDMA_Ports_OutPage              EndP

; Flip-Flop Register
VDMA_Ports_InAddress            Proc Near
   mov     al, 0FFh
   ret
   test    [esi+VDMAslotStruc.FlipFlop], VDMAslot_FlipFlop_Address
   jnz     VDMAPIA_2ndByte
   call    VDMA_UpdateCurLength          ; Update current DMA Channel CurLength
   mov     al, bptr [esi+VDMAslotStruc.CurAddress]
   xor     [esi+VDMAslotStruc.FlipFlop], VDMAslot_FlipFlop_Address
   ret
  VDMAPIA_2ndByte:
   mov     al, bptr [esi+VDMAslotStruc.CurAddress]
   xor     [esi+VDMAslotStruc.FlipFlop], VDMAslot_FlipFlop_Address
   ret
VDMA_Ports_InAddress            EndP

; Flip-Flop Register
VDMA_Ports_OutAddress           Proc Near
   test    [esi+VDMAslotStruc.FlipFlop], VDMAslot_FlipFlop_Address
   jnz     VDMAPOA_2ndByte
   mov     bptr [esi+VDMAslotStruc.BaseAddress], al
   xor     [esi+VDMAslotStruc.FlipFlop], VDMAslot_FlipFlop_Address
   ret
  VDMAPOA_2ndByte:
   mov     bptr [esi+VDMAslotStruc.BaseAddress+1], al
   xor     [esi+VDMAslotStruc.FlipFlop], VDMAslot_FlipFlop_Address
   ret
VDMA_Ports_OutAddress           EndP

; Flip-Flop Register
VDMA_Ports_InCurLength          Proc Near
   test    [esi+VDMAslotStruc.FlipFlop], VDMAslot_FlipFlop_Length
   jnz     VDMAPICP_2ndByte
   call    VDMA_UpdateCurLength          ; Update current DMA Channel CurPos
   mov     al, bptr [esi+VDMAslotStruc.CurLength]
   xor     [esi+VDMAslotStruc.FlipFlop], VDMAslot_FlipFlop_Length
   ret
  VDMAPICP_2ndByte:
   mov     al, bptr [esi+VDMAslotStruc.CurLength+1]
   xor     [esi+VDMAslotStruc.FlipFlop], VDMAslot_FlipFlop_Length
   ret
VDMA_Ports_InCurLength          EndP

; Flip-Flop Register
VDMA_Ports_OutLength            Proc Near
   test    [esi+VDMAslotStruc.FlipFlop], VDMAslot_FlipFlop_Length
   jnz     VDMAPOL_2ndByte
   mov     bptr [esi+VDMAslotStruc.TransferLength], al
   xor     [esi+VDMAslotStruc.FlipFlop], VDMAslot_FlipFlop_Length
   ret
  VDMAPOL_2ndByte:
   mov     bptr [esi+VDMAslotStruc.TransferLength+1], al
   xor     [esi+VDMAslotStruc.FlipFlop], VDMAslot_FlipFlop_Length
   ret
VDMA_Ports_OutLength            EndP

; Single Mask Bit Register
;  Bit 0-1 - Current Channel
;  Bit 2   - 1-Set mask for channel, 0-Clear Mask (actually enable)
; Attention: If Mask is cleared we restart the Channel in any way, even if mask
;             was already cleared. This will fix Pandora Directive.
VDMA_Ports_OutMask              Proc Near
   movzx   ebx, al
   and     ebx, 03h
   shl     ebx, VDMAslot_LengthShift
   add     esi, ebx                      ; ESI - Pointer to selected DMA-Slot
   push    eax
      call    VDMA_UpdateCurLength       ; Update current DMA Channel CurLength
   pop     eax
   shr     al, 3
   jc      DisableChannel

  EnableChannel:
   test    [esi+VDMAslotStruc.Flags], VDMAslot_Flags_ChannelEnabled
   jz      CurrentlyDisabled
   MPush   <esi,edi>                     ; Stop Channel if already playing...
      push    esi
      call    VDMA_TransferStopped
      add     esp, 4
   MPop    <edi,esi>
  CurrentlyDisabled:
   MPush   <esi,edi>
      push    esi
         call    VDMA_TransferStarted
      add     esp, 4
   MPop    <edi,esi>
   ret

  DisableChannel:
   test    [esi+VDMAslotStruc.Flags], VDMAslot_Flags_ChannelEnabled
   jz      Done
   MPush   <esi,edi>
      push    esi
      call    VDMA_TransferStopped
      add     esp, 4
   MPop    <edi,esi>
  Done:
   ret
VDMA_Ports_OutMask              EndP

; Holds the status of 4 aligned DMA channels
;  Bit 0-3 -> Channel reached terminal count (which means is done with transfer)
;  Bit 4-7 -> Request pending (means in use)
VDMA_Ports_InStatus             Proc Near
   add     esi, VDMAslot_Length
   call    VDMA_UpdateCurLength          ; Update current DMA Channel CurLength
   sub     esi, VDMAslot_Length

   add     esi, 3*VDMAslot_Length
   xor     eax, eax
   mov     ecx, 4
  VDMAPIS_Loop:
      test    [esi+VDMAslotStruc.Flags], VDMAslot_Flags_TerminalCount
      jz      VDMAPIS_NoTerminalCount
      stc
     VDMAPIS_NoTerminalCount:
      rcl     al, 1
      test    [esi+VDMAslotStruc.Flags], VDMAslot_Flags_ChannelEnabled
      jz      VDMAPIS_IsDisabled
      stc
     VDMAPIS_IsDisabled:
      rcl     ah, 1
      ; Reset Terminal Count...
      and     [esi+VDMAslotStruc.Flags], VDMAslot_Flags_TerminalCountNOT
      sub     esi, VDMAslot_Length
   dec     ecx
   jnz     VDMAPIS_Loop
   shl     ah, 4
   or      al, ah                        ; Combine both 8-bit values
   ret
VDMA_Ports_InStatus             EndP

; Command Register
;  Bit 0 - Enable Mem2Mem DMA
;  Bit 1 - Enable Ch0 Address hold
;  Bit 2 - Disable controller (no-no)
;  Bit 3 - Compressed Timing Mode
;  Bit 4 - Enable rotating priority
;  Bit 5 - Extended Write Mode, (0-late write)
;  Bit 6 - DRQ Sensing - Active
;  Bit 7 - DACK Sensing - Active
VDMA_Ports_OutCommand           Proc Near
   ret
VDMA_Ports_OutCommand           EndP

; Write Request Register
;  Bit 0-1 - Current Channel
;  Bit 2   - 1-Set request bit for channel, 0-Reset request
VDMA_Ports_OutWriteRequest      Proc Near
   ret
VDMA_Ports_OutWriteRequest      EndP

; Mode Register
;  Bit 0-1 - Current Channel
;  Bit 2-3 - Transfer Type (00b-Verify, 01b-Write, 10b-Read(from Memory)
;  Bit 4   - Auto-Init Mode
;  Bit 5   - Address Decrement
;  Bit 6-7 - 00b-Demand Mode, 01b-Single, 10b-Block, 11b-Cascade
;   Single-Mode
VDMA_Ports_OutMode              Proc Near
   movzx   ebx, al
   and     ebx, 03h
   shl     ebx, VDMAslot_LengthShift
   add     esi, ebx                      ; ESI - Pointer to selected DMA-Slot
   shr     al, 2
   mov     [esi+VDMAslotStruc.Mode], al
   ret
VDMA_Ports_OutMode              EndP

; Replies the last byte passed through DMA (not emulated currently)
VDMA_Ports_InTemp               Proc Near
   mov     al, 0FFh
   ret
VDMA_Ports_InTemp               EndP

; Any OUT clears the controller (must be reinitialized)
VDMA_Ports_OutMasterClear       Proc Near
   ret
VDMA_Ports_OutMasterClear       EndP

; Clear Mask Register
;  Any OUT enables all 4 aligned channels
VDMA_Ports_OutClearMasks        Proc Near
   mov     ecx, 4
  VDMAPOCM_Loop:
      test    [esi+VDMAslotStruc.Flags], VDMAslot_Flags_ChannelEnabled
      jnz     VDMAPOCM_AlreadyEnabled
      MPush   <ecx,esi,edi>              ; Save important registers
         push    esi
            call    VDMA_TransferStarted
         add     esp, 4
      MPop    <edi,esi,ecx>
     VDMAPOCM_AlreadyEnabled:
      add     esi, VDMAslot_Length
   dec     ecx
   jnz     VDMAPOCM_Loop
   ret
VDMA_Ports_OutClearMasks        EndP

; Get Channel Masks (get mask of 4 aligned channels)
;  Bit 0 - Mask State of Channel +0
;  Bit 1 - Mask State of Channel +1
;  Bit 2 - Mask State of Channel +2
;  Bit 3 - Mask State of Channel +3
VDMA_Ports_InWriteMasks         Proc Near
   add     esi, 3*VDMAslot_Length
   xor     eax, eax
   mov     ecx, 4
  VDMAPIWM_Loop:
      test    [esi+VDMAslotStruc.Flags], VDMAslot_Flags_ChannelEnabled
      jnz     VDMAPIWM_ChannelEnabled
      stc
     VDMAPIWM_ChannelEnabled:
      rcl     eax, 1
      sub     esi, VDMAslot_Length
   dec     ecx
   jnz     VDMAPIWM_Loop
   ret
VDMA_Ports_InWriteMasks         EndP

; Set Channel Masks - Clear or mask all of the 4 aligned channels
;  Bit 0 - Mask Channel +0
;  Bit 1 - Mask Channel +1
;  Bit 2 - Mask Channel +2
;  Bit 3 - Mask Channel +3
VDMA_Ports_OutWriteMasks        Proc Near
   mov     ecx, 4
  VDMAPOWM_Loop:
      rcr     eax, 1
      jc      VDMAPOWN_ChannelDisable
     VDMAPOWN_ChannelEnable:
      test    [esi+VDMAslotStruc.Flags], VDMAslot_Flags_ChannelEnabled
      jnz     VDMAPOWN_AlreadyDone
      MPush   <eax,ecx,esi,edi>
         push    esi
            call    VDMA_TransferStarted
         add     esp, 4
      MPop    <edi,esi,ecx,eax>
      jmp     VDMAPOWN_AlreadyDone
     VDMAPOWN_ChannelDisable:
      test    [esi+VDMAslotStruc.Flags], VDMAslot_Flags_ChannelEnabled
      jz      VDMAPOWN_AlreadyDone
      MPush   <eax,ecx,esi,edi>
         push    esi
            call    VDMA_TransferStopped
         add     esp, 4
      MPop    <edi,esi,ecx,eax>
     VDMAPOWN_AlreadyDone:
      add     esi, VDMAslot_Length
   dec     ecx
   jnz     VDMAPOWM_Loop
   ret
VDMA_Ports_OutWriteMasks        EndP
