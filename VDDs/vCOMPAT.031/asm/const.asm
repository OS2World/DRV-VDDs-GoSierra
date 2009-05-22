public CONST_COMPAT_MAIN
public CONST_COMPAT_COPYRIGHT
public CONST_COMPAT_2GBLIMIT
public CONST_COMPAT_CDROM
public CONST_COMPAT_DPMI
public CONST_COMPAT_DPMI_NOHOOK
public CONST_COMPAT_DPMI_ANTICLI
public CONST_COMPAT_JOYSTICKBIOS
public CONST_COMPAT_MAGICVMPATCHER
public CONST_COMPAT_MAGICVM_ENUM
public CONST_COMPAT_MAGICVM_AUTO
public CONST_COMPAT_MAGICVM_ON
public CONST_COMPAT_MAGICVM_OFF
public CONST_COMPAT_MOUSENSE
public CONST_COMPAT_DevName
public CONST_DPMDOS

CONST_COMPAT_MAIN:           db 'COMPATIBILITY', 0
CONST_COMPAT_COPYRIGHT:      db 'vCOMPAT v0.31b - (c) by Kiewitz in 2002', 0
                             db ' - Dedicated to Gerd Kiewitz', 0, 0
CONST_COMPAT_2GBLIMIT:       db 'COMPATIBILITY_2GBSIZELIMIT', 0
CONST_COMPAT_CDROM:          db 'COMPATIBILITY_CDROM', 0
CONST_COMPAT_DPMI:           db 'COMPATIBILITY_DPMI', 0
CONST_COMPAT_DPMI_NOHOOK     db 'Could not hook into VDPMI!', 0, 0
CONST_COMPAT_DPMI_ANTICLI:   db 'COMPATIBILITY_DPMI_ANTICLI', 0
CONST_COMPAT_JOYSTICKBIOS:   db 'COMPATIBILITY_JOYSTICKBIOS', 0
CONST_COMPAT_MAGICVMPATCHER: db 'COMPATIBILITY_MAGICVMPATCHER', 0
CONST_COMPAT_MAGICVM_ENUM:
CONST_COMPAT_MAGICVM_AUTO:   db 'AUTOMATIC', 0
CONST_COMPAT_MAGICVM_ON:     db 'ENABLED', 0
CONST_COMPAT_MAGICVM_OFF:    db 'DISABLED', 0, 0
CONST_COMPAT_MOUSENSE:       db 'COMPATIBILITY_MOUSESENSE', 0

CONST_COMPAT_DevName:        db 'VCOMPAT$', 0
CONST_DPMDOS:                db 'DPMDOS', 0

RegFrame                       Struc
   Client_EDI      dd ?
   Client_ESI      dd ?
   Client_EBP      dd ?
   Client_PadESP   dd ?
   Client_EBX      dd ?
   Client_EDX      dd ?
   Client_ECX      dd ?
   Client_EAX      dd ?
   Client_TrapNum  dd ?                  ; Only filled out when interrupt time
   Client_ErrCode  dd ?                  ; ditto...
   Client_EIP      dd ?
   Client_CS       dw ?
   Client_PadCS    dw ?
   Client_EFLAGS   dd ?
   Client_ESP      dd ?
   Client_SS       dw ?
   Client_PadSS    dw ?
   Client_ES       dw ?
   Client_PadES    dw ?
   Client_DS       dw ?
   Client_PadDS    dw ?
   Client_FS       dw ?
   Client_PadFS    dw ?
   Client_GS       dw ?
   Client_PadGS    dw ?
RegFrame                       EndS

EFLAGS_Carry                    equ 00000001b
