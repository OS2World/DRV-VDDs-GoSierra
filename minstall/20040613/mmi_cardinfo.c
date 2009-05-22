
// ˘ ƒ ƒƒƒƒÕÕ = ƒ  ˘  ƒ = ÕÕƒƒƒƒ ƒ ˘
// ≥                               ≥
//    ‹€€€€€€€‹   ‹€‹  ‹€€€€€€€€‹          ˙  ˙ƒƒƒÕƒƒÕƒÕÕƒƒÕÕÕÕƒÕÕÕÕÕÕÕÕÕŒƒ
// ≥ €€€€ﬂﬂﬂ€€€€ €€€€€ €€€ﬂ   ﬂ€€€ ≥             MINSTALL Front-End      ∫
// ∫ €€€€‹‹‹€€€€ €€€€€ €€€‹   ‹€€€ ∫      ˙ ƒƒƒƒÕƒÕÕƒƒÕÕÕÕƒÕÕÕÕÕÕÕÕƒÕÕÕÕÕŒƒ
// ∫ €€€€€€€€€€€ €€€€€ €€€€€€€€€ﬂ  ∫       Section: MMOS/2 for eCS       ∫
// ∫ €€€€   €€€€ €€€€€ €€€€ ﬂ€€€€‹ ∫     ≥ Created: 28/10/02             ∫
// ≥ ﬂ€€ﬂ   ﬂ€€ﬂ  ﬂ€ﬂ  ﬂ€€ﬂ   ﬂ€€ﬂ ≥     ≥ Last Modified:                ≥
//                  ‹‹‹                  ≥ Number Of Modifications: 000  ≥
// ˘              ‹€€ﬂ             ˘     ≥ INCs required: *none*         ≥
//      ƒƒƒƒƒƒƒ ‹€€ﬂ                     ∫ Written By: Martin Kiewitz    ≥
// ≥     ⁄ø⁄ø≥‹€€€‹‹€€€‹           ≥     ∫ (c) Copyright by              ≥
// ∫     ¿Ÿ≥¿Ÿﬂ€€€ﬂﬂ‹€€ﬂ           ∫     ∫      AiR ON-Line Software '02 ˙
// ∫    ƒƒƒƒƒƒƒ    ‹€€›            ∫     ∫ All rights reserved.
// ∫              ‹€€€ƒƒƒƒƒƒƒƒƒ    ∫    ƒŒÕÕÕƒÕÕÕÕÕƒÕÕÕÕƒÕÕƒƒÕƒƒÕƒƒƒ˙ƒƒ  ˙
// ∫             ‹€€€›≥ ≥⁄ø≥≥ƒ     ∫
// ≥            ‹€€€€ ¿ƒ≥≥¿Ÿ≥ƒ     ≥
//             ﬂ€€€€›ƒƒƒƒƒƒƒƒƒƒ     
// ≥             ﬂﬂ                ≥
// ˘ ƒ¥-=íiÁ ÈÔ-LiÔÓ SÈü‚WíÁÓ=-√ƒƒ ˘


#define INCL_BASE
#define INCL_DOSMODULEMGR
#define INCL_WINWORKPLACE                   // for WPS functions
#define INCL_WINMESSAGEMGR
#define INCL_WINWINDOWMGR
#define INCL_OS2MM
#include <os2.h>
#include <os2me.h>
#include <malloc.h>

#include <global.h>
#include <cfgsys.h>
#include <crcs.h>
#include <dll.h>
#include <file.h>
#include <globstr.h>
#include <msg.h>
#include <mciini.h>                         // MCI-INI Functions
#include <mmi_public.h>
#include <mmi_types.h>
#include <mmi_main.h>
#include <mmi_helper.h>
#include <mmi_msg.h>
#include <mmi_inistuff.h>
#include <mmi_ctrlprc.h>

// ****************************************************************************

