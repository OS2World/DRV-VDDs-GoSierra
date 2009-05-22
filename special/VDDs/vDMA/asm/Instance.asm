
Public VDD_InitInstanceData

; -----------------------------------------------------------------------------

VDD_InitInstanceData            Proc Near   Uses ebx ecx edx edi
   mov       edi, offset VDMA_VDMAslots
   mov       ecx, VDMAslot_Length
   shl       ecx, 1             ; (StrucLength/4)*8 -> StrucLength*2
   xor       eax, eax
   rep       stosd              ; NUL out DMA-Slots
   mov       edi, offset VDMA_VDMAslots
   xor       eax, eax
   mov       ebx, offset VDMA_PDMAslots
  VDMAIID_InitLoop:
      mov       [edi+VDMAslotStruc.DMAno], al ; Set DMA Channel Number
      mov       [edi+VDMAslotStruc.PhysicalSlotPtr], ebx
      mov       [edi+VDMAslotStruc.TempDMAleft], 0FFFFh
      mov       edx, [VDMA_DMAOwnerFuncs+eax*4]
      mov       [edi+VDMAslotStruc.OwnerFunc], edx
      add       edi, VDMAslot_Length
      add       ebx, PDMAslot_Length
      inc       eax
   cmp       eax, 8
   jb        VDMAIID_InitLoop
   ret
VDD_InitInstanceData            EndP
