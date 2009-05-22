#include <mvdmndoc.h>
#define INCL_VDH
#define INCL_VDHVDMA
#define INCL_SSTODS
#include <mvdm.h>                       /* VDH services, etc.        */
#include <mvdmdpmi.h>                   /* VDPMI Stuff - VDHRegisterDPMI */

#include <globaldefs.h>
#include <vdd_str.h>
#include <magicvmp.h>
#include <asm\main.h>
/* extern void     INT31_PreProcessHandler   (void); */

// ============================================================================

VOID DebugBeep (void) {
   VDHDevBeep (1800, 200);
}

VOID DebugBeepDetect (void) {
   VDHDevBeep (1200, 400);
}

VOID HOOKENTRY VCOMPAT_VMAPI (PVOID p,PCRF pcrf) {
   VPVOID vpretaddr;
   USHORT OriginalAX;

   if (VDHPopStack( 4, SSToDS(&vpretaddr))) {
      // Set CS:IP to end-of-call...
      IP(pcrf)   = OFFSETOF16(vpretaddr);
      CS(pcrf)   = SEGMENTOF16(vpretaddr);

      // Get Original AX from Stack to restore it later...
      VDHPopStack (2, SSToDS(&OriginalAX));

      switch (AH(pcrf)) {
        case 0x01:              // Magical VM Patcher
         switch (AL(pcrf)) {
           case 0x00:                    // MVMP - Set First MCB
            // Define FirstMCB-Location (Segment in DX)
            FirstMCBpointer = PFROMVADDR(DX(pcrf),0);
            if (*FirstMCBpointer!=0x4D)
               VDHKillVDM(0); // Kill current VDM, cause invalid MCB pointer
           case 0x01:                    // MVMP - Protected Mode Main Trigger
            VCOMPAT_MagicVMPatcherInPM_INT10 (pcrf);
          }
         break;
       }

      // Restore Original AX
      AX(pcrf)   = OriginalAX;
    }
   return;
 }

PBVDM InstallPatchModule (char *PatchModulePtr, ushort PatchModuleLen) {
   PBVDM ModuleInDOSptr = NULL;

   ModuleInDOSptr = VDHAllocDosMem(PatchModuleLen);
   if (ModuleInDOSptr) {
      // Copy Patch-Module to VDM Memory Buffer
      VDHCopyMem(PatchModulePtr, ModuleInDOSptr, PatchModuleLen);

      // Patch current Segment into NextPatchSegment
      if (PATCH_NextPatchSegPtr) {
         *(PULONG)(&TempV86seg) = HISEG(ModuleInDOSptr);
         VDHCopyMem ((PVOID)(&TempV86seg), PATCH_NextPatchSegPtr, 2);
         PATCH_NextPatchSegPtr = ModuleInDOSptr+0;
       } else {
         PATCH_NextPatchSegPtr = ModuleInDOSptr+18; // Helper Device Driver
       }
    }
   return ModuleInDOSptr;
 }

// ============================================================================
// This routine is called on every VDM creation...

BOOL HOOKENTRY VDMCreate (HVDM CurVDMHandle) {
   PCHAR PropertyVMPatcher;

   // Safety check, if we were called with a handle in hvdm.
   MyVDMHandle = CurVDMHandle;
   if (MyVDMHandle == Null) return FALSE;

   // Initialize Instance-Variables...
   VDD_InitInstanceData();

   // Register our VM-API...
   VDHRegisterAPI(&CONST_COMPAT_DevName, (PFNHOOK)VCOMPAT_VMAPI, NULL);

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
   if (VDHQueryProperty(&CONST_COMPAT_CDROM))
      PATCH_CDROMinDOSptr = InstallPatchModule(&PATCH_CDROM, PATCH_CDROMlength);
   if (VDHQueryProperty(&CONST_COMPAT_DPMI))
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

   // Check DPMI Properties...
   PROPERTY_DPMI        = VDHQueryProperty(&CONST_COMPAT_DPMI);
   PROPERTY_DPMIAntiCLI = VDHQueryProperty(&CONST_COMPAT_DPMI_ANTICLI);

   if (PROPERTY_DPMIAntiCLI) { // Install Anti-CLI Timer, if requested...
      AutoVPMStiTimerHandle = VDHAllocHook(VDH_TIMER_HOOK, (PFNARM)VCOMPAT_AutoVPMSti, 4);
      VDHArmTimerHook (AutoVPMStiTimerHandle, 50, MyVDMHandle);
    }

   // Hook into various interrupts as prereflection-hook (occurs before turning
   //  those interrupts into V86 mode and after all Protected-Mode hooks)
   if (!(VDHInstallIntHook(0,0x21,&V86PreHook_INT21h,VDH_ASM_HOOK|VDH_PRE_HOOK)))
      return FALSE;

   return TRUE;
 }