// Reads in CARDINFO.DLL information for all groups...
BOOL MINSTALL_LoadCARDINFO (VOID) {
   PCHAR      ResourcePtr    = 0;
   ULONG      ResourceSize   = 0;
   PCHAR      ResourceEndPtr = 0;
   PCHAR      ResourceTmpPtr = 0;
   CHAR       CARDINFOFile[MINSTMAX_PATHLENGTH];
   PMINSTFILE CurFilePtr     = 0;
   PMINSTDIR  CurDirPtr      = 0;
   PMINSTGRP  CurGroupPtr    = 0;
   PMINSTGENI CurGeninPtr    = 0;
   ULONG      DLLGroupNo     = 0;
   ULONG      DLLGroupCount  = 0;
   ULONG      DLLKnownGroups = 0;
   ULONG      DLLGeninID     = 0;
   ULONG      DLLResourceID  = 0;
   ULONG      PromptNo       = 0;
   ULONG      PromptChoiceNo = 0;
   ULONG      PromptDefault  = 0;
   ULONG      DriverNo       = 0;
   ULONG      CurNo          = 0;
   ULONG      TmpLen         = 0;
   ULONG      TempULONG      = 0;
   ULONG      TempULONG2     = 0;
   ULONG      CRC32          = 0;

   // If no cardinfo.dll in filelisting or Genin not used -> skip but SUCCESS
   if ((!FCF_CARDINFOFilePtr) || (!MINSTALL_GeninUsed))
      return TRUE;

   // Remember this action for cleanup...
   MINSTALL_Done |= MINSTDONE_LOADCARDINFO;

   CurDirPtr = MINSTALL_SearchSourceDirID(FCF_CARDINFOFilePtr->SourceID);
   if (!STRING_CombinePSZ ((PCHAR)&CARDINFOFile, MINSTMAX_PATHLENGTH, CurDirPtr->FQName, FCF_CARDINFOFilePtr->Name))
      return FALSE;

   // Set Insert 1 to CARDINFO.DLL, because this file is now processed...
   MSG_SetInsertViaPSZ (1, CARDINFOFile);

   // Try to load CARDINFO.DLL, if this fails -> fail altogether...
   if (!(FCF_CARDINFOHandle = DLL_Load(CARDINFOFile))) {
      MINSTALL_TrappedError (MINSTMSG_CouldNotLoad); return FALSE; }

   // Get ResourceID 1. This contains number of groups in DLL.
   if (!DLL_GetDataResource(FCF_CARDINFOHandle, 1, (PVOID)&ResourcePtr, &ResourceSize))
      return FALSE;
   ResourceEndPtr = (PCHAR)(((ULONG)ResourcePtr)+ResourceSize);
   if (!(ResourcePtr = STRING_GetASCIIZNumericValue (&DLLGroupCount, ResourcePtr, ResourceEndPtr)))
      return FALSE;

   while (DLLGroupNo<DLLGroupCount) {
      // Get first resource for that Group... (contains GroupID)
      DLLResourceID += 10;
      if (!DLL_GetDataResource(FCF_CARDINFOHandle, DLLResourceID, (PVOID)&ResourcePtr, &ResourceSize))
         return FALSE;
      ResourceEndPtr = (PCHAR)(((ULONG)ResourcePtr)+ResourceSize);

      // Get the Genin-ID for this CARDINFO-entry...
      if (!(ResourcePtr = STRING_GetASCIIZNumericValue (&DLLGeninID, ResourcePtr, ResourceEndPtr)))
         return FALSE;
      CurGroupPtr = MINSTALL_SearchGroupGeninID(DLLGeninID);
      // We know this group and it wasnt already processed?
      if ((CurGroupPtr!=0) && (!CurGroupPtr->GeninPtr)) {
         // First allocate Genin-Structure for holding CARDINFO-data...
         CurGeninPtr = malloc(sizeof(MINSTGENI));
         if (!CurGeninPtr) {
            MINSTALL_TrappedError (MINSTMSG_OutOfMemory); return FALSE; }
         memset (CurGeninPtr, 0, sizeof(MINSTGENI));

         CurGroupPtr->GeninPtr = CurGeninPtr;
         CurGeninPtr->CARDINFOResourceID = DLLResourceID+1;

         // ============================================ Read basic information
         // --------------------------------- Element 1 - Maximum Adapter Count
         if (!DLL_GetDataResource(FCF_CARDINFOHandle, DLLResourceID+1, (PVOID)&ResourcePtr, &ResourceSize))
            return FALSE;
         ResourceEndPtr = (PCHAR)(((ULONG)ResourcePtr)+ResourceSize);
         if (!(ResourcePtr = STRING_GetASCIIZNumericValue (&CurGeninPtr->MaxCardCount, ResourcePtr, ResourceEndPtr)))
            return FALSE;
         CurGeninPtr->SelectedCards = 1; // Defaults to 1 card...
         if ((CurGeninPtr->MaxCardCount==0) || (CurGeninPtr->MaxCardCount>MINSTMAX_GENINCARDS)) {
            MINSTALL_TrappedError (MINSTMSG_IllegalAdapterCount); return FALSE; }
         // ------------------------------- Element 2 - Skip over Helpfile-Name
         if (!(ResourcePtr = STRING_SkipASCIIZ(ResourcePtr, ResourceEndPtr)))
            return FALSE;
         // ----------------------------- Element 3 - Adapter specific DLL Name
         if (!(ResourcePtr = STRING_GetASCIIZString(CurGeninPtr->CustomDLLFileName, MINSTMAX_PATHLENGTH, ResourcePtr, ResourceEndPtr)))
            return FALSE;
         // ---------------------- Element 4 - Adapter specific DLL Entry Point
         if (!(ResourcePtr = STRING_GetASCIIZString(CurGeninPtr->CustomDLLEntry, MINSTMAX_STRLENGTH, ResourcePtr, ResourceEndPtr)))
            return FALSE;
         // Check if DLLName&DLLEntry are both set...
         if ((CurGeninPtr->CustomDLLFileName[0]!=0) && (CurGeninPtr->CustomDLLEntry[0]!=0)) {
            strlwr(CurGeninPtr->CustomDLLFileName);
            // If FileName doesn't contain '.dll', add it by ourselves...
            TmpLen = strlen(CurGeninPtr->CustomDLLFileName);
            if ((TmpLen<4) || (strcmp(CurGeninPtr->CustomDLLFileName+TmpLen-4,".dll")!=0))
               if (TmpLen+4<MINSTMAX_PATHLENGTH)
                  strcpy (CurGeninPtr->CustomDLLFileName+TmpLen, ".dll");
            // We found something, check if the filename got listed...
            CRC32 = CRC32_GetFromPSZ(CurGeninPtr->CustomDLLFileName);
            if (!(CurFilePtr = MINSTALL_SearchFileCRC32(CRC32))) {
               MSG_SetInsertViaPSZ (2, CurGeninPtr->CustomDLLFileName);
               MINSTALL_TrappedError (MINSTMSG_UnlistedInstallDLL);
               return FALSE;                // if DLL not found in filelisting
             }
            // Remove Included-state from file, so it won't get copied...
            CurFilePtr->Flags            &= !MINSTFILE_Flags_Included;
            CurGeninPtr->CustomDLLFilePtr = CurFilePtr;
          } else {
            CurGeninPtr->CustomDLLFileName[0] = 0; // <-- for safety
          }
         // ---------------------------- Element 5 - Number of CONFIG.SYS Lines
         if (!(ResourcePtr = STRING_GetASCIIZNumericValue (&CurGeninPtr->ConfigSysLinesCount, ResourcePtr, ResourceEndPtr)))
            return FALSE;
         if (CurGeninPtr->ConfigSysLinesCount>MINSTMAX_GENINCONFIGSYSLINES) {
            MINSTALL_TrappedError (MINSTMSG_IllegalConfigSysLineCount); return FALSE; }

         // -------------------------------------- Element 6 - CONFIG.SYS Lines
         while (CurNo<CurGeninPtr->ConfigSysLinesCount) {
            if (!(ResourceTmpPtr = STRING_SkipASCIIZ(ResourcePtr, ResourceEndPtr)))
               return FALSE;
            TmpLen = ResourceTmpPtr-ResourcePtr;
            CurGeninPtr->ConfigSysLinesPtr[CurNo] = ResourcePtr;
            ResourcePtr = ResourceTmpPtr;
            CurNo++;
          }

         // ------------------------- Element 7 - Number of Drivers per Adapter
         if (!(ResourcePtr = STRING_GetASCIIZNumericValue(&CurGeninPtr->DriverCount, ResourcePtr, ResourceEndPtr)))
            return FALSE;
         if ((CurGeninPtr->DriverCount==0) || (CurGeninPtr->DriverCount>MINSTMAX_GENINDRIVERS)) {
            MINSTALL_TrappedError (MINSTMSG_IllegalDriverCount); return FALSE; }
         // ------------------------------------------ Element 8 - Product Name
         CurGeninPtr->ProductNamePtr = ResourcePtr;
         if (!(ResourcePtr = STRING_SkipASCIIZ(ResourcePtr, ResourceEndPtr)))
            return FALSE;
         TmpLen = strlen(CurGeninPtr->ProductNamePtr);
         if ((TmpLen==0) || (TmpLen>=MCIMAX_PRODLENGTH)) {
            MSG_SetInsertViaPSZ (2, "ProductName");
            MINSTALL_TrappedError (MINSTMSG_CIBadValueFor); return FALSE; }
         // --------------------------------------- Element 9 - Product Version
         CurGeninPtr->ProductVersionPtr = ResourcePtr;
         if (!(ResourcePtr = STRING_SkipASCIIZ(ResourcePtr, ResourceEndPtr)))
            return FALSE;
         TmpLen = strlen(CurGeninPtr->ProductVersionPtr);
         if ((TmpLen==0) || (TmpLen>=MCIMAX_VERSIONLENGTH)) {
            MSG_SetInsertViaPSZ (2, "ProductVersion");
            MINSTALL_TrappedError (MINSTMSG_CIBadValueFor); return FALSE; }
         // --------------------------------------------- Element 10 - PDD Name
         CurGeninPtr->PDDNamePtr = ResourcePtr;
         if (!(ResourcePtr = STRING_SkipASCIIZ(ResourcePtr, ResourceEndPtr)))
            return FALSE;
         TmpLen = strlen(CurGeninPtr->PDDNamePtr);
         if (TmpLen>=MCIMAX_PDDNAMELENGTH-2) {
            MSG_SetInsertViaPSZ (2, "PDDName");
            MINSTALL_TrappedError (MINSTMSG_CIBadValueFor); return FALSE; }
         // -------------------------------------------- Element 11 - MCD Table
         CurGeninPtr->MCDTableNamePtr = ResourcePtr;
         if (!(ResourcePtr = STRING_SkipASCIIZ(ResourcePtr, ResourceEndPtr)))
            return FALSE;
         TmpLen = strlen(CurGeninPtr->MCDTableNamePtr);
         if (TmpLen>=MCIMAX_DEVICENAMELENGTH) {
            MSG_SetInsertViaPSZ (2, "MCDTable");
            MINSTALL_TrappedError (MINSTMSG_CIBadValueFor); return FALSE; }
         // -------------------------------------------- Element 12 - VSD Table
         CurGeninPtr->VSDTableNamePtr = ResourcePtr;
         if (!(ResourcePtr = STRING_SkipASCIIZ(ResourcePtr, ResourceEndPtr)))
            return FALSE;
         TmpLen = strlen(CurGeninPtr->VSDTableNamePtr);
         if (TmpLen>=MCIMAX_DEVICENAMELENGTH) {
            MSG_SetInsertViaPSZ (2, "VSDTable");
            MINSTALL_TrappedError (MINSTMSG_CIBadValueFor); return FALSE; }

         // =================================== Readin driver install resources
         for (DriverNo=0; DriverNo<CurGeninPtr->DriverCount; DriverNo++) {
            if (!DLL_GetDataResource(FCF_CARDINFOHandle, DLLResourceID+2+DriverNo, (PVOID)&ResourcePtr, &ResourceSize))
               return FALSE;
            ResourceEndPtr = (PCHAR)(((ULONG)ResourcePtr)+ResourceSize);

            // ---------------------------------------- Element 1 - InstallName
            CurGeninPtr->Drivers[DriverNo].InstallNamePtr = ResourcePtr;
            if (!(ResourcePtr = STRING_SkipASCIIZ(ResourcePtr, ResourceEndPtr)))
               return FALSE;
            TmpLen = strlen(CurGeninPtr->Drivers[DriverNo].InstallNamePtr);
            if ((TmpLen==0) || (TmpLen>=MCIMAX_DEVICENAMELENGTH-2)) {
               MSG_SetInsertViaPSZ (2, "InstallName");
               MINSTALL_TrappedError (MINSTMSG_CIBadValueFor); return FALSE; }
            // ----------------------------------------- Element 2 - DeviceType
            if (!(ResourcePtr = STRING_GetASCIIZNumericValue(&TempULONG, ResourcePtr, ResourceEndPtr)))
               return FALSE;
            CurGeninPtr->Drivers[DriverNo].DeviceType = TempULONG;
            // ----------------------------------------- Element 3 - DeviceFlag
            if (!(ResourcePtr = STRING_GetASCIIZNumericValue(&CurGeninPtr->Drivers[DriverNo].DeviceFlag, ResourcePtr, ResourceEndPtr)))
               return FALSE;
            // -------------------------------------- Element 4 - MCDDriverName
            CurGeninPtr->Drivers[DriverNo].MCDDriverNamePtr = ResourcePtr;
            if (!(ResourcePtr = STRING_SkipASCIIZ(ResourcePtr, ResourceEndPtr)))
               return FALSE;
            TmpLen = strlen(CurGeninPtr->Drivers[DriverNo].MCDDriverNamePtr);
            if ((TmpLen==0) || (TmpLen>=MCIMAX_DEVICENAMELENGTH)) {
               MSG_SetInsertViaPSZ (2, "MCDDriverName");
               MINSTALL_TrappedError (MINSTMSG_CIBadValueFor); return FALSE; }
            // -------------------------------------- Element 5 - VSDDriverName
            CurGeninPtr->Drivers[DriverNo].VSDDriverNamePtr = ResourcePtr;
            if (!(ResourcePtr = STRING_SkipASCIIZ(ResourcePtr, ResourceEndPtr)))
               return FALSE;
            TmpLen = strlen(CurGeninPtr->Drivers[DriverNo].VSDDriverNamePtr);
            if (TmpLen>=MCIMAX_DEVICENAMELENGTH) {
               MSG_SetInsertViaPSZ (2, "VSDDriverName");
               MINSTALL_TrappedError (MINSTMSG_CIBadValueFor); return FALSE; }
            // ------------------------------------------ Element 6 - ShareType
            if (!(ResourcePtr = STRING_GetASCIIZNumericValue(&TempULONG, ResourcePtr, ResourceEndPtr)))
               return FALSE;
            CurGeninPtr->Drivers[DriverNo].ShareType = (USHORT)TempULONG;
            // --------------------------------------- Element 7 - ResourceName
            CurGeninPtr->Drivers[DriverNo].ResourceNamePtr = ResourcePtr;
            if (!(ResourcePtr = STRING_SkipASCIIZ(ResourcePtr, ResourceEndPtr)))
               return FALSE;
            TmpLen = strlen(CurGeninPtr->Drivers[DriverNo].ResourceNamePtr);
            if ((TmpLen==0) || (TmpLen>=MCIMAX_DEVICENAMELENGTH)) {
               MSG_SetInsertViaPSZ (2, "ResourceName");
               MINSTALL_TrappedError (MINSTMSG_CIBadValueFor); return FALSE; }
            // -------------------------------------- Element 8 - ResourceUnits
            if (!(ResourcePtr = STRING_GetASCIIZNumericValue(&TempULONG, ResourcePtr, ResourceEndPtr)))
               return FALSE;
            CurGeninPtr->Drivers[DriverNo].ResourceUnits = (USHORT)TempULONG;
            // --------------------------------- Element 9 - ResourceClassCount
            if (!(ResourcePtr = STRING_GetASCIIZNumericValue(&TempULONG, ResourcePtr, ResourceEndPtr)))
               return FALSE;
            // No more than 9 classes...
            if ((TempULONG==0) || (TempULONG>=MCIMAX_CLASSES)) {
               MSG_SetInsertViaPSZ (2, "ResourceClassCount");
               MINSTALL_TrappedError (MINSTMSG_CIBadValueFor); return FALSE; }
            CurGeninPtr->Drivers[DriverNo].ResourceClassCount = (USHORT)TempULONG;
            // ----------------------------------- Element 10 - ResourceClasses
            for (CurNo=0; CurNo<CurGeninPtr->Drivers[DriverNo].ResourceClassCount; CurNo++) {
               if (!(ResourcePtr = STRING_GetASCIIZNumericValue(&TempULONG, ResourcePtr, ResourceEndPtr)))
                  return FALSE;
               CurGeninPtr->Drivers[DriverNo].ResourceClassArray[CurNo] = (USHORT)TempULONG;
             }
            // --------------------------- Element 11 - ResourceClassComboCount
            if (!(ResourcePtr = STRING_GetASCIIZNumericValue(&TempULONG, ResourcePtr, ResourceEndPtr)))
               return FALSE;
            if (TempULONG>MCIMAX_CLASSES*MCIMAX_CLASSES) {
               MSG_SetInsertViaPSZ (2, "ResourceClassComboCount");
               MINSTALL_TrappedError (MINSTMSG_CIBadValueFor); return FALSE; }
            CurGeninPtr->Drivers[DriverNo].ResourceClassComboCount = (USHORT)TempULONG;
            // --------------------------- Element 12 - ResourceClassComboArray
            for (CurNo=0; CurNo<CurGeninPtr->Drivers[DriverNo].ResourceClassComboCount; CurNo++) {
               if (!(ResourcePtr = STRING_GetASCIIZNumericValue(&TempULONG, ResourcePtr, ResourceEndPtr)))
                  return FALSE;
               if (!(ResourcePtr = STRING_GetASCIIZNumericValue(&TempULONG2, ResourcePtr, ResourceEndPtr)))
                  return FALSE;
               if ((TempULONG==0) || (TempULONG>=MCIMAX_CLASSES) || (TempULONG2==0) || (TempULONG2>=MCIMAX_CLASSES)) {
                  MSG_SetInsertViaPSZ (2, "ClassComboArray");
                  MINSTALL_TrappedError (MINSTMSG_CIBadValueFor); return FALSE; }
               CurGeninPtr->Drivers[DriverNo].ResourceClassComboArray[TempULONG][TempULONG2] = 1;
               CurGeninPtr->Drivers[DriverNo].ResourceClassComboArray[TempULONG2][TempULONG] = 1;
             }
            // ------------------------------------ Element 13 - ConnectorCount
            if (!(ResourcePtr = STRING_GetASCIIZNumericValue(&TempULONG, ResourcePtr, ResourceEndPtr)))
               return FALSE;
            if (TempULONG>MCIMAX_CONNECTORS) {
               MSG_SetInsertViaPSZ (2, "ConnectorCount");
               MINSTALL_TrappedError (MINSTMSG_CIBadValueFor); return FALSE; }
            CurGeninPtr->Drivers[DriverNo].ConnectorCount = (USHORT)TempULONG;
            // ------------------------------------ Element 14 - ConnectorArray
            CurGeninPtr->Drivers[DriverNo].ConnectorArrayPtr = ResourcePtr;
            for (CurNo=0; CurNo<CurGeninPtr->Drivers[DriverNo].ConnectorCount; CurNo++) {
               if (!(ResourcePtr = STRING_GetASCIIZNumericValue(&TempULONG, ResourcePtr, ResourceEndPtr)))
                  return FALSE;
               CurGeninPtr->Drivers[DriverNo].ConnectorType[CurNo] = (USHORT)TempULONG;
               CurGeninPtr->Drivers[DriverNo].ConnectorToInstallNamePtr[CurNo] = ResourcePtr;
               if (!(ResourceTmpPtr = STRING_SkipASCIIZ(ResourcePtr, ResourceEndPtr)))
                  return FALSE;
               TmpLen = (ULONG)ResourceTmpPtr-(ULONG)ResourcePtr-1;
               if (TmpLen>=MCIMAX_DEVICENAMELENGTH-2) {
                  MSG_SetInsertViaPSZ (2, "ConnectorName");
                  MINSTALL_TrappedError (MINSTMSG_CIBadValueFor); return FALSE; }
               if (!(ResourcePtr = STRING_GetASCIIZNumericValue(&TempULONG, ResourceTmpPtr, ResourceEndPtr)))
                  return FALSE;
               CurGeninPtr->Drivers[DriverNo].ConnectorToConnectIndex[CurNo] = (USHORT)TempULONG;
             }
            // ------------------------------------ Element 15 - ExtensionCount
            if (!(ResourcePtr = STRING_GetASCIIZNumericValue(&TempULONG, ResourcePtr, ResourceEndPtr)))
               return FALSE;
            if (TempULONG>MCIMAX_EXTENSIONS) {
               MSG_SetInsertViaPSZ (2, "ExtensionCount");
               MINSTALL_TrappedError (MINSTMSG_CIBadValueFor); return FALSE; }
            CurGeninPtr->Drivers[DriverNo].ExtensionCount = (USHORT)TempULONG;
            // ------------------------------------ Element 16 - ExtensionArray
            for (CurNo=0; CurNo<CurGeninPtr->Drivers[DriverNo].ExtensionCount; CurNo++) {
               if (!(ResourcePtr = STRING_GetASCIIZString(CurGeninPtr->Drivers[DriverNo].ExtensionArray[CurNo], MCIMAX_EXTENSIONNAMELENGTH, ResourcePtr, ResourceEndPtr))) {
                  MSG_SetInsertViaPSZ (2, "Extensions");
                  MINSTALL_TrappedError (MINSTMSG_CIBadValueFor); return FALSE; }
             }
            // ------------------------------------------- Element 17 - EATypes
            CurGeninPtr->Drivers[DriverNo].EATypesPtr = ResourcePtr;
            if (!(ResourcePtr = STRING_SkipASCIIZ(ResourcePtr, ResourceEndPtr)))
               return FALSE;
            TmpLen = strlen(CurGeninPtr->Drivers[DriverNo].EATypesPtr);
            if (TmpLen>=MCIMAX_TYPELISTLENGTH) {
               MSG_SetInsertViaPSZ (2, "EATypes");
               MINSTALL_TrappedError (MINSTMSG_CIBadValueFor); return FALSE; }
            // ----------------------------------------- Element 18 - AliasName
            CurGeninPtr->Drivers[DriverNo].AliasNamePtr = ResourcePtr;
            if (!(ResourcePtr = STRING_SkipASCIIZ(ResourcePtr, ResourceEndPtr)))
               return FALSE;
            TmpLen = strlen(CurGeninPtr->Drivers[DriverNo].AliasNamePtr);
            if (TmpLen>=MCIMAX_ALIASNAMELENGTH) {
               MSG_SetInsertViaPSZ (2, "AliasName");
               MINSTALL_TrappedError (MINSTMSG_CIBadValueFor); return FALSE; }
            // ----------------------------------------- Element 19 - DevParams
            CurGeninPtr->Drivers[DriverNo].DeviceParmsPtr = ResourcePtr;
            if (!(ResourcePtr = STRING_SkipASCIIZ(ResourcePtr, ResourceEndPtr)))
               return FALSE;
            TmpLen = strlen(CurGeninPtr->Drivers[DriverNo].DeviceParmsPtr);
            if (TmpLen>=MCIMAX_DEVPARAMSLENGTH) {
               MSG_SetInsertViaPSZ (2, "DeviceParams");
               MINSTALL_TrappedError (MINSTMSG_CIBadValueFor); return FALSE; }
          }

         // ============================= Now we get the User-Prompt data (xx9)
         if (!DLL_GetDataResource(FCF_CARDINFOHandle, DLLResourceID+9, (PVOID)&ResourcePtr, &ResourceSize))
            return FALSE;
         ResourceEndPtr = (PCHAR)(((ULONG)ResourcePtr)+ResourceSize);

         // ------------------------------------------ Element 1 - Prompt Count
         if (!(ResourcePtr = STRING_GetASCIIZNumericValue(&CurGeninPtr->PromptsCount, ResourcePtr, ResourceEndPtr)))
            return FALSE;

         // And get all the pointers...
         for (PromptNo=0; PromptNo<CurGeninPtr->PromptsCount; PromptNo++) {
            // --------------------------------------- Element 2 - Prompt Title
            CurGeninPtr->PromptTitlePtr[PromptNo]    = ResourcePtr;
            if (!(ResourcePtr = STRING_SkipASCIIZ(ResourcePtr, ResourceEndPtr)))
               return FALSE;
            // -------------------------------- Element 3 - Prompt Choice Count
            if (!(ResourcePtr = STRING_GetASCIIZNumericValue(&PromptChoiceNo, ResourcePtr, ResourceEndPtr)))
               return FALSE;
            CurGeninPtr->PromptChoiceCount[PromptNo] = PromptChoiceNo;
            if ((PromptChoiceNo==0) || (PromptChoiceNo>MINSTMAX_GENINPROMPTS)) {
               MINSTALL_TrappedError (MINSTMSG_IllegalPromptCount); return FALSE; }
            // Get the pointers to the prompts...
            // ------------------------------------- Element 4 - Prompt Choices
            CurGeninPtr->PromptChoiceStrings[PromptNo] = ResourcePtr;
            for (PromptChoiceNo=0; PromptChoiceNo<CurGeninPtr->PromptChoiceCount[PromptNo]; PromptChoiceNo++) {
               if (!(ResourcePtr = STRING_SkipASCIIZ(ResourcePtr, ResourceEndPtr)))
                  return FALSE;
             }

            // -------------------------------------- Element 5 - Prompt Values
            CurGeninPtr->PromptChoiceValues[PromptNo] = ResourcePtr;
            for (PromptChoiceNo=0; PromptChoiceNo<CurGeninPtr->PromptChoiceCount[PromptNo]; PromptChoiceNo++) {
               if (!(ResourcePtr = STRING_SkipASCIIZ(ResourcePtr, ResourceEndPtr)))
                  return FALSE;
             }

            // ------------------------------------- Element 6 - Default Prompt
            if (!(ResourcePtr = STRING_GetASCIIZNumericValue(&PromptDefault, ResourcePtr, ResourceEndPtr)))
               return FALSE;
            if ((PromptDefault==0) || (PromptDefault>MINSTMAX_GENINPROMPTS)) {
               MINSTALL_TrappedError (MINSTMSG_IllegalPromptCount); return FALSE; }
            PromptDefault--;
            CurGeninPtr->PromptChoiceDefault[PromptNo] = PromptDefault;
            ResourceTmpPtr  = CurGeninPtr->PromptChoiceValues[PromptNo];

            // Get the default selected value
            for (PromptChoiceNo=0; PromptChoiceNo<PromptDefault; PromptChoiceNo++) {
               ResourceTmpPtr = STRING_SkipASCIIZ(ResourceTmpPtr, ResourceEndPtr);
             }
            for (PromptChoiceNo=0; PromptChoiceNo<MINSTMAX_GENINCARDS; PromptChoiceNo++) {
               CurGeninPtr->PromptSelectedValue[PromptChoiceNo][PromptNo]   = ResourceTmpPtr;
               CurGeninPtr->PromptSelectedValueNo[PromptChoiceNo][PromptNo] = PromptDefault;
             }
          }
         DLLKnownGroups++;                  // Remember that we got one...
       }
      
      DLLGroupNo++;
    }
   if (DLLKnownGroups==0) {                 // Error, if no known group
      MINSTALL_TrappedError (MINSTMSG_NoKnownGroups);
      return FALSE;
    }
   return TRUE;
 }

