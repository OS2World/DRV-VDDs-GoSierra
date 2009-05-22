/* CONST.asm */
extern char     CONST_CMOS_MAIN;
extern char     CONST_CMOS_COPYRIGHT;
extern char     CONST_CMOS_WRITEPROTECT;
extern char     CONST_CMOS_VIRTUALRTC;
extern char     CONST_CMOS_VIRTUALRTC_NOGO;
extern char     CONST_VDMA;

/* GlobalData.asm */
extern HIRQ     VIRQ_Handle;
extern HVDD     VDMA_Handle;
extern BOOL     VDMA_ExtensionsFound;
extern HVDM     VCMOS_IRQ8OnVDM;

/* PortIOdata.asm */
extern IOH      VCMOS_AddrPort_IOhookTable;
extern IOH      VCMOS_DataPort_IOhookTable;

// Variables in Instance Data-Segment (for every VDM)
extern HVDM     CurVDMHandle;

extern BOOL     PROPERTY_WriteProtection;
extern BOOL     PROPERTY_PeriodicInterrupt;
extern BOOL     TRIGGER_TimerInUse;

/* Instance.asm */
extern VOID     VDD_INT3();
extern VOID     VDD_InitInstanceData();
