Public CONST_CR
Public CONST_VDMA
Public CONST_VSOUND
Public CONST_VCOMPAT
Public CONST_SOUND_MAIN
Public CONST_SOUND_COPYRIGHT
Public CONST_SOUND_DEBUG
Public CONST_SOUND_PASSTHRU
Public CONST_SOUND_TYPE
Public CONST_SOUND_TYPE_ENUM
Public CONST_SOUND_TYPE_NONE
Public CONST_SOUND_TYPE_SB
Public CONST_SOUND_TYPE_SBPRO
Public CONST_SOUND_TYPE_SB16
Public CONST_SOUND_MIXER

CONST_CR                       db 0Dh, 0Ah
CONST_VDMA                     db 'VDMA', 0
CONST_VSOUND                   db 'VSOUND', 0
CONST_VCOMPAT                  db 'VCOMPAT', 0
CONST_SOUND_MAIN               db 'HW_SOUND', 0
CONST_SOUND_COPYRIGHT          db 'vSOUND v0.1b', 0
                               db ' - (c) by Kiewitz in 2002,2006', 0
                               db ' - Dedicated to Gerd Kiewitz', 0, 0
CONST_SOUND_DEBUG              db 'HW_SOUND_DEBUG', 0
CONST_SOUND_PASSTHRU           db 'HW_SOUND_PASSTHRU', 0
CONST_SOUND_TYPE               db 'HW_SOUND_TYPE', 0
CONST_SOUND_TYPE_ENUM:
CONST_SOUND_TYPE_NONE          db 'None', 0
CONST_SOUND_TYPE_SB            db 'Soundblaster', 0
CONST_SOUND_TYPE_SBPRO         db 'Soundblaster PRO', 0
CONST_SOUND_TYPE_SB16          db 'Soundblaster 16', 0, 0
CONST_SOUND_MIXER              db 'HW_SOUND_MIXER', 0

CONST_Debug_PortOut            db 'OUT %x - %x', 0Dh, 0
CONST_Debug_PortIn             db 'IN  %x', 0Dh, 0

CONST_Debug_PassThru           db 'PASSTHRU-SINGLE ', 0
CONST_Debug_PassThruAuto       db 'PASSTHRU-AUTOINT', 0
CONST_Debug_PassThruPause      db 'PASSTHRU-PAUSE  ', 0