// This routine generates CONFIG.SYS change information and also does the MCI
//  modifications required via GENIN/CARDINFO.
// NOTE: CONFIG.SYS gets changed at the end in one pass via cross-call to
//        MINSTALL_ProcessConfigControl().
BOOL MINSTALL_ProcessCARDINFOGroup (PMINSTGRP CurGroupPtr) {
   PMINSTGENI       GeninPtr         = CurGroupPtr->GeninPtr;
   PMINSTFILE       CustomDLLFilePtr = 0;
   HMODULE          CustomDLLHandle  = 0;
   PFN              CustomDLLFunc    = 0;
   ULONG            CardNo           = 0;
   ULONG            CardSeqNo        = 0;
   ULONG            DriverNo         = 0;
   ULONG            CurNo            = 0;
   PMINSTGENIDRV    CurDriverPtr     = 0;
   APIRET           rc               = 0;
   CHAR             MacroPATH[MINSTMAX_PATHLENGTH];
   CHAR             MacroORD[6];                // Maximum is USHORT (5 chars)
   ULONG            CurORDNo;
   CHAR             MacroSPEC[5][259];
   ULONG            CurSPECNo, CurVALNo;
   PSZ              CurValuePtr;
   CHAR             MacroPDD[MCIMAX_PDDNAMELENGTH];
   CHAR             DriverName[MCIMAX_DEVICENAMELENGTH];
   CHAR             ResourceName[MCIMAX_DEVICENAMELENGTH];
   CHAR             ConnectorToInstallNameArray[MCIMAX_CONNECTORS][MCIMAX_DEVICENAMELENGTH];
   CHAR             TempBuffer[MINSTMAX_PATHLENGTH];
   CHAR             IntelliAliasName[MCIMAX_DEVICENAMELENGTH];
   CHAR             CurAliasName[MCIMAX_DEVICENAMELENGTH];
   ULONG            CurAliasNameLength;
   PCHAR            CurPos, StartPos, EndPos, WritePos, WordPos;
   ULONG            WriteLeft, TmpLength, CRC32;
   PCONFIGSYSACTION ConfigSysActionArrayPtr;
   PCONFIGSYSACTION ConfigSysActionCurPtr;
   PCONFIGSYSACTSTR ConfigSysStringArrayPtr;
   PCONFIGSYSACTSTR ConfigSysStringCurPtr;
   ULONG            ConfigSysActionCount;
   BOOL             ChangedToMatchInLine;
   CHAR             CurDefaultDeviceName[MCIMAX_DEVICENAMELENGTH];

   // Macros for CONFIG.SYS entries:
   //================================
   // *PATH* - following filename will get looked up. If it's found, that path
   //           will get inserted. Otherwise MINSTALL_MMBase (fixed)
   // *ORD*  - MCI Ordinal for the 1st driver (multiple)
   // *SEQ*  - Sequential number of card, base is 1 (multiple)
   // *PDD*  - PDD-Name of the card, actually PDD-Name & Seq-No & '$' (single)
   // *VAL*  - User defined value from user prompts (multiple)
   // *SPEC* - From Custom-DLL (multiple)

   // Set strings to NUL...
   MacroPDD[0] = 0;

   if (GeninPtr->CustomDLLFilePtr) {
      CustomDLLFilePtr = (PMINSTFILE)GeninPtr->CustomDLLFilePtr;
      if (!STRING_CombinePSZ(TempBuffer, MINSTMAX_PATHLENGTH, CustomDLLFilePtr->SourcePtr->FQName, GeninPtr->CustomDLLFileName))
         return FALSE;
      MINSTLOG_ToFile ("Custom DLL is %s\n", TempBuffer);
      if ((CustomDLLHandle = DLL_Load(TempBuffer))!=0)
         CustomDLLFunc = DLL_GetEntryPoint (CustomDLLHandle, GeninPtr->CustomDLLEntry);
      if (!CustomDLLFunc) {
         DLL_UnLoad (CustomDLLHandle);
         MINSTALL_TrappedError (MINSTMSG_CICouldNotLoadCustomDLL); return FALSE; }
    }

   memset (&ConnectorToInstallNameArray, 0, sizeof(ConnectorToInstallNameArray));

   // Allocate space for CONFIG.SYS-Action
   ConfigSysActionCount = GeninPtr->ConfigSysLinesCount*(GeninPtr->SelectedCards+1);
   if (ConfigSysActionCount) {
      ConfigSysActionArrayPtr = malloc(ConfigSysActionCount*sizeof(CONFIGSYSACTION));
      if (!ConfigSysActionArrayPtr) {
         MINSTALL_TrappedError (MINSTMSG_OutOfMemory); return FALSE; }
      ConfigSysStringArrayPtr = malloc(ConfigSysActionCount*sizeof(CONFIGSYSACTSTR));
      if (!ConfigSysStringArrayPtr) {
         free (ConfigSysActionArrayPtr);
         MINSTALL_TrappedError (MINSTMSG_OutOfMemory); return FALSE; }

      memset (ConfigSysActionArrayPtr, 0, ConfigSysActionCount*sizeof(CONFIGSYSACTION));
      memset (ConfigSysStringArrayPtr, 0, ConfigSysActionCount*sizeof(CONFIGSYSACTSTR));
      ConfigSysActionCurPtr = ConfigSysActionArrayPtr;
      ConfigSysStringCurPtr = ConfigSysStringArrayPtr;
    }

   // First remove all existing drivers with the same name and generate removal
   //  instructions for the CONFIG.SYS lines...
   MINSTLOG_ToAll ("Removing existing MCI-drivers...\n");
   for (CardNo=0; CardNo<MINSTMAX_GENINCARDS; CardNo++) {
      CardSeqNo = CardNo+1;
      for (DriverNo=0; DriverNo<GeninPtr->DriverCount; DriverNo++) {
         CurDriverPtr = &GeninPtr->Drivers[DriverNo];
         sprintf (DriverName, "%s0%X", CurDriverPtr->InstallNamePtr, CardSeqNo);

         // Create MCI-Driver...
         MCIINI_DeleteDriver (DriverName);
       }
    }

   if (ConfigSysActionCount) {
      // Generate CONFIG.SYS-removal Actions...
      //  Fill out *PATH*, *PDD*. Leave out *ORD*, *SEQ*, *VAL*, *SPEC*
      //  *PDD* is filled out with just the PDD-Base-Name (w/o SeqNo nor '$')
      for (CurNo=0; CurNo<GeninPtr->ConfigSysLinesCount; CurNo++) {
         CurPos    = GeninPtr->ConfigSysLinesPtr[CurNo];
         EndPos    = (PCHAR)(((ULONG)CurPos)+strlen(CurPos));

         WritePos  = ConfigSysStringCurPtr->CommandStr;
         WriteLeft = CONFIGSYSACTSTR_MAXLENGTH-1;
         while (CurPos<EndPos) {
            if (*CurPos=='=') {
               CurPos++; break;
             }
            if (WriteLeft>0) {
               *WritePos = *CurPos; WritePos++; WriteLeft--; }
            CurPos++;
          }

         WritePos  = ConfigSysStringCurPtr->MatchStr;
         WriteLeft = CONFIGSYSACTSTR_MAXLENGTH-1;
         ChangedToMatchInLine = FALSE;
         while (CurPos<EndPos) {
            if (*CurPos=='*') {
               CurPos++;
               StartPos = CurPos;
               while ((CurPos<EndPos) && (*CurPos!='*'))
                  CurPos++;
               if (CurPos<EndPos) {
                  // We got a macro
                  CRC32 = CRC32_GetFromString(StartPos, CurPos-StartPos);
                  switch (CRC32) {
                   case 0x3DC166BB: // *PATH*
                     TmpLength = strlen(MINSTALL_MMBase);
                     if (TmpLength<WriteLeft) {
                        memcpy (WritePos, &MINSTALL_MMBase, TmpLength);
                        WritePos += TmpLength; WriteLeft -= TmpLength; }
                     break;
                   case 0x7659F82A: // *PDD*
                     TmpLength = strlen(GeninPtr->PDDNamePtr);
                     if (TmpLength<WriteLeft) {
                        memcpy (WritePos, GeninPtr->PDDNamePtr, TmpLength);
                        WritePos += TmpLength; WriteLeft -= TmpLength; }
                   }
                }
             } else if ((*CurPos==' ') && (!ChangedToMatchInLine)) {
               WritePos  = ConfigSysStringCurPtr->MatchInLineStr;
               WriteLeft = CONFIGSYSACTSTR_MAXLENGTH-1;
               ChangedToMatchInLine = TRUE;
             } else {
               if (WriteLeft>0) {
                  *WritePos = *CurPos; WritePos++; WriteLeft--; }
             }
            CurPos++;
          }

         ConfigSysActionCurPtr->Flags = CONFIGSYSACTION_Flags_RemoveAll;
         ConfigSysActionCurPtr->CommandStrPtr     = ConfigSysStringCurPtr->CommandStr;
         ConfigSysActionCurPtr->MatchStrPtr       = ConfigSysStringCurPtr->MatchStr;
         ConfigSysActionCurPtr->MatchInLineStrPtr = ConfigSysStringCurPtr->MatchInLineStr;
         ConfigSysActionCurPtr->ValueStrPtr       = ConfigSysStringCurPtr->ValueStr;

         MINSTLOG_ToFile ("CONFIG/Remove - '%s' - '%s'\n", ConfigSysStringCurPtr->MatchStr, ConfigSysStringCurPtr->MatchInLineStr);
         ConfigSysActionCurPtr++; ConfigSysStringCurPtr++;
       }
    }
   
   // Now generate a base alias-name for this device by analyzing the Product-
   //  Information string word by word. Maximum Card-Information: 13 chars
   //  ' xxxxy' is added to string to form the whole alias name
   //  where 'xxxx' is a 4-char name (Wave/Midi) and 'y' is a number
   // This new alias-name will only get used on WAVE or MIDI devices...
   MINSTLOG_ToFile ("Getting IntelliAliasname...\n");
   memset (IntelliAliasName, 0, sizeof(IntelliAliasName));
   CurPos   = GeninPtr->ProductNamePtr;
   EndPos   = (PCHAR)(((ULONG)CurPos)+strlen(CurPos));
   WritePos = IntelliAliasName; WriteLeft = 13;
   while ((CurPos = STRING_IsolateWord (&WordPos, &TmpLength, CurPos, EndPos))!=0) {
      // Got an isolated word
      if (TmpLength<WriteLeft) {           // We got enough bytes left
         memcpy (&TempBuffer, WordPos, TmpLength);
         TempBuffer[TmpLength] = 0;
         strupr (TempBuffer);               // we got upcased word here
         CRC32 = CRC32_GetFromPSZ(TempBuffer);
         switch (CRC32) {
          case 0xEF29F425: // 'AUDIO'
          case 0x7ABDF43D: // 'ADVANCED'
          case 0xEC91403D: // 'WAVE'
          case 0xAC649A86: // 'MIDI'
            break;
          default:
            memcpy (WritePos, WordPos, TmpLength); WritePos += TmpLength;
            *WritePos = 0x20; WritePos++;   // Add a space...
            WriteLeft -= TmpLength+1;
          }
       }
    }

   // Now generate entries per card, also call custom-DLL, if specified...
   if (!MINSTALL_ErrorMsgID) {
      for (CardNo=0; CardNo<GeninPtr->SelectedCards; CardNo++) {
         CardSeqNo = CardNo+1;

         MINSTLOG_ToAll ("Generating card...\n");
         if (ConfigSysActionCount)
            sprintf (MacroPDD, "%s%d$", GeninPtr->PDDNamePtr, CardSeqNo);

         // Call Custom-DLL, if specified to get *SPEC* macro...
         if (CustomDLLFunc) {
            MINSTLOG_ToAll ("Calling custom DLL-entry...\n");
            memset (&MacroSPEC, 0, sizeof(MacroSPEC));
            (CustomDLLFunc) ((USHORT)CardNo+1, &MacroSPEC);
          }
         // Now create all drivers for this card...
         for (DriverNo=0; DriverNo<GeninPtr->DriverCount; DriverNo++) {
            CurDriverPtr = &GeninPtr->Drivers[DriverNo];

            sprintf (DriverName, "%s0%X", CurDriverPtr->InstallNamePtr, CardSeqNo);
            sprintf (ResourceName, "%s0%X", CurDriverPtr->ResourceNamePtr, CardSeqNo);
            MINSTLOG_ToAll ("Creating MCI-Driver '%s'\n", DriverName);

            // Create MCI-Driver...
            if (MCIINI_CreateDriver (DriverName,
             CurDriverPtr->DeviceType, CurDriverPtr->DeviceFlag,
             GeninPtr->ProductVersionPtr, GeninPtr->ProductNamePtr,
             CurDriverPtr->MCDDriverNamePtr, CurDriverPtr->VSDDriverNamePtr,
             MacroPDD,               // <-- is the PDD-Name with 'x$' extension
             GeninPtr->MCDTableNamePtr, GeninPtr->VSDTableNamePtr,
             CurDriverPtr->ShareType,
             ResourceName,
             CurDriverPtr->ResourceUnits, CurDriverPtr->ResourceClassCount,
             (PUSHORT)CurDriverPtr->ResourceClassArray,
             (PUSHORT)CurDriverPtr->ResourceClassComboArray)) {
             MINSTLOG_ToFile ("Error during MCI Create\n"); break; }

            if (DriverNo==0) {
               // Gets total devices of first driver type, which is
               //  automatically the ordinal of the driver. Don't ask me, this
               //  gets messed up in config.sys pretty easy, but this is how
               //  IBM designed it.
               CurORDNo = MCIINI_GetTotalDevices (CurDriverPtr->DeviceType);
               itoa (CurORDNo, MacroORD, 10);
             }

            // Now create MCI-Driver Connectors...
            for (CurNo=0; CurNo<CurDriverPtr->ConnectorCount; CurNo++) {
               if (*CurDriverPtr->ConnectorToInstallNamePtr[CurNo]!=0)
                  sprintf (ConnectorToInstallNameArray[CurNo], "%s0%X", CurDriverPtr->ConnectorToInstallNamePtr[CurNo], CardSeqNo);
                 else
                  ConnectorToInstallNameArray[CurNo][0] = 0;
             }

            if (MCIINI_SetConnectors (DriverName,
             CurDriverPtr->ConnectorCount,
             CurDriverPtr->ConnectorType, (PCHAR)&ConnectorToInstallNameArray,
             CurDriverPtr->ConnectorToConnectIndex)) {
             MINSTLOG_ToFile ("Error during MCI Set Connectors\n"); break; }

            if (*CurDriverPtr->DeviceParmsPtr!=0) {
               // Device-parameters defined, so set them...
               if (MCIINI_SetDeviceParameters (DriverName, CurDriverPtr->DeviceParmsPtr)) {
                  MINSTLOG_ToFile ("Error during MCI Set DevParms\n"); break; }
             }

            // Create MCI-Driver Extension Association...
            if (CurDriverPtr->ExtensionCount>0) {
               rc = MCIINI_SetFileExtensions (DriverName,
                CurDriverPtr->ExtensionCount,
                (PCHAR)CurDriverPtr->ExtensionArray);
               if (rc==MCIERR_DUPLICATE_EXTENSION) {
                  MINSTLOG_ToFile ("Duplicate File-Extension (not critical)\n");
                } else {
                  MINSTLOG_ToFile ("Error during MCI Set File-Extensions (not critical) - %d\n", rc);
                }
             }

            if (*CurDriverPtr->EATypesPtr!=0) {
               // Extended Attributes were defined, so set them...
               rc = MCIINI_SetEATypes (DriverName, CurDriverPtr->EATypesPtr);
               if (rc==MCIERR_DUPLICATE_EA) {
                  MINSTLOG_ToFile ("Duplicate EA-Types (not critical)\n");
                } else {
                  MINSTLOG_ToFile ("Error during MCI Set EA-Types (not critical) - %d\n", rc);
                }
             }

            // Finally set alias-name...
            memset (CurAliasName, 0, sizeof(CurAliasName));
            switch (CurDriverPtr->DeviceType) {
             case MCI_DEVTYPE_WAVEFORM_AUDIO:
               STRING_CombinePSZ (CurAliasName, MCIMAX_DEVICENAMELENGTH, IntelliAliasName, "Wave");
               break;
             case MCI_DEVTYPE_SEQUENCER:
               STRING_CombinePSZ (CurAliasName, MCIMAX_DEVICENAMELENGTH, IntelliAliasName, "Midi");
               break;
             case MCI_DEVTYPE_CD_AUDIO:
               strcpy (CurAliasName, "CD-Audio");
               break;
             default:
               strcpy (CurAliasName, CurDriverPtr->AliasNamePtr);
             }
            CurAliasNameLength = strlen(CurAliasName);
            if (CurAliasNameLength) {
               CurNo = 1;
               while (CurNo<36) {
                  rc = MCIINI_SetAliasName (DriverName, CurAliasName);
                  if (rc==MCIERR_SUCCESS) break; // <-- success? -> exit
                  if (rc!=MCIERR_DUPLICATE_ALIAS) {
                     MINSTLOG_ToFile ("Error during MCI Set Aliasname (not critical) - %d\n", rc);
                     break;
                   }
                  // We got duplicate Alias, so try again...
                  CurNo++;
                  if (CurNo<10)
                     CurAliasName[CurAliasNameLength] = CurNo+0x30;
                    else
                     CurAliasName[CurAliasNameLength] = CurNo+55;
                }
               MINSTLOG_ToFile ("Alias-Name that got set was '%s'\n", CurAliasName);
             }
          }

         if (ConfigSysActionCount) {
            // Generate CONFIG.SYS modifications...
            CurSPECNo = CurVALNo = 0;
            for (CurNo=0; CurNo<GeninPtr->ConfigSysLinesCount; CurNo++) {
               CurPos    = GeninPtr->ConfigSysLinesPtr[CurNo];
               EndPos    = (PCHAR)(((ULONG)CurPos)+strlen(CurPos));

               WritePos  = ConfigSysStringCurPtr->CommandStr;
               WriteLeft = CONFIGSYSACTSTR_MAXLENGTH-1;
               while (CurPos<EndPos) {
                  if (*CurPos=='=') {
                     CurPos++; break;
                   }
                  if (WriteLeft>0) {
                     *WritePos = *CurPos; WritePos++; WriteLeft--; }
                  CurPos++;
                }
   
               WritePos  = ConfigSysStringCurPtr->ValueStr;
               WriteLeft = CONFIGSYSACTSTR_MAXLENGTH-1;
               while (CurPos<EndPos) {
                  if (*CurPos=='*') {
                     CurPos++;
                     StartPos = CurPos;
                     while ((CurPos<EndPos) && (*CurPos!='*'))
                        CurPos++;
                     if (CurPos<EndPos) {
                        // We got a macro
                        CRC32 = CRC32_GetFromString(StartPos, CurPos-StartPos);
                        switch (CRC32) {
                         case 0x3DC166BB: // *PATH*
                           TmpLength = strlen(MINSTALL_MMBase);
                           if (TmpLength<WriteLeft) {
                              memcpy (WritePos, &MINSTALL_MMBase, TmpLength);
                              WritePos += TmpLength; WriteLeft -= TmpLength; }
                           break;
                         case 0x7659F82A: // *PDD*
                           TmpLength = strlen(GeninPtr->PDDNamePtr);
                           if (TmpLength+2<WriteLeft) {
                              memcpy (WritePos, GeninPtr->PDDNamePtr, TmpLength);
                              WritePos += TmpLength; WriteLeft -= TmpLength;
                              *WritePos = CardSeqNo+0x30; WritePos++;
                              *WritePos = '$'; WritePos++; }
                           break;
                         case 0x00D993D9: // *SEQ*
                           if (WriteLeft>0) {
                              *WritePos = CardSeqNo+0x30; WritePos++; }
                           break;
                         case 0x7DBBA9B0: // *ORD*
                           TmpLength = strlen(MacroORD);
                           if (TmpLength<WriteLeft) {
                              memcpy (WritePos, &MacroORD, TmpLength);
                              WritePos += TmpLength; WriteLeft -= TmpLength; }
                           break;
                         case 0xF69BFA8A: // *SPEC*
                           TmpLength = strlen(MacroSPEC[CurSPECNo]);
                           if (TmpLength<WriteLeft) {
                              memcpy (WritePos, &MacroSPEC[CurSPECNo], TmpLength);
                              WritePos += TmpLength; WriteLeft -= TmpLength; }
                           CurSPECNo++;           // Go to next SPEC-Macro...
                           if (CurSPECNo==5) CurSPECNo=0; // Handle overflow
                           break;
                         case 0x0178F8EF: // *VAL*
                           CurValuePtr = GeninPtr->PromptSelectedValue[CardNo][CurVALNo];
                           TmpLength = strlen(CurValuePtr);
                           if (TmpLength<WriteLeft) {
                              memcpy (WritePos, CurValuePtr, TmpLength);
                              WritePos += TmpLength; WriteLeft -= TmpLength; }
                           CurVALNo++;            // Go to next VAL-Macro...
                           if (CurVALNo==GeninPtr->PromptsCount) CurVALNo=0;
                           break;
                         }
                      }
                   } else {
                     if (WriteLeft>0) {
                        *WritePos = *CurPos; WritePos++; WriteLeft--; }
                   }
                  CurPos++;
                }
   
               ConfigSysActionCurPtr->Flags = 0;
               ConfigSysActionCurPtr->CommandStrPtr     = ConfigSysStringCurPtr->CommandStr;
               ConfigSysActionCurPtr->MatchStrPtr       = ConfigSysStringCurPtr->MatchStr;
               ConfigSysActionCurPtr->MatchInLineStrPtr = ConfigSysStringCurPtr->MatchInLineStr;
               ConfigSysActionCurPtr->ValueStrPtr       = ConfigSysStringCurPtr->ValueStr;
   
               // Copy ValueStr to MatchStr, so there will be no match...
               strcpy (ConfigSysStringCurPtr->MatchStr, ConfigSysStringCurPtr->ValueStr);
   
               MINSTLOG_ToFile ("CONFIG/Add - '%s'\n", ConfigSysStringCurPtr->ValueStr);
               ConfigSysActionCurPtr++; ConfigSysStringCurPtr++;
             }
          }
       }
    }
   if (CustomDLLHandle) DLL_UnLoad (CustomDLLHandle);

   MINSTLOG_ToFile ("Total CONFIG.SYS Actions: %d\n", ConfigSysActionCount);
   if (ConfigSysActionCount) {
      MINSTALL_ProcessConfigControl (ConfigSysActionCount, ConfigSysActionArrayPtr);
      free (ConfigSysStringArrayPtr);
      free (ConfigSysActionArrayPtr);
    }
   if (MINSTALL_ErrorMsgID) return FALSE;
   return TRUE;
 }

