
; vCOMPAT is for OS/2 only */
;  You may not reuse this source or parts of this source in any way and/or
;  (re)compile it for a different platform without the allowance of
;  kiewitz@netlabs.org. It's (c) Copyright by Martin Kiewitz.

Public VDD_InitInstanceData
Public VDD_ResetMemSelTable
Public VCOMPAT_InitPatchModules
Public VCOMPAT_APIEntry

; -----------------------------------------------------------------------------

VDD_InitInstanceData            Proc Near   Uses ecx edi
   mov       edi, offset VDD_InstanceData
   mov       ecx, offset VDD_InstanceDataEnd-offset VDD_InstanceData
   xor       al, al
   rep       stosb             ; NULs out InstanceData-Area
   ret
VDD_InitInstanceData            EndP

VDD_ResetMemSelTable            Proc Near   Uses ecx edi
   cmp     MemoryBlockCount, 0              ; Skip, if already empty
   je      MemoryDone
   xor     eax, eax
   mov     MemoryBlockCount, 0
   mov     ecx, (MemoryBlockCountMax*MemoryBlockStrucLen)/4
   mov     edi, offset MemoryBlocks
   rep     stosd
  MemoryDone:
   cmp     CodeSelectorCount, 0             ; Skip, if already empty
   je      SelectorDone
   xor     eax, eax
   mov     CodeSelectorCount, 0
   mov     ecx, CodeSelectorCountMax/2      ; WORD per Selector
   mov     edi, offset CodeSelectors
   rep     stosd
  SelectorDone:
   ret
VDD_ResetMemSelTable            EndP

VCOMPAT_InitPatchModules        Proc Near   Uses ebx ecx edx esi
   mov     edx, PATCH_FirstPatchSegPtr
   mov     esi, edx
   shl     edx, 12                          ; EDX - V86-Pointer to Patch-Module
   xor     ebx, ebx
   mov     ecx, 512
  ModuleLoop:
      ; Set vCOMPATAPI field to contain vCOMPATAPI BP-EntryPoint
      mov     eax, VCOMPAT_APIBreakPoint
      mov     dptr [esi+2], eax
      ; Now process the interrupt-table
      push    esi
         add     esi, 6
        InterruptLoop:
            mov     bl, bptr [esi]
            or      bl, bl
            jz      InterruptEnd
            mov     dx, wptr [esi+2]        ; EDX - V86-Pointer to Int-Handler
            mov     eax, dptr [ebx*4]       ; EAX - V86-Pointer to org Handler
            mov     dptr [esi], eax         ; Patch old handler into Module
            mov     dptr [ebx*4], edx       ; Patch in new handler
         add     esi, 4
         jmp     InterruptLoop
        InterruptEnd:
      pop     esi
   mov     dx, wptr [esi+0]                 ; Get NextPatchSegment
   shl     edx, 16                          ; EDX - V86-Pointer to Patch-Module
   mov     esi, edx
   shr     esi, 12                          ; ESI - Pointer to Patch-Module
   or      edx, edx
   jz      ModuleDone
   dec     ecx
   jnz     ModuleLoop
  ModuleDone:
   ; Now process some special patchings...
   mov     esi, PATCH_CDROMinDOSptr
   or      esi, esi
   jz      NoCDROMModule
   test    TRIGGER_VCDROMReplacement, 1
   jnz     GotCDROMReplacement
   add     esi, 4
  GotCDROMReplacement:
   ; Hardcoded in CDROM/CDROMREP
   mov     al, bptr CDROM_FirstDriveNo
   mov     [esi+11], al                     ; First-DriveNo (0-A,1-B,etc.)
   add     al, bptr CDROM_DriveCount
   mov     [esi+12], al                     ; After-DriveNo (one beyond last)
  NoCDROMModule:
   ret
VCOMPAT_InitPatchModules        EndP

; This routine gets called from Help-DD and/or patch-modules
VCOMPAT_APIEntry                Proc Near Pascal Uses ebx ecx esi edi,  HookDataPtr:dword, ClientRegisterFramePtr:dword
   call    VDHPopInt
   or      eax, eax                         ; If PopInt fails -> Close VDM
   jnz     ProcessCall
  KillVDM:
   push    0
   call    VDHKillVDM
  ProcessCall:
   mov     esi, ClientRegisterFramePtr
   mov     cx, wptr [esi+RegFrame.Client_ECX]
   cmp     ch, 1
   je      MagicalVMPatcher
  ByeBye:
   ret

  MagicalVMPatcher:
   cmp     cl, 1
   jb      MVMP_HookInPatchModules
   je      MVMP_PMMainTrigger
   jmp     ByeBye

   ; Is called via Help-DD as soon as first INT 21h/EXEC is received
   ;  That's the right point to hook into all sorts of INT services
  MVMP_HookInPatchModules:
   movzx   eax, wptr [esi+RegFrame.Client_EDX]
   shl     eax, 4
   mov     PTR_FirstMCB, eax
   cmp     bptr [eax], 4Dh                  ; If it doesnt point to MCB, byebye
   jne     KillVDM
   movzx   eax, [esi+RegFrame.Client_ES]    ; Get List-Of-Lists pointer from
   shl     eax, 4                           ;  ES:BX
   add     ax, wptr [esi+RegFrame.Client_EBX]
   jnc     NoLOLOverflow
   add     eax, 10000h
  NoLOLOverflow:
   mov     PTR_ListOfLists, eax
   call    VCOMPAT_PatchDeviceDriverHeaders
   call    VCOMPAT_InitPatchModules
   ret

  MVMP_PMMainTrigger:
   push    esi
   call    VCOMPAT_MagicVMPatcherInPM_INT10
   add     esp, 4
   ret
VCOMPAT_APIEntry                EndP
