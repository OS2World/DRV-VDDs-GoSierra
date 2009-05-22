
/* vCOMPAT is for OS/2 only */
/*  You may not reuse this source or parts of this source in any way and/or */
/*  (re)compile it for a different platform without the allowance of        */
/*  kiewitz@netlabs.org. It's (c) Copyright by Martin Kiewitz.              */

#include <mvdmndoc.h>
#define INCL_VDH
#define INCL_VDHVDMA
#define INCL_SSTODS
#include <mvdm.h>                       /* VDH services, etc.        */
#include <mvdmdpmi.h>                   /* VDPMI Stuff - VDHRegisterDPMI */

#include <globaldefs.h>
#include <vdd_str.h>
#include <..\API\VDD-API.h>
#include <magicvmp.h>
#include <asm\main.h>
#include <..\API\udocumnt.h>            // Undocumented features of MVDM

#include <..\API\debug.c>

// ============================================================================

PBVDM InstallPatchModule (char *PatchModulePtr, ushort PatchModuleLen) {
   PBVDM ModuleInDOSptr = NULL;

   ModuleInDOSptr = VDHAllocDosMem(PatchModuleLen);
   if (ModuleInDOSptr) {
      // Copy Patch-Module to VDM Memory Buffer
      VDHCopyMem(PatchModulePtr, ModuleInDOSptr, PatchModuleLen);

      // Patch current Segment into NextPatchSegment
      if (TRIGGER_CompatDDInstalled) {
         // Put that segment into the LastPatchSegment offset 0
         if (PATCH_LastPatchSegPtr) {
            *(PULONG)(PATCH_LastPatchSegPtr) = HISEG(ModuleInDOSptr);
          } else {
            PATCH_FirstPatchSegPtr = ModuleInDOSptr;
          }
         PATCH_LastPatchSegPtr = ModuleInDOSptr+0;
       } else {
         // We just injected our Help-Devicedriver into VDM...
         TRIGGER_CompatDDInstalled = TRUE;
         // Now patch in our BP-Hook address, so that we can get called
         //  It's hardcoded to offset 18, so put it there
         *(PULONG)(ModuleInDOSptr+18) = (ULONG)VCOMPAT_APIBreakPoint;
       }
    }
   return ModuleInDOSptr;
 }

// ============================================================================
// This routine is called on every VDM creation...

