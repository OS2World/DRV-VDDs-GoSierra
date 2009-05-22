
Public VSOUND_OutOnSB
Public VSOUND_InOnSB

; -----------------------------------------------------------------------------

; This routine gets control, when a byte (AL) is OUTed to a SB-port (DX)
;  BX points to ClientRegisterFrame
VSOUND_OutOnSB                  Proc Near   Uses ebx ecx edx esi edi
   mov     esi, ebx             ; SI = ClientRegisterFrame
;   MPush   <eax,ebx,ecx,edx,esi,edi>
;      and     eax, 0FFh
;      push    eax
;      push    edx
;      push    offset CONST_Debug_PortOut
;      call    DebugPrintF
;      add     esp, 12
;   MPop    <edi,esi,edx,ecx,ebx,eax>

   ; Now give control to Port-Worker...
   mov     ebx, edx
   and     ebx, 000Fh
   shl     ebx, 3                        ; EBX = xxFh * 8
   mov     ebx, [VSOUND_Ports_FunctionTable+ebx+4]
   call    ebx
   ret
VSOUND_OutOnSB                  EndP

; This routine gets control, when a byte (AL) is READ from a SB-port (DX)
;  BX points to ClientRegisterFrame
VSOUND_InOnSB                   Proc Near   Uses ebx ecx edx esi edi
;   MPush   <eax,ebx,ecx,edx,esi,edi>
;      push    edx
;      push    offset CONST_Debug_PortIn
;      call    DebugPrintF
;      add     esp, 8
;   MPop    <edi,esi,edx,ecx,ebx,eax>

   ; Now give control to Port-Worker...
   mov     ebx, edx
   and     ebx, 000Fh
   shl     ebx, 3                        ; EBX = xxFh * 8
   mov     ebx, [VSOUND_Ports_FunctionTable+ebx+0]
   call    ebx
   ret
VSOUND_InOnSB                   EndP

; -----------------------------------------------------------------------------
;  Workers
; -----------------------------------------------------------------------------

VSOUND_Ports_InNOP              Proc Near
   mov     al, 0FFh                      ; Standard reply from empty ports
   ret
VSOUND_Ports_InNOP              EndP

VSOUND_Ports_OutNOP             Proc Near
   ; Write to a not-used/not-supported port, so simply ignore it
   ret
VSOUND_Ports_OutNOP             EndP

; -----------------------------------------------------------------------------
; Mixer-Address Port - Write -> Remember for access to data-port
VSOUND_Ports_OutMixerAddress    Proc Near
   mov     bptr [SBmixerRegister], al
   ret
VSOUND_Ports_OutMixerAddress    EndP

; -----------------------------------------------------------------------------
VSOUND_Ports_OutMixerData       Proc Near
   mov     ebx, SBmixerRegister
   mov     byte ptr [SBmixerData+ebx], al
   ret
VSOUND_Ports_OutMixerData       EndP

; --------------------------------------------------------------------------
; Reset-Port - Write =! 0 -> remember
;              Write == 0 -> if something rememberd, put 0AAh to In-Queue
VSOUND_Ports_OutReset           Proc Near
   or      al, al
   jz      VSOUNDPOR_ResetBegin
   mov     SBreset, al                 ; Remember, if something >0
   ret
  VSOUNDPOR_ResetBegin:
   mov     al, SBreset
   or      al, al
   jz      VSOUND_Ports_OutNOP
   ; Okay, there was a write >0, so put AAh into Read-Queue
   mov     al, 0AAh
   mov     byte ptr [SBreadQueue], al
   xor     eax, eax
   mov     SBreadPos, eax
   mov     SBreset, al
   inc     eax
   mov     SBreadLength, eax ; 1 byte to read - 0AAh
   ret
VSOUND_Ports_OutReset           EndP

; -----------------------------------------------------------------------------
; Data-Port - first byte is opcode, then wait for the required data and
;              call directly to function handler.
VSOUND_Ports_OutData            Proc Near
   mov     ebx, SBwritePos
   ; Add this byte to Write-Queue
   mov     byte ptr [SBwriteQueue+ebx], al ; Put byte onto Write-Queue
   or      ebx, ebx
   jnz     IsData
   ; Get Total-Length from OpCode
   push    ebx
      movzx   eax, al
      mov     ebx, eax
      and     ebx, 0F0h                ; EBX = Upper 4 Bits
      and     eax, 00Fh                ; EAX = Lower 4 Bits
      shr     ebx, 2                   ; Get Upper 4-bits, divide by 4
      mov     ebx, [VSOUND_Ports_CMDlengthTable+ebx]
      add     ebx, eax
      movzx   eax, byte ptr [ebx]
   pop     ebx
   mov     SBwriteLength, eax
  IsData:
   inc     ebx
   cmp     ebx, SBwriteLength
   jbe     NotYetExec
   ; Execute OpCode via CommandHelperTable
   movzx   eax, bptr [SBopcode]
   mov     ebx, eax
   push    eax
      and     ebx, 0FCh
      and     eax, 003h
      mov     ebx, [VSOUND_Ports_CMDfuncTable+ebx]
      shl     eax, 2                   ; Multiply * 4
      add     ebx, eax
      mov     ebx, [ebx]               ; EBX = from VSOUND_Ports_CMDFuncXXX
   pop     eax
   or      ebx, ebx
   jz      NoOperation
   call    ebx                         ; AL = OpCode
  NoOperation:
   xor     ebx, ebx                    ; Reset SBwritePos for next OpCode
  NotYetExec:
   mov     SBwritePos, ebx
   ret
VSOUND_Ports_OutData            EndP

; -----------------------------------------------------------------------------
VSOUND_Ports_InMixerAddress     Proc Near
   mov     al, byte ptr [SBmixerRegister]
   ret
VSOUND_Ports_InMixerAddress     EndP

; -----------------------------------------------------------------------------
VSOUND_Ports_InMixerData        Proc Near
   mov     ebx, SBmixerRegister
   mov     al, byte ptr [SBmixerData+ebx]
   ret
VSOUND_Ports_InMixerData        EndP

; -----------------------------------------------------------------------------
VSOUND_Ports_InData             Proc Near
   mov     ecx, SBreadLength ; Ignore any reads, when nothing in Read-Queue
   or      ecx, ecx
   jz      VSOUND_Ports_InNOP
   mov     ebx, SBreadPos    ; EBX - ReadPos, ECX - Length
   mov     al, byte ptr [SBreadQueue+ebx] ; Get Byte from Read-Queue
   inc     ebx
   cmp     ebx, ecx          ; If our length equals the Next-Position stay
   jae     StayAtPos
   mov     SBreadPos, ebx
  StayAtPos:
   ret
VSOUND_Ports_InData             EndP

VSOUND_Ports_InWriteReady       Proc Near
   mov     al, 7Fh           ; We are ready anytime for any data :-)
   ret
VSOUND_Ports_InWriteReady       EndP

; This here functions as IRQ-Acknowledge as well
VSOUND_Ports_InDataAvail8bit    Proc Near
   ; If HW_SOUND_PASSTHRU, forward IRQ-Acknowledge to Passthru.asm
   in       al, dx
   jmp      VSOUND_Ports_InNOP
VSOUND_Ports_InDataAvail8bit    EndP

VSOUND_Ports_InDataAvail16bit   Proc Near
   ; If HW_SOUND_PASSTHRU, forward IRQ-Acknowledge to Passthru.asm
   in       al, dx
   jmp      VSOUND_Ports_InNOP
VSOUND_Ports_InDataAvail16bit   EndP
