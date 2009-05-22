// from mmi_inistuff.h
#define MCIMAX_DEVICENAMELENGTH    20
#define MCIMAX_VERSIONLENGTH        6
#define MCIMAX_PRODLENGTH          40
#define MCIMAX_PDDNAMELENGTH        9
#define MCIMAX_ALIASNAMELENGTH     20
#define MCIMAX_DEVPARAMSLENGTH    128
#define MCIMAX_CLASSES             10
#define MCIMAX_CONNECTORS          10
#define MCIMAX_EXTENSIONS          25
#define MCIMAX_EXTENSIONNAMELENGTH  4
#define MCIMAX_TYPELISTLENGTH     257

// These flags are used, so that MINSTALL_CleanUp() knows what needs clean-up.
#define MINSTDONE_BEGANPACKAGEINIT          0x0001
#define MINSTDONE_LOADMASTERCTRLSCR         0x0002
#define MINSTDONE_LOADFILECTRLSCR           0x0004
#define MINSTDONE_LOADCARDINFO              0x0008
#define MINSTDONE_LOADCUSTOMCTRLSCR         0x0010
#define MINSTDONE_PUBLICGROUP               0x0020
#define MINSTDONE_COMPLETEDPACKAGEINIT      0x0040
#define MINSTDONE_LINKINIMPORTS             0x0080

typedef struct _MINSTDIR { // MINSTALL-Directory Container for one directory
   ULONG      ID;
   ULONG      Flags;
   CHAR       Name[MINSTMAX_PATHLENGTH];
   CHAR       FQName[MINSTMAX_PATHLENGTH];  // Full-Qualified Directory
 } MINSTDIR;
typedef MINSTDIR *PMINSTDIR;

#define MINSTDIR_Length                  sizeof(MINSTDIR)
#define MINSTDIR_Flags_Included          0x01
#define MINSTDIR_Flags_Selected          0x02 // If already generated
#define MINSTDIR_Flags_Source            0x04 // Set, if source-directory
#define MINSTDIR_Flags_Boot              0x08 // On-Boot-Drive
#define MINSTDIR_Flags_Delete            0x10 // Delete instead of copy
#define MINSTDIR_Flags_Locked            0x20 // Unlock, if required IBMLANLK
#define MINSTDIR_Flags_MMBase            0x40 // Insert MMBase...

typedef struct _MINSTGENIDRV {           // Generic Installer Driver Info
   PCHAR      InstallNamePtr;            // 2-digit number added
   USHORT     DeviceType;
   ULONG      DeviceFlag;
   PCHAR      MCDDriverNamePtr;
   PCHAR      VSDDriverNamePtr;
   USHORT     ShareType;
   PCHAR      ResourceNamePtr;           // 2-digit number added
   USHORT     ResourceUnits;
   USHORT     ResourceClassCount;
   USHORT     ResourceClassArray[MCIMAX_CLASSES];
   USHORT     ResourceClassComboCount;
   USHORT     ResourceClassComboArray[MCIMAX_CLASSES][MCIMAX_CLASSES];
   USHORT     ConnectorCount;
   USHORT     ConnectorType[MCIMAX_CONNECTORS];
   PCHAR      ConnectorToInstallNamePtr[MCIMAX_CONNECTORS];
   USHORT     ConnectorToConnectIndex[MCIMAX_CONNECTORS];
   PCHAR      ConnectorArrayPtr;         // 2nd element - 2-digit number added
   USHORT     ExtensionCount;            //                (if non-NUL string)
   CHAR       ExtensionArray[MCIMAX_EXTENSIONS][MCIMAX_EXTENSIONNAMELENGTH];
   PCHAR      EATypesPtr;
   PCHAR      AliasNamePtr;
   PCHAR      DeviceParmsPtr;
 } MINSTGENIDRV;
typedef MINSTGENIDRV *PMINSTGENIDRV;

typedef struct _MINSTGENI {              // Generic Installer Container
   ULONG      CARDINFOResourceID;
   ULONG      MaxCardCount;
   ULONG      SelectedCards;
   CHAR       CustomDLLFileName[MINSTMAX_PATHLENGTH];
   PVOID      CustomDLLFilePtr;
   CHAR       CustomDLLEntry[MINSTMAX_STRLENGTH];
   ULONG      ConfigSysLinesCount;
   PSZ        ConfigSysLinesPtr[MINSTMAX_GENINCONFIGSYSLINES];
   ULONG      DriverCount;
   PSZ        ProductNamePtr;
   PSZ        ProductVersionPtr;
   PSZ        PDDNamePtr;
   PSZ        MCDTableNamePtr;
   PSZ        VSDTableNamePtr;
   ULONG      PromptsCount;
   PSZ        PromptTitlePtr[MINSTMAX_GENINPROMPTS];      // ASCIIZ String
   ULONG      PromptChoiceCount[MINSTMAX_GENINPROMPTS];   // Count of Choice
   ULONG      PromptChoiceDefault[MINSTMAX_GENINPROMPTS];
   PSZ        PromptChoiceStrings[MINSTMAX_GENINPROMPTS]; // ASCIIZ Strings
   PSZ        PromptChoiceValues[MINSTMAX_GENINPROMPTS];  // ASCIIZ Strings
   // Ptr to current choosen PromptChoiceValues[]-Value
   PSZ        PromptSelectedValue[MINSTMAX_GENINCARDS][MINSTMAX_GENINPROMPTS];
   // Number of currently choosen Choice (0 based)
   ULONG      PromptSelectedValueNo[MINSTMAX_GENINCARDS][MINSTMAX_GENINPROMPTS];
   MINSTGENIDRV Drivers[MINSTMAX_GENINDRIVERS];
 } MINSTGENI;
