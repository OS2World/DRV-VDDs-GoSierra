; About this SB emulation VDD:
;==============================
;
; The whole emulation is *hard-coded* to settings 220h-22Fh (ports), IRQ 5 and
;  DMA 1/DMA 5. This was done, because there are no hardware conflicts in VDM
;  and for ease of assembly programming.
;
; All I/O hooks are done in 100% assembly for speed. Calls to DTA are done using
;  C subroutines.
;
; --------------------------------------------------------------------------

extern VDM_RaiseVIRQ:near
extern VDM_RaiseDetectionVIRQ:near

extern VDM_PlaybackBuffer:near
extern DebugBeep:near

Public SBemu_InitVars                    ; Initializes Variables
Public SBemulationSwitch                 ; Variable to toogle Emulation

Public InVIRQDetection
Public InVIRQDetectionCounter

Public SBoutputRate
Public SBoutputFlags
Public SBoutputLength
Public SBoutputDMApos

;  Port-Emulation Routines:
; ==========================
Public SBemu_OutOnSB                     ; Emulate for OUT on SB
Public SBemu_InOnSB                      ; Emulate for IN  on SB
Public SBemu_OutOnDMA                    ; Emulate for OUT on DMA
Public SBemu_InOnDMA                     ; Emulate for IN  on DMA

db 'This code is (c) 2002, Copyright by Martin Kiewitz. All rights reserved.', 0

SBemu_InitVars               Proc Near
   mov       edi, offset InstanceData
   mov       ecx, offset InstanceDataEnd-offset InstanceData
   xor       al, al
   rep       stosb             ; NULs out InstanceData-Area
   mov       esi, offset MixerChipDefaults
   mov       edi, offset SBmixerData
   mov       ecx, 64
   rep       movsd
   ; Initialize Read-Port to have AAh ready (DSP-initialized)
   mov       al, 0AAh
   mov       byte ptr [SBreadQueue], al
   mov       eax, 1
   mov       SBreadLength, eax ; 1 byte to read - 0AAh
   ret
SBemu_InitVars               EndP

; =============================================================================
;  Port Emulation is hard-coded to ports 220h-22Fh.

; This routine outs virtually a byte (AL) to Port (DX)
SBemu_OutOnSB                Proc Near   Uses ebx
   mov       InVIRQDetection, 0
   ; First, check for what Port that byte is for:
   cmp       dx, 224h
   je        SBemu_OOSB_MixerAddress
   cmp       dx, 225h
   je        SBemu_OOSB_MixerData
   cmp       dx, 226h
   je        SBemu_OOSB_ResetPort
   cmp       dx, 22Ch
   je        SBemu_OOSB_DataPort
   ; Write to a not-used/not-supported port, so simply ignore it
  SBemu_OOSB_Ignore:
   ret

   ; Mixer-Address Port - Write -> Remember for access to data-port
  SBemu_OOSB_MixerAddress:
   mov       byte ptr [SBmixerRegister], al
   ret

  SBemu_OOSB_MixerData:
   mov       ebx, SBmixerRegister
   mov       byte ptr [SBmixerData+ebx], al
   ret

   ; Reset-Port - Write =! 0 -> remember
   ;              Write == 0 -> if something rememberd, put 0AAh to In-Queue
  SBemu_OOSB_ResetPort:
   or        al, al
   jz        SBemu_OOSB_ResetBegin
   mov       SBreset, al       ; Remember, if something >0
   ret

  SBemu_OOSB_ResetBegin:
   mov       al, SBreset
   or        al, al
   jz        SBemu_OOSB_Ignore
   ; Okay, there was a write >0, so put AAh into Read-Queue
   mov       al, 0AAh
   mov       byte ptr [SBreadQueue], al
   xor       eax, eax
   mov       SBreadPos, eax
   mov       SBreset, al
   inc       eax
   mov       SBreadLength, eax ; 1 byte to read - 0AAh
   ret

   ; Data-Port - first byte is opcode, then wait for the required data and
   ;              call directly to function handler.
  SBemu_OOSB_DataPort:
   mov       ebx, SBwritePos
   ; Add this byte to Write-Queue
   mov       byte ptr [SBwriteQueue+ebx], al ; Put byte onto Write-Queue
   or        ebx, ebx
   jnz       SBemu_OOSB_NoOpCode
   ; Get Total-Length from OpCode
   push      ebx
      movzx     ebx, al
      and       ebx, 0F0h
      shr       ebx, 1
      call      [SBemu_CommandHelperTable+ebx]
   pop       ebx
   mov       SBwriteLength, eax
  SBemu_OOSB_NoOpCode:
   inc       ebx
   cmp       ebx, SBwriteLength
   jbe       SBemu_OOSB_NotYetExec
   ; Execute OpCode via CommandHelperTable
   mov       al, byte ptr [SBopcode]
   movzx     ebx, al
   and       ebx, 0F0h
   shr       ebx, 1
   call      [SBemu_CommandHelperTable+ebx+4] ; AL = OpCode
   xor       ebx, ebx          ; Reset SBwritePos for next OpCode
  SBemu_OOSB_NotYetExec:
   mov       SBwritePos, ebx
   ret
