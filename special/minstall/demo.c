   LONG  CONFIGSYSrc = 0;

   CONFIGSYSrc = CONFIGSYS_Process (0, ChangeCount, (PCONFIGSYSACTION)ChangeArrayPtr, "\nREM *** MMOS/2 ***\n");
   switch (CONFIGSYSrc) {
    case CONFIGSYS_DONE:
      MINSTLOG_ToFile ("Internal: CONFIG.SYS processed, did not get modified\n");
      return TRUE;
    case CONFIGSYS_DONE_BackUp:
      MINSTLOG_ToFile ("Internal: CONFIG.SYS updated, old one backupped\n");
      return TRUE;
    case CONFIGSYS_DONE_Changed:
      MINSTLOG_ToFile ("Internal: CONFIG.SYS updated, w/o backup\n");
      return TRUE;
    case CONFIGSYS_ERR_IsReadOnly:
      MINSTALL_TrappedError (MINSTMSG_CONFIGSYSReadOnly); return FALSE;
    case CONFIGSYS_ERR_FailedBackUp:
      MINSTALL_TrappedError (MINSTMSG_CONFIGSYSFailedBackUp); return FALSE;
    default:
      MINSTALL_TrappedError (MINSTMSG_CONFIGSYSGenericProblem); return FALSE;
    }

            rc = FILE_Replace (TempSourceFile, TempDestinFile);
            if (rc==ERROR_SHARING_VIOLATION) {
               CfgSysRC = CONFIGSYS_DelayCopyFile (TempSourceFile, TempDestinFile);
               MINSTLOG_ToFile ("Delaying RC %d\n", CfgSysRC);
               if (CfgSysRC!=CONFIGSYS_DONE) {
                  MSG_SetInsertViaPSZ (1, TempDestinFile);
                  MINSTALL_TrappedError (MINSTMSG_CouldNotCopyToFile);
                  return FALSE;                // Problem during Copying
                }
               AnythingDelayed = TRUE;
             }

