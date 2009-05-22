
Public VDD_InitInstanceData

; -----------------------------------------------------------------------------

VDD_InitInstanceData            Proc Near   Uses ecx esi edi
   mov       edi, offset VDD_InstanceData
   mov       ecx, offset VDD_InstanceDataEnd-offset VDD_InstanceData
   xor       al, al
   rep       stosb             ; NULs out InstanceData-Area
   mov       esi, offset VCMOS_StdRTCArea
   mov       edi, offset VCMOS_RTCArea
   mov       ecx, VCMOS_RTCAreaLen/2
   rep       movsw             ; Copy over standard RTC Area
   ret
VDD_InitInstanceData            EndP