BOOL HOOKENTRY VDMCreate (HVDM VDMHandle) {
   PCHAR  PropertyVMPatcher;
   ULONG  ActionTaken;
   HFILE  TempHandle = 0;
   ULONG  ParmLength = 0;
   ULONG  DataLength = 0;
   HHOOK  TempHook   = 0;
   ULONG  DebugFileAction;

   // Initialize Instance-Variables...
   VDD_InitInstanceData();

   // Safety check, if we were called with a handle in hvdm.
   if ((CurVDMHandle = VDMHandle) == NULL) return FALSE;

   // Create BreakPoint Hook for interaction with Help-DD and Patch-Modules
   TempHook = VDHAllocHook(VDH_BP_HOOK, (PFNARM)&VCOMPAT_APIEntry, 0);
   if (TempHook) VCOMPAT_APIBreakPoint = VDHArmBPHook(TempHook);

   // First, we have to install our little DOS Helper Device Driver to hook
   //  correctly into DOS interrupts...
   PATCH_DeviceDriverInDOSptr = InstallPatchModule(&PATCH_COMPATDD, PATCH_COMPATDDlength);
   if (PATCH_DeviceDriverInDOSptr) {
      // Tell OS/2 to load this Helper DOS Device Driver
      VDHSetDosDevice( (VPDOSDDTYPE)VPFROMP(PATCH_DeviceDriverInDOSptr) );
    }

   // Now install various mandatory Compatibility Patches
   PATCH_INT25inDOSptr    = InstallPatchModule(&PATCH_INT25, PATCH_INT25length);

   // Now install the remaining Compatibility Patches, if wanted by property
   if (VDHQueryProperty(&CONST_COMPAT_2GBLIMIT))
      PATCH_2GBLIMITinDOSptr = InstallPatchModule(&PATCH_2GBLIMIT, PATCH_2GBLIMITlength);

   // CD-ROM related patch-module(s)...
   if (VDHOpen(&CONST_CDROM_CHARDEV, SSToDS(&TempHandle), SSToDS(&ActionTaken), 0, 0, VDHOPEN_FILE_EXISTED, 0x2040, 0)) {
      // CD-ROM2$ got opened...
      ParmLength = 0;
      DataLength = 4; // We receive 2 USHORTs from CD-ROM2$
      if (VDHDevIOCtl(TempHandle, 0x82, 0x60, NULL, ParmLength, SSToDS(&ParmLength),
           &CDROM_CHARDEV_Information, DataLength, SSToDS(&DataLength))) {
         // Got information, check if we got CD-ROMs on this system...
         if (CDROM_DriveCount) {
            if (TRIGGER_VCDROMReplacement) {
               // Our new vCDROM got detected, so automatically install the
               //  small CD-ROM IFS patch in any case...
               PATCH_CDROMinDOSptr = InstallPatchModule(&PATCH_CDROMREP, PATCH_CDROMREPlength);
             } else {
               if (VDHQueryProperty(&CONST_COMPAT_CDROM))
                  PATCH_CDROMinDOSptr = InstallPatchModule(&PATCH_CDROM, PATCH_CDROMlength);
             }
          }
       }
      VDHClose (TempHandle);
    }

   if (TRIGGER_VDPMIHooked) {
      // Check DPMI Properties...
      PROPERTY_DPMI        = VDHQueryProperty(&CONST_COMPAT_DPMI);
      PROPERTY_DPMIAntiCLI = VDHQueryProperty(&CONST_COMPAT_DPMI_ANTICLI);
      PROPERTY_DPMIMemory  = VDHQueryProperty(&CONST_COMPAT_DPMI_MEMORY);
      PROPERTY_DPMIMemoryLimit = VDHQueryProperty(&CONST_DPMI_MEMORY_LIMIT);
    }

   if (PROPERTY_DPMI)
      PATCH_DPMITRIGinDOSptr = InstallPatchModule(&PATCH_DPMITRIG, PATCH_DPMITRIGlength);
   if (VDHQueryProperty(&CONST_COMPAT_MOUSENSE))
      PATCH_MOUSENSEinDOSptr = InstallPatchModule(&PATCH_MOUSENSE, PATCH_MOUSENSElength);
   if (VDHQueryProperty(&CONST_COMPAT_JOYSTICKBIOS))
      PATCH_JOYSTICKBIOSinDOSptr = InstallPatchModule(&PATCH_JOYSTICK, PATCH_JOYSTICKlength);

   // Check VM-Patcher Property...
   PROPERTY_VMPatcherON = TRUE; PROPERTY_VMPatcherAUTO = FALSE;
   PropertyVMPatcher = (PCHAR)VDHQueryProperty(&CONST_COMPAT_MAGICVMPATCHER);
   if (PropertyVMPatcher) {
      if (dd_strcmp(PropertyVMPatcher,&CONST_COMPAT_MAGICVM_AUTO)==0)
         PROPERTY_VMPatcherAUTO = TRUE;
      if (dd_strcmp(PropertyVMPatcher,&CONST_COMPAT_MAGICVM_OFF)==0)
         PROPERTY_VMPatcherON   = FALSE;
    }

   if (PROPERTY_DPMIAntiCLI) { // Install Anti-CLI Timer, if requested...
      AutoVPMStiTimerHandle = VDHAllocHook(VDH_TIMER_HOOK, (PFNARM)VCOMPAT_AutoVPMSti, 4);
      VDHArmTimerHook (AutoVPMStiTimerHandle, 50, CurVDMHandle);
    }

   // Check GOSIERRA Property...
   if (TRIGGER_VSOUNDFound) {
      PROPERTY_GOSIERRA    = VDHQueryProperty(&CONST_COMPAT_GOSIERRA);
    } else {
      PROPERTY_GOSIERRA    = FALSE;
    }

   // Hook into various interrupts as prereflection-hook (occurs before turning
   //  those interrupts into V86 mode and after all Protected-Mode hooks)
   if (!(VDHInstallIntHook(0,0x21,&V86PreHook_INT21h,VDH_ASM_HOOK|VDH_PRE_HOOK)))
      return FALSE;

//   PROPERTY_DEBUG = VDHQueryProperty(&CONST_COMPAT_DEBUG);
   PROPERTY_DEBUG = FALSE;
   if (PROPERTY_DEBUG) {
      // Create/Open a debug file
      VDHOpen("C:\\VCOMPAT.log", &DebugFileHandle, (PVOID)&DebugFileAction, 0, VDHOPEN_FILE_NORMAL, VDHOPEN_FILE_REPLACE|VDHOPEN_ACTION_CREATE_IF_NEW, VDHOPEN_ACCESS_READWRITE|VDHOPEN_SHARE_DENYNONE, NULL);
      DebugPrintCR("vCOMPAT - debug output");
    }

   return TRUE;
 }

// This routine is called on every VDM termination...
BOOL HOOKENTRY VDMTerminate (HVDM VDMHandle) {
   if (PROPERTY_DEBUG) {
      VDHClose(DebugFileHandle);
    }
   return TRUE;
 }

#pragma entry(Init)

