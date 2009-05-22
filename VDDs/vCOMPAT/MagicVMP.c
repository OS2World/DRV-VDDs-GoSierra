/* vCOMPAT is for OS/2 only */
/*  You may not reuse this source or parts of this source in any way and/or */
/*  (re)compile it for a different platform without the allowance of        */
/*  kiewitz@netlabs.org. It's (c) Copyright by Martin Kiewitz.              */

#include <mvdmndoc.h>
#define INCL_VDH
#define INCL_VDHVDMA
#define INCL_SSTODS
#include <mvdm.h>                       /* VDH services, etc.        */

#include <globaldefs.h>
#include <vcompat.h>
#include <asm\main.h>

#include <..\API\udocumnt.h>            // Undocumented features of MVDM

#include <..\API\debug.h>

VOID VCOMPAT_PatchDeviceDriverHeaders (void) {
   PVOID  DeviceDriverPtr = (PVOID)((ULONG)PTR_ListOfLists+0x22);
   ULONG  NxtDeviceDrvPtr;
   ULONG  CharDevName1, CharDevName2;
   UCHAR  TempVal;
   USHORT DeviceDriverCounter = 0;

   while (1) {
      CharDevName1 = *(PULONG)((ULONG)DeviceDriverPtr+10);
      CharDevName2 = *(PULONG)((ULONG)DeviceDriverPtr+14);

      if ((CharDevName1=='DCSM') & (CharDevName2==' 100')) { // MSCD001_
         // VCDROM Device-Header
         TempVal = *(PUCHAR)((ULONG)DeviceDriverPtr+20); // Drive-Letter Byte
         // Only patch, when current Drive-Letter==0 and CDROM-Patch injected
         //  We won't patch our VCDROM replacement device header, because that
         //  one already has the correct Drive-Letter byte set.
         if ((TempVal==0) & (PATCH_CDROMinDOSptr!=0)) {
            // +24 -> hard-coded, points to 1st CD-ROM drive letter
            TempVal = *(PUCHAR)((ULONG)PATCH_CDROMinDOSptr+24);
            // we need base 1, but we got base 0 in table, that's why +1
            *(PUCHAR)((ULONG)DeviceDriverPtr+20) = TempVal+1;
          }
       }

      NxtDeviceDrvPtr = *(PULONG)DeviceDriverPtr;
      if (WORDOF(NxtDeviceDrvPtr,0)==0xFFFF) break;

      DeviceDriverPtr = PFROMVP(NxtDeviceDrvPtr);

      // If we dont find End-Of-Device-Driver-Chain after 50 headers, we assume
      //  that something went wrong...
      DeviceDriverCounter++;
      if (DeviceDriverCounter>50) break;
    }
   return;
 }

// Asks user, if he wants to apply (VMPBundle), returns TRUE if told so
BOOL VCOMPAT_AskUserAboutPatch (uchar *VMPBundlePtr) {
   ULONG  result = 0;
   CHAR   TextMessage[1024];
   if (PROPERTY_VMPatcherAUTO) return TRUE;
   SPrintF((PCHAR)SSToDS(&TextMessage), 1024, "%s%s%s", &CONST_PopUpStart, MagicVMP_GetNamePtr(VMPBundlePtr), &CONST_PopUpEnd);
   VDHPopup ((PCHAR)SSToDS(&TextMessage), 1, MSG_DIRECTSTRING, SSToDS(&result), VDHP_IGNORE|VDHP_ACKNOWLEDGE, NULL);
// 08092006 Kie Popup now uses undocumented "ACKNOWLEDGE", if that is selected
//              VDM will set an internal error, which doesn't hurt at all and
//              will NOT set "result", so we will have zero still in there.
//   if (result==VDHP_TERMINATE_SESSION)
   if (result!=VDHP_IGNORE)
      return TRUE;
   return FALSE;
 }

PUCHAR VCOMPAT_SearchSignatureWithinMCB (uchar *VMPBundlePtr, uchar *OpCodePtr, long AdjustOffset, ulong MaxSize) {
   PUCHAR CurMCBpointer = PTR_FirstMCB;
   PUCHAR NextMCBpointer;
   ULONG  TotalLength;

   while ((*CurMCBpointer==0x4D) || (*CurMCBpointer==0x5A)) {
      // Get pointer to next MCB...
      NextMCBpointer = CurMCBpointer+(((ulong)(*(PUSHORT)(CurMCBpointer+3))+1)<<4);
      if (NextMCBpointer>OpCodePtr) {
         // Okay, we found the correct MCB...
         OpCodePtr += AdjustOffset;      // OpCodePtr is now SearchStartPtr
         if (OpCodePtr<=CurMCBpointer)   // if not within MCB -> Adjust
            OpCodePtr = (PUCHAR)((ulong)CurMCBpointer+16);

         // Calculate Total-Length from SearchStart to End-Of-MCB
         TotalLength = NextMCBpointer-OpCodePtr;
         if (MaxSize>TotalLength)
            MaxSize = TotalLength;     // And adjust accordingly...
         // Now finally search for the signature...
         return MagicVMP_SearchSignature (VMPBundlePtr, OpCodePtr, MaxSize);
       }
      CurMCBpointer = NextMCBpointer;
    }
   return 0; // Corresponding MCB not found... (should never be the case)
 }

