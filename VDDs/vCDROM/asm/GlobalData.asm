
Public VCDROM_DeviceDriverHeader
Public VCDROM_DeviceDriverCode
;Public VPIC_Handle
;Public VPIC_SlaveRequestFunc

; -----------------------------------------------------------------------------

VCDROM_DeviceDriverHeader:      dd -1       ; Pointer to next DD-Header
                                dw 0C800h   ; Flags (Char/IOCTL/Removable)
                                dw 0FFFFh   ; Offset to Strategy (filled out)
                                dw 0FFFFh   ; Offset to Interrupt (filled out)
                                db 'MSCD000 '
                                dw 0        ; Reserved (has to be 0)
                                db 0        ; Drive-Letter (last one, if multi)
                                            ; 0-A:, 1-B:, 2-C:, etc.
                                db 1        ; Number of units
                                dd 0        ; Space for Request Header pointer
                                dw 0, 0, 0  ; Filler
                                ; 32 bytes - 2x 16-byte chunks
VCDROM_DeviceDriverHeaderLen   equ 32
VCDROM_DDHeader_ReqHeaderPtr   equ 23

; Please note that this code is called using different offsets, so no absolute
;  offsets may get used. DD-Header will be at offset 0, but nothing else.
;  The code will get called from different offsets depending on the DD-Header.
;  Make sure that only relative jumps are used, otherwise the code will fail.
;  The Ring-0 PM code will find out to which the call belongs by looking at
;  the callers CS. CS will in that case point to the specific DD-Header.
VCDROM_DeviceDriverCode:        ; Strategy-Entry (11 bytes)
                                db 2Eh, 89h, 1Eh    ; MOV CS:[xx], BX
                                dw 23               ; To [RequestHeaderSpace]
                                db 2Eh, 8Ch, 06h    ; MOV CS:[xx], ES
                                dw 25               ; To [RequestHeaderSpace+2]
                                db 0CBh             ; RETF
                                ; Interrupt-Entry (7 bytes)
                                db 9Ch              ; PUSHF
                                db 9Ah              ; CALL FAR to ARPL
                                dw 0FFFFh, 0FFFFh
                                db 0CBh             ; RETF
                                ; INT2Fh interrupt hook
                                db 80h, 0FCh, 15h   ; CMP AH, 15h
                                db 75h, 05h         ; JNZ -> JMP OLD INT 2Fh
                                db 0EAh             ; JMP FAR to ARPL
                                dw 0FFFFh, 0FFFFh
                                db 0EAh             ; JMP FAR OLD INT 2Fh
                                dw 0FFFFh, 0FFFFh
                                db 0, 0, 0
                                dw 0, 0, 0, 0, 0, 0
                                ; 48 bytes - 3x 16-byte chunks
VCDROM_DeviceDriverCodeLen     equ 48
VCDROM_DDCode_Strategy         equ  0
VCDROM_DDCode_Interrupt        equ 11
VCDROM_DDCode_Interrupt_Patch1 equ 13       ; -> ARPL-Address of DD-BreakPoint
VCDROM_DDCode_INT2F            equ 18
VCDROM_DDCode_INT2F_Patch1     equ 24       ; -> ARPL-Address of 2F-BreakPoint
VCDROM_DDCode_INT2F_Patch2     equ 29       ; -> Old INT2Fh EntryPoint (resume)

VCDROM_DriveNameTable           dw ':A', 0, ':B', 0, ':C', 0, ':D', 0, ':E', 0
                                dw ':F', 0, ':G', 0, ':H', 0, ':I', 0, ':J', 0
                                dw ':K', 0, ':L', 0, ':M', 0, ':N', 0, ':O', 0
                                dw ':P', 0, ':Q', 0, ':R', 0, ':S', 0, ':T', 0
                                dw ':U', 0, ':V', 0, ':W', 0, ':X', 0, ':Y', 0
                                dw ':Z', 0

;VPIC_Handle                     dd 0
;VPIC_SlaveRequestFunc           dd 0

VCDROM_DriveLockCount           dd 26 dup (0)
