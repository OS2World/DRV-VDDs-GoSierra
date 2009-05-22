; ======================================
;  SoundBlaster Commands - DMA PlayBack
; ======================================

; All these workers will get called from PortIO.asm / VSOUND_Ports_OutData

VSB_PlayOneSample:                                          ; Sample:BYTE - 10h
   ; This needs to collect samples and put them together as buffer
   ;  I doubt that this will give accurate results, but one may always try
   ;  current not supported
   ret

VSB_StartLowSpeedDMA8bit:                                   ; Length:WORD - 14h
   movzx   eax, word ptr [SBparameters]
   inc     eax
   mov     VSOUND_OutputSize, eax
   ; Normal, 8-Bit, Mono, Unsigned
   xor     ax, ax
   mov     VSOUND_OutputFlags, ax
   jmp     VSB_StartSBplayback

VSB_StartLowSpeedAutoInitDMA8bit:                                         ; 1Ch
   ; Auto-Init, 8-Bit, Mono, Unsigned
   mov     ax, VSOUNDoutput_Flags_AutoInit
   mov     VSOUND_OutputFlags, ax
   jmp     VSB_StartSBplayback

VSB_StartHiSpeedDMA8bit:                                                  ; 91h
   ; Normal, 8-Bit, Unsigned
   xor     ax, ax
   ; Check, if stereo shall be used by looking at Mixer-Register 0Eh - Bit 1
   mov     dl, byte ptr [SBmixerData+0Eh]
   test    dl, 02h                    ; Test for Bit 1
   jz      VSB_ESHSDMA8_Mono
   or      ax, VSOUNDoutput_Flags_Stereo
  VSB_ESHSDMA8_Mono:
   mov     VSOUND_OutputFlags, ax
   jmp     VSB_StartSBplayback

VSB_StartHiSpeedAutoInitDMA8bit:                                          ; 90h
   ; Auto-Init, 8-Bit, Unsigned
   mov     ax, VSOUNDoutput_Flags_AutoInit
   ; Check, if stereo shall be used by looking at Mixer-Register 0Eh - Bit 1
   mov     dl, byte ptr [SBmixerData+0Eh]
   test    dl, 02h                    ; Test for Bit 1
   jz      VSB_ESHSAIDMA8_Mono
   or      ax, VSOUNDoutput_Flags_Stereo
  VSB_ESHSAIDMA8_Mono:
   mov     VSOUND_OutputFlags, ax
   jmp     VSB_StartSBplayback

VSB_StartExtDMA16bit:                            ; Mode:BYTE, Length:WORD - Byh
   mov     dx, VSOUNDoutput_Flags_16bit ; 16-Bit !
   mov     ah, byte ptr [SBparameters]
   ; OpCode is in AX (AL-OpCode, AH-Mode)
   test    al, 00000100b                 ; Auto-Init ?
   jz      VSB_ESEDMA16_NormalDMA
   or      dx, VSOUNDoutput_Flags_AutoInit
  VSB_ESEDMA16_NormalDMA:
   test    ah, 00100000b                 ; Stereo ?
   jz      VSB_ESEDMA16_Mono
   or      dx, VSOUNDoutput_Flags_Stereo
  VSB_ESEDMA16_Mono:
   test    ah, 00010000b                 ; Signed ?
   jz      VSB_ESEDMA16_Unsigned
   or      dx, VSOUNDoutput_Flags_Signed
  VSB_ESEDMA16_Unsigned:
   mov     VSOUND_OutputFlags, dx
   movzx   edx, word ptr [SBparameters+1]
   inc     edx
   shl     edx, 1                        ; WORD instead of BYTEs
   mov     VSOUND_OutputSize, edx
   test    al, 00001000b                 ; Record ?
   jnz     VSB_ESEDMA16bit_RecordMode
   jmp     VSB_StartSBplayback
  VSB_ESEDMA16bit_RecordMode:
   ret

VSB_StartExtDMA8bit:                             ; Mode:BYTE, Length:WORD - Cyh
   xor     dx, dx                        ; 8-Bit !
   mov     ah, byte ptr [SBparameters]
   ; OpCode is in AX (AL-OpCode, AH-Mode)
   test    al, 00000100b                 ; Auto-Init ?
   jz      VSB_ESEDMA8_NormalDMA
   or      dx, VSOUNDoutput_Flags_AutoInit
  VSB_ESEDMA8_NormalDMA:
   test    ah, 00100000b                 ; Stereo ?
   jz      VSB_ESEDMA8_Mono
   or      dx, VSOUNDoutput_Flags_Stereo
  VSB_ESEDMA8_Mono:
   test    ah, 00010000b                 ; Signed ?
   jz      VSB_ESEDMA8_Unsigned
   or      dx, VSOUNDoutput_Flags_Signed
  VSB_ESEDMA8_Unsigned:
   mov     VSOUND_OutputFlags, dx
   movzx   edx, word ptr [SBparameters+1]
   inc     edx
   mov     VSOUND_OutputSize, edx
   test    al, 00001000b                 ; Record ?
   jnz     VSB_ESEDMA8bit_RecordMode
   jmp     VSB_StartSBplayback
  VSB_ESEDMA8bit_RecordMode:
   ret

