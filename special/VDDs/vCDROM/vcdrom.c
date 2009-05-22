#include <mvdmndoc.h>
#define INCL_VDH
#define INCL_SSTODS
#include <mvdm.h>                       // VDH services, etc.

#include <globaldefs.h>
#include <asm\main.h>

// ============================================================================

VOID DebugBeep (void) {
   VDHDevBeep (1800, 150);
 }

VOID DebugBeepDetect (void) {
   VDHDevBeep (1200, 400);
 }

VOID DebugBeepShort (void) {
   VDHDevBeep (2500, 50);
 }

// ============================================================================

// This routine is called on every VDM creation...
BOOL HOOKENTRY VDMCreate (HVDM VDMHandle) {
   HFILE TempHandle  = 0;
   ULONG ActionTaken = 0;
   ULONG ParmLength  = 0;
   ULONG DataLength  = 4;       // We receive 2 USHORTs from CD-ROM2$
   HHOOK TempHook    = 0;

   // Initialize Instance-Variables...
   VDD_InitInstanceData();

   // Safety check, if we were called with a handle in hvdm.
   if ((CurVDMHandle = VDMHandle) == NULL) return FALSE;

   if (!VDHOpen(&CONST_CDROM_CHARDEV, SSToDS(&TempHandle), SSToDS(&ActionTaken), 0, 0, VDHOPEN_FILE_EXISTED, 0x2040, 0)) {
      // We got any CD-ROMs in this system, no? -> simply do nothing
      return TRUE;
    }

   if (!VDHDevIOCtl(TempHandle, 0x82, 0x60, NULL, ParmLength, SSToDS(&ParmLength),
        &CDROM_CHARDEV_Information, DataLength, SSToDS(&DataLength))) {
      // Failed information call? so fail VDM creation...
      VDHClose (TempHandle);
      return FALSE;
    }

   VDHClose(TempHandle);

   // Check, if we are supposed to use VPIC-SlaveProcessor for DevIOCTL
   //  so that interrupts will get reflected during processing to VDM
   PROPERTY_INTDuringIO = VDHQueryProperty(&CONST_CDROM_INTDURINGIO);
   if (PROPERTY_INTDuringIO) {
      // We do this optional, which means if VPIC is unavailable or anything
      //  fails, we still load up, but disable the feature.
      if (!VPIC_SlaveRequestFunc) {
         if (!VPIC_Handle) VPIC_Handle = VDHOpenVDD(&CONST_VPIC);
         if (VPIC_Handle) {
            // Undocumented stuff: Get Slave-DevIOCTL processor PFN
            VDHRequestVDD(VPIC_Handle, 0, VPIC_API_GETSLAVEPROCESSOR, NULL, (PVOID)&VPIC_SlaveRequestFunc);
            if (!VPIC_SlaveRequestFunc)
               PROPERTY_INTDuringIO = FALSE; // Switch the feature off
          }
       }
    }

   // Generate BreakPoint Hooks for INT2F API and Device-Driver virtualization
   TempHook = VDHAllocHook(VDH_BP_HOOK, (PFNARM)&VCDROM_APIEntry, 0);
   if (TempHook) VCDROM_APIBreakPoint = VDHArmBPHook(TempHook);
   TempHook = VDHAllocHook(VDH_BP_HOOK, (PFNARM)&VCDROM_DDEntry, 0);
   if (TempHook) VCDROM_DDBreakPoint  = VDHArmBPHook(TempHook);

   // Install Device-Driver(s) into VDM...
   VCDROM_InstallCode();

   return TRUE;
 }

// This routine is called on every VDM termination...
BOOL HOOKENTRY VDMTerminate (HVDM VDMHandle) {
   // Safety check...
   if (!(CurVDMHandle == VDMHandle)) return FALSE;

   VDD_InstanceClosing();
   return TRUE;
 }

//      VDHChangeVPMIF (1);

#pragma entry(Init)

// Called at sysinit time to initialize VDD and returns TRUE, if success
BOOL _pascal Init(char *CmdLine) {
   // Install our Create/Terminate hooks...
   if (VDHInstallUserHook(VDM_CREATE,(PFNARM)VDMCreate) != VDH_SUCCESS) return FALSE;
   if (VDHInstallUserHook(VDM_TERMINATE,(PFNARM)VDMTerminate) != VDH_SUCCESS) return FALSE;

   // Register our VDD-API...
   if (VDHRegisterVDD(&CONST_VCDROM,NULL,&VDDAPI) != VDH_SUCCESS)
      return FALSE;

   // Install Property that contains Copyright message
   if (VDHRegisterProperty(&CONST_CDROM_MAIN, NULL, 0, VDMP_ENUM, VDMP_ORD_OTHER, VDMP_CREATE, &CONST_CDROM_COPYRIGHT, &CONST_CDROM_COPYRIGHT, NULL) != VDH_SUCCESS)
      return FALSE;
   if (VDHRegisterProperty(&CONST_CDROM_INTDURINGIO, NULL, 0, VDMP_BOOL, VDMP_ORD_OTHER, VDMP_CREATE, (VOID *)FALSE, NULL, NULL) != VDH_SUCCESS)
      return FALSE;

   return TRUE;
 }
