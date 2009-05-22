;---------------------------------------------------------------------------
; VDM-COMPATIBILITY-MODULE - 'COMPATIBILITY_MOUSESENSE'
;
; vCOMPAT is for OS/2 only */
;  You may not reuse this source or parts of this source in any way and/or
;  (re)compile it for a different platform without the allowance of
;  kiewitz@netlabs.org. It's (c) Copyright by Martin Kiewitz.
;
; Function:
;===========
;  This makes the mouse more sensitive. This was done for some games, where
;   the mouse is too insensitive and you need hours to acoomplish certain
;   things.
;
;  READ MOTION COUNTERS (INT 33h/AX=000Bh)
;   CX = number of mickeys mouse moved horizontally since last call
;   DX = number of mickeys mouse moved vertically
;
; Known to fix:
;===============
;  Usability of Tie Fighter & X-Wing
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
   Interrupt1           dw         33h
                        dw offset PatchINT33
   InterruptPatchStop   db          0h

;---------------------------------------------------------------------------

PatchINT33:     cmp     ax, 000Bh         ; Read Motion Counters
                je      ReadMotionCounters
DontPatchCall:  jmp     dword ptr cs:[Interrupt1]

               ReadMotionCounters:
                pushf
                call    dword ptr cs:[Interrupt1] ; Do original call
                ; CX & DX are signed values, that means we may not destroy Bit7
                push    ax
                   and     cx, cx
                   js      HorizNegative
                   cmp     cx, 4000h     ; Check for Bit 6
                   jae     HorizDone
                   shl     cx, 1         ; *2
                   jmp     HorizDone
                  HorizNegative:
                   cmp     cx, 0C000h
                   jb      HorizDone
                   mov     ax, cx
                   not     ax
                   inc     ax
                   sub     cx, ax
                  HorizDone:
                   and     dx, dx
                   js      VertNegative
                   cmp     dx, 4000h        ; Check for Bit 6
                   jae     VertDone
                   shl     dx, 1            ; *2
                   jmp     VertDone
                  VertNegative:
                   cmp     dx, 0C000h
                   jb      VertDone
                   mov     ax, dx
                   not     ax
                   inc     ax
                   sub     dx, ax
                  VertDone:
                pop     ax
                iret

code_seg	ends
		end PatchModule
