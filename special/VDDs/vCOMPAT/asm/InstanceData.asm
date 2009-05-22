; vCOMPAT is for OS/2 only */
;  You may not reuse this source or parts of this source in any way and/or
;  (re)compile it for a different platform without the allowance of
;  kiewitz@netlabs.org. It's (c) Copyright by Martin Kiewitz.

Public DebugFileHandle
Public CurVDMHandle
Public VCOMPAT_APIBreakPoint
Public PATCH_DeviceDriverInDOSptr,  PATCH_2GBLIMITinDOSptr
Public PATCH_CDROMinDOSptr,         PATCH_DPMITRIGinDOSptr
Public PATCH_INT25inDOSptr,         PATCH_JOYSTICKBIOSinDOSptr
Public PATCH_MOUSENSEinDOSptr
Public PATCH_FirstPatchSegPtr,      PATCH_LastPatchSegPtr
Public PROPERTY_DEBUG
Public PROPERTY_DPMI,               PROPERTY_DPMIAntiCLI
Public PROPERTY_DPMIMemory,         PROPERTY_DPMIMemoryLimit
Public PROPERTY_GOSIERRA
Public PROPERTY_VMPatcherON,        PROPERTY_VMPatcherAUTO
Public TRIGGER_InINT21Execute,      TRIGGER_TurboPascalDPMI
Public TRIGGER_CompatDDInstalled
Public CDROM_CHARDEV_Information
Public CDROM_DriveCount,            CDROM_FirstDriveNo
;Public TempV86seg
Public AutoVPMStiTimerHandle
Public PTR_FirstMCB,                PTR_ListOfLists

; -----------------------------------------------------------------------------

VDD_InstanceData:
DebugFileHandle                 dd ?
CurVDMHandle                    dd ?
VCOMPAT_APIBreakPoint           dd ?
PATCH_DeviceDriverInDOSptr      dd ?
PATCH_2GBLIMITinDOSptr          dd ?
PATCH_CDROMinDOSptr             dd ?
PATCH_DPMITRIGinDOSptr          dd ?
PATCH_INT25inDOSptr             dd ?
PATCH_JOYSTICKBIOSinDOSptr      dd ?
PATCH_MOUSENSEinDOSptr          dd ?
PATCH_FirstPatchSegPtr          dd ?
PATCH_LastPatchSegPtr           dd ?
PROPERTY_DEBUG                  dd ?
PROPERTY_DPMI                   dd ?
PROPERTY_DPMIAntiCLI            dd ?
PROPERTY_DPMIMemory             dd ?
PROPERTY_DPMIMemoryLimit        dd ?
PROPERTY_GOSIERRA               dd ?
PROPERTY_VMPatcherON            dd ?
PROPERTY_VMPatcherAUTO          dd ?
TRIGGER_InINT21Execute          dd ? ; is set, if INT21h/4Bh till MVP-Hook
TRIGGER_TurboPascalDPMI         dd ? ; is set, if TP DPMI got detected
TRIGGER_CompatDDInstalled       dd ?

; This information package is taken from CD-ROM2$ (ffs. VCDROM.c)
CDROM_CHARDEV_Information:
CDROM_DriveCount                dw ?
CDROM_FirstDriveNo              dw ?

;TempV86seg                      dw ?
AutoVPMStiTimerHandle           dd ?
TempDWord                       dd ?

PTR_FirstMCB                    dd ? ; points to 1st MCB-Block in cur VDM
PTR_ListOfLists                 dd ? ; points to List-Of-Lists

MemoryBlockStruc               Struc
   Handle          dd ?         ; Memory Block Handle
   LinearAddress   dd ?         ; Linear Address of Memory Block
   BlockLength     dd ?         ; Length of Memory Block
   Flags           dd ?         ; Bit 0 - Anti-CLI patched
MemoryBlockStruc               EndS
MemoryBlockStrucLen             equ 16

; Space for original code during MagicVMP_ApplyPatch()
MagicVMP_OriginalCodeSize       equ 256
MagicVMP_OriginalCode           db MagicVMP_OriginalCodeSize dup (?)

DPMI_OriginalFreeMemorySize     equ 12*4
DPMI_OriginalFreeMemory         dd 12 dup (?)
DPMI_OriginalFreeMemoryOffset   dd ?

; Space for 128 memory blocks per VDM session - filled up by DPMIrouter.asm
MemoryBlockCount                dd ?
MemoryBlockCountMax             equ 128
MemoryBlocks:                   MemoryBlockStruc MemoryBlockCountMax dup (<?,?,?,?>)
MemoryBlocksEnd:

CodeSelectorCount               dd ?
CodeSelectorCountMax            equ 128
CodeSelectors:                  dw 128 dup (?)
CodeSelectorsEnd:

VDD_InstanceDataEnd:
