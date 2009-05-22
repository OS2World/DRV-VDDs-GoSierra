; =======================
;  SoundBlaster Passthru
; =======================

Public PASSTHRU_PlaybackStart
Public PASSTHRU_PlaybackPause
Public PASSTHRU_PlaybackResume
Public DirectIO_InitSB
Public DirectIO_AckIRQ

; Those workers will get called from 

;        In: *none*, VSOUND_OutputXXX variables must be defined
;       Out: *none*, real Soundblaster will get playback commands
; Destroyed: *none*
;
;      From: VSOUND_StartPlayback
;   Context: task
;  Function: Starts playback on a real Soundblaster behind VDM
PASSTHRU_PlaybackStart          Proc Near   Uses ebx ecx edx esi edi
   mov     eax, RealSoundblasterVDMHandle
   ; TODO: Check, if our VDM owns the soundblaster. If no VDM owns it, assign
   ;        it. Otherwise skip PASSTHRU!
;   test    PASSTHRU_SBInitiated, 1
;   jnz     NoInit
;   call    DirectIO_InitSB
;   or      PASSTHRU_SBInitiated, 1
;  NoInit:

   ; Set Soundblaster divisor
   mov     al, 40h              ; Output divisor
   call    DirectIO_SendSBCmd
   mov     cx, VSOUND_OutputSampleRate
   xor     ax, ax
   or      cx, cx
   jz      BadSampleRate
   mov     dx, 0Fh
   mov     ax, 4240h            ; DX:AX - 1000000
   div     cx                   ; Divisor = 256-(1000000/SampleRate)
  BadSampleRate:
   not     ax                   ; Soundblaster-Divisor is now in AL
   call    DirectIO_SendSBCmd

   mov     ax, VSOUND_OutputFlags
   test    ax, VSOUNDoutput_Flags_AutoInit
   jz      MonoUnsigned8bit

  MonoUnsigned8bitAuto:
   MPush   <eax,ebx,ecx,edx,esi,edi>
      push    offset CONST_Debug_PassThruAuto
      call    DebugPrintCR
      add     esp, 4
   MPop    <edi,esi,edx,ecx,ebx,eax>
   mov     al, 48h              ; Set transfer length
   call    DirectIO_SendSBCmd
   mov     eax, VSOUND_OutputSize
   dec     eax
   call    DirectIO_SendSBCmd
   mov     al, ah
   call    DirectIO_SendSBCmd
   mov     al, 1Ch              ; DMA 8-bit mono unsigned AutoInit
   call    DirectIO_SendSBCmd
   ret
  MonoUnsigned8bit:
   MPush   <eax,ebx,ecx,edx,esi,edi>
      push    offset CONST_Debug_PassThru
      call    DebugPrintCR
      add     esp, 4
   MPop    <edi,esi,edx,ecx,ebx,eax>
   mov     al, 14h              ; DMA 8-bit mono unsigned No-AutoInit
   call    DirectIO_SendSBCmd
   mov     eax, VSOUND_OutputSize
   dec     eax
   call    DirectIO_SendSBCmd
   mov     al, ah
   call    DirectIO_SendSBCmd
   ret
PASSTHRU_PlaybackStart          EndP

PASSTHRU_PlaybackPause          Proc Near   Uses ebx ecx edx esi edi
   MPush   <eax,ebx,ecx,edx,esi,edi>
      push    offset CONST_Debug_PassThruPause
      call    DebugPrintCR
      add     esp, 4
   MPop    <edi,esi,edx,ecx,ebx,eax>
   mov     al, 0D0h
   call    DirectIO_SendSBCmd
   ret
PASSTHRU_PlaybackPause          EndP

PASSTHRU_PlaybackResume         Proc Near   Uses ebx ecx edx esi edi
   mov     al, 0D4h
   call    DirectIO_SendSBCmd
   ret
PASSTHRU_PlaybackResume         EndP

;        In: AL - Command-Byte to send to Soundblaster
;       Out: *none*
; Destroyed: *none*
DirectIO_SendSBCmd              Proc Near   Uses eax ecx edx
   mov     edx, 22Ch
   mov     ah, al
   mov     ecx, 0FFh
  NotReadyLoop:
      in      al, dx
      or      al, al
      jns     Ready
      loop    NotReadyLoop
  Ready:
   mov     al, ah
   out     dx, al
   ret
DirectIO_SendSBCmd              EndP

DirectIO_ReadSB                 Proc Near   Uses ecx edx
   mov     dx, 022Eh
   mov     ecx, 0FFh
  NotReadyLoop:
      in      al, dx
      or      al, al
      js      Ready
      loop    NotReadyLoop
  Ready:
   sub     dx, 4
   in      al, dx
   ret
DirectIO_ReadSB                 EndP

DirectIO_InitSB                 Proc Near   Uses eax ecx edx
   mov    dx, 0226h
   mov    al, 1
   out    dx, al
   in     al, dx
   in     al, dx
   in     al, dx
   in     al, dx
   in     al, dx
   in     al, dx   ; 3.3ms delay
   xor    al, al
   out    dx, al
   mov    ecx, 64
  InitLoop:
      call   DirectIO_ReadSB
      cmp    al, 0AAh
      je     InitDone
   loop   InitLoop
  InitDone:
   ret
DirectIO_InitSB                 EndP

DirectIO_AckIRQ                 Proc Near   Uses eax edx
   mov    dx, 022Eh
   in     al, dx
   ret
DirectIO_AckIRQ                 EndP