SBemu_OutOnSB                EndP

; This routine inputs virtually a byte (AL) from Port (DX)
SBemu_InOnSB                 Proc Near   Uses ebx
   test      SBemulationSwitch, 1
   jz        SBemu_IOSB_Ignore
   test      InVIRQDetection, 1
   jz        SBemu_IOSB_NoVIRQdetectionPending

   inc       InVIRQDetectionCounter
   cmp       InVIRQDetectionCounter, 10
   jb        SBemu_IOSB_NoVIRQdetectionPending
   push      eax
   push      edx
      call      VDM_RaiseVIRQ
   pop       edx
   pop       eax

  SBemu_IOSB_NoVIRQdetectionPending:
   ; First, check for what Port to Input:
   cmp       dx, 224h
   je        SBemu_IOSB_MixerAddress
   cmp       dx, 225h
   je        SBemu_IOSB_MixerData
   cmp       dx, 22Ah
   je        SBemu_IOSB_ReadPort
   cmp       dx, 22Ch
   je        SBemu_IOSB_WriteReadyPort
   cmp       dx, 22Eh
   je        SBemu_IOSB_DataAvailPort
   ja        SBemu_IOSB_DataAvailPort ; 22Fh
   ; Read to not-used/not-supported port, so simply ignore it
  SBemu_IOSB_Ignore:
   mov       al, 0FFh
   ret

  SBemu_IOSB_MixerAddress:
   mov       al, byte ptr [SBmixerRegister]
   ret

  SBemu_IOSB_MixerData:
   mov       ebx, SBmixerRegister
   mov       al, byte ptr [SBmixerData+ebx]
   ret

  SBemu_IOSB_ReadPort:
   mov       ecx, SBreadLength ; Ignore any reads, when nothing in Read-Queue
   or        ecx, ecx
   jz        SBemu_IOSB_Ignore
   mov       ebx, SBreadPos    ; EBX - ReadPos, ECX - Length
   mov       al, byte ptr [SBreadQueue+ebx] ; Get Byte from Read-Queue
   inc       ebx
   cmp       ebx, ecx          ; If our length equals the Next-Position stay
   jae       SBemu_IOSB_StayAtPos
   mov       SBreadPos, ebx
  SBemu_IOSB_StayAtPos:
   ret

  SBemu_IOSB_WriteReadyPort:
   mov       al, 7Fh           ; We are ready anytime for any data :-)
   ret

   ; This here functions as IRQ-Acknowledge as well
  SBemu_IOSB_DataAvailPort:
   jmp       SBemu_IOSB_Ignore
;   mov       ecx, SBreadLength ; Reply FFh, if nothing in Read-Queue
;   or        ecx, ecx          ; Checking Length is correct, because the org. SB
;   jnz       SBemu_IOSB_Ignore  ; stays on the last value it returned
;   mov       al, 7Fh
;   ret
SBemu_InOnSB                 EndP

SBemu_OutOnDMA               Proc Near
   ret
SBemu_OutOnDMA               EndP

