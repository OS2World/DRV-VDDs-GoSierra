
; vCOMPAT is for OS/2 only */
;  You may not reuse this source or parts of this source in any way and/or
;  (re)compile it for a different platform without the allowance of
;  kiewitz@netlabs.org. It's (c) Copyright by Martin Kiewitz.

; --------------------------------------------------------------------------

Public V86PreHook_INT21h                    ;

;        In: BX - CRF (Client Register Frame)
;       Out: Carry set to continue interrupt chain
; Destroyed: EAX, ECX, EDX (may get destroyed!)
;
;      From: VDM-Kernel
;   Context: task
;  Function: Gets called prior actual execution of INT 21h. It's *ONLY* called
;             when INT 21h opcode is executed, this means it can *NOT* be used
;             for initial hooking.
V86PreHook_INT21h               Proc Near
   mov     ax, wptr [ebx+RegFrame.Client_EAX]
   cmp     ah, 4Bh                       ; DOS - LOAD&EXECUTE
   je      EXECUTE
   cmp     ah, 4Ch                       ; DOS - TERMINATE
   je      TERMINATE
   cmp     ax, 3500h                     ; DOS - SET INTERRUPT VECTOR 0
   je      SETINTVECTOR00
   cmp     ah, 30h                       ; DOS - GET DOS VERSION
   je      GETDOSVERSION
  Done:
   stc                                   ; Chain to next handler or into V86
   ret

  EXECUTE:
   mov     TRIGGER_InINT21Execute, 1
   mov     TRIGGER_TurboPascalDPMI, 0
   jmp     Done

  TERMINATE:
   mov     TRIGGER_InINT21Execute, 0
   mov     TRIGGER_TurboPascalDPMI, 0
   call    VDD_ResetMemSelTable          ; is done, because memory got released
   jmp     Done

  SETINTVECTOR00:
   cmp     TRIGGER_InINT21Execute, 0
   je      Done
   MPush   <ebx,esi,edi>                 ; Those registers may not get destroyed
      push    ebx
      call    VCOMPAT_MagicVMPatcherInRM_TurboPascalCRT
      add     esp, 4
   MPop    <edi,esi,ebx>
   dec     TRIGGER_InINT21Execute
   jmp     Done

  GETDOSVERSION:
   cmp     TRIGGER_InINT21Execute, 0
   je      Done
   MPush   <ebx,esi,edi>
      push    ebx
      call    VCOMPAT_MagicVMPatcherInRM_MS_C_TimerInitBug
      add     esp, 4
      push    ebx
      call    VCOMPAT_MagicVMPatcherInRM_Clipper_TimerBug
      add     esp, 4
   MPop    <edi,esi,ebx>
   dec     TRIGGER_InINT21Execute
   jmp     Done
V86PreHook_INT21h               EndP
