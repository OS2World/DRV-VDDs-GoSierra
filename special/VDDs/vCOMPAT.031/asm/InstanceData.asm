Public MyVDMHandle
Public PATCH_DeviceDriverInDOSptr,  PATCH_2GBLIMITinDOSptr
Public PATCH_CDROMinDOSptr,         PATCH_DPMITRIGinDOSptr
Public PATCH_INT25inDOSptr,         PATCH_JOYSTICKBIOSinDOSptr
Public PATCH_MOUSENSEinDOSptr
Public PATCH_NextPatchSegPtr
Public PROPERTY_DPMI,               PROPERTY_DPMIAntiCLI
Public PROPERTY_VMPatcherON,        PROPERTY_VMPatcherAUTO
Public TRIGGER_InINT21Execute,      TRIGGER_TurboPascalDPMI
Public TempV86seg
Public AutoVPMStiTimerHandle
Public FirstMCBpointer

; -----------------------------------------------------------------------------

VDD_InstanceData:
MyVDMHandle                     dd ?
PATCH_DeviceDriverInDOSptr      dd ?
PATCH_2GBLIMITinDOSptr          dd ?
PATCH_CDROMinDOSptr             dd ?
PATCH_DPMITRIGinDOSptr          dd ?
PATCH_INT25inDOSptr             dd ?
PATCH_JOYSTICKBIOSinDOSptr      dd ?
PATCH_MOUSENSEinDOSptr          dd ?
PATCH_NextPatchSegPtr           dd ?
PROPERTY_DPMI                   dd ?
PROPERTY_DPMIAntiCLI            dd ?
PROPERTY_VMPatcherON            dd ?
PROPERTY_VMPatcherAUTO          dd ?
TRIGGER_InINT21Execute          dd ? ; is set, if INT21h/4Bh till MVP-Hook
TRIGGER_TurboPascalDPMI         dd ? ; is set, if TP DPMI got detected

TempV86seg                      dw ?
AutoVPMStiTimerHandle           dd ?
FirstMCBpointer                 dd ? ; points to 1st MCB-Block in cur VDM

TempDWord                       dd ?


MemoryBlockStruc               Struc
   Handle          dd ?         ; Memory Block Handle
   LinearAddress   dd ?         ; Linear Address of Memory Block
   BlockLength     dd ?         ; Length of Memory Block
   Flags           dd ?         ; Bit 0 - Anti-CLI patched
MemoryBlockStruc               EndS
MemoryBlockStrucLen             equ 16

; Space for 128 memory blocks per VDM session - filled up by DPMIrouter.asm
MemoryBlockCount                dd ?
MemoryBlockCountMax             equ 128
MemoryBlocks:                   MemoryBlockStruc MemoryBlockCountMax dup (<?,?,?,?>)
MemoryBlocksEnd:

CodeSelectorCount               dd ?
CodeSelectorCountMax            equ 128
CodeSelectors:                  dw 128 dup (0)
CodeSelectorsEnd:

VDD_InstanceDataEnd:
