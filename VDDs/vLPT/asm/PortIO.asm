
Public VLPT_Ports_InData
Public VLPT_Ports_OutData
Public VLPT_Ports_InStatus
Public VLPT_Ports_OutStatus
Public VLPT_Ports_InControl
Public VLPT_Ports_OutControl

; -----------------------------------------------------------------------------

; This routine gets control, when a byte (AL) is OUTed to a DMA-port (DX)
VLPT_Ports_InData               Proc Near   Uses ebx ecx edx esi edi
   in    
   ret
VLPT_Ports_InData               EndP

; This routine gets control, when a byte (AL) is READ from a DMA-port (DX)
VLPT_Ports_OutData              Proc Near   Uses ebx ecx edx esi edi
   ret
VLPT_Ports_OutData              EndP

; This routine gets control, when a byte (AL) is OUTed to a DMA-port (DX)
VLPT_Ports_InStatus             Proc Near   Uses ebx ecx edx esi edi
   mov     al, 0FFh             ; Reply with 0FFh (std reply from empty ports)
   ret
VLPT_Ports_InStatus             EndP

; This routine gets control, when a byte (AL) is READ from a DMA-port (DX)
VLPT_Ports_OutStatus            Proc Near   Uses ebx ecx edx esi edi
   ret
VLPT_Ports_OutStatus            EndP

; This routine gets control, when a byte (AL) is OUTed to a DMA-port (DX)
VLPT_Ports_InControl            Proc Near   Uses ebx ecx edx esi edi
   ret
VLPT_Ports_InControl            EndP

; This routine gets control, when a byte (AL) is READ from a DMA-port (DX)
VLPT_Ports_OutControl           Proc Near   Uses ebx ecx edx esi edi
   ret
VLPT_Ports_OutControl           EndP