VSB_SetSampleRate:                                         ; divisor:BYTE - 40h
   movzx   eax, bptr [SBparameters]
   push    eax
      not     al                         ; Negate divisor = NanoSeconds per Sample
      mov     bptr [VSOUND_OutputNSPerSample], al
   pop     eax
   shl     eax, 1                        ; Offset into WORD array
   mov     ax, wptr [SBSampleRates+eax]
   mov     VSOUND_OutputSampleRate, ax
   ret

VSB_SetExtSampleRate:                      ; Sample-Rate:WORD (non-intel) - 41h
   ; for Commands Bxh & Cxh -> Output only
   mov     cx, word ptr [SBparameters]
   xchg    cl, ch           ; <- To Intel-Order
   or      cx, cx
   jz      VSB_SESR_BadSampleRate
   cmp     cx, 44100
   jbe     VSB_SESR_NoOverflow
  VSB_SESR_BadSampleRate:
   mov     cx, 44100
  VSB_SESR_NoOverflow:
   mov     VSOUND_OutputSampleRate, cx
   mov     dx, 0Fh
   mov     ax, 4240h            ; DX:AX - 1000000
   div     cx                   ; Divisor = 256-(1000000/SampleRate)
   mov     VSOUND_OutputNSPerSample, ax
   ret

VSB_SetTransferLength:                              ; TransferLength:WORD - 48h
   ; for Commands 1Ch, 90h, 91h, 99h
   movzx   eax, word ptr [SBparameters]
   inc     eax                           ; All 8-bit transfers
   mov     VSOUND_OutputSize, eax
   ret

; This is called, when apps execute SB-Playback...
VSB_StartSBplayback:
   ; Reset DMA-CurPos
   mov     eax, VSOUND_OutputSize
   cmp     eax, 2
   jb      VSB_ESSBPB_NulBuffer
   call    VSOUND_PlaybackBuffer
   ret
   ; On NUL-buffers, ONLY raise IRQ. Is used by some games to detect IRQ...
  VSB_ESSBPB_NulBuffer:
   mov     VSOUND_OutputFlags, 0      ; Delete possible Auto-Init flag
   push    esi                  ; Give ClientRegisterFrame
   call    VSOUND_RaiseDetectionVIRQ
   add     esp, 4
   ret

VSB_PlaySilentBlock:                                  ; SilentLength:WORD - 80h
   movzx   eax, word ptr [SBparameters]
   inc     eax                           ; All 8-bit transfers
   ; We check, if application tries to output silent block of 1 byte
   ;  This is another way of detecting IRQ, so we switch to that code
   cmp     eax, 2
   jb      VSB_ESSBPB_NulBuffer
   ; We actually don't output anything, but emulate an IRQ after the calculated
   ;  silent-block time.
   push    eax
   call    VSOUND_PlaybackSilence
   add     esp, 4
   ret

VSB_Pause8bitDMA:                                                         ; D0h
   call    VSOUND_PlaybackPause
   ret

VSB_Resume8bitDMA:                                                        ; D4h
   call    VSOUND_PlaybackResume
   ret

VSB_Pause16bitDMA:                                                        ; D5h
   call    VSOUND_PlaybackPause
   ret

VSB_Resume16bitDMA:                                                       ; D6h
   call    VSOUND_PlaybackResume
   ret

; ==============================================
;  SoundBlaster Commands - Detect/Version Stuff
; ==============================================

VSB_ReadDACOutputStatus:                                                  ; D8h
   mov     al, 0FFh           ; Output is always switched on
   mov     bptr [SBreadQueue], al
   mov     eax, 1
   jmp     VSB_ResetReadQueue

VSB_GetDSPid:                                               ; tstval:BYTE - E0h
   mov     al, bptr [SBparameters]
   not     al
   mov     byte ptr [SBreadQueue], al
   mov     eax, 1
   jmp     VSB_ResetReadQueue

VSB_GetDSPversion:                                                        ; E1h
   ; 4.16 for Soundblaster 16
   ; 3. 1 for Soundblaster PRO
   ; 2. 0 for Soundblaster 2
   mov     eax, PROPERTY_HW_SOUND_TYPE
   or      eax, 4B4D0000h    ; Add magic "MK" to version number
   mov     dword ptr [SBreadQueue], eax
   mov     eax, 4
   jmp     VSB_ResetReadQueue

VSB_GetDSPid2:                                              ; magics:WORD - E4h
   mov     ax, word ptr [SBparameters]
   cmp     ax, 0E8AAh        ; Hard-Coded Magic
   je      VSB_EGDSPid2_GotIt
   ret
  VSB_EGDSPid2_GotIt:
   mov     al, 0AAh
   mov     byte ptr [SBreadQueue], al
   mov     eax, 1
   jmp     VSB_ResetReadQueue

; Function E7h - Identify ESS card
;  -> Returns 48h/82h for ESS-488
;  -> Returns 68h/??h for ESS-688

VSB_RaiseIRQline:                                                         ; F2h
   push    esi                  ; Give ClientRegisterFrame
   call    VSOUND_RaiseDetectionVIRQ
   add     esp, 4
   ret

; Function D1h - Turn on SB Speaker (no effect DSP v4+)

; Function D3h - Turn off SB Speaker (no effect DSP v4+)

; Function D9h - Exit Autoinit mode (16-bit) (v4+)

; Function DAh - Exit Autoinit mode (8-bit) (v4+)

; -----------------------------------------------------------------------------
VSB_ResetReadQueue:
   mov    SBreadLength, eax
   xor    eax, eax
   mov    SBreadPos, eax
   ret
