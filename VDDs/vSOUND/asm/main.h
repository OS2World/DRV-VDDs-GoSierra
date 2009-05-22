/* CONST.asm */
extern char      CONST_CR;
extern char      CONST_VDMA;
extern char      CONST_VSOUND;
extern char      CONST_VCOMPAT;
extern char      CONST_SOUND_MAIN;
extern char      CONST_SOUND_COPYRIGHT;
extern char      CONST_SOUND_DEBUG;
extern char      CONST_SOUND_PASSTHRU;
extern char      CONST_SOUND_TYPE;
extern char      CONST_SOUND_TYPE_ENUM;
extern char      CONST_SOUND_TYPE_NONE;
extern char      CONST_SOUND_TYPE_SB;
extern char      CONST_SOUND_TYPE_SBPRO;
extern char      CONST_SOUND_TYPE_SB16;
extern char      CONST_SOUND_MIXER;

/* Global.asm */
extern HIRQ      VIRQ5Handle;

// Variables in Instance Data-Segment (for every VDM)
extern HVDM      CurVDMHandle;
extern HFILE     DebugFileHandle;

extern HHOOK     TIMER_VIRQHandle;

extern BOOL      TRIGGER_VIRQTimerActive;

extern BOOL      PROPERTY_DEBUG;
extern BOOL      PROPERTY_HW_SOUND_ON;
extern USHORT    PROPERTY_HW_SOUND_TYPE;
extern BOOL      PROPERTY_HW_SOUND_PASSTHRU;
extern BOOL      PROPERTY_HW_SOUND_MIXER;

extern USHORT    VSOUND_OutputSampleRate;  // Actual sample rate
extern USHORT    VSOUND_OutputNSPerSample; // Nanoseconds per sample
extern USHORT    VSOUND_OutputFlags;
extern ULONG     VSOUND_OutputSize;

#define SBoutputFlag_AutoInit    0x001  // Bit 0
#define SBoutputFlag_16bit       0x002  // Bit 1
#define SBoutputFlag_Stereo      0x004  // Bit 2
#define SBoutputFlag_Signed      0x008  // Bit 3

// =====================================================================[CODE]=

/* printf.asm */
extern ULONG     StrLen (PSZ StringPtr);
extern ULONG     StrCpy (PSZ StringPtr, ULONG StringSize, PSZ SourcePtr);
extern ULONG     InternalSPrintF (PSZ StringPtr, ULONG StringSize, PSZ FormatPtr, PVOID FormatDataPtr);

/* Instance.asm */
extern VOID      VDD_InitInstanceData();
extern long      VSOUND_EmulationSwitch;

/* PortIO.asm */
extern void      VSOUND_OutOnSB();
extern void      VSOUND_InOnSB();

/* PortIOdata.asm */
extern IOH       VSOUND_Ports_IOhookTable;

/* Passthru.asm */
extern void      PASSTHRU_PlaybackStart();
extern void      PASSTHRU_PlaybackPause();
extern void      PASSTHRU_PlaybackResume();
extern void      DirectIO_InitSB();
extern void      DirectIO_AckIRQ();

/* vCOMPAT.asm */
extern void      vCOMPAT_ReportIRQDetection(PCRF pcrf);

/* VDD-API.asm */
extern BOOL      VDDAPI ();
