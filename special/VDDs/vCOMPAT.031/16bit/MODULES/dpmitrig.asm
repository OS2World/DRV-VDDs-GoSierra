;---------------------------------------------------------------------------
;
; VDM-COMPATIBILITY-MODULE - 'COMPATIBILITY_DPMI'
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
   NextPatchSegment     dw         -1
   InitPtr              dw          0h
   vCOMPATPtr           dd  0FFFF0000h
   Interrupt1_No        db        010h
   Interrupt1_OrgPtr    dd  0FFFF0000h
   Interrupt1_Patch     dw offset PatchINT10
   InterruptPatchStop   db          0h
   TriggerActive        db          0    ; This will get set by vCOMPAT

;---------------------------------------------------------------------------

PatchINT10:     cmp     TriggerActive, 0
                je      NoTriggerNeeded
                push    ax
                   mov     ax, 0101h     ; Magic VM Patcher - PM Main Trigger
                   call    dword ptr cs:[vCOMPATPtr]
                ; AX is popped back by Magic VM Patcher...
                mov     TriggerActive, 0
               NoTriggerNeeded:
                jmp     cs:[Interrupt1_OrgPtr]

code_seg	ends
		end PatchModule
