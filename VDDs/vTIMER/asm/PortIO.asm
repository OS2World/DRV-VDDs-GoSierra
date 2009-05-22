
Public VTIMER_InOnPITCounter
Public VTIMER_OutOnPITCounter
Public VTIMER_InOnPITMode
Public VTIMER_OutOnPITMode
Public VTIMER_InOnKeyboard
Public VTIMER_OutOnKeyboard

; -----------------------------------------------------------------------------

; This routine gets control, when a byte (AL) is OUTed to a DMA-port (DX)
VTIMER_OutOnPITCounter          Proc Near   Uses ebx ecx edx esi edi
   ret
VTIMER_OutOnPITCounter          EndP

; This routine gets control, when a byte (AL) is READ from a DMA-port (DX)
VTIMER_InOnPITCounter           Proc Near   Uses ebx ecx edx esi edi
   ret
VTIMER_InOnPITCounter           EndP

; This routine gets control, when a byte (AL) is OUTed to a DMA-port (DX)
VTIMER_OutOnPITMode             Proc Near   Uses ebx ecx edx esi edi
   ret
VTIMER_OutOnPITMode             EndP

; This routine gets control, when a byte (AL) is READ from a DMA-port (DX)
VTIMER_InOnPITMode              Proc Near   Uses ebx ecx edx esi edi
   mov     al, 0FFh             ; Reply with 0FFh (std reply from empty ports)
   ret
VTIMER_InOnPITMode              EndP

; This routine gets control, when a byte (AL) is OUTed to a DMA-port (DX)
VTIMER_OutOnKeyboard            Proc Near   Uses ebx ecx edx esi edi
   ret
VTIMER_OutOnKeyboard            EndP

; This routine gets control, when a byte (AL) is READ from a DMA-port (DX)
VTIMER_InOnKeyboard             Proc Near   Uses ebx ecx edx esi edi
   ; Bit 0 - "Timer 2 gate to speaker enable"
   ; Bit 1 - "Speaker data enable"
   ; Bit 4 - Toogle with each refresh request (INP)
   ; Everything else should be read as 30h
   ret
VTIMER_InOnKeyboard             EndP
