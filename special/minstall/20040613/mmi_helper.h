
PMINSTDIR  MINSTALL_SearchSourceDirID (ULONG DirectoryID);
PMINSTDIR  MINSTALL_SearchDestinDirID (ULONG DirectoryID);
PMINSTGRP  MINSTALL_SearchGroupID (ULONG GroupID);
PMINSTGRP  MINSTALL_SearchGroupGeninID (ULONG GeninID);
PMINSTFILE MINSTALL_SearchFileCRC32 (ULONG FileCRC32);
PCHAR      MINSTALL_ExtractValue (PULONG DestPtr, PCHAR StartPos, PCHAR EndPos);
PSZ        MINSTALL_GetPointerToMacro (PCHAR *CurPosPtr, PCHAR EndPos);
PCHAR      MINSTALL_GetMacrodString (PCHAR DestPtr, ULONG DestMaxSize, PCHAR StartPos, PCHAR EndPos);
PCHAR      MINSTALL_GetNumericValue (PULONG DestPtr, PCHAR StartPos, PCHAR EndPos);
ULONG      MINSTALL_GetVersionCode (PSZ VersionString);
VOID       MINSTALL_GetInstalledVersion (PSZ GroupName, PSZ DestVersionInstalled);
VOID       MINSTALL_printf (PSZ FormatStr, ...);

VOID       MINSTALL_TrappedError (ULONG ErrorMsgID);

VOID       MINSTLOG_OpenFile (void);
VOID       MINSTLOG_CloseFile (void);
VOID       MINSTLOG_ToFile (PSZ FormatStr,...);
VOID       MINSTLOG_ToScreen (PSZ FormatStr,...);
VOID       MINSTLOG_ToAll (PSZ FormatStr,...);
