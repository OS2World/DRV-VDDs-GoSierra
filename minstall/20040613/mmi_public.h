#define MINSTMAX_STRLENGTH                   128
#define MINSTMAX_PATHLENGTH                  256
#define MINSTMAX_GENINCARDS                    9
#define MINSTMAX_GENINCONFIGSYSLINES           6
#define MINSTMAX_GENINDRIVERS                  6
#define MINSTMAX_GENINPROMPTS                 10
#define MINSTMAX_CUSTOMDATALENGTH            256

typedef struct _MINSTPUBGROUP {
   ULONG      ID;
   BOOL       Selected;
   BOOL       SelectionForced;
   CHAR       Name[MINSTMAX_STRLENGTH];
   CHAR       Version[MINSTMAX_STRLENGTH];
   CHAR       VersionInstalled[MINSTMAX_STRLENGTH];
   ULONG      SpaceNeeded;
   ULONG      MaxCardCount;
   ULONG      PromptsCount;
   PSZ        PromptTitlePtr[MINSTMAX_GENINPROMPTS];      // ASCIIZ String
   ULONG      PromptChoiceCount[MINSTMAX_GENINPROMPTS];   // Count of Choice
   ULONG      PromptChoiceDefault[MINSTMAX_GENINPROMPTS]; // Defaults for Choice
   PSZ        PromptChoiceStrings[MINSTMAX_GENINPROMPTS]; // ASCIIZ Strings
 } MINSTPUBGROUP;
typedef MINSTPUBGROUP *PMINSTPUBGROUP;

// Public API Functions
BOOL   EXPENTRY MINSTALL_Init (ULONG BootDrive, HAB PMHandle, HMQ MSGQHandle, PSZ MMBase, PSZ LogFileName);
BOOL   EXPENTRY MINSTALL_InitPackage (PSZ SourcePath);
BOOL   EXPENTRY MINSTALL_InstallPackage (void);
PSZ    EXPENTRY MINSTALL_GetErrorMsgPtr (void);
USHORT EXPENTRY MINSTALL_GetErrorMsgCIDCode (void);
PSZ    EXPENTRY MINSTALL_GetSourcePathPtr (void);
PSZ    EXPENTRY MINSTALL_GetTargetPathPtr (void);
ULONG  EXPENTRY MINSTALL_GetPublicGroupArrayPtr (PMINSTPUBGROUP *GroupArrayPtr);
PSZ    EXPENTRY MINSTALL_GetPublicGroupCustomDataPtr (ULONG GroupID);
BOOL   EXPENTRY MINSTALL_SetPublicGroupCustomData (ULONG GroupID, PSZ CustomData);
PSZ    EXPENTRY MINSTALL_GetPackageTitlePtr (void);
VOID   EXPENTRY MINSTALL_SelectGroup (ULONG GroupID);
VOID   EXPENTRY MINSTALL_DeSelectGroup (ULONG GroupID);
VOID   EXPENTRY MINSTALL_SetCARDINFOCardCountForGroup (ULONG GroupID, ULONG SelectedCards);
ULONG  EXPENTRY MINSTALL_GetCARDINFOChoiceForGroup (ULONG GroupID, ULONG CardNo, ULONG PromptNo);
VOID   EXPENTRY MINSTALL_SetCARDINFOChoiceForGroup (ULONG GroupID, ULONG CardNo, ULONG PromptNo, ULONG ChoiceNo);
VOID   EXPENTRY MINSTALL_CleanUp (void);