// Parses CustomData-block and fills out GENIN Selections
//  Supports both the old and new format
//  Old: "Yamaha OPL3-SA Series Audio.=NUM=1,V1=7,V1=01,V1=530,V1=388,V1=0,V1=0,V1=390,V1=220,V1=1,201,V1=1,201,"
//  New: "CARDCOUNT=1;VALUES[1]=9,1,3"
BOOL MINSTALL_UseCARDINFOCustomData (PMINSTGRP GroupPtr) {
   ULONG      CardNo        = 0;
   ULONG      CardCount     = 0;
   ULONG      CardProcessed = 0;
   ULONG      PromptNo      = 0;
   ULONG      ValueNo       = 0;
   ULONG      ValueCount    = 0;
   PSZ        ValuePtr      = 0;
   PCHAR      StartPos      = GroupPtr->CustomData;
   PCHAR      CurPos        = StartPos;
   PCHAR      EndPos        = STRING_SkipASCIIZ (StartPos, NULL)-1;
   ULONG      CRC32;
   ULONG      BitCurCard    = 0;
   ULONG      BitAllCards   = 0;
   ULONG      BitGotCards   = 0;
   PMINSTGENI GeninPtr      = GroupPtr->GeninPtr;
   ULONG      BytesLeft     = 0;

   while (*CurPos!='=') {
      if (CurPos>=EndPos) {                 // Unexpected end-of-data
         MINSTALL_TrappedError (MINSTMSG_CARDINFOAutoCfgBadFormat); return FALSE; }
      *CurPos = toupper(*CurPos);
      CurPos++;
    }
   CRC32 = CRC32_GetFromString (StartPos, CurPos-StartPos);
   CurPos++;
   if (CurPos>=EndPos) {                    // Unexpected end-of-data
      MINSTALL_TrappedError (MINSTMSG_CARDINFOAutoCfgBadFormat); return FALSE; }

   if (CRC32==0x700D2834) {                 // First entry == 'CARDCOUNT'
      // =========================================================== New Format
      CurPos = STRING_GetNumericValue(&CardCount, CurPos, EndPos);
      if (CurPos==NULL) {
         MINSTALL_TrappedError (MINSTMSG_CARDINFOAutoCfgBadFormat); return FALSE; }
      if (CardCount>GeninPtr->MaxCardCount) {
         MINSTALL_TrappedError (MINSTMSG_CARDINFOAutoCfgBadCardNo); return FALSE; }
      GeninPtr->SelectedCards = CardCount;

      // If CardCount is 1 or bigger get values for selections
      BitAllCards = (1<<CardCount)-1; BitGotCards = 0;
      for (CardProcessed=1; CardProcessed<=CardCount; CardProcessed++) {
         if (*CurPos!=';') {
            MINSTALL_TrappedError (MINSTMSG_CARDINFOAutoCfgBadFormat); return FALSE; }
         CurPos++;

         StartPos = CurPos;
         while (*CurPos!='[') {
            if (CurPos>=EndPos) {                 // Unexpected end-of-data
               MINSTALL_TrappedError (MINSTMSG_CARDINFOAutoCfgBadFormat); return FALSE; }
            *CurPos = toupper(*CurPos);
            CurPos++;
          }
         CRC32 = CRC32_GetFromString (StartPos, CurPos-StartPos);
         CurPos++;
         if (CRC32!=0xCA5F8B60) {           // It's 'VALUES'?
            MINSTALL_TrappedError (MINSTMSG_CARDINFOAutoCfgBadFormat); return FALSE; }

         // Extract Array-Number
         CurPos = STRING_GetNumericValue(&CardNo, CurPos, EndPos);
         if ((CurPos==NULL) || (*CurPos!=']')) {
            MINSTALL_TrappedError (MINSTMSG_CARDINFOAutoCfgBadFormat); return FALSE; }
         CurPos++;
         if (*CurPos!='=') {
            MINSTALL_TrappedError (MINSTMSG_CARDINFOAutoCfgBadFormat); return FALSE; }
         CurPos++;
         if ((CardNo==0) || (CardNo>CardCount)) { // In Range?
            MINSTALL_TrappedError (MINSTMSG_CARDINFOAutoCfgMismatch); return FALSE; }
         CardNo--;
         BitCurCard = (1<<CardNo);
         if (BitGotCards & BitCurCard) {
            MINSTALL_TrappedError (MINSTMSG_CARDINFOAutoCfgMismatch); return FALSE; }
         BitGotCards |= BitCurCard;

         // Now extract all values and set them for the specified card...
         for (PromptNo=0; PromptNo<GeninPtr->PromptsCount; PromptNo++) {
            if (PromptNo>0) {
               if (*CurPos!=',') {
                  MINSTALL_TrappedError (MINSTMSG_CARDINFOAutoCfgMismatch); return FALSE; }
               CurPos++;
             }
            if (CurPos>=EndPos) {                 // Unexpected end-of-data
               MINSTALL_TrappedError (MINSTMSG_CARDINFOAutoCfgBadFormat); return FALSE; }
            CurPos = STRING_GetNumericValue(&ValueNo, CurPos, EndPos);
            if (CurPos==NULL) {
               MINSTALL_TrappedError (MINSTMSG_CARDINFOAutoCfgBadFormat); return FALSE; }
            // Check, if given PromptNo seems to be correct
            if ((ValueNo==0) || (ValueNo>GeninPtr->PromptChoiceCount[PromptNo])) {
               MINSTALL_TrappedError (MINSTMSG_CARDINFOAutoCfgMismatch); return FALSE; }
            ValueNo--;
            GeninPtr->PromptSelectedValueNo[CardNo][PromptNo] = ValueNo;
            ValuePtr = GeninPtr->PromptChoiceValues[PromptNo];
            while (ValueNo) {
               ValuePtr = STRING_SkipASCIIZ(ValuePtr, NULL);
               ValueNo--;
             }
            GeninPtr->PromptSelectedValue[CardNo][PromptNo]   = ValuePtr;
          }

         if ((*CurPos!=0) && (*CurPos!=';')) {
            MINSTALL_TrappedError (MINSTMSG_CARDINFOAutoCfgMismatch); return FALSE; }
       }
    } else {
      // =========================================================== Old Format
      // We assume that it starts with NUM=x and is then followed by values
      //  using ',Vx=', where x is the card number. All values have to be in
      //  order (card 1 -> card 2 -> card 3 etc.)
      //  Also ',' is not enough to detect the end of a string, but ',V' (and
      //   even that isn't good, but that's bad design by IBM :(
      //   We also check, if there is a such-called value, find out ValueNo and
      //   set everything correctly (not directly using the specified value)

      // First search for "NUM=" string (case-sensitive)...
      while (1) {
         if (CurPos>=EndPos) {              // Unexpected end-of-data
            MINSTALL_TrappedError (MINSTMSG_CARDINFOAutoCfgBadFormat); return FALSE; }
         BytesLeft = EndPos-CurPos;
         if (BytesLeft<4) {
            MINSTALL_TrappedError (MINSTMSG_CARDINFOAutoCfgBadFormat); return FALSE; }
         if (strncmp(CurPos, "NUM=", 4)==0)
            break;                          // If found -> go out of loop
         CurPos++;
       }
      CurPos += 4;

      CurPos = STRING_GetNumericValue(&CardCount, CurPos, EndPos);
      if (CurPos==NULL) {
         MINSTALL_TrappedError (MINSTMSG_CARDINFOAutoCfgBadFormat); return FALSE; }
      if (CardCount>GeninPtr->MaxCardCount) {
         MINSTALL_TrappedError (MINSTMSG_CARDINFOAutoCfgBadCardNo); return FALSE; }
      GeninPtr->SelectedCards = CardCount;

      if ((GeninPtr->PromptsCount) && (CardCount)) {
         // If any prompts required & CardCount not 0, assume ',V' next
         if (*CurPos!=',') {
            MINSTALL_TrappedError (MINSTMSG_CARDINFOAutoCfgBadFormat); return FALSE; }
         CurPos++;
         if (*CurPos!='V') {
            MINSTALL_TrappedError (MINSTMSG_CARDINFOAutoCfgBadFormat); return FALSE; }
         CurPos++;

         for (CardNo=0; CardNo<CardCount; CardNo++) {
            for (PromptNo=0; PromptNo<GeninPtr->PromptsCount; PromptNo++) {
               if (CurPos>=EndPos) {
                  MINSTALL_TrappedError (MINSTMSG_CARDINFOAutoCfgMismatch); return FALSE; }
               // Check, if Card-Number matches
               CurPos = STRING_GetNumericValue(&CardProcessed, CurPos, EndPos);
               if (CurPos==NULL) {
                  MINSTALL_TrappedError (MINSTMSG_CARDINFOAutoCfgBadFormat); return FALSE; }
               if ((CardNo+1)!=CardProcessed) { // Card-Number has to match
                  MINSTALL_TrappedError (MINSTMSG_CARDINFOAutoCfgMismatch); return FALSE; }
               // '=' has to follow...
               if (*CurPos!='=') {
                  MINSTALL_TrappedError (MINSTMSG_CARDINFOAutoCfgBadFormat); return FALSE; }
               CurPos++;

               // Now search for next ',V' in CustomData
               StartPos = CurPos;
               while (CurPos<EndPos) {
                  if (*(PUSHORT)CurPos=='V,')
                     break;                 // If found -> go out of loop
                  CurPos++;
                }
               // If we are at End-Of-Data and LastChar==',', forget ','
               BytesLeft = CurPos-StartPos;
               if ((CurPos==EndPos) && (*(PCHAR)(((ULONG)CurPos)-1)==','))
                  BytesLeft--;

               // So now search for the value...
               ValueNo    = 0;
               ValueCount = GeninPtr->PromptChoiceCount[PromptNo];
               ValuePtr   = GeninPtr->PromptChoiceValues[PromptNo];
               while (1) {
                  if (ValueNo>=ValueCount) {
                     MINSTALL_TrappedError (MINSTMSG_CARDINFOAutoCfgMismatch); return FALSE; }
                  if (strlen(ValuePtr)==BytesLeft) {
                     // Length of Value matches
                     if (strncmp(ValuePtr, StartPos, BytesLeft)==0)
                        break;
                   }
                  ValueNo++;
                  ValuePtr = STRING_SkipASCIIZ(ValuePtr, NULL);
                }
               // We found it, so select this value...
               GeninPtr->PromptSelectedValueNo[CardNo][PromptNo] = ValueNo;
               GeninPtr->PromptSelectedValue[CardNo][PromptNo]   = ValuePtr;

               // Adjust CurPos, if not end-of-data
               if ((CurPos+1)<EndPos)
                  CurPos += 2;
             }
          }
       }
    }
   return TRUE;
 }