// Processes VMP-Bundle directly
BOOL VCOMPAT_ProcessVMPBundle (uchar *VMPBundlePtr, uchar *OpCodePtr, ulong MaxSize) {
   PUCHAR  SignaturePtr = 0;
   SignaturePtr = MagicVMP_SearchSignature (VMPBundlePtr, OpCodePtr, MaxSize);
   if (SignaturePtr) {
      DebugPrintF("MagicVMP: Detected '%s'\n", MagicVMP_GetNamePtr(VMPBundlePtr));
      // Ask via popup (if requested)
      if (VCOMPAT_AskUserAboutPatch(VMPBundlePtr)) {
         MagicVMP_ApplyPatch (VMPBundlePtr, SignaturePtr);
         DebugPrintCR("MagicVMP: Applied patch.");
         return TRUE;
       }
    }
   return FALSE;
 }

// Processes VMP-Bundle using MCB search
BOOL VCOMPAT_ProcessVMPBundleWithinMCB (uchar *VMPBundlePtr, uchar *OpCodePtr, long AdjustOffset, ulong MaxSize) {
   PUCHAR  SignaturePtr = 0;
   SignaturePtr = VCOMPAT_SearchSignatureWithinMCB (VMPBundlePtr, OpCodePtr, AdjustOffset, MaxSize);
   if (SignaturePtr) {
      DebugPrintF("MagicVMP: Detected '%s'\n", MagicVMP_GetNamePtr(VMPBundlePtr));
      // Ask via popup (if requested)
      if (VCOMPAT_AskUserAboutPatch(VMPBundlePtr)) {
         MagicVMP_ApplyPatch (VMPBundlePtr, SignaturePtr);
         DebugPrintCR("MagicVMP: Applied patch.");
         return TRUE;
       }
    }
   return FALSE;
 }

// Processes VMP-Bundle using Selector search
// This is bad boy code, because we search through all code selectors that are
//  open till that time which means we waste much time. Only use this function
//  if you got a really good trigger (like TurboPascalDPMI), otherwise one will
//  waste much time on normal applications.
BOOL VCOMPAT_ProcessVMPBundleInSelectors (uchar *VMPBundlePtr, ulong MaxSize) {
   PUCHAR  SignaturePtr = 0;
   SignaturePtr = MagicVMP_SearchSignatureInSel (VMPBundlePtr, MaxSize);
   if (SignaturePtr) {
      DebugPrintF("MagicVMP: Detected '%s'\n", MagicVMP_GetNamePtr(VMPBundlePtr));
      // Ask via popup (if requested)
      if (VCOMPAT_AskUserAboutPatch(VMPBundlePtr)) {
         MagicVMP_ApplyPatch (VMPBundlePtr, SignaturePtr);
         DebugPrintCR("MagicVMP: Applied patch.");
         return TRUE;
       }
    }
   return FALSE;
 }

// Searches for Turbo Pascal CRT Unit V86 bug...
VOID VCOMPAT_MagicVMPatcherInRM_TurboPascalCRT (PCRF pcrf) {
   // If VDM running in Protected Mode -> Dont try VM-Patching!
   if (flVdmStatus & VDM_STATUS_VPM_APP) return;
   if (!PROPERTY_VMPatcherON) return;

   // Try to find Turbo Pascal CRT-Unit bugger...
   VCOMPAT_ProcessVMPBundleWithinMCB (&MagicVMPData_TurboPascalCRT, 
                                      PFROMVADDR(CS(pcrf),IP(pcrf)),
                                      -8000, 8000);
 }

// Searches for Micro$loft buggy C unit code
//  found in Monkey Island 1, Indiana Jones and many more
VOID VCOMPAT_MagicVMPatcherInRM_MS_C_TimerInitBug (PCRF pcrf) {
   // If VDM running in Protected Mode -> Dont try VM-Patching!
   if (flVdmStatus & VDM_STATUS_VPM_APP) return;
   if (!PROPERTY_VMPatcherON) return;

   // Try to find M$ C Timer Init bugger...
   VCOMPAT_ProcessVMPBundleWithinMCB (&MagicVMPData_MicrosuckC, 
                                      PFROMVADDR(CS(pcrf),IP(pcrf)),
                                      -12000, 12000);
 }