// old code, left in cause it contains some nice structures that I don't want
//  to forget about :)
// BOOL HOOKENTRY VDMCreateDone (HVDM CurVDMHandle) {
//    if (PATCH_INT25inDOSptr) {
// 
//       // Patch old Interrupt Vector to [0000]
//       // *(PULONG)((ULONG)&PATCH_INT25) = (ULONG)VDMBase.rb_avpIVT[0x25];
//       VDHCopyMem(&VDMBase.rb_avpIVT[0x25], PATCH_INT25inDOSptr, 4);
// 
//       // Patch new Interrupt Vector into Interrupt Table
//       VDMBase.rb_avpIVT[0x25] = (PVOID)((ULONG)VPFROMP(&PATCH_INT25inDOSptr) + 4);
//     }
// 
//    return TRUE;
//  }

#pragma entry(Init)

// Called at sysinit time to initialize VDD. Runs at r0
// and must return TRUE to successfully load the VDD
BOOL _pascal Init(char *CmdLine) {
   HVDD   VDPMIHandle;
   PUCHAR VDPMIPointerTable[3];
   DPMX   DPMIExports;
   VPMX   DPMIImports;

   // install the create hook 
   if (VDHInstallUserHook(VDM_CREATE,(PFNARM)VDMCreate) != VDH_SUCCESS)
      return FALSE;

   // Install Property that contains Copyright message
   if (VDHRegisterProperty(&CONST_COMPAT_MAIN, NULL, 0, VDMP_ENUM, VDMP_ORD_OTHER, VDMP_CREATE, &CONST_COMPAT_COPYRIGHT, &CONST_COMPAT_COPYRIGHT, NULL) != VDH_SUCCESS)
      return FALSE;

   // Try to get a VDPMI entry-point for further analysation
   VDPMIHandle = VDHOpenVDD(&CONST_DPMDOS);
   if (VDPMIHandle) {
      VDHRequestVDD (VDPMIHandle, 0, 2, NULL, (PVOID)SSToDS(&VDPMIPointerTable));
      VDPMIPointerTable[1] = (PVOID)((ULONG)VDPMIPointerTable[1]-16384);
      OrgINT31RouterPtr     = MagicVMP_SearchSignature (&MagicData_INT31Router, VDPMIPointerTable[1], 16384);
      OrgINT31CreateTaskPtr = 0; OrgINT31EndTaskPtr = 0; OrgINT31QueryPtr = 0;
      if (OrgINT31RouterPtr) {
         OrgINT31CreateTaskPtr = MagicVMP_SearchSignature (&MagicData_INT31CreateTask, OrgINT31RouterPtr, 16384);
         if (OrgINT31CreateTaskPtr) {
            OrgINT31EndTaskPtr = MagicVMP_SearchSignature (&MagicData_INT31EndTask, OrgINT31CreateTaskPtr, 16384);
            if (OrgINT31EndTaskPtr)
               OrgINT31QueryPtr = MagicVMP_SearchSignature (&MagicData_INT31Query, OrgINT31EndTaskPtr, 16384);
          }
       }
      if (OrgINT31QueryPtr) {
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
       } else {
         VDHRegisterProperty(&CONST_COMPAT_DPMI, NULL, 0, VDMP_ENUM, VDMP_ORD_OTHER, VDMP_CREATE, &CONST_COMPAT_DPMI_NOHOOK, &CONST_COMPAT_DPMI_NOHOOK, NULL);
       }
      VDHCloseVDD (VDPMIHandle);
    }

   // Last but not least register our Properties with OS/2 :-)
   if (VDHRegisterProperty(&CONST_COMPAT_2GBLIMIT, NULL, 0, VDMP_BOOL, VDMP_ORD_OTHER, VDMP_CREATE, (VOID *)TRUE, NULL, NULL) != VDH_SUCCESS)
      return FALSE;
   if (VDHRegisterProperty(&CONST_COMPAT_CDROM, NULL, 0, VDMP_BOOL, VDMP_ORD_OTHER, VDMP_CREATE, (VOID *)TRUE, NULL, NULL) != VDH_SUCCESS)
      return FALSE;
   if (VDHRegisterProperty(&CONST_COMPAT_MOUSENSE, NULL, 0, VDMP_BOOL, VDMP_ORD_OTHER, VDMP_CREATE, (VOID *)FALSE, NULL, NULL) != VDH_SUCCESS)
      return FALSE;
   if (VDHRegisterProperty(&CONST_COMPAT_JOYSTICKBIOS, NULL, 0, VDMP_BOOL, VDMP_ORD_OTHER, VDMP_CREATE, (VOID *)FALSE, NULL, NULL) != VDH_SUCCESS)
      return FALSE;
   if (VDHRegisterProperty(&CONST_COMPAT_MAGICVMPATCHER, NULL, 0, VDMP_ENUM, VDMP_ORD_OTHER, VDMP_CREATE, &CONST_COMPAT_MAGICVM_AUTO, &CONST_COMPAT_MAGICVM_ENUM, NULL) != VDH_SUCCESS)
      return FALSE;

   return TRUE;
 }