VOID MINSTALL_FillCARDINFOCustomData (PMINSTGRP GroupPtr) {
   CHAR       TempData[MINSTMAX_CUSTOMDATALENGTH];
   ULONG      WriteLeft = MINSTMAX_CUSTOMDATALENGTH;
   PCHAR      CurPos    = 0;
   ULONG      CardNo    = 0;
   ULONG      PromptNo  = 0;
   PMINSTGENI GeninPtr = GroupPtr->GeninPtr;

   // Generate Custom-Data for CID processing...
   sprintf (TempData, "CARDCOUNT=%d", GeninPtr->SelectedCards);
   WriteLeft = MINSTMAX_CUSTOMDATALENGTH;
   CurPos = STRING_BuildEscaped (GroupPtr->CustomData, &WriteLeft, TempData);

   CardNo = 0;
   while ((CardNo<GeninPtr->SelectedCards) && (CurPos)) {
      sprintf (TempData, ";VALUES[%d]=", CardNo+1);
      CurPos   = STRING_BuildEscaped (CurPos, &WriteLeft, TempData);

      PromptNo = 0;
      while ((PromptNo<GeninPtr->PromptsCount) && (CurPos)) {
         if (PromptNo==0) {
            sprintf (TempData, "%d", GeninPtr->PromptSelectedValueNo[CardNo][PromptNo]+1);
          } else {
            sprintf (TempData, ",%d", GeninPtr->PromptSelectedValueNo[CardNo][PromptNo]+1);
          }
         CurPos = STRING_BuildEscaped (CurPos, &WriteLeft, TempData);
         PromptNo++;
       }
      CardNo++;
    }
 }

