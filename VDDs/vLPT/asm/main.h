#pragma pack (1);               // needs to be done, Watcom screws up otherwise

/* const.asm */
extern CHAR      CONST_TIMERPDD;
extern CHAR      CONST_VTIMERVDD;
extern CHAR      CONST_TIMER_MAIN;
extern CHAR      CONST_TIMER_COPYRIGHT;
extern CHAR      CONST_TIMER_DEBUG;
extern CHAR      CONST_DOS_BACKGROUND_EXEC;
extern CHAR      CONST_HW_NOSOUND;
extern CHAR      CONST_HW_TIMER;
extern CHAR      CONST_XMS_MEMORY_LIMIT;

// Variables in Instance Data-Segment (for every VDM)
extern HVDM      CurVDMHandle;
extern HFILE     DebugFileHandle;

extern BOOL      PROPERTY_TIMER_DEBUG;
extern BOOL      PROPERTY_DOS_BACKGROUND_EXEC;
extern BOOL      PROPERTY_HW_NOSOUND;
extern BOOL      PROPERTY_HW_TIMER;
extern ULONG     PROPERTY_XMS_MEMORY_LIMIT;

/* PortIOdata.asm */
extern IOH       VTIMER_Ports_PITCounterIOhookTable;
extern IOH       VTIMER_Ports_PITModeIOhookTable;
extern IOH       VTIMER_Ports_KeyboardIOhookTable;

// =====================================================================[CODE]=

/* Instance.asm */
extern VOID      VDD_InitInstanceData();

/* VTIMER_API.asm */
extern BOOL      VTIMER_VDDAPI ();

/* PortIO.asm */
extern void      VTIMER_InOnPITCounter();
extern void      VTIMER_OutOnPITCounter();
extern void      VTIMER_InOnPITMode();
extern void      VTIMER_OutOnPITMode();
extern void      VTIMER_InOnKeyboard();
extern void      VTIMER_OutOnKeyboard();

#pragma pack ();                // restores default pack()
