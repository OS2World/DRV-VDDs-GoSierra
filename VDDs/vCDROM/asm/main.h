/* CONST.asm */
extern CHAR     CONST_CDROM_MAIN;
extern CHAR     CONST_CDROM_COPYRIGHT;
extern CHAR     CONST_CDROM_INTDURINGIO;
extern CHAR     CONST_CDROM_CHARDEV;
extern CHAR     CONST_VCDROM;
extern CHAR     CONST_VPIC;

/* GlobalData.asm */

// Variables in Instance Data-Segment (for every VDM)
extern HVDM     CurVDMHandle;

extern CHAR     CDROM_CHARDEV_Information;
extern USHORT   CDROM_DriveCount;
extern USHORT   CDROM_FirstDriveNo;

extern BOOL     PROPERTY_INTDuringIO;
extern HVDD     VPIC_Handle;
extern PFN      VPIC_SlaveRequestFunc;

extern VPVOID   VCDROM_APIBreakPoint;
extern USHORT   VCDROM_DDHeaderSegment;
extern VPVOID   VCDROM_DDBreakPoint;

/* Instance.asm */
extern VOID     VDD_INT3();
extern VOID     VDD_InitInstanceData();
extern VOID     VDD_InstanceClosing();

extern VOID     VCDROM_InstallCode();
extern BOOL     VCDROM_APIEntry(PVOID pHookData, PCRF pcrf);
extern BOOL     VCDROM_DDEntry(PVOID pHookData, PCRF pcrf);

/* VDD-API.asm */
extern BOOL     VDDAPI ();
