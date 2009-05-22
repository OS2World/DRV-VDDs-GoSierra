
; vCOMPAT is for OS/2 only */
;  You may not reuse this source or parts of this source in any way and/or
;  (re)compile it for a different platform without the allowance of
;  kiewitz@netlabs.org. It's (c) Copyright by Martin Kiewitz.

Public CONST_CR
Public CONST_VCOMPAT
Public CONST_COMPAT_MAIN
Public CONST_COMPAT_COPYRIGHT
Public CONST_COMPAT_2GBLIMIT
Public CONST_COMPAT_CDROM
Public CONST_COMPAT_CDROM_REPLACE
Public CONST_COMPAT_DEBUG
Public CONST_COMPAT_DPMI
Public CONST_COMPAT_DPMI_NOHOOK
Public CONST_COMPAT_DPMI_ANTICLI
Public CONST_COMPAT_DPMI_MEMORY
Public CONST_COMPAT_GOSIERRA
Public CONST_COMPAT_GOSIERRA_NOVSOUND
Public CONST_COMPAT_JOYSTICKBIOS
Public CONST_COMPAT_MAGICVMPATCHER
Public CONST_COMPAT_MAGICVM_ENUM
Public CONST_COMPAT_MAGICVM_AUTO
Public CONST_COMPAT_MAGICVM_ON
Public CONST_COMPAT_MAGICVM_OFF
Public CONST_COMPAT_MOUSENSE
Public CONST_DPMI_MEMORY_LIMIT

Public CONST_CDROM_CHARDEV
Public CONST_DPMDOS
Public CONST_VCDROM
Public CONST_VSOUND

Public CONST_PopUpStart
Public CONST_PopUpEnd

CONST_CR                       db 0Dh, 0Ah
CONST_VCOMPAT                  db 'VCOMPAT', 0
CONST_COMPAT_MAIN              db 'COMPATIBILITY', 0
CONST_COMPAT_COPYRIGHT         db 'vCOMPAT v0.35b', 0
                               db ' - (c) by Kiewitz in 2002-2003,2005-2006', 0
                               db ' - Dedicated to Gerd Kiewitz', 0, 0
CONST_COMPAT_2GBLIMIT          db 'COMPATIBILITY_2GBSIZELIMIT', 0
CONST_COMPAT_CDROM             db 'COMPATIBILITY_CDROM', 0
CONST_COMPAT_CDROM_REPLACE     db 'vCDROM Replacement detected!', 0, 0
CONST_COMPAT_DEBUG             db 'COMPATIBILITY_DEBUG', 0
CONST_COMPAT_DPMI              db 'COMPATIBILITY_DPMI', 0
CONST_COMPAT_DPMI_NOHOOK       db 'Could not hook into VDPMI!', 0, 0
CONST_COMPAT_DPMI_ANTICLI      db 'COMPATIBILITY_DPMI_ANTICLI', 0
CONST_COMPAT_DPMI_MEMORY       db 'COMPATIBILITY_DPMI_MEMORY', 0
CONST_COMPAT_GOSIERRA          db 'COMPATIBILITY_GOSIERRA', 0
CONST_COMPAT_GOSIERRA_NOVSOUND db 'DISABLED, vSOUND not detected', 0, 0
CONST_COMPAT_JOYSTICKBIOS      db 'COMPATIBILITY_JOYSTICKBIOS', 0
CONST_COMPAT_MAGICVMPATCHER    db 'COMPATIBILITY_MAGICVMPATCHER', 0
CONST_COMPAT_MAGICVM_ENUM:
CONST_COMPAT_MAGICVM_AUTO      db 'AUTOMATIC', 0
CONST_COMPAT_MAGICVM_ON        db 'ENABLED', 0
CONST_COMPAT_MAGICVM_OFF       db 'DISABLED', 0, 0
CONST_COMPAT_MOUSENSE          db 'COMPATIBILITY_MOUSESENSE', 0
CONST_DPMI_MEMORY_LIMIT        db 'DPMI_MEMORY_LIMIT', 0

CONST_CDROM_CHARDEV            db 'CD-ROM2$', 0
CONST_DPMDOS                   db 'DPMDOS', 0
CONST_VCDROM                   db 'VCDROM', 0
CONST_VSOUND                   db 'VSOUND', 0

CONST_PopUpStart               db '************************************************************', 13, 10
                               db 'vCOMPAT - Magical VM Patcher detected:', 13, 10
                               db ' =', 0
CONST_PopUpEnd                 db '=', 13, 10
                               db ' ', 13, 10
                               db '(Select IGNORE, if you DONT want to patch)', 13, 10
                               db '************************************************************', 0

CONST_Debug_EAX                db 'EAX=xxxx', 0
CONST_Debug_BXCX               db 'BXxxCXxx', 0
