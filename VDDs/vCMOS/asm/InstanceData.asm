
Public CurVDMHandle
Public PROPERTY_WriteProtection
Public PROPERTY_PeriodicInterrupt

; -----------------------------------------------------------------------------

VDD_InstanceData:
CurVDMHandle                    dd ?

PROPERTY_WriteProtection        dd ?
PROPERTY_PeriodicInterrupt      dd ?

VCMOS_CurRegister               db ?     ; Current register of virtual CMOS
                                db ?     ; Filler

VCMOS_RTCAreaLen               equ 14
VCMOS_RTCArea                   db VCMOS_RTCAreaLen dup (?)

VDD_InstanceDataEnd:
