;---------------------------------------------------------------------------
; VDM-COMPATIBILITY-MODULE - 'COMPATIBILITY_DPMI'
;
; vCOMPAT is for OS/2 only */
;  You may not reuse this source or parts of this source in any way and/or
;  (re)compile it for a different platform without the allowance of
;  kiewitz@netlabs.org. It's (c) Copyright by Martin Kiewitz.
;
; Function:
;===========
;  This hooks into several interrupts and acts as a trigger for DPMI related
;   Magical VM Patching. If it gets activated by vCOMPAT (done by setting a
;   hardcoded byte to 1), it will make a vCOMPAT call at the next time as soon
;   as it receives a trigger.
;
;  It's not possible to use a pre-hook under PM for this job, because prehooks
;   don't get called under VPM :(((
;
; Known to fix:
;===============
;  *NONE* - Internal usage only
;
; Known incompatibilities:
;==========================
;  *NONE* - Internal usage only
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
   Interrupt1           dw         10h
                        dw offset PatchINT10
   InterruptPatchStop   db          0h
   TriggerActive        db          0    ; This will get set by vCOMPAT

;---------------------------------------------------------------------------

PatchINT10:     cmp     TriggerActive, 0
                je      NoTriggerNeeded
                push    cx
                   mov     cx, 0101h     ; Magic VM Patcher - PM Main Trigger
                   pushf
                   call    dword ptr cs:[vCOMPATAPI]
                pop     cx
                mov     TriggerActive, 0
               NoTriggerNeeded:
                jmp     dword ptr cs:[Interrupt1]

code_seg	ends
		end PatchModule