BOOL MINSTALL_LoadConfigControlFile (PMINSTFILE ScriptFilePtr) {
   ULONG            ConfigEntryCount     = 0;
   PCHAR            CurPos               = 0;
   PCHAR            EndPos               = 0;
   PCHAR            LineStartPos         = 0;
   PCHAR            LineEndPos           = 0;
   CHAR             CurChar              = 0;
   ULONG            Temp                 = 0;
   PCHAR            CommandSpacePtr      = 0;
   PCONFIGSYSACTION ConfigEntryArrayPtr  = 0;
   PCONFIGSYSACTION CurConfigEntry       = 0;
   PCONFIGSYSACTSTR ConfigStringArrayPtr = 0;
   PCONFIGSYSACTSTR CurConfigString      = 0;
   PMINSTDIR        CurDirPtr            = 0;
   ULONG            CommandID1           = 0;
   ULONG            CommandID2           = 0;
   PCHAR            ValueSpacePtr        = 0;
   PCHAR            TempPtr              = 0;
   ULONG            ActionID             = 0;
   ULONG            CurLineNo            = 1;

   // Get Full-Qualified Script Name
   if (!STRING_CombinePSZ (CHANGESCR.Name, MINSTMAX_PATHLENGTH, ScriptFilePtr->SourcePtr->FQName, ScriptFilePtr->Name))
      return FALSE;
   if (!FILE_LoadFileControl(&CHANGESCR, 131767)) {
      MSG_SetInsertViaPSZ (1, CHANGESCR.Name);
      MINSTALL_TrappedError (MINSTMSG_CouldNotLoad);
      return FALSE;
    }
   FILE_PreProcessControlFile(&CHANGESCR);
   ConfigEntryCount = FILE_CountControlFileLines (&CHANGESCR);
   if (ConfigEntryCount==0) {
      FILE_UnLoadFileControl(&CHANGESCR);
      return TRUE;                          // No entries, so success
    }

   // Now allocate memory for those entries...
   ConfigEntryArrayPtr = malloc(ConfigEntryCount*CONFIGSYSACTION_Length);
   if (!ConfigEntryArrayPtr) {
      FILE_UnLoadFileControl(&CHANGESCR);
      MINSTALL_TrappedError (MINSTMSG_OutOfMemory); return FALSE; // OutOfMemory
    }
   ConfigStringArrayPtr = malloc(ConfigEntryCount*CONFIGSYSACTSTR_Length);
   if (!ConfigStringArrayPtr) {
      free (ConfigEntryArrayPtr);
      FILE_UnLoadFileControl(&CHANGESCR);
      MINSTALL_TrappedError (MINSTMSG_OutOfMemory); return FALSE; // OutOfMemory
    }

   // NUL out both arrays...
   memset (ConfigEntryArrayPtr, 0, ConfigEntryCount*sizeof(CONFIGSYSACTION));
   memset (ConfigStringArrayPtr, 0, ConfigEntryCount*sizeof(CONFIGSYSACTSTR));

   // Now extract all entries one-by-one. Known are:
   //  "MERGE"   - only used on SET lines,
   //               may include a numeric digit, which specifies the directory
   //  "REPLACE" - will replace a line, if it already got found. Otherwise
   //               the line will get added
   //               05062004 - If a path is specified, Action is 'REPLACE' and
   //                           the command is 'SET', add ';' to the end.
   //                          It's done by original minstall and needed for
   //                          compatibility.
   //  "DEVICE"  - will add that line

   ConfigEntryCount = 0;
   CurPos = CHANGESCR.BufferPtr; EndPos = CHANGESCR.BufferEndPtr;
   CurConfigEntry = ConfigEntryArrayPtr;
   CurConfigString = ConfigStringArrayPtr;
   while (CurPos<EndPos) {
      if (!(CurChar = STRING_GetValidChar(&CurPos, EndPos, &CurLineNo)))
         break;
      LineStartPos = CurPos;
      LineEndPos   = STRING_GetEndOfLinePtr (CurPos, EndPos);

      while ((CurPos<LineEndPos) && (*CurPos!=0x20) && (*CurPos!=0x3D)) {
         *CurPos = toupper(*CurPos);     // Uppercase...
         CurPos++;                       // Search for space or '='
       }
      ActionID = CRC32_GetFromString (LineStartPos, CurPos-LineStartPos);

      if ((CurChar = STRING_GetValidChar(&CurPos, EndPos, &CurLineNo))!='=') {
         // Read in Command/Specifier into TempBuffer...
         CurPos = STRING_GetString(CurConfigString->CommandStr, CONFIGSYSACTSTR_MAXLENGTH, CurPos, LineEndPos);
         CommandSpacePtr = (PCHAR)CurConfigString->CommandStr;
         while (*CommandSpacePtr!=0x20) {  // Find 1st space in HelpBuffer
            if (*CommandSpacePtr==0x00) {
               CommandSpacePtr = 0; break;
             }
            CommandSpacePtr++;
          }
         CurChar = STRING_GetValidChar(&CurPos, EndPos, &CurLineNo);
       } else {
         CommandSpacePtr = 0;
       }
      CurPos++;

      if (CurPos>=LineEndPos) {
         MINSTALL_ErrorMsgID = MINSTMSG_UnexpectedEndOfLine; break; }

      if (CurChar!='=') {
         MINSTALL_ErrorMsgID = MINSTMSG_ValueExpected; break; }

      if (ActionID==0xF9D77108) {
         /* We have to check this earlier, because we put command 'DEVICE' */
         /*  and that one is needed because we get CommandID1/2 now instead of */
         /*  later. */
         if (CurConfigString->CommandStr[0]!=0) MINSTALL_TrappedError (MINSTMSG_NoConfigCommandExpected);
         strcpy (CurConfigString->CommandStr, "DEVICE");
       }

      if (CommandSpacePtr) {
         // We got a space in the Command, so we take 2 CommandIDs
         CommandID1 = CRC32_GetFromString(CurConfigString->CommandStr,CommandSpacePtr-CurConfigString->CommandStr);
         CommandID2 = CRC32_GetFromPSZ(CommandSpacePtr+1);
       } else {
         CommandID1 = CRC32_GetFromPSZ(CurConfigString->CommandStr);
         CommandID2 = 0;
       }

      CurChar = STRING_GetValidChar(&CurPos, EndPos, &CurLineNo);
      if (CurChar=='"') {
         // String-Delimiter, so we assume string and extract (w macros)
         if (!(CurPos = MINSTALL_GetMacrodString((PCHAR)CurConfigString->ValueStr, MINSTMAX_PATHLENGTH, CurPos, LineEndPos)))
            break;                 // Error during macro processing
       } else {
         if (!(CurPos = STRING_GetNumericValue(&Temp, CurPos, LineEndPos)))
            break;                 // Error during value extract
         CurDirPtr = MINSTALL_SearchDestinDirID (Temp);
         if (CurDirPtr) {
            strcpy (CurConfigString->ValueStr, CurDirPtr->FQName);
            Temp = strlen(CurConfigString->ValueStr);
            if (Temp>0) Temp--;
            if ((ActionID==0x33D8DA5F) && (CommandID1==0x70B36756)) {
               // If Action is 'REPLACE' and Command is 'SET'
               //  Add a ';' here for compatibility reasons (05062004)
               CurConfigString->ValueStr[Temp] = ';';
             } else {
               // cut last char (which is a '\')
               CurConfigString->ValueStr[Temp] = 0;
             }
          } else {
            MINSTALL_ErrorMsgID = MINSTMSG_UnknownDestinID; break;
          }
       }

      switch (ActionID) {
       case 0x33D8DA5F: // REPLACE, expects HelpBuffer
         if (CurConfigString->CommandStr[0]==0) MINSTALL_TrappedError (MINSTMSG_ConfigCommandExpected);
         break;
       case 0x1C3D55E9: // MERGE, expects HelpBuffer
         if (CurConfigString->CommandStr[0]==0) MINSTALL_TrappedError (MINSTMSG_ConfigCommandExpected);
         CurConfigEntry->Flags |= CONFIGSYSACTION_Flags_Merge;
         break;
       case 0xF9D77108: // DEVICE, expects NO HelpBuffer
         /* CommandStr should now be 'DEVICE' and is checked earlier for Error */
/*         if (CurConfigString->CommandStr[0]!=0) MINSTALL_TrappedError (MINSTMSG_NoConfigCommandExpected); */
/*         strcpy (CurConfigString->CommandStr, "DEVICE"); */
         CurConfigEntry->Flags |= CONFIGSYSACTION_Flags_MatchOnFilename;
         break;
       default:
         // We got something unknown...
         MINSTALL_ErrorMsgID = MINSTMSG_BadCommand; break;
       }

      switch (CommandID1) {
       case 0xC6D1E64A: // RUN
       case 0xF9D77108: // DEVICE
       case 0x2110156E: // BASEDEV
         break;
       case 0x70B36756: // SET
         if (CommandID2==0x8262959) // LIBPATH -> strip "SET"
            strcpy (CurConfigString->CommandStr, CommandSpacePtr+1);
         break;
       default:
         MINSTALL_ErrorMsgID = MINSTMSG_BadConfigCommand; break;
       }
      if (MINSTALL_ErrorMsgID) break;

      // If no error found, add this entry...
      ValueSpacePtr = CurConfigString->ValueStr;
      while (*ValueSpacePtr!=0) {
         if (*ValueSpacePtr==0x20) // If space found
            break;
         ValueSpacePtr++;
       }
      switch (CommandID1) {
       case 0xC6D1E64A: // RUN
       case 0xF9D77108: // DEVICE
       case 0x2110156E: // BASEDEV
         if (ActionID==0xF9D77108) { // DEVICE
            // Match only on filename...
            TempPtr = ValueSpacePtr;
            while (TempPtr>CurConfigString->ValueStr) {
               if (*TempPtr==0x5C) {
                  TempPtr++;
                  break;
                }
               TempPtr--;          // Search backwards for '\'
             }
            strncpy (CurConfigString->MatchStr, TempPtr, ValueSpacePtr-TempPtr);
          } else {
            // full qualified filename is match string...
            strncpy (CurConfigString->MatchStr, CurConfigString->ValueStr, ValueSpacePtr-CurConfigString->ValueStr);
          }
       }
      MINSTLOG_ToFile ("Command \"%s\", Match-Onto \"%s\" (Flags %X)\n", CurConfigString->CommandStr, CurConfigString->MatchStr, CurConfigEntry->Flags);
      MINSTLOG_ToFile (" Add/Merge in \"%s\"\n", CurConfigString->ValueStr);
      CurConfigString->MatchInLineStr[0] = 0;
      CurConfigEntry->CommandStrPtr     = CurConfigString->CommandStr;
      CurConfigEntry->MatchStrPtr       = CurConfigString->MatchStr;
      CurConfigEntry->MatchInLineStrPtr = CurConfigString->MatchInLineStr;
      CurConfigEntry->ValueStrPtr       = CurConfigString->ValueStr;
      ConfigEntryCount++; CurConfigEntry++; CurConfigString++;

      CurPos = LineEndPos+1; CurLineNo++;
    }

   // Put that Array&Count into ConfigChange-Queue...
   ScriptFilePtr->GroupPtr->ConfigChangeArray = ConfigEntryArrayPtr;
   ScriptFilePtr->GroupPtr->ConfigStringArray = ConfigStringArrayPtr;
   ScriptFilePtr->GroupPtr->ConfigChangeCount = ConfigEntryCount;
   
   // Remove that file from memory...
   FILE_UnLoadFileControl(&CHANGESCR);

   // We didn't find anything?
   if (ConfigEntryCount==0)
      MINSTALL_ErrorMsgID = MINSTMSG_UnexpectedEndOfFile;

   if (MINSTALL_ErrorMsgID) {               // If Error-found during parsing...
      MSG_SetInsertFileLocation (1, CHANGESCR.Name, CurLineNo);
      MINSTALL_TrappedError (MINSTALL_ErrorMsgID);
      return FALSE;
    }
   return TRUE;
 }
