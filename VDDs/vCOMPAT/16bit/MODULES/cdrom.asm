;---------------------------------------------------------------------------
; VDM-COMPATIBILITY-MODULE - 'COMPATIBILITY_CDROM'
;
; vCOMPAT is for OS/2 only */
;  You may not reuse this source or parts of this source in any way and/or
;  (re)compile it for a different platform without the allowance of
;  kiewitz@netlabs.org. It's (c) Copyright by Martin Kiewitz.
;
; Function:
;===========
;  This fixes various VCDROM.SYS implementation errors and implements some bugs
;   from original MSCDEX for compatibility reasons.
;
;  Find 1st
; ==========
;  This fixes VDM behaviour, when FINDFIRST is issued using "Volume Label" as
;   file mask for a CD ROM drive. Actual DOS is crazy and responds in an
;   idiotic manner, but some software relies on it to find CD-ROMs, etc.
;
;  FINDFIRST (INT 21h/AH=4Eh/CX=8) -> only on CD-ROM drives
;  a) Search for 'x:\' will succeed
;  b) Search for 'x:\MYLABEL' will succeed, *even* if the true volume label is
;      something completly different
;
;  VDM will only succeed, when 'x:\*' or '*' is searched for.
;
;  Send Request
; ==============
;   If a Send-Request is done with a drive-number that is invalid, the normal
;    behaviour is to reply with AX==000Fh "Invalid drive" and not process the
;    request.
;
;   Actual VDM-behaviour:
;    Request is accepted and applied to a "matched" CD-ROM, which means the
;    first one, if drive-letter<first drive or the last one, if drive-letter>
;    last drive.
;
;   Fix Proposal:
;    We do a quick checking and reply the error code for VCDROM.
;
;  IOCTL - "Audio Status"
; ========================
;   if no CD-Audio is playing (which means not playing nor paused) the normal
;    behaviour is to NUL out Starting and Ending location.
;
;    Actual VDM-behaviour:
;     Audio-Play, Audio-Stop (during Playback), another Audio-Stop
;      -> still Starting/Ending location are returned unmodified
;     Audio-Play, [...till Audio done...]
;      -> Starting/Ending location are still returned back
;
;    Fix Proposal:
;     Check Busy-Bit after "Audio Status" calls. If not set, reset location
;      data, because Audio is not playing anymore. Additionally look at callers
;      usage of CD-Audio PLAY/STOP/RESUME and guess what the current status
;      should be.
;
;  CD-Audio PLAY
; ===============
;   Original MSCDEX has a bug in its playing routines. If asked for e.g. 75
;    frames, it will actually play back 74, so ending location returned from
;    Audio-Status won't be accurate. Some software relies on this behaviour.
;
;    Actual VDM-behaviour:
;     Is calculating and playing correctly :)
;
;    Fix Proposal:
;     Decrease TotalFrames on PLAY calls. This will fix the calculation and
;      behaviour.
;
;  Device Driver Header
; ======================
;   Original MSCDEX contains a drive-letter in its device-driver headers. Also
;    it has one device-driver header per CD-ROM drive (found by Max Alekseyev).
;
;    Actual VDM-behaviour:
;     The case under OS/2. VCDROM only emulates one device-driver header to
;     conserve memory and that byte is set to 0. Some installers strangely
;     check that byte instead of using the normal CDEX-APIs.
;
;    Fix Proposal:
;     We put the 1st CD-ROM drive letter in there. This is done from VDD-space
;     to safe some memory. ffs. VCOMPAT_PatchDeviceDriverHeaders()
;     We can not fix the multiple device-driver headers, but I personally
;     consider this whole mess as application bug.
;
; Known to fix:
;===============
;  Rayman
;  Broken Sword (Baphomet's Fluch)
;  Command & Conquer 2 - Red Alert
;  Pandora Directive
;  Various CD-ROM detection software
;  Descent 2 Installer
;  Darklight Conflict
;
; Known incompatibilities:
;==========================
;  *NONE*
;
; Code Examples:
;================
;  *NONE AVAILABLE*
;
;---------------------------------------------------------------------------

		.386p

code_seg        segment public use16
                assume  cs:code_seg, ds:nothing, es:nothing
                org     0000h

PatchModule:
   NextPatchSegment     dw          0
   vCOMPATAPI           dd  0FFFF0000h
   Interrupt1           dw         21h
                        dw offset PatchINT21
   Interrupt2           dw         2Fh
                        dw offset PatchINT2F
   InterruptPatchStop   db          0h

; -----------------------------------------------------------------------------

   CDROMFirstDrive      db          0h
   CDROMAfterDrive      db          0h      ; Filled out by vCOMPAT VDD-Space
   VolumeLabelSpec      db  'x:\*', 0
   CDaudioStatus        db          0h   ; Audio not playing

; =============================================================================

PatchINT21:     cmp     ah, 4Eh           ; Find First
                je      FindFirst
DontPatchCall:  jmp     dword ptr cs:[Interrupt1]

               FindFirst:
                cmp     cx, 8             ; For Volume-Label?
                jne     DontPatchCall
                push    bx
                   mov     bx, dx
                   cmp     word ptr ds:[bx+1], '\:'
                   je      DriveSpecified
NoPatching:     pop     bx
                jmp     DontPatchCall

DriveSpecified:    ; If File-Spec match -> copy Drive Letter to our Spec
                   mov     bl, byte ptr ds:[bx+0]
                   mov     cs:[VolumeLabelSpec], bl
                   or      bl, 20h       ; Lowercasing drive letter
                   sub     bl, 'a'       ; Converting 'a' -> [00]
                   cmp     bl, cs:[CDROMFirstDrive]
                   jb      NoPatching
                   cmp     bl, cs:[CDROMAfterDrive]
                   jae     NoPatching
                   push    ds dx
                      push    cs
                      pop     ds
                      mov     dx, offset VolumeLabelSpec
                      ; Now run FindFirst, but on our Spec to find the label
                      pushf
                      call    dword ptr cs:[Interrupt1]
                   pop     dx ds
                pop     bx
                retf    2                 ; Dont restore flags

; =============================================================================

PatchINT2F:     cmp     ax, 1510h         ; CDEX - "Send Request"?
                je      CDEX_SendRequest
JumpOrgHandler: jmp     dword ptr cs:[Interrupt2]

               CDEX_SendRequest:
                cmp     cl, cs:[CDROMFirstDrive]
                jb      InvalidDrive
                cmp     cl, cs:[CDROMAfterDrive]
                jae     InvalidDrive
                jmp     IsCDROMdrive
InvalidDrive:   mov     ax, 000Fh        ; 'Invalid drive'
                stc
                retf    2

IsCDROMdrive:   cmp     byte ptr es:[bx+2], 3 ; IOCTL-Read Request?
                je      IOCTL_ReadReq
                cmp     byte ptr es:[bx+2], 132 ; CD-Audio PLAY?
                je      CDAudio_PLAY
                cmp     byte ptr es:[bx+2], 136 ; CD-Audio RESUME?
                je      CDAudio_RESUME
                cmp     byte ptr es:[bx+2], 133 ; CD-Audio PAUSE/STOP?
                jne     JumpOrgHandler
CDAudio_STOP:   dec     cs:[CDaudioStatus]
                jns     JumpOrgHandler
                inc     cs:[CDaudioStatus]
                jmp     JumpOrgHandler

CDAudio_PLAY:   ; CD-Audio Play
                dec     dword ptr es:[bx+18]
                jns     CDAudio_RESUME
                inc     dword ptr es:[bx+18]
CDAudio_RESUME: mov     cs:[CDaudioStatus], 2
                jmp     JumpOrgHandler

IOCTL_ReadReq:  ; Make that call, but reget control after call is done
                pushf
                call    dword ptr cs:[Interrupt2]
                jnc     NoError
                retf    2

               NoError:
                pushf                     ; Push Flags
                push    ax ds si
                   lds     si, es:[bx+14] ; DS:SI -> IOCTL Control-Block
                   cmp     byte ptr ds:[si], 15 ; "Audio-Status"?
                   jne     NoAudioStatus
                   xor     ax, ax
                   test    byte ptr es:[bx+4], 10b ; If Busy -> Audio Playing
                   jnz     NoAudioStatus
                   test    byte ptr ds:[si+1], 1b  ; No Audio-Paused -> NUL OUT
                   jz      NoAudioPlaying
                   or      cs:[CDaudioStatus], al  ; Remembered status=!0
                   jnz     NoAudioStatus           ;  Audio-Playing/Paused
NoAudioPlaying:    mov     cs:[CDaudioStatus], al
                   and     byte ptr ds:[si+1], 0FEh ; Unset Audio-Paused Bit
                   add     si, 3
                   stosw
                   stosw
                   stosw
                   stosw                  ; NUL out values
                  NoAudioStatus:
                pop     si ds ax
                popf
                retf    2                 ; Dont restore flags

code_seg	ends
		end PatchModule