// Searches for Clipper unit code
VOID VCOMPAT_MagicVMPatcherInRM_Clipper_TimerBug (PCRF pcrf) {
   // If VDM running in Protected Mode -> Dont try VM-Patching!
   if (flVdmStatus & VDM_STATUS_VPM_APP) return;
   if (!PROPERTY_VMPatcherON) return;

   // Try to find Clipper Timer Init bugger...
   VCOMPAT_ProcessVMPBundleWithinMCB (&MagicVMPData_Clipper, 
                                      PFROMVADDR(CS(pcrf),IP(pcrf)),
                                      0, 128000);
 }

// Searches for Sierra On-Line sound driver bugs
VOID VCOMPAT_MagicVMPatcherInRM_IRQDetection (PCRF pcrf) {
   PUCHAR  OpCodePointer;
   PUCHAR  SignaturePtr = 0;
   BOOL    PatchApplied = FALSE;
   PUSHORT CallPtr = NULL;

   // If VDM running in Protected Mode -> Dont try VM-Patching!
   if (flVdmStatus & VDM_STATUS_VPM_APP) return;
   if (!PROPERTY_VMPatcherON) return;
   if (!PROPERTY_GOSIERRA) return;

   // Try to find Sierra On-Line bugger...
   OpCodePointer = PFROMVADDR(CS(pcrf),0);

   // Look and fix all sorts of bugs...
   PatchApplied  = VCOMPAT_ProcessVMPBundle (&MagicVMPData_SierraDriverBugType1,
                                            OpCodePointer, 16384);
   PatchApplied |= VCOMPAT_ProcessVMPBundle (&MagicVMPData_SierraDriverBugType1b,
                                            OpCodePointer, 16384);
   PatchApplied |= VCOMPAT_ProcessVMPBundle (&MagicVMPData_SierraDriverBugType2,
                                            OpCodePointer, 16384);
   PatchApplied |= VCOMPAT_ProcessVMPBundle (&MagicVMPData_SierraDriverBugType2b,
                                            OpCodePointer, 16384);
   PatchApplied |= VCOMPAT_ProcessVMPBundle (&MagicVMPData_SierraDriverBugType3,
                                            OpCodePointer, 16384);

   if (PatchApplied) {
      // If we patched anything, also check for Dynamix bug and patch it w/o
      //  asking user...
      SignaturePtr = MagicVMP_SearchSignature (&MagicVMPData_SierraDriverBugDynamix, OpCodePointer, 16384);
      if (SignaturePtr) {
         DebugPrintF("MagicVMP: Applied patch '%s'\n", MagicVMP_GetNamePtr(&MagicVMPData_SierraDriverBugDynamix));
         MagicVMP_ApplyPatch (&MagicVMPData_SierraDriverBugDynamix, SignaturePtr);
         // HARDCODED: Will fix 2 CALL instruction offsets
         CallPtr = (PUSHORT)((ULONG)SignaturePtr+40);
         *CallPtr = (*CallPtr)-7;
         CallPtr = (PUSHORT)((ULONG)SignaturePtr+54);
         *CallPtr = (*CallPtr)-7;
       }
    }
 }

// This trigger is executed as soon as possible after program execution.
// It's meant for e.g. games that switch to another videomode and/or do output
//  via INT10h. We assume that an encoded program is fully decoded till INT10h.
VOID VCOMPAT_MagicVMPatcherInPM_INT10 (PCRF pcrf) {
   // If VDM is NOT running a Protected Mode application -> Exit!
   if (!(flVdmStatus & VDM_STATUS_VPM_APP)) return;

   // User allowed us to patch?
   if (!PROPERTY_VMPatcherON) return;

   if (flVdmStatus & VDM_STATUS_VPM_32) {
      // 32-bit applications - we do Anti-CLI Patching
      MagicVMP_DoAntiCLI();                 // Processes Anti-CLI
    } else {
      // 16-bit applications - we check if Turbo Pascal Trigger is active
      if (TRIGGER_TurboPascalDPMI) {
         // Try to find Turbo Pascal DPMI CRT-Unit bugger...
         if (VCOMPAT_ProcessVMPBundleInSelectors (&MagicVMPData_TurboPascalCRT, 20000)) {
            // Disable TurboPascal DPMI trigger, if found
            TRIGGER_TurboPascalDPMI = FALSE;
          }
       }
    }
   VDD_ResetMemSelTable();
 }

VOID HOOKENTRY VCOMPAT_AutoVPMSti (PVOID p, PCRF pcrf) {
   // Enable Interrupts...
   if (flVdmStatus & VDM_STATUS_VPM_APP) {
      VDHChangeVPMIF (1);
    }
   VDHArmTimerHook (AutoVPMStiTimerHandle, 50, CurVDMHandle);
 }

