
#include <16bit\modules.h>

/* CONST.asm */
extern char     CONST_COMPAT_InitMessage;
extern char     CONST_COMPAT_MAIN;
extern char     CONST_COMPAT_COPYRIGHT;
extern char     CONST_COMPAT_2GBLIMIT;
extern char     CONST_COMPAT_CDROM;
extern char     CONST_COMPAT_DPMI;
extern char     CONST_COMPAT_DPMI_NOHOOK;
extern char     CONST_COMPAT_DPMI_ANTICLI;
extern char     CONST_COMPAT_JOYSTICKBIOS;
extern char     CONST_COMPAT_MAGICVMPATCHER;
extern char     CONST_COMPAT_MAGICVM_ENUM;
extern char     CONST_COMPAT_MAGICVM_AUTO;
extern char     CONST_COMPAT_MAGICVM_ON;
extern char     CONST_COMPAT_MAGICVM_OFF;
extern char     CONST_COMPAT_MOUSENSE;

extern char     CONST_COMPAT_DevName;
extern char     CONST_DPMDOS;

/* GlobalData.asm */
extern PUCHAR   OrgINT31RouterPtr;
extern PUCHAR   OrgINT31CreateTaskPtr;
extern PUCHAR   OrgINT31EndTaskPtr;
extern PUCHAR   OrgINT31QueryPtr;

/* MagicVMP_data.inc */
extern uchar    MagicData_TurboPascalCRT;
extern uchar    MagicData_TurboPascalCRTtext;
extern uchar    MagicData_TurboPascalCRTpatch;
extern uchar    MagicData_TurboPascalCRTDPMItext;
extern uchar    MagicData_MicrosuckC;
extern uchar    MagicData_MicrosuckCtext;
extern uchar    MagicData_MicrosuckCpatch;
extern uchar    MagicData_INT31Router;
extern uchar    MagicData_INT31CreateTask;
extern uchar    MagicData_INT31EndTask;
extern uchar    MagicData_INT31Query;

// Variables in Instance Data-Segment (for every VDM)
extern HVDM     MyVDMHandle;
extern PBVDM    PATCH_DeviceDriverInDOSptr;
extern PBVDM    PATCH_2GBLIMITinDOSptr;
extern PBVDM    PATCH_CDROMinDOSptr;
extern PBVDM    PATCH_DPMITRIGinDOSptr;
extern PBVDM    PATCH_INT25inDOSptr;
extern PBVDM    PATCH_JOYSTICKBIOSinDOSptr;
extern PBVDM    PATCH_MOUSENSEinDOSptr;
extern PBVDM    PATCH_NextPatchSegPtr;
extern BOOL     PROPERTY_DPMI;
extern BOOL     PROPERTY_DPMIAntiCLI;
extern BOOL     PROPERTY_VMPatcherON;
extern BOOL     PROPERTY_VMPatcherAUTO;
extern BOOL     TRIGGER_InINT21Execute;
extern BOOL     TRIGGER_TurboPascalDPMI;

extern USHORT   TempV86seg;
extern HHOOK    AutoVPMStiTimerHandle;

// Points to first MCB-Block in current VDM...
extern PUCHAR   FirstMCBpointer;

/* Instance.asm */
extern VOID      VDD_INT3();
extern VOID      VDD_InitInstanceData();
extern VOID      VDD_ResetMemSelTable();

/* MagicVMP.asm */
extern PUCHAR   MagicVMP_SearchSignature  (uchar *MagicDataPtr, uchar *AreaPtr, ulong AreaLength);
extern PUCHAR   MagicVMP_SearchSignatureInSel (uchar *MagicDataPtr, ulong MaxSize);

extern void     MagicVMP_ApplyPatch       (uchar *MagicPatchPtr, uchar *SignaturePtr);
extern void     MagicVMP_DoAntiCLI        ();
extern void     MagicVMP_DoRemoveTPCRTbug ();

/* DPMIrouter.asm */
extern void     DPMIRouter_InjectedCode   ();
/* extern void     DPMIRouter_ApplyPatch     (uchar *OriginalRouterPtr); */

/* V86Hooks.asm */
extern void     V86PreHook_INT21h         ();
