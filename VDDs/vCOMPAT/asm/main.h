
/* vCOMPAT is for OS/2 only */
/*  You may not reuse this source or parts of this source in any way and/or */
/*  (re)compile it for a different platform without the allowance of        */
/*  kiewitz@netlabs.org. It's (c) Copyright by Martin Kiewitz.              */

#include <16bit\modules.h>

/* CONST.asm */
extern char     CONST_CR;
extern char     CONST_VCOMPAT;
extern char     CONST_COMPAT_InitMessage;
extern char     CONST_COMPAT_MAIN;
extern char     CONST_COMPAT_COPYRIGHT;
extern char     CONST_COMPAT_2GBLIMIT;
extern char     CONST_COMPAT_CDROM;
extern char     CONST_COMPAT_CDROM_REPLACE;
extern char     CONST_COMPAT_DEBUG;
extern char     CONST_COMPAT_DPMI;
extern char     CONST_COMPAT_DPMI_NOHOOK;
extern char     CONST_COMPAT_DPMI_ANTICLI;
extern char     CONST_COMPAT_DPMI_MEMORY;
extern char     CONST_COMPAT_GOSIERRA;
extern char     CONST_COMPAT_GOSIERRA_NOVSOUND;
extern char     CONST_COMPAT_JOYSTICKBIOS;
extern char     CONST_COMPAT_MAGICVMPATCHER;
extern char     CONST_COMPAT_MAGICVM_ENUM;
extern char     CONST_COMPAT_MAGICVM_AUTO;
extern char     CONST_COMPAT_MAGICVM_ON;
extern char     CONST_COMPAT_MAGICVM_OFF;
extern char     CONST_COMPAT_MOUSENSE;
extern char     CONST_DPMI_MEMORY_LIMIT;

extern char     CONST_CDROM_CHARDEV;
extern char     CONST_COMPAT_DevName;
extern char     CONST_DPMDOS;
extern char     CONST_VCDROM;
extern char     CONST_VSOUND;

extern char     CONST_PopUpStart;
extern char     CONST_PopUpEnd;

/* GlobalData.asm */
extern PUCHAR   OrgINT31RouterPtr;
extern PUCHAR   OrgINT31CreateTaskPtr;
extern PUCHAR   OrgINT31EndTaskPtr;
extern PUCHAR   OrgINT31QueryPtr;
extern BOOL     TRIGGER_VCDROMReplacement;
extern BOOL     TRIGGER_VSOUNDFound;
extern BOOL     TRIGGER_VDPMIHooked;

/* MagicVMP_data.inc */
extern uchar    MagicVMPData_TurboPascalCRT;
extern uchar    MagicVMPData_MicrosuckC;
extern uchar    MagicVMPData_Clipper;
extern uchar    MagicVMPData_SierraDriverBugType1;
extern uchar    MagicVMPData_SierraDriverBugType1b;
extern uchar    MagicVMPData_SierraDriverBugType2;
extern uchar    MagicVMPData_SierraDriverBugType2b;
extern uchar    MagicVMPData_SierraDriverBugType3;
extern uchar    MagicVMPData_SierraDriverBugDynamix;
extern uchar    MagicVMPData_INT31Router;
extern uchar    MagicVMPData_INT31CreateTask;
extern uchar    MagicVMPData_INT31CreateTaskWarp3;
extern uchar    MagicVMPData_INT31EndTask;
extern uchar    MagicVMPData_INT31Query;

// Variables in Instance Data-Segment (for every VDM)
extern HFILE    DebugFileHandle;
extern HVDM     CurVDMHandle;
extern VPVOID   VCOMPAT_APIBreakPoint;
extern PBVDM    PATCH_DeviceDriverInDOSptr;
extern PBVDM    PATCH_2GBLIMITinDOSptr;
extern PBVDM    PATCH_CDROMinDOSptr;
extern PBVDM    PATCH_DPMITRIGinDOSptr;
extern PBVDM    PATCH_INT25inDOSptr;
extern PBVDM    PATCH_JOYSTICKBIOSinDOSptr;
extern PBVDM    PATCH_MOUSENSEinDOSptr;
extern PBVDM    PATCH_FirstPatchSegPtr;
extern PBVDM    PATCH_LastPatchSegPtr;
extern BOOL     PROPERTY_DEBUG;
extern BOOL     PROPERTY_DPMI;
extern BOOL     PROPERTY_DPMIAntiCLI;
extern BOOL     PROPERTY_DPMIMemory;
extern BOOL     PROPERTY_DPMIMemoryLimit;
extern BOOL     PROPERTY_GOSIERRA;
extern BOOL     PROPERTY_VMPatcherON;
extern BOOL     PROPERTY_VMPatcherAUTO;
extern BOOL     TRIGGER_InINT21Execute;
extern BOOL     TRIGGER_TurboPascalDPMI;
extern BOOL     TRIGGER_CompatDDInstalled;

extern CHAR     CDROM_CHARDEV_Information;
extern USHORT   CDROM_DriveCount;
extern USHORT   CDROM_FirstDriveNo;

extern HHOOK    AutoVPMStiTimerHandle;

extern PUCHAR   PTR_FirstMCB;            // -> first MCB-Block in current VDM
extern PVOID    PTR_ListOfLists;         // -> ListOfLists (AH=52h/INT21)

/* printf.asm */
extern ULONG    StrLen (PSZ StringPtr);
extern ULONG    StrCpy (PSZ StringPtr, ULONG StringSize, PSZ SourcePtr);
extern ULONG    InternalSPrintF (PSZ StringPtr, ULONG StringSize, PSZ FormatPtr, PVOID FormatDataPtr);

/* Instance.asm */
extern VOID     VDD_INT3();
extern VOID     VDD_InitInstanceData();
extern VOID     VDD_ResetMemSelTable();
extern VOID     VCOMPAT_InitPatchModules();
extern BOOL     VCOMPAT_APIEntry(PVOID pHookData, PCRF pcrf);

/* MagicVMP.asm */
extern PCHAR    MagicVMP_GetNamePtr (uchar *VMPBundlePtr);
extern void     MagicVMP_BuildPopUpMessage(uchar *VMPBundlePtr, uchar *MessagePtr);
extern PUCHAR   MagicVMP_SearchSignature  (uchar *VMPBundlePtr, uchar *AreaPtr, ulong AreaLength);
extern PUCHAR   MagicVMP_SearchSignatureInSel (uchar *VMPBundlePtr, ulong MaxSize);

extern void     MagicVMP_ApplyPatch       (uchar *VMPBundlePtr, uchar *SignaturePtr);
extern void     MagicVMP_DoAntiCLI        ();
extern void     MagicVMP_DoRemoveTPCRTbug ();

/* DPMIrouter.asm */
extern void     DPMIRouter_InjectedCode   ();

/* V86Hooks.asm */
extern void     V86PreHook_INT21h         ();

/* VDD-API.asm */
extern BOOL      VDDAPI ();