// Called at sysinit time to initialize VDD. Runs at r0
// and must return TRUE to successfully load the VDD
BOOL _pascal Init(char *CmdLine) {
   HVDD   VDDHandle;
   PUCHAR VDPMIPointerTable[3];
   DPMX   DPMIExports;
   VPMX   DPMIImports;
   BOOL   DPMIGotEntries = FALSE;

   // install our create/exit hook 
   if (VDHInstallUserHook(VDM_CREATE,(PFNARM)VDMCreate) != VDH_SUCCESS)
      return FALSE;
   if (VDHInstallUserHook(VDM_TERMINATE,(PFNARM)VDMTerminate) != VDH_SUCCESS)
      return FALSE;

   // Install Property that contains Copyright message
   if (VDHRegisterProperty(&CONST_COMPAT_MAIN, NULL, 0, VDMP_ENUM, VDMP_ORD_OTHER, VDMP_CREATE, &CONST_COMPAT_COPYRIGHT, &CONST_COMPAT_COPYRIGHT, NULL) != VDH_SUCCESS)
      return FALSE;

   // Register our VDD-API...
   if (VDHRegisterVDD(&CONST_VCOMPAT,NULL,&VDDAPI) != VDH_SUCCESS)
      return FALSE;

   // Try to get a VDPMI entry-point for further analysation
   VDDHandle = VDHOpenVDD(&CONST_DPMDOS);
   if (VDDHandle) {
      VDHRequestVDD (VDDHandle, 0, 2, NULL, (PVOID)SSToDS(&VDPMIPointerTable));
      VDPMIPointerTable[1] = (PVOID)((ULONG)VDPMIPointerTable[1]-16384);
      OrgINT31RouterPtr     = MagicVMP_SearchSignature (&MagicVMPData_INT31Router, VDPMIPointerTable[1], 16384);
      OrgINT31CreateTaskPtr = 0; OrgINT31EndTaskPtr = 0; OrgINT31QueryPtr = 0;
      if (OrgINT31RouterPtr) {
         OrgINT31CreateTaskPtr = MagicVMP_SearchSignature (&MagicVMPData_INT31CreateTask, OrgINT31RouterPtr, 16384);
         if (OrgINT31CreateTaskPtr) {
            OrgINT31EndTaskPtr = MagicVMP_SearchSignature (&MagicVMPData_INT31EndTask, OrgINT31CreateTaskPtr, 16384);
            if (OrgINT31EndTaskPtr)
               OrgINT31QueryPtr = MagicVMP_SearchSignature (&MagicVMPData_INT31Query, OrgINT31EndTaskPtr, 16384);
               if (OrgINT31QueryPtr) DPMIGotEntries = TRUE;
          } else {
            OrgINT31CreateTaskPtr = MagicVMP_SearchSignature (&MagicVMPData_INT31CreateTaskWarp3, OrgINT31RouterPtr, 16384);
            if (OrgINT31CreateTaskPtr) {
               OrgINT31EndTaskPtr = MagicVMP_SearchSignature (&MagicVMPData_INT31EndTask, OrgINT31CreateTaskPtr, 16384);
               if (OrgINT31EndTaskPtr) {
                  DPMIGotEntries = TRUE;
                  OrgINT31QueryPtr = 0; // Warp 3 DPMI does not have Query
                }
             }
          }
       }
      if (DPMIGotEntries) {
         /* Register DPMI Entrypoints again including our Injected Code */
         DPMIExports.INT31Router     = &DPMIRouter_InjectedCode;
         DPMIExports.INT31CreateTask = OrgINT31CreateTaskPtr;
         DPMIExports.INT31EndTask    = OrgINT31EndTaskPtr;
         DPMIExports.INT31Query      = OrgINT31QueryPtr;

         /* 0x5F -> DPMI 0.95 */
         VDHRegisterDPMI (0x5F, SSToDS(&DPMIExports), SSToDS(&DPMIImports));

         if (VDHRegisterProperty(&CONST_COMPAT_DPMI, NULL, 0, VDMP_BOOL, VDMP_ORD_OTHER, VDMP_CREATE, (VOID *)TRUE, NULL, NULL) != VDH_SUCCESS)
            return FALSE;
         if (VDHRegisterProperty(&CONST_COMPAT_DPMI_ANTICLI, NULL, 0, VDMP_BOOL, VDMP_ORD_OTHER, VDMP_CREATE, (VOID *)FALSE, NULL, NULL) != VDH_SUCCESS)
            return FALSE;
         if (VDHRegisterProperty(&CONST_COMPAT_DPMI_MEMORY, NULL, 0, VDMP_BOOL, VDMP_ORD_OTHER, VDMP_CREATE, (VOID *)TRUE, NULL, NULL) != VDH_SUCCESS)
            return FALSE;
         TRIGGER_VDPMIHooked = TRUE;
       } else {
         // Register dummy to show that DPMI didnt work out
         VDHRegisterProperty(&CONST_COMPAT_DPMI, NULL, 0, VDMP_ENUM, VDMP_ORD_OTHER, VDMP_CREATE, &CONST_COMPAT_DPMI_NOHOOK, &CONST_COMPAT_DPMI_NOHOOK, NULL);
       }
      VDHCloseVDD (VDDHandle);
    } else {
      // Register dummy to show that DPMI didnt work out
      VDHRegisterProperty(&CONST_COMPAT_DPMI, NULL, 0, VDMP_ENUM, VDMP_ORD_OTHER, VDMP_CREATE, &CONST_COMPAT_DPMI_NOHOOK, &CONST_COMPAT_DPMI_NOHOOK, NULL);
    }


   // Try to find VCDROM replacement...
   VDDHandle = VDHOpenVDD(&CONST_VCDROM);
   if (VDDHandle) {
      if (VDHRequestVDD (VDDHandle, 0, VCDROMAPI_DetectReplacement, NULL, NULL))
         TRIGGER_VCDROMReplacement = TRUE;
      VDHCloseVDD (VDDHandle);
    }

   // Try to open VSOUND
   VDDHandle = VDHOpenVDD(&CONST_VSOUND);
   if (VDDHandle) {
      // Give VSOUND our VDDAPI entrypoint
      VDHRequestVDD (VDDHandle, 0, VSOUNDAPI_SetVCOMPATEntry, &VDDAPI, NULL);
      VDHCloseVDD (VDDHandle);
      TRIGGER_VSOUNDFound = TRUE;
    }

   // Last but not least register our Properties with OS/2 :-)
   if (VDHRegisterProperty(&CONST_COMPAT_2GBLIMIT, NULL, 0, VDMP_BOOL, VDMP_ORD_OTHER, VDMP_CREATE, (VOID *)TRUE, NULL, NULL) != VDH_SUCCESS)
      return FALSE;
   if (TRIGGER_VCDROMReplacement) {
      if (VDHRegisterProperty(&CONST_COMPAT_CDROM, NULL, 0, VDMP_ENUM, VDMP_ORD_OTHER, VDMP_CREATE, &CONST_COMPAT_CDROM_REPLACE, &CONST_COMPAT_CDROM_REPLACE, NULL) != VDH_SUCCESS)
         return FALSE;
    } else {
      if (VDHRegisterProperty(&CONST_COMPAT_CDROM, NULL, 0, VDMP_BOOL, VDMP_ORD_OTHER, VDMP_CREATE, (VOID *)TRUE, NULL, NULL) != VDH_SUCCESS)
         return FALSE;
    }
//   if (VDHRegisterProperty(&CONST_COMPAT_DEBUG, NULL, 0, VDMP_BOOL, VDMP_ORD_OTHER, VDMP_CREATE, (VOID *)FALSE, NULL, NULL) != VDH_SUCCESS)
//      return FALSE;
   // If vSOUND detected, enable GOSIERRA property
   if (TRIGGER_VSOUNDFound) {
      if (VDHRegisterProperty(&CONST_COMPAT_GOSIERRA, NULL, 0, VDMP_BOOL, VDMP_ORD_OTHER, VDMP_CREATE, (VOID *)TRUE, NULL, NULL) != VDH_SUCCESS)
         return FALSE;
    } else {
      // Otherwise generate a dummy, that reports VSOUND as missing
      if (VDHRegisterProperty(&CONST_COMPAT_GOSIERRA, NULL, 0, VDMP_ENUM, VDMP_ORD_OTHER, VDMP_CREATE, &CONST_COMPAT_GOSIERRA_NOVSOUND, &CONST_COMPAT_GOSIERRA_NOVSOUND, NULL) != VDH_SUCCESS)
         return FALSE;
    }
   if (VDHRegisterProperty(&CONST_COMPAT_JOYSTICKBIOS, NULL, 0, VDMP_BOOL, VDMP_ORD_OTHER, VDMP_CREATE, (VOID *)FALSE, NULL, NULL) != VDH_SUCCESS)
      return FALSE;
   if (VDHRegisterProperty(&CONST_COMPAT_MAGICVMPATCHER, NULL, 0, VDMP_ENUM, VDMP_ORD_OTHER, VDMP_CREATE, &CONST_COMPAT_MAGICVM_AUTO, &CONST_COMPAT_MAGICVM_ENUM, NULL) != VDH_SUCCESS)
      return FALSE;
   if (VDHRegisterProperty(&CONST_COMPAT_MOUSENSE, NULL, 0, VDMP_BOOL, VDMP_ORD_OTHER, VDMP_CREATE, (VOID *)FALSE, NULL, NULL) != VDH_SUCCESS)
      return FALSE;

   return TRUE;
 }