typedef MINSTGENI *PMINSTGENI;

typedef struct _MINSTGRP { // MINSTALL-Group Container for one group
   ULONG      ID;
   ULONG      GeninID;
   ULONG      Flags;
   CHAR       Name[MINSTMAX_STRLENGTH];
   ULONG      VersionCode;
   ULONG      VersionInstalledCode;
   CHAR       Version[MINSTMAX_STRLENGTH];
   CHAR       VersionInstalled[MINSTMAX_STRLENGTH];
   CHAR       Icon[MINSTMAX_STRLENGTH];
   USHORT     AutoSelect;
   CHAR       ConfigFileName[MINSTMAX_STRLENGTH];
   PVOID      ConfigFilePtr;                // actually PMINSTALLFILE
   CHAR       INIFileName[MINSTMAX_STRLENGTH];
   PVOID      INIFilePtr;                   // actually PMINSTALLFILE
   CHAR       CoReqs[MINSTMAX_STRLENGTH];
   CHAR       ODInst[MINSTMAX_STRLENGTH];
   CHAR       DLLFileName[MINSTMAX_STRLENGTH];
   PVOID      DLLFilePtr;                   // actually PMINSTALLFILE
   CHAR       DLLEntry[MINSTMAX_STRLENGTH];
   CHAR       DLLParms[MINSTMAX_STRLENGTH];
   CHAR       TermDLLFileName[MINSTMAX_STRLENGTH];
   PVOID      TermDLLFilePtr;               // actually PMINSTALLFILE
   CHAR       TermDLLEntry[MINSTMAX_STRLENGTH];
   CHAR       CustomData[MINSTMAX_CUSTOMDATALENGTH];
   ULONG      SpaceNeeded;
   PVOID      ConfigChangeArray;            // <-- done by mmi_ctrlprc.c
   PVOID      ConfigStringArray;
   ULONG      ConfigChangeCount;
   PVOID      INIChange1stEntry;            // <-- done by mmi_ctrlprc.c as well
   ULONG      INIChangeCount;
   PMINSTGENI GeninPtr;                     // Generic Installer (GENIN) info
 } MINSTGRP;
typedef MINSTGRP *PMINSTGRP;

#define MINSTGRP_Length                  sizeof(MINSTGRP)
#define MINSTGRP_Flags_Included          0x01
#define MINSTGRP_Flags_Selected          0x02
#define MINSTGRP_Flags_SelectionForced   0x04
#define MINSTGRP_Flags_DontListPublic    0x08 // means unlisted in PubGroup

// If ForceSelect is present, this group won't get shown to the calling app
//  in PublicGroupArray. 

#define MINSTGRP_Select_Always           0 // 
#define MINSTGRP_Select_Required         1
#define MINSTGRP_Select_Version          2
#define MINSTGRP_Select_Yes              3
#define MINSTGRP_Select_No               4
#define MINSTGRP_Select_BaseNewer        5
#define MINSTGRP_Select_OnlyNewer        6

typedef struct _MINSTFILE { // MINSTALL-File Container for one file
   CHAR       Name[MINSTMAX_PATHLENGTH];
   ULONG      NameCRC32;
   ULONG      Flags;
   ULONG      DiskID;
   ULONG      GroupID;
   PMINSTGRP  GroupPtr;
   ULONG      DestinID;
   PMINSTDIR  DestinPtr;
   ULONG      SourceID;
   PMINSTDIR  SourcePtr;
 } MINSTFILE;
typedef MINSTFILE *PMINSTFILE;

#define MINSTFILE_Length                 sizeof(MINSTFILE)
#define MINSTFILE_Flags_Included         0x01
#define MINSTFILE_Flags_Selected         0x02
#define MINSTFILE_Flags_INSTDLL          0x04 // Is Installer-DLL
#define MINSTFILE_Flags_INSTTermDLL      0x08 // Is Installer-Term-DLL
#define MINSTFILE_Flags_INICF            0x10 // Is INI-Control-File
#define MINSTFILE_Flags_CFGCF            0x20 // Is CFG-Control-File

// "Included" means in virtual file-listing (and will get copied, if selected)
// "Selected" means that the file is selected due group
// "INSTDLL" means that the file is required for MINSTCID-Processing
// "INICF" means that the file is an INI-Control-File
// "CFGCF" means that the file is an CONFIG-Control-File

typedef struct _MINSTINI_DEFENTRY {
   ULONG               ID;
   PSZ                 Name;
   PVOID               ParmListPtr;
   ULONG               MaxSize;
 } MINSTINI_DEFENTRY;
typedef MINSTINI_DEFENTRY *PMINSTINI_DEFENTRY;
