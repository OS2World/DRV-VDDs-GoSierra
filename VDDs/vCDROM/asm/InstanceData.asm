
Public CurVDMHandle
Public CDROM_CHARDEV_Information
Public CDROM_DriveCount
Public CDROM_FirstDriveNo
Public PROPERTY_INTDuringIO

Public VCDROM_APIBreakPoint
Public VCDROM_DDHeaderSegment
Public VCDROM_DDBreakPoint

Public VPIC_Handle
Public VPIC_SlaveRequestFunc
Public VPIC_SlaveFSCTL

; -----------------------------------------------------------------------------

VDD_InstanceData:
CurVDMHandle                    dd ?
CurCRFPtr                       dd ?

; This information package is taken from CD-ROM2$ (ffs. VCDROM.c)
CDROM_CHARDEV_Information:
CDROM_DriveCount                dw ?
CDROM_FirstDriveNo              dw ?

PROPERTY_INTDuringIO            dd ?

TRIGGER_INT2FHooked             dd ?
TRIGGER_DriveLocked             dd 26 dup (?)
TRIGGER_MediaChanged            dd 26 dup (?)

VCDROM_APIBreakPoint            dd ?
VCDROM_DDHeaderSegment          dw ?
VCDROM_DDBreakPoint             dd ?

VCDROM_DDCodePtr                dd ?

VCDROM_Audio_LastPos            dd 26 dup (?)
VCDROM_Audio_LastEnd            dd 26 dup (?)
VCDROM_Audio_Paused             dd 26 dup (?)

VCDROM_CurDeviceStatus          dd ?
VCDROM_DevStat_AudioReadable   equ 40000000h
VCDROM_DevStat_IsAudioPlaying  equ 00001000h
VCDROM_DevStat_IsDiskPresent   equ 00000800h
VCDROM_DevStat_RedBookSupport  equ 00000200h
VCDROM_DevStat_QChannelMod     equ 00000100h
VCDROM_DevStat_PrefetchSupport equ 00000080h
VCDROM_DevStat_Interleaveable  equ 00000020h
VCDROM_DevStat_IsAudioCapable  equ 00000010h
VCDROM_DevStat_WriteSupport    equ 00000008h
VCDROM_DevStat_RawReadSupport  equ 00000004h
VCDROM_DevStat_IsDoorUnlocked  equ 00000002h
VCDROM_DevStat_IsDoorOpen      equ 00000001h

VCDROM_TempActionTaken          dd ?
VCDROM_TempMediaChanged         dw ?

; Holds all access drive handles in a table (0-A:, 1-B:, etc.)
VCDROM_HandleTable              dw 26 dup (?)

VCDROM_IOParmLength             dd ?
VCDROM_IOParm                   db 16 dup (?)
VCDROM_IODataPtr                dd ?
VCDROM_IODataMaxLength          dd ?
VCDROM_IODataLength             dd ?
VCDROM_IOData                   db 16 dup (?)

VCDROM_FSCTLParmLength          dd ?
VCDROM_FSCTLParm                db 256+16 dup (?)
VCDROM_FSCTLDataLength          dd ?

VPIC_Handle                     dd ?
VPIC_SlaveRequestFunc           dd ?
VPIC_SlaveFSCTL:                dd 10 dup (?) ; Help-Buffer for SlaveRequest

VDD_InstanceDataEnd:
