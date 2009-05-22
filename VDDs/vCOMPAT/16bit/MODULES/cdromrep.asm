;---------------------------------------------------------------------------
; VDM-COMPATIBILITY-MODULE - 'COMPATIBILITY_CDROM' (Replacement version)
;
; vCOMPAT is for OS/2 only */
;  You may not reuse this source or parts of this source in any way and/or
;  (re)compile it for a different platform without the allowance of
;  kiewitz@netlabs.org. It's (c) Copyright by Martin Kiewitz.
;
; Function:
;===========
;  This fixes only IFS related problems for compatibility reasons. It's used
;   automatically, if our VCDROM replacement got detected.
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
; Known to fix:
;===============
;  [see cdrom.asm for listing]
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
   InterruptPatchStop   db          0h

; -----------------------------------------------------------------------------

   CDROMFirstDrive      db          0h
   CDROMAfterDrive      db          0h      ; Filled out by vCOMPAT VDD-Space
   VolumeLabelSpec      db  'x:\*', 0

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

code_seg	ends
		end PatchModule