BOOL MINSTALL_ProcessCARDINFO (void) {
   BOOL       CurNo       = 0;
   PMINSTGRP  CurGroupPtr = MCF_GroupArrayPtr;

   while (CurNo<MCF_GroupCount) {
      if ((CurGroupPtr->Flags & MINSTGRP_Flags_Selected) && (CurGroupPtr->GeninPtr)) {
         MINSTLOG_ToFile ("ProcessCARDINFOGroup()...\n");
         if (!MINSTALL_ProcessCARDINFOGroup (CurGroupPtr))
            return FALSE;
         MINSTLOG_ToFile ("ProcessCARDINFOGroup() DONE\n");
       }
      CurGroupPtr++; CurNo++;
    }
   return TRUE;
 }

VOID MINSTALL_CleanUpCARDINFO (void) {
   BOOL       CurNo       = 0;
   PMINSTGRP  CurGroupPtr = MCF_GroupArrayPtr;

   // Release GENIN-memory-blocks...
   while (CurNo<MCF_GroupCount) {
      if (CurGroupPtr->GeninPtr) {
         free (CurGroupPtr->GeninPtr);      // Release memory...
         CurGroupPtr->GeninPtr = 0; }
      CurGroupPtr++; CurNo++;
    }

   // Unload CARDINFO.DLL, if got loaded...
   if (FCF_CARDINFOHandle) {
      DLL_UnLoad (FCF_CARDINFOHandle);
      FCF_CARDINFOHandle = 0; }

   // Remove this action from cleanup...
   MINSTALL_Done &= !MINSTDONE_LOADCARDINFO;
 }
