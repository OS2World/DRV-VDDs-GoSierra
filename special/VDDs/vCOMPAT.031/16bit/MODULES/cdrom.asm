;---------------------------------------------------------------------------
;
; VDM-COMPATIBILITY-MODULE - 'COMPATIBILITY_CDROM'
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
; Known to fix:
;===============
;  Rayman
;  Broken Sword (Baphomet's Fluch)
;  Command & Conquer 2 - Red Alert
;  Pandora Directive
;  various CD-ROM detection software
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
   NextPatchSegment     dw         -1
   InitPtr              dw offset InitCode
   vCOMPATPtr           dd  0FFFF0000h
   Interrupt1_No        db        021h
   Interrupt1_OrgPtr    dd  0FFFF0000h
   Interrupt1_Patch     dw offset PatchINT21
   Interrupt2_No        db        02Fh
   Interrupt2_OrgPtr    dd  0FFFF0000h
   Interrupt2_Patch     dw offset PatchINT2F
   InterruptPatchStop   db          0h

; -----------------------------------------------------------------------------

   VolumeLabelSpec      db 'x:\*', 0
   CDaudioStatus        db          0h   ; Audio not playing
   CDROMdriveCount      db          0h   ; Count of Drive-Letters
   CDROMdriveList       db 26 dup (0)    ; Drive-Letters of CD-ROM drives... 

; =============================================================================

; This Init-Code will check for CD-Extensions and get some static information
;  may destroy AX, CX, DX, SI, DI
;  DS==DX==CS assumed
InitCode:       push    es bx
                   mov     ax, 1500h
                   xor     bx, bx
                   int     2Fh
                   mov     CDROMdriveCount, bl
                   add     al, 0Dh
                   mov     es, dx
                   mov     bx, offset CDROMdriveList
                   int     2Fh
                pop     bx es
                retf

; =============================================================================

PatchINT21:     cmp     ah, 4Eh           ; Find First
                je      FindFirst
DontPatchCall:  jmp     cs:[Interrupt1_OrgPtr]

               FindFirst:
                cmp     cx, 8             ; For Volume-Label?
                jne     DontPatchCall
                push    bx
                   mov     bx, dx
                   cmp     word ptr ds:[bx+1], '\:'
                   je      DriveSpecified
NoPatching:     pop     bx
                jmp     DontPatchCall

DriveSpecified: push    ax cx
                   ; If File-Spec match -> copy Drive Letter to our Spec
                   mov     cl, byte ptr ds:[bx+0]
                   mov     cs:[VolumeLabelSpec], cl
                   or      cl, 20h       ; Lowercasing drive letter
                   sub     cl, 'a'       ; Converting 'a' -> [00]
                   call    CheckIfCDROM  ; Checks CL, uses BX
;                   movzx   cx, bl
;                   mov     ax, 150Bh     ; CD-Extensions - Drive Check
;                   int     2Fh
;                   cmp     bx, 0ADADh    ; BX == ADADh -> CDEX installed
;                   jne     NoCDext
;                   sub     ax, 150Bh     ; AX == 150B -> We got a CD-drive
                pop     cx ax bx
                jnc     DontPatchCall    ; No-Carry? -> No CD-drive
                push    ds dx
                   push    cs
                   pop     ds
                   mov     dx, offset VolumeLabelSpec
                   ; Now run FindFirst, but on our Spec to find the label
                   pushf
                   call    dword ptr cs:[Interrupt1_OrgPtr]
                pop     dx ds
                retf    2                 ; Dont restore flags

; Helper-Sub-Routine, will check if we got a CD-ROM
;  CL - CD-ROM drive, CH&BX - will get destroyed
;  Replies CARRY-Flag, if CD-ROM drive...
CheckIfCDROM:
   mov     bx, offset CDROMdriveList
   mov     ch, CDROMdriveCount
   or      ch, ch
   jnz     CICLoop
  CICDone:
   retn
  CICLoop:
      cmp     byte ptr cs:[bx], cl
      je      CICFound
   inc     bx
   dec     ch
   jnz     CICLoop
   jmp     CICDone
  CICFound:
   stc
   retn

; =============================================================================

PatchINT2F:     cmp     ax, 1510h         ; CDEX - "Send Request"?
                je      CDEX_SendRequest
JumpOrgHandler: jmp     cs:[Interrupt2_OrgPtr]

               CDEX_SendRequest:
                push    bx cx
                   call    CheckIfCDROM
                pop     cx bx
                jc      IsCDROMdrive
                mov     ax, 000Fh        ; 'Invalid drive'
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
                call    dword ptr cs:[Interrupt2_OrgPtr]
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
