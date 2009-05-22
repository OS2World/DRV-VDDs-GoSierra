#include <mvdmndoc.h>
#define INCL_VDH
#define INCL_VDHVDMA
#define INCL_SSTODS
#include <mvdm.h>                       /* VDH services, etc.        */

#include <globaldefs.h>
#include <vcompat.h>
#include <asm\main.h>

BOOL VCOMPAT_MagicVMpopup (uchar *TextMessagePtr) {
   ulong   popupresult = 0;
   if (PROPERTY_VMPatcherAUTO) return TRUE;
   VDHPopup (TextMessagePtr, 1, MSG_DIRECTSTRING, SSToDS(&popupresult), VDHP_IGNORE, NULL);
   return (popupresult==VDHP_TERMINATE_SESSION);
 }

PUCHAR VCOMPAT_SearchSignatureInMCB (uchar *MagicDataPtr, uchar *OpCodePtr, long AdjustOffset, ulong MaxLength) {
   PUCHAR CurMCBpointer = FirstMCBpointer;
   PUCHAR NextMCBpointer;
   ulong  TotalLength;

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
         if (MaxLength>TotalLength)
            MaxLength = TotalLength;     // And adjust accordingly...
         // Now finally search for the signature...
         return MagicVMP_SearchSignature (MagicDataPtr, OpCodePtr, MaxLength);
       }
      CurMCBpointer = NextMCBpointer;
    }
   return 0; // Corresponding MCB not found... (should never be the case)
 }

// Searches for Turbo Pascal CRT Unit V86 bug...
VOID VCOMPAT_MagicVMPatcherInRM_TurboPascalCRT (PCRF pcrf) {
   PUCHAR  OpCodePointer;
   PUCHAR  SignaturePtr = 0;

   // If VDM running in Protected Mode -> Dont try VM-Patching!
   if (flVdmStatus & VDM_STATUS_VPM_APP) return;
   if (!PROPERTY_VMPatcherON) return;

   // Try to find Turbo Pascal CRT-Unit bugger...
   OpCodePointer = PFROMVADDR(CS(pcrf),IP(pcrf));
   SignaturePtr = VCOMPAT_SearchSignatureInMCB (&MagicData_TurboPascalCRT, OpCodePointer, -8000, 8000);
   if ((SignaturePtr!=0) && (VCOMPAT_MagicVMpopup(&MagicData_TurboPascalCRTtext)))
      MagicVMP_ApplyPatch (&MagicData_TurboPascalCRTpatch, SignaturePtr);
 }

// Searches for Micro$loft buggy C unit code
//  found in Monkey Island 1, Indiana Jones and many more
VOID VCOMPAT_MagicVMPatcherInRM_MS_C_TimerInitBug (PCRF pcrf) {
   PUCHAR  OpCodePointer;
   PUCHAR  SignaturePtr = 0;

   // If VDM running in Protected Mode -> Dont try VM-Patching!
   if (flVdmStatus & VDM_STATUS_VPM_APP) return;
   if (!PROPERTY_VMPatcherON) return;

   // Try to find M$ C Timer Init bugger...
   OpCodePointer = PFROMVADDR(CS(pcrf),IP(pcrf));
   SignaturePtr = VCOMPAT_SearchSignatureInMCB (&MagicData_MicrosuckC, OpCodePointer, -12000, 12000);
   if ((SignaturePtr!=0) && (VCOMPAT_MagicVMpopup(&MagicData_MicrosuckCtext)))
      MagicVMP_ApplyPatch (&MagicData_MicrosuckCpatch, SignaturePtr);
 }

// This is bad boy code, because we search through all code selectors that are
//  open till that time which means we waste much time, but it's working and
//  the TurboPascalDPMI-Trigger is somewhat safe, so time won't be wasted on
//  normal applications.
VOID VCOMPAT_MagicVMPatcherInPM_TurboPascalCRT () {
   PUCHAR  SignaturePtr = 0;

   // Try to find Turbo Pascal DPMI CRT-Unit bugger...
   SignaturePtr = MagicVMP_SearchSignatureInSel (&MagicData_TurboPascalCRT, 20000);
   if ((SignaturePtr!=0) && (VCOMPAT_MagicVMpopup(&MagicData_TurboPascalCRTDPMItext))) {
      MagicVMP_ApplyPatch (&MagicData_TurboPascalCRTpatch, SignaturePtr);
      TRIGGER_TurboPascalDPMI = 0;
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
         VCOMPAT_MagicVMPatcherInPM_TurboPascalCRT();
       }
    }
   VDD_ResetMemSelTable();
 }

VOID HOOKENTRY VCOMPAT_AutoVPMSti (PVOID p, PCRF pcrf) {
   // Enable Interrupts...
   if (flVdmStatus & VDM_STATUS_VPM_APP) {
      VDHChangeVPMIF (1);
    }
   VDHArmTimerHook (AutoVPMStiTimerHandle, 50, MyVDMHandle);
 }

