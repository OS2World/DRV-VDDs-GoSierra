
; vCOMPAT is for OS/2 only */
;  You may not reuse this source or parts of this source in any way and/or
;  (re)compile it for a different platform without the allowance of
;  kiewitz@netlabs.org. It's (c) Copyright by Martin Kiewitz.

; VDM-externals
extern _flVdmStatus:dword
extern _TKSSBase:near
extern VDHKillVDM:near
extern VDHPopInt:near
extern VDHReadUBuf:near
extern VDHWriteUBuf:near
extern VDHGetSelBase:near
extern VDHCheckPagePerm:near
extern VDHYield:near

VdmStatus_VPM32BIT              equ       1h

extern DebugPrint:near
extern DebugPrintCR:near
extern DebugWriteBin:near

extern VCOMPAT_PatchDeviceDriverHeaders:near
extern VCOMPAT_MagicVMPatcherInRM_TurboPascalCRT:near
extern VCOMPAT_MagicVMPatcherInRM_MS_C_TimerInitBug:near
extern VCOMPAT_MagicVMPatcherInRM_Clipper_TimerBug:near
extern VCOMPAT_MagicVMPatcherInRM_IRQDetection:near
extern VCOMPAT_MagicVMPatcherInPM_INT10:near
