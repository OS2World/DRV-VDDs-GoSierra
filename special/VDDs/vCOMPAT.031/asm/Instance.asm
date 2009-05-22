
Public VDD_InitInstanceData
Public VDD_ResetMemSelTable

; -----------------------------------------------------------------------------

VDD_InitInstanceData            Proc Near   Uses ecx edi
   mov       edi, offset VDD_InstanceData
   mov       ecx, offset VDD_InstanceDataEnd-offset VDD_InstanceData
   xor       al, al
   rep       stosb             ; NULs out InstanceData-Area

;   ; Initialize Patch locations to NULL
;   mov     PatMod_NextPatchSegPtr, 0
;   mov     PatMod_DeviceDriverInDOSptr, 0
;   mov     PatMod_INT25inDOSptr, 0
;   mov     PatMod_2GBLIMITinDOSptr, 0
;   mov     PatMod_CDROMinDOSptr, 0
;   mov     PatMod_DPMITRIGinDOSptr, 0
;   mov     PatMod_MOUSENSEinDOSptr, 0
;   mov     PatMod_JOYSTICKBIOSinDOSptr, 0
;
;   ; 
;   mov     FirstMCBpointer, 0
;   mov     INT21_InExecute, 0
;   mov     Trigger_TurboPascalDPMI, 0
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
