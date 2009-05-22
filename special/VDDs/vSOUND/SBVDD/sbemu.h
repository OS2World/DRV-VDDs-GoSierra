
/* SBEMU.OBJ */
extern void   SBemu_InitVars         (void);
extern long   SBemulationSwitch;

extern void   SBemu_OutOnSB          (void);
extern void   SBemu_InOnSB           (void);
extern void   SBemu_OutOnDMA         (void);
extern void   SBemu_InOnDMA          (void);

extern long   InVIRQDetection;
extern long   InVIRQDetectionCounter;

extern short  SBoutputRate;
extern short  SBoutputFlags;
extern short  SBoutputLength;
extern short  SBoutputDMApos;

#define SBoutputFlag_AutoInit    0x001  // Bit 0
#define SBoutputFlag_16bit       0x002  // Bit 1
#define SBoutputFlag_Stereo      0x004  // Bit 2
#define SBoutputFlag_Signed      0x008  // Bit 3
