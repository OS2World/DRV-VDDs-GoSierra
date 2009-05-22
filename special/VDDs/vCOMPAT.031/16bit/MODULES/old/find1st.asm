;---------------------------------------------------------------------------
;
; VDM-COMPATIBILITY-MODULE - MANDATORY
;
; Function:
;===========
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
;  Broken Sword (Baphomet's Fluch)
;  Command & Conquer 2 - Red Alert
;  Pandora Directive
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
   Interrupt1_No        db        021h
   Interrupt1_OrgPtr    dd  0FFFF0000h
   Interrupt1_Patch     dw offset PatchINT21
   InterruptPatchStop   db          0h

   VolumeLabelSpec      db 'x:\*', 0

;---------------------------------------------------------------------------

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
                   mov     bl, byte ptr ds:[bx+0]
                   mov     cs:[VolumeLabelSpec], bl
                   or      bl, 20h       ; Lowercasing drive letter
                   sub     bl, 'a'       ; Converting 'a' -> [00]
                   movzx   cx, bl
                   mov     ax, 150Bh     ; CD-Extensions - Drive Check
                   int     2Fh
                   cmp     bx, 0ADADh    ; BX == ADADh -> CDEX installed
                   jne     NoCDext
                   sub     ax, 150Bh     ; AX == 150B -> We got a CD-drive
NoCDext:        pop     cx ax bx
                jnz     DontPatchCall    ; <-- Highly optimized for size
                push    ds dx
                   push    cs
                   pop     ds
                   mov     dx, offset VolumeLabelSpec
                   ; Now run FindFirst, but on our Spec to find the label
                   pushf
                   call    dword ptr cs:[Interrupt1_OrgPtr]
                pop     dx ds
                retf    2                 ; Dont restore flags

code_seg	ends
		end PatchModule
