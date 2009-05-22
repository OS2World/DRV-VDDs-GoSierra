
Public VDD_InitInstanceData

; -----------------------------------------------------------------------------

VDD_InitInstanceData            Proc Near   Uses ebx ecx esi edi
   mov       edi, offset VDD_InstanceData
   mov       ecx, offset VDD_InstanceDataEnd-offset VDD_InstanceData
   xor       al, al
   rep       stosb             ; NULs out InstanceData-Area
   mov       esi, offset SBmixerChipDefaults
   mov       edi, offset SBmixerData
   mov       ecx, 64
   rep       movsd
   ; Initialize Read-Port to have AAh ready (DSP-initialized)
   mov       SBreadQueue, 0AAh
   mov       SBreadLength, 1             ; 1 byte to read - 0AAh
   ret
VDD_InitInstanceData            EndP
