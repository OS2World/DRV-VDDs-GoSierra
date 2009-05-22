;---------------------------------------------------------------------------
;
; VDM-COMPATIBILITY-MODULE - 'COMPATIBILITY_CDROM'
;
; Function:
;===========
;  This fixes various VCDROM.SYS implementation errors and implements some bugs
;   from original MSCDEX for compatibility reasons.
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
;  Rayman, various CD-ROM detection software
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
   Interrupt1_No        db        02Fh
   Interrupt1_OrgPtr    dd  0FFFF0000h
   Interrupt1_Patch     dw offset PatchINT2F
   InterruptPatchStop   db          0h

   CDaudioStatus        db          0h    ; Audio not playing

;---------------------------------------------------------------------------

PatchINT2F:     cmp     ax, 1510h         ; CDEX - "Send Request"?
                je      CDEX_SendRequest
JumpOrgHandler: jmp     cs:[Interrupt1_OrgPtr]

               CDEX_SendRequest:
                cmp     byte ptr es:[bx+2], 3 ; IOCTL-Read Request?
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
                call    dword ptr cs:[Interrupt1_OrgPtr]
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
