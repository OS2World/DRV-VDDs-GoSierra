
Public VIRQ_Handle
Public VDMA_Handle
Public VDMA_ExtensionsFound
Public VCMOS_IRQ8OnVDM
Public VCMOS_StdRTCArea

; -----------------------------------------------------------------------------

VIRQ_Handle                     dd  0       ; Handle for virtual IRQ8
VDMA_Handle                     dd  0       ; Handle to VDMA
VDMA_ExtensionsFound            dd  0       ; Set, if Extensions are available

VCMOS_IRQ8OnVDM                 dd ?
VCMOS_IRQ8TimeOut               dd ?

; CMOS - Standard RTC Area (Register 0-13)
VCMOS_StdRTCArea                db 0FFh     ; Register 0 - Seconds
                                db 0FFh     ; Register 1 - Second Alarm
                                db 0FFh     ; Register 2 - Minutes
                                db 0FFh     ; Register 3 - Minute Alarm
                                db 0FFh     ; Register 4 - Hours
                                db 0FFh     ; Register 5 - Hour Alarm
                                db 0FFh     ; Register 6 - Day of Week
                                db 0FFh     ; Register 7 - Date
                                db 0FFh     ; Register 8 - Month
                                db 0FFh     ; Register 9 - Year
                                db  26h     ; Register A - Status Register A
                                db  02h     ; Register B - Status Register B
                                db  50h     ; Register C - Status Register C
                                db 0FFh     ; Register D - Status Register D

; Note: Register 0,2,4,6,7,8,9 are calculated on-the-fly and not taken from
;        that table. Also Register D is read from real CMOS, but writes to that
;        location will get reflected to the table (for ease of programming).

VCMOS_InTimeRegisterCodePtr     dd offset VCMOS_InOnRegSeconds
                                dd offset VCMOS_InOnRegSeconds
                                dd offset VCMOS_InOnRegMinutes
                                dd offset VCMOS_InOnRegMinutes
                                dd offset VCMOS_InOnRegHours
                                dd offset VCMOS_InOnRegHours
                                dd offset VCMOS_InOnRegDayOfWeek
                                dd offset VCMOS_InOnRegDate
                                dd offset VCMOS_InOnRegMonth
                                dd offset VCMOS_InOnRegYear

VCMOS_TimerRateTable            dw    0 ; Disabled
                                dw    0 ;  30 microseconds (unsupported)
                                dw    0 ;  61 microseconds (unsupported)
                                dw    0 ; 122 microseconds (unsupported)
                                dw    0 ; 244 microseconds (unsupported)
                                dw    0 ; 488 microseconds (unsupported)
                                dw    1 ; 976 microseconds -> 1024x per second
                                dw    2 ; 1.9 milliseconds -> 512x per second
                                dw    4 ; 3.9 milliseconds -> 256x per second
                                dw    8 ; -> 128x per second
                                dw   16 ; -> 64x per second
                                dw   32 ; -> 32x per second
                                dw   64 ; -> 16x per second
                                dw  128 ; -> 8x per second
                                dw  256 ; -> 4x per second
                                dw  512 ; -> 2x per second