SBemu_InOnDMA                Proc Near   Uses ebx
   xor       SBoutputDMAflipflop, 1
   jz        SBemu_IODMA_SecondAccess
   ; First-Access on Port
   mov       al, byte ptr [SBoutputDMApos+0]
   ret

  SBemu_IODMA_SecondAccess:
   ; Second-Access on Port
   mov       al, byte ptr [SBoutputDMApos+1]
   mov       ecx, SBoutputDMApos
   sub       ecx, 50
   jno       SBemu_IODMA_NoOverflow
   xor       ecx, ecx
  SBemu_IODMA_NoOverflow:
   mov       SBoutputDMApos, ecx
   ret
SBemu_InOnDMA                EndP


; ======================================
;  SoundBlaster Commands - DMA PlayBack
; ======================================

SBemu_ExeStartLowSpeedDMA8bit:                              ; length:WORD - 14h
   movzx      eax, word ptr [SBparameters]
   inc        eax
   mov        SBoutputLength, eax
   xor        ax, ax                     ; Normal, 8-Bit, Mono, Unsigned
   mov        SBoutputFlags, ax
   call       SBemu_ExeStartSBplayback
   ret

SBemu_ExeStartLowSpeedAutoInitDMA8bit:                                    ; 1Ch
   mov        ax, SBoutputFlag_AutoInit  ; Auto-Init, 8-Bit, Mono, Unsigned
   mov        SBoutputFlags, ax
   call       SBemu_ExeStartSBplayback
   ret

SBemu_ExeStartHiSpeedDMA8bit:                                             ; 91h
   xor        ax, ax                     ; Normal, 8-Bit, Unsigned
   ; Check, if stereo shall be used by looking at Mixer-Register 0Eh - Bit 1
   mov        dl, byte ptr [SBmixerData+0Eh]
   test       dl, 02h                    ; Test for Bit 1
   jz         SBemu_ESHSDMA8_Mono
   or         ax, SBoutputFlag_Stereo
  SBemu_ESHSDMA8_Mono:
   mov        SBoutputFlags, ax
   call       SBemu_ExeStartSBplayback
   ret

SBemu_ExeStartHiSpeedAutoInitDMA8bit:                                     ; 90h
   mov        ax, SBoutputFlag_AutoInit  ; Auto-Init, 8-Bit, Unsigned
   ; Check, if stereo shall be used by looking at Mixer-Register 0Eh - Bit 1
   mov        dl, byte ptr [SBmixerData+0Eh]
   test       dl, 02h                    ; Test for Bit 1
   jz         SBemu_ESHSAIDMA8_Mono
   or         ax, SBoutputFlag_Stereo
  SBemu_ESHSAIDMA8_Mono:
   mov        SBoutputFlags, ax
   call       SBemu_ExeStartSBplayback
   ret

SBemu_ExeStartExtDMA16bit:                       ; Mode:BYTE, Length:WORD - Byh
   mov        dx, SBoutputFlag_16bit     ; 16-Bit !
   mov        ah, byte ptr [SBparameters]
   ; OpCode is in AX (AL-OpCode, AH-Mode)
   test       al, 00000100b              ; Auto-Init ?
   jz         SBemu_ESEDMA16_NormalDMA
   or         dx, SBoutputFlag_AutoInit
  SBemu_ESEDMA16_NormalDMA:
   test       ah, 00100000b              ; Stereo ?
   jz         SBemu_ESEDMA16_Mono
   or         dx, SBoutputFlag_Stereo
  SBemu_ESEDMA16_Mono:
   test       ah, 00010000b              ; Signed ?
   jz         SBemu_ESEDMA16_Unsigned
   or         dx, SBoutputFlag_Signed
  SBemu_ESEDMA16_Unsigned:
   mov        SBoutputFlags, dx
   movzx      edx, word ptr [SBparameters+1]
   inc        edx
   mov        SBoutputLength, edx
   test       al, 00001000b              ; Record ?
   jnz        SBemu_ESEDMA16bit_RecordMode
   jmp        SBemu_ExeStartSBplayback
  SBemu_ESEDMA16bit_RecordMode:
   ret

SBemu_ExeStartExtDMA8bit:                        ; Mode:BYTE, Length:WORD - Cyh
   xor        dx, dx                     ; 8-Bit !
   mov        ah, byte ptr [SBparameters]
   ; OpCode is in AX (AL-OpCode, AH-Mode)
   test       al, 00000100b              ; Auto-Init ?
   jz         SBemu_ESEDMA8_NormalDMA
   or         dx, SBoutputFlag_AutoInit
  SBemu_ESEDMA8_NormalDMA:
   test       ah, 00100000b              ; Stereo ?
   jz         SBemu_ESEDMA8_Mono
   or         dx, SBoutputFlag_Stereo
  SBemu_ESEDMA8_Mono:
   test       ah, 00010000b              ; Signed ?
   jz         SBemu_ESEDMA8_Unsigned
   or         dx, SBoutputFlag_Signed
  SBemu_ESEDMA8_Unsigned:
   mov        SBoutputFlags, dx
   movzx      edx, word ptr [SBparameters+1]
   inc        edx
   mov        SBoutputLength, edx
   test       al, 00001000b              ; Record ?
   jnz        SBemu_ESEDMA8bit_RecordMode
   jmp        SBemu_ExeStartSBplayback
  SBemu_ESEDMA8bit_RecordMode:
   ret

SBemu_ExeSetSampleRate:                                    ; divisor:BYTE - 40h
   movzx      cx, byte ptr [SBparameters]
   not        cx
   xor        ax, ax
   or         cx, cx
   jz         SBemu_ESSR_BlankDivisor
   mov        ax, 4240h
   mov        dx, 0Fh
   div        cx
  SBemu_ESSR_BlankDivisor:
   mov        SBoutputRate, ax ; 44 khz -> 43478
   ret

SBemu_ExeSetExtSampleRate:                 ; Sample-Rate:WORD (non-intel) - 41h
   ; for Commands Bxh & Cxh -> Output only
   mov        ax, word ptr [SBparameters]
   xchg       al, ah           ; <- To Intel-Order
   mov        SBoutputRate, ax
   ret

SBemu_ExeSetTransferLength:                         ; TransferLength:WORD - 48h
   ; for Commands 1Ch, 90h, 91h, 99h
   movzx      eax, word ptr [SBparameters]
   inc        eax
   mov        SBoutputLength, eax
   ret

; This is called, when apps execute SB-Playback...
SBemu_ExeStartSBplayback:
   ; Reset DMA-CurPos
   mov        eax, SBoutputLength
   mov        SBoutputDMApos, eax

   cmp        eax, 512
   jb         SBemu_ESSBPB_NulBuffer
   call       VDM_PlaybackBuffer
   ret
   ; On NUL-buffers, ONLY raise IRQ. Is used by some games to detect IRQ...
  SBemu_ESSBPB_NulBuffer:
   call      VDM_RaiseDetectionVIRQ
   ret

; ==============================================
;  SoundBlaster Commands - Detect/Version Stuff
; ==============================================

SBemu_ExeGetDSPid:                                          ; tstval:BYTE - E0h
   mov       al, byte ptr [SBparameters]
   not       al
   mov       byte ptr [SBreadQueue], al
   mov       eax, 1
   jmp       SBemu_ExeResetReadQueue

SBemu_ExeGetDSPversion:                                                   ; E1h
   mov       eax, 4B4D1004h    ; Version-Number -> 4.16 and magic MK
   mov       dword ptr [SBreadQueue], eax
   mov       eax, 4
   jmp       SBemu_ExeResetReadQueue

SBemu_ExeGetDSPid2:                                         ; magics:WORD - E4h
   mov       ax, word ptr [SBparameters]
   cmp       ax, 0E8AAh        ; Hard-Coded Magic
   je        SBemu_EGDSPid2_GotIt
   ret
  SBemu_EGDSPid2_GotIt:
   mov       al, 0AAh
   mov       byte ptr [SBreadQueue], al
   mov       eax, 1
   jmp       SBemu_ExeResetReadQueue

SBemu_RaiseIRQline:                                                       ; F2h
   call      VDM_RaiseDetectionVIRQ
   ret
   
; -----------------------------------------------------------------------------
SBemu_ExeResetReadQueue:
   mov       SBreadLength, eax
   xor       eax, eax
   mov       SBreadPos, eax
   ret

SBemu_CommandHelperTable:
   dd offset SBemu_CommandNop,    offset SBemu_CommandNop
   dd offset SBemu_CommandLen10,  offset SBemu_CommandExe10
   dd offset SBemu_CommandLen20,  offset SBemu_CommandExe20
   dd offset SBemu_CommandNop,    offset SBemu_CommandNop
   dd offset SBemu_CommandLen40,  offset SBemu_CommandExe40
   dd offset SBemu_CommandNop,    offset SBemu_CommandNop
   dd offset SBemu_CommandNop,    offset SBemu_CommandNop
   dd offset SBemu_CommandLen70,  offset SBemu_CommandExe70
   dd offset SBemu_CommandLen80,  offset SBemu_CommandExe80
   dd offset SBemu_CommandNop,    offset SBemu_CommandExe90
   dd offset SBemu_CommandNop,    offset SBemu_CommandNop
   dd offset SBemu_CommandLenIs3, offset SBemu_CommandExeB0
   dd offset SBemu_CommandLenIs3, offset SBemu_CommandExeC0
   dd offset SBemu_CommandNop,    offset SBemu_CommandExeD0
   dd offset SBemu_CommandLenE0,  offset SBemu_CommandExeE0
   dd offset SBemu_CommandNop,    offset SBemu_CommandExeF0

SBemu_CommandNop:
   xor       eax, eax
   ret
SBemu_CommandLenIs1:
   mov       eax, 1
   ret
SBemu_CommandLenIs2:
   mov       eax, 2
   ret
SBemu_CommandLenIs3:
   mov       eax, 3
   ret

SBemu_CommandLen10:
   cmp       al, 10h
   je        SBemu_CommandLenIs1
   cmp       al, 14h
   je        SBemu_CommandLenIs2
   cmp       al, 17h
   je        SBemu_CommandLenIs2
   jmp       SBemu_CommandNop
SBemu_CommandExe10:
   cmp       al, 14h
   je        SBemu_ExeStartLowSpeedDMA8bit
   cmp       al, 1Ch
   je        SBemu_ExeStartLowSpeedAutoInitDMA8bit
   ret
SBemu_CommandLen20:
   cmp       al, 24h
   je        SBemu_CommandLenIs2
   jmp       SBemu_CommandNop
SBemu_CommandExe20:
   ret
SBemu_CommandLen40:
   cmp       al, 41h
   jb        SBemu_CommandLenIs1
   je        SBemu_CommandLenIs2
   cmp       al, 42h
   je        SBemu_CommandLenIs2
   cmp       al, 48h
   je        SBemu_CommandLenIs2
   jmp       SBemu_CommandNop
SBemu_CommandExe40:
   cmp       al, 41h
   jb        SBemu_ExeSetSampleRate
   je        SBemu_ExeSetExtSampleRate
   cmp       al, 48h
   je        SBemu_ExeSetTransferLength
   ret
SBemu_CommandLen70:
   cmp       al, 74h
   je        SBemu_CommandLenIs2
   cmp       al, 77h
   je        SBemu_CommandLenIs2
   jmp       SBemu_CommandNop
SBemu_CommandExe70:
   ret
SBemu_CommandLen80:
   cmp       al, 80h
   je        SBemu_CommandLenIs2
   jmp       SBemu_CommandNop
SBemu_CommandExe80:
   ret
SBemu_CommandExe90:
   cmp       al, 91h
   jb        SBemu_ExeStartHiSpeedAutoInitDMA8bit
   je        SBemu_ExeStartHiSpeedDMA8bit
   ret
SBemu_CommandExeB0:
   jmp       SBemu_ExeStartExtDMA16bit
SBemu_CommandExeC0:
   jmp       SBemu_ExeStartExtDMA8bit
SBemu_CommandExeD0:
   ret
SBemu_CommandLenE0:
   cmp       al, 0E0h
   je        SBemu_CommandLenIs1
   cmp       al, 0E4h
   je        SBemu_CommandLenIs2
   jmp       SBemu_CommandNop
SBemu_CommandExeE0:            ; =IMPLEMENTATION DONE=
   cmp       al, 0E1h
   jb        SBemu_ExeGetDSPid
   je        SBemu_ExeGetDSPversion
   cmp       al, 0E4h
   je        SBemu_ExeGetDSPid2
   ret
SBemu_CommandExeF0:
   cmp       al, 0F2h
   je        SBemu_RaiseIRQline
   ret
