
/* vCOMPAT is for OS/2 only */
/*  You may not reuse this source or parts of this source in any way and/or */
/*  (re)compile it for a different platform without the allowance of        */
/*  kiewitz@netlabs.org. It's (c) Copyright by Martin Kiewitz.              */

VOID VCOMPAT_PatchDeviceDriverHeaders                 (void);
VOID VCOMPAT_MagicVMPatcherInRM_TurboPascalCRT        (PCRF pcrf);
VOID VCOMPAT_MagicVMPatcherInRM_MS_C_TimerInitBug     (PCRF pcrf);
VOID VCOMPAT_MagicVMPatcherInRM_IRQDetection          (PCRF pcrf);
VOID VCOMPAT_MagicVMPatcherInPM_INT10                 (PCRF pcrf);
VOID VCOMPAT_MagicVMPatcherInPM_GetDPMIVersion        (PCRF pcrf);
VOID VCOMPAT_AutoVPMSti                               (PVOID p, PCRF pcrf);
