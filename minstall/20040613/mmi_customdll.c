
// щ Д ДДДДНН = Д  щ  Д = ННДДДД Д щ
// і                               і
//    ЬЫЫЫЫЫЫЫЬ   ЬЫЬ  ЬЫЫЫЫЫЫЫЫЬ          ъ  ъДДДНДДНДННДДННННДНННННННННОД
// і ЫЫЫЫЯЯЯЫЫЫЫ ЫЫЫЫЫ ЫЫЫЯ   ЯЫЫЫ і             MINSTALL Front-End      є
// є ЫЫЫЫЬЬЬЫЫЫЫ ЫЫЫЫЫ ЫЫЫЬ   ЬЫЫЫ є      ъ ДДДДНДННДДННННДННННННННДНННННОД
// є ЫЫЫЫЫЫЫЫЫЫЫ ЫЫЫЫЫ ЫЫЫЫЫЫЫЫЫЯ  є       Section: MMOS/2 for eCS       є
// є ЫЫЫЫ   ЫЫЫЫ ЫЫЫЫЫ ЫЫЫЫ ЯЫЫЫЫЬ є     і Created: 28/10/02             є
// і ЯЫЫЯ   ЯЫЫЯ  ЯЫЯ  ЯЫЫЯ   ЯЫЫЯ і     і Last Modified:                і
//                  ЬЬЬ                  і Number Of Modifications: 000  і
// щ              ЬЫЫЯ             щ     і INCs required: *none*         і
//      ДДДДДДД ЬЫЫЯ                     є Written By: Martin Kiewitz    і
// і     ЪїЪїіЬЫЫЫЬЬЫЫЫЬ           і     є (c) Copyright by              і
// є     АЩіАЩЯЫЫЫЯЯЬЫЫЯ           є     є      AiR ON-Line Software '02 ъ
// є    ДДДДДДД    ЬЫЫЭ            є     є All rights reserved.
// є              ЬЫЫЫДДДДДДДДД    є    ДОНННДНННННДННННДННДДНДДНДДДъДД  ъ
// є             ЬЫЫЫЭі іЪїііД     є
// і            ЬЫЫЫЫ АДііАЩіД     і
//             ЯЫЫЫЫЭДДДДДДДДДД     
// і             ЯЯ                і
// щ Дґ-=’iз йп-Liпо SйџвW’зо=-ГДД щ


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
#include <mmi_customdll.h>


PSZ FakedConfigSysFile[] = {
   "IFS=C:\\OS2\\HPFS.IFS",
   "LIBPATH=C:\\OS2\\DLL",
   "SET PATH=C:\\OS2",
   "SET DPATH=C:\\OS2",
   "BASEDEV=IBMKBD.SYS",
   "DEVICE=C:\\OS2\\FAKED.SYS" };
#define FakedConfigSysFileMaxNo 5

PMINSTINIHEADER CustomAPI_INIChange1stEntryPtr  = 0;
PMINSTINIHEADER CustomAPI_INIChangeLastEntryPtr = 0;

// ****************************************************************************

PMINSTINIHEADER MINSTALL_CustomAPIAllocINIChange (ULONG EntryID, ULONG EntrySize) {
   PMINSTINIHEADER CurEntryPtr = malloc(EntrySize);

   if (CurEntryPtr) {
      // It worked, so set public variable or update last entry
      if (CustomAPI_INIChangeLastEntryPtr) {
         CustomAPI_INIChangeLastEntryPtr->NextPtr = CurEntryPtr;
       } else {
         CustomAPI_INIChange1stEntryPtr = CurEntryPtr;
       }
      memset (CurEntryPtr, 0, EntrySize);
      CurEntryPtr->ID   = EntryID;
      CurEntryPtr->Size = EntrySize;
      CustomAPI_INIChangeLastEntryPtr = CurEntryPtr;
    }
   return CurEntryPtr;
 }

// This procedure needs MINSTALL_LinkInImports()!
MRESULT EXPENTRY MINSTALL_CustomAPIProcedure (HWND WindowHandle, ULONG MsgID, MPARAM mp1, MPARAM mp2) {
   MRESULT                   WResult;
   ULONG                     APIResult         = 0;
   PMINSTOLD_CONFIGDATA      ConfigData;
   ULONG                     TmpLen;
   CHAR                      TempBuffer[MAXFILELENGTH];
   ULONG                     CRC32;
   PMINSTFILE                CurFilePtr        = 0;
   PMINSTOLD_MCI_SENDCOMMAND CurSendCommand    = 0;
   PMINSTINIHEADER           INIChangeEntryPtr = 0;

   switch (MsgID) {
    case MINSTOLD_LOG_ERROR_MSGID:
      MINSTLOG_ToFile ("Log: %s\n", (PSZ)mp1);
      break;
    case MINSTOLD_QUERYPATH_MSGID:
      if (!STRING_CombinePSZ (TempBuffer, MAXFILELENGTH, (PSZ)mp1, ""))
         break;
      strlwr (TempBuffer);                  // Filename needs to be low-cased
      FILE_SetDefaultExtension (TempBuffer, MAXFILELENGTH, ".dll");
      CRC32 = CRC32_GetFromPSZ(TempBuffer);
      CurFilePtr = MINSTALL_SearchFileCRC32(CRC32);
      MINSTLOG_ToFile ("Querying path for %s...", TempBuffer);
      if (CurFilePtr) {
         STRING_CombinePSZ((PSZ)mp2, CCHMAXPATH, CurFilePtr->SourcePtr->FQName, TempBuffer);
         MINSTLOG_ToFile ("found\n");
       } else {
         memset ((PSZ)mp2, 0, CCHMAXPATH);
         MINSTLOG_ToFile ("not found\n");
       }
      break;
    case MINSTOLD_MCI_SYSINFO_MSGID:
      // Cheap wrapper to MCI - Extended SYSINFO
      // mp1 got FunctionID, mp2 got SysInfoParm
      MINSTLOG_ToFile ("Doing MCI-SYSINFO...\n");
      APIResult = MCIINI_SendSysInfoExtCommand ((ULONG)mp1, (PVOID)mp2);
      break;
    case MINSTOLD_MCI_SENDCOMMAND_MSGID:
      // Wrapper to send an MCI command
      // mp2 got MciSendCommand
      MINSTLOG_ToFile ("Doing MCI-SendCommand...\n");
      CurSendCommand = (PMINSTOLD_MCI_SENDCOMMAND)mp2;
      MINSTLOG_ToFile ("wDeviceID = %d\n", CurSendCommand->wDeviceID);
      MINSTLOG_ToFile ("wMessage  = %d\n", CurSendCommand->wMessage);
/*      MINSTLOG_ToFile ("Dump = %d\n", *(PULONG)(((ULONG)CurSendCommand->dwParam2)+8)); */
      APIResult = (*MCIINI_MciSendCommandFunc) (CurSendCommand->wDeviceID, CurSendCommand->wMessage,
                                  CurSendCommand->dwParam1, CurSendCommand->dwParam2,
                                  CurSendCommand->wUserParm);
      break;
    case MINSTOLD_CONFIG_ENUMERATE_MSGID:
    case MINSTOLD_CONFIG_UPDATE_MSGID:
    case MINSTOLD_CONFIG_MERGE_MSGID:
    case MINSTOLD_CONFIG_REPLACE_MSGID:
    case MINSTOLD_CONFIG_NEW_MSGID:
    case MINSTOLD_CONFIG_DELETE_MSGID:
    case MINSTOLD_CONFIG_QUERYCHANGED_MSGID:
      ConfigData = (PMINSTOLD_CONFIGDATA)mp1;
      switch (ConfigData->lLine) {
       case MINSTOLD_CONFIG_TOP:    CustomAPI_ConfigSysLine = 0; break;
       case MINSTOLD_CONFIG_BOTTOM: CustomAPI_ConfigSysLine = FakedConfigSysFileMaxNo; break;
       case MINSTOLD_CONFIG_NEXT:
         CustomAPI_ConfigSysLine++;
         if (CustomAPI_ConfigSysLine>=FakedConfigSysFileMaxNo) {
            CustomAPI_ConfigSysLine = FakedConfigSysFileMaxNo;
            APIResult = MINSTOLD_RETATBOTTOM;
          }
         break;
       case MINSTOLD_CONFIG_PREV:
         CustomAPI_ConfigSysLine--;
         if (CustomAPI_ConfigSysLine>=FakedConfigSysFileMaxNo) {
            CustomAPI_ConfigSysLine = 0;
            APIResult = MINSTOLD_RETATTOP;
          }
         break;
       case MINSTOLD_CONFIG_CURRENT:
         break;
       default:
         CustomAPI_ConfigSysLine = ConfigData->lLine;
       }
      if (CustomAPI_ConfigSysLine>FakedConfigSysFileMaxNo) {
         APIResult = MINSTOLD_RETLINENOTFOUND;
       } else {
         switch (MsgID) {
          case MINSTOLD_CONFIG_ENUMERATE_MSGID:
            // Get that specific line and copy it into destination buffer
            TmpLen = strlen(FakedConfigSysFile[CustomAPI_ConfigSysLine]);
            if (TmpLen<ConfigData->lBufferLen) {
               strcpy (ConfigData->pszBuffer, FakedConfigSysFile[CustomAPI_ConfigSysLine]);
             } else {
               if (!APIResult) APIResult = MINSTOLD_RETBUFFEROVERFLOW;
             }
            break;
          case MINSTOLD_CONFIG_UPDATE_MSGID:
            MINSTLOG_ToFile ("Update: %s\n", ConfigData->pszBuffer);
            break;
          case MINSTOLD_CONFIG_MERGE_MSGID:
            MINSTLOG_ToFile ("Merge: %s\n", ConfigData->pszBuffer);
            break;
          case MINSTOLD_CONFIG_NEW_MSGID:
            MINSTLOG_ToFile ("Add new line: %s\n", ConfigData->pszBuffer);
            break;
          case MINSTOLD_CONFIG_QUERYCHANGED_MSGID:
            APIResult = TRUE;               // We reply TRUE at any time
            break;
          // Unsupported functions...
          case MINSTOLD_CONFIG_REPLACE_MSGID:
            MINSTLOG_ToFile ("Tried to replace CONFIG.SYS, not supported!\n");
            break;
          case MINSTOLD_CONFIG_DELETE_MSGID:
            MINSTLOG_ToFile ("Tried to delete line, not supported!\n");
            break;
          }
       }
      break;
    case MINSTOLD_EA_JOIN_MSGID:
      // Joins EAs from a file onto a file/path
      MINSTLOG_ToFile ("Delaying EA_JOINEA...\n");
      if ((INIChangeEntryPtr = MINSTALL_CustomAPIAllocINIChange(EA_JOINEA_ID, sizeof(EA_JOINEA)))!=0) {
         strcpy (((PEA_JOINEA)INIChangeEntryPtr)->JoinFileName, ((PMINSTOLD_EA_JOIN)mp2)->achFileName);
         strcpy (((PEA_JOINEA)INIChangeEntryPtr)->JoinEAFileName, ((PMINSTOLD_EA_JOIN)mp2)->achEAFileName);
       }
      break;
    case MINSTOLD_EA_LONGNAMEJOIN_MSGID:
      // Joins EAs from a file onto a file/path, also sets long-name
      MINSTLOG_ToFile ("Delaying EA_LONGNAMEJOIN...\n");
      if ((INIChangeEntryPtr = MINSTALL_CustomAPIAllocINIChange(EA_JOINLONGNAMEEA_ID, sizeof(EA_JOINLONGNAMEEA)))!=0) {
         strcpy (((PEA_JOINLONGNAMEEA)INIChangeEntryPtr)->JoinLongName, ((PMINSTOLD_EA_LONGNAMEJOIN)mp2)->achLongName);
         strcpy (((PEA_JOINLONGNAMEEA)INIChangeEntryPtr)->JoinLongFileName, ((PMINSTOLD_EA_LONGNAMEJOIN)mp2)->achLongFileName);
         strcpy (((PEA_JOINLONGNAMEEA)INIChangeEntryPtr)->JoinEALongFileName, ((PMINSTOLD_EA_LONGNAMEJOIN)mp2)->achEALongFileName);
       }
      break;
    case MINSTOLD_MMIO_INSTALL_MSGID:
      // Installs an IO-Proc (using obscure MINSTALL format)
      MINSTLOG_ToFile ("Delaying MMIO_INSTALL...\n");
      if ((INIChangeEntryPtr = MINSTALL_CustomAPIAllocINIChange(MMIO_MMIOINSTALL_ID, sizeof(MMIO_MMIOINSTALL)))!=0) {
         ((PMMIO_MMIOINSTALL)INIChangeEntryPtr)->fccIOProc    = (ULONG)((PMINSTOLD_MMIO_INSTALL)mp2)->fccIOProc;
         strcpy (((PMMIO_MMIOINSTALL)INIChangeEntryPtr)->szDLLName, ((PMINSTOLD_MMIO_INSTALL)mp2)->szDLLName);
         strcpy (((PMMIO_MMIOINSTALL)INIChangeEntryPtr)->szProcName, ((PMINSTOLD_MMIO_INSTALL)mp2)->szProcName);
         ((PMMIO_MMIOINSTALL)INIChangeEntryPtr)->dwFlags      = ((PMINSTOLD_MMIO_INSTALL)mp2)->ulFlags;
         ((PMMIO_MMIOINSTALL)INIChangeEntryPtr)->dwExtendLen  = ((PMINSTOLD_MMIO_INSTALL)mp2)->ulExtendLen;
         ((PMMIO_MMIOINSTALL)INIChangeEntryPtr)->dwMediaType  = ((PMINSTOLD_MMIO_INSTALL)mp2)->ulMediaType;
         ((PMMIO_MMIOINSTALL)INIChangeEntryPtr)->dwIOProcType = ((PMINSTOLD_MMIO_INSTALL)mp2)->ulIOProcType;
         strcpy (((PMMIO_MMIOINSTALL)INIChangeEntryPtr)->szDefExt, ((PMINSTOLD_MMIO_INSTALL)mp2)->szDefExt);
       }
      break;
    case MINSTOLD_MMIO_CODEC1INSTALL_MSGID:
    case MINSTOLD_MMIO_CODEC2INSTALL_MSGID:
      // Installs an IO-Codec (using ulCodecCompType or fccCodecCompType)
      MINSTLOG_ToFile ("Delaying MMIO_CODECxINSTALL...\n");
      // We get an MMIOCODEC1INSTALL-Block, in fact it doesnt matter because
      //  process routine handles both the same way (due same buffer format)
      if ((INIChangeEntryPtr = MINSTALL_CustomAPIAllocINIChange(MMIO_MMIOCODEC1INSTALL_ID, sizeof(MMIO_MMIOCODEC)))!=0) {
         ((PMMIO_MMIOCODEC)INIChangeEntryPtr)->ulStructLen        = ((PMINSTOLD_MMIO_CODEC)mp2)->ulStructLen;
         ((PMMIO_MMIOCODEC)INIChangeEntryPtr)->fcc                = (ULONG)((PMINSTOLD_MMIO_CODEC)mp2)->fcc;
         strcpy (((PMMIO_MMIOCODEC)INIChangeEntryPtr)->szDLLName, ((PMINSTOLD_MMIO_CODEC)mp2)->szDLLName);
         strcpy (((PMMIO_MMIOCODEC)INIChangeEntryPtr)->szProcName, ((PMINSTOLD_MMIO_CODEC)mp2)->szProcName);
         if (MsgID==MINSTOLD_MMIO_CODEC1INSTALL_MSGID) {
            ((PMMIO_MMIOCODEC)INIChangeEntryPtr)->ulCompressType  = ((PMINSTOLD_MMIO_CODEC)mp2)->x.ulCodecCompType;
          } else {
            ((PMMIO_MMIOCODEC)INIChangeEntryPtr)->ulCompressType  = (ULONG)((PMINSTOLD_MMIO_CODEC)mp2)->x.fccCodecCompType;
          }
         ((PMMIO_MMIOCODEC)INIChangeEntryPtr)->ulCompressSubType  = ((PMINSTOLD_MMIO_CODEC)mp2)->ulCompressSubType;
         ((PMMIO_MMIOCODEC)INIChangeEntryPtr)->ulMediaType        = ((PMINSTOLD_MMIO_CODEC)mp2)->ulMediaType;
         ((PMMIO_MMIOCODEC)INIChangeEntryPtr)->ulCapsFlags        = ((PMINSTOLD_MMIO_CODEC)mp2)->ulCapsFlags;
         ((PMMIO_MMIOCODEC)INIChangeEntryPtr)->ulFlags            = ((PMINSTOLD_MMIO_CODEC)mp2)->ulFlags;
         strcpy (((PMMIO_MMIOCODEC)INIChangeEntryPtr)->szHWID, ((PMINSTOLD_MMIO_CODEC)mp2)->szHWID);
         ((PMMIO_MMIOCODEC)INIChangeEntryPtr)->ulMaxSrcBufLen     = ((PMINSTOLD_MMIO_CODEC)mp2)->ulMaxSrcBufLen;
         ((PMMIO_MMIOCODEC)INIChangeEntryPtr)->ulSyncMethod       = ((PMINSTOLD_MMIO_CODEC)mp2)->ulSyncMethod;
         ((PMMIO_MMIOCODEC)INIChangeEntryPtr)->fccPreferredFormat = ((PMINSTOLD_MMIO_CODEC)mp2)->fccPreferredFormat;
         ((PMMIO_MMIOCODEC)INIChangeEntryPtr)->ulXalignment       = ((PMINSTOLD_MMIO_CODEC)mp2)->ulXalignment;
         ((PMMIO_MMIOCODEC)INIChangeEntryPtr)->ulYalignment       = ((PMINSTOLD_MMIO_CODEC)mp2)->ulYalignment;
         strcpy (((PMMIO_MMIOCODEC)INIChangeEntryPtr)->szSpecInfo, ((PMINSTOLD_MMIO_CODEC)mp2)->szSpecInfo);
       }
      break;
    case MINSTOLD_MMIO_CODECDELETE_MSGID:
      // Deletes an IO-Codec
      MINSTLOG_ToFile ("Delaying MMIO_CODECDELETE...\n");
      if ((INIChangeEntryPtr = MINSTALL_CustomAPIAllocINIChange(MMIO_MMIOCODECDELETE_ID, sizeof(MMIO_MMIOCODEC)))!=0) {
         ((PMMIO_MMIOCODEC)INIChangeEntryPtr)->ulStructLen        = ((PMINSTOLD_MMIO_CODEC)mp2)->ulStructLen;
         ((PMMIO_MMIOCODEC)INIChangeEntryPtr)->fcc                = (ULONG)((PMINSTOLD_MMIO_CODEC)mp2)->fcc;
         strcpy (((PMMIO_MMIOCODEC)INIChangeEntryPtr)->szDLLName, ((PMINSTOLD_MMIO_CODEC)mp2)->szDLLName);
         strcpy (((PMMIO_MMIOCODEC)INIChangeEntryPtr)->szProcName, ((PMINSTOLD_MMIO_CODEC)mp2)->szProcName);
         ((PMMIO_MMIOCODEC)INIChangeEntryPtr)->ulCompressType  = ((PMINSTOLD_MMIO_CODEC)mp2)->x.ulCodecCompType;
         ((PMMIO_MMIOCODEC)INIChangeEntryPtr)->ulCompressSubType  = ((PMINSTOLD_MMIO_CODEC)mp2)->ulCompressSubType;
         ((PMMIO_MMIOCODEC)INIChangeEntryPtr)->ulMediaType        = ((PMINSTOLD_MMIO_CODEC)mp2)->ulMediaType;
         ((PMMIO_MMIOCODEC)INIChangeEntryPtr)->ulCapsFlags        = ((PMINSTOLD_MMIO_CODEC)mp2)->ulCapsFlags;
         ((PMMIO_MMIOCODEC)INIChangeEntryPtr)->ulFlags            = ((PMINSTOLD_MMIO_CODEC)mp2)->ulFlags;
         strcpy (((PMMIO_MMIOCODEC)INIChangeEntryPtr)->szHWID, ((PMINSTOLD_MMIO_CODEC)mp2)->szHWID);
         ((PMMIO_MMIOCODEC)INIChangeEntryPtr)->ulMaxSrcBufLen     = ((PMINSTOLD_MMIO_CODEC)mp2)->ulMaxSrcBufLen;
         ((PMMIO_MMIOCODEC)INIChangeEntryPtr)->ulSyncMethod       = ((PMINSTOLD_MMIO_CODEC)mp2)->ulSyncMethod;
         ((PMMIO_MMIOCODEC)INIChangeEntryPtr)->fccPreferredFormat = ((PMINSTOLD_MMIO_CODEC)mp2)->fccPreferredFormat;
         ((PMMIO_MMIOCODEC)INIChangeEntryPtr)->ulXalignment       = ((PMINSTOLD_MMIO_CODEC)mp2)->ulXalignment;
         ((PMMIO_MMIOCODEC)INIChangeEntryPtr)->ulYalignment       = ((PMINSTOLD_MMIO_CODEC)mp2)->ulYalignment;
         strcpy (((PMMIO_MMIOCODEC)INIChangeEntryPtr)->szSpecInfo, ((PMINSTOLD_MMIO_CODEC)mp2)->szSpecInfo);
       }
      break;
    case MINSTOLD_PRF_STRINGDATA_MSGID:
      // Adds a profile string to an INI file
      MINSTLOG_ToFile ("Delaying PRF_STRINGDATA...\n");
      if ((INIChangeEntryPtr = MINSTALL_CustomAPIAllocINIChange(PRF_PROFILESTRING_ID, sizeof(PRF_PROFILESTRING)))!=0) {
         strcpy (((PPRF_PROFILESTRING)INIChangeEntryPtr)->Inis, ((PMINSTOLD_PRF_STRINGDATA)mp2)->achInisName);
         strcpy (((PPRF_PROFILESTRING)INIChangeEntryPtr)->AppNames, ((PMINSTOLD_PRF_STRINGDATA)mp2)->achAppsName);
         strcpy (((PPRF_PROFILESTRING)INIChangeEntryPtr)->KeyNames, ((PMINSTOLD_PRF_STRINGDATA)mp2)->achKeysName);
         strcpy (((PPRF_PROFILESTRING)INIChangeEntryPtr)->Datas, ((PMINSTOLD_PRF_STRINGDATA)mp2)->achDatasName);
       }
      break;
    case MINSTOLD_PRF_APPENDDATA_MSGID:
      // Appends a string onto an INI file
      MINSTLOG_ToFile ("Delaying PRF_APPENDDATA (UNSUPPORTED!)...\n");
      break;
    case MINSTOLD_SPI_INSTALL_MSGID:
      // Just an SpiInstall (primitive forward)
      MINSTLOG_ToFile ("Delaying SPI_INSTALL...\n");
      if ((INIChangeEntryPtr = MINSTALL_CustomAPIAllocINIChange(SPI_SPIINSTALL_ID, sizeof(SPI_SPIINSTALL)))!=0) {
         strcpy (((PSPI_SPIINSTALL)INIChangeEntryPtr)->SpiDllName, (PSZ)mp2);
       }
      break;
    case MINSTOLD_WPS_CREATEOBJECT_MSGID:
      // Generates a WPS-object
      MINSTLOG_ToFile ("Delaying WPS_CREATEOBJECT...\n");
      if ((INIChangeEntryPtr = MINSTALL_CustomAPIAllocINIChange(WPS_CREATEOBJECT_ID, sizeof(WPS_CREATEOBJECT)))!=0) {
         strcpy (((PWPS_CREATEOBJECT)INIChangeEntryPtr)->WPClassName, ((PMINSTOLD_WPS_CREATEOBJECT)mp2)->achClassName);
         strcpy (((PWPS_CREATEOBJECT)INIChangeEntryPtr)->WPTitle, ((PMINSTOLD_WPS_CREATEOBJECT)mp2)->achTitle);
         strcpy (((PWPS_CREATEOBJECT)INIChangeEntryPtr)->WPSetupString, ((PMINSTOLD_WPS_CREATEOBJECT)mp2)->achSetupString);
         strcpy (((PWPS_CREATEOBJECT)INIChangeEntryPtr)->WPLocation, ((PMINSTOLD_WPS_CREATEOBJECT)mp2)->achLocation);
         ((PWPS_CREATEOBJECT)INIChangeEntryPtr)->WPFlags = ((PMINSTOLD_WPS_CREATEOBJECT)mp2)->ulFlags;
       }
      break;
    case MINSTOLD_WPS_DESTROYOBJECT_MSGID:
      // Removes a WPS-object
      MINSTLOG_ToFile ("Delaying WPS_DESTROYOBJECT...\n");
      if ((INIChangeEntryPtr = MINSTALL_CustomAPIAllocINIChange(WPS_DESTROYOBJECT_ID, sizeof(WPS_DESTROYOBJECT)))!=0) {
         strcpy (((PWPS_DESTROYOBJECT)INIChangeEntryPtr)->WPDestroyObjectID, (PSZ)mp2);
       }
      break;
    case MINSTOLD_WPS_WPCLASS_MSGID:
      // Registers a WPS-class and is able to replace another class with it
      MINSTLOG_ToFile ("Delaying WPS_WPCLASS...\n");
      if ((INIChangeEntryPtr = MINSTALL_CustomAPIAllocINIChange(WPS_WPCLASS_ID, sizeof(WPS_WPCLASS)))!=0) {
         strcpy (((PWPS_WPCLASS)INIChangeEntryPtr)->WPClassNameNew, ((PMINSTOLD_WPS_WPCLASS)mp2)->achClassNewName);
         strcpy (((PWPS_WPCLASS)INIChangeEntryPtr)->WPDllName, ((PMINSTOLD_WPS_WPCLASS)mp2)->achDllName);
         strcpy (((PWPS_WPCLASS)INIChangeEntryPtr)->WPReplaceClass, ((PMINSTOLD_WPS_WPCLASS)mp2)->achReplaceClass);
       }
      break;
    case MINSTOLD_MIDIMAP_INSTALL_MSGID:
      // Installs a MIDIMAP
      MINSTLOG_ToFile ("Delaying MIDIMAP_INSTALL (UNSUPPORTED!)...\n");
      break;
    default:
      MINSTLOG_ToFile ("Unsupported MsgID: MsgID %d\n", MsgID);
      WResult = WinDefWindowProc(WindowHandle, MsgID, mp1, mp2);
      return WResult;
    }
   WResult = (PVOID)APIResult;
   return WResult;
 }

VOID MINSTALL_CustomAPIThread (PVOID pvoid) {
   QMSG  qmsg;
   ERRORID ErrorID;

   do {
      // We need our own PM and message queue handle in here...
      if (!(CustomAPI_PMHandle = WinInitialize(0)))
         break;

      if (!(CustomAPI_MSGQHandle = WinCreateMsgQueue(CustomAPI_PMHandle, 0)))
         break;

      if (!WinRegisterClass(CustomAPI_PMHandle, "OBJECTWINDOW", (PFNWP)MINSTALL_CustomAPIProcedure, 0, 0))
         break;

      if (!(CustomAPI_WindowHandle = WinCreateWindow(HWND_OBJECT, "OBJECTWINDOW",
          NULL, 0, 0, 0, 0, 0, NULLHANDLE, HWND_TOP, 1, NULL, NULL)))
         break;

      CustomAPI_ThreadCreated = TRUE;
      DosPostEventSem (CustomAPI_InitEventHandle);
                                                    /* Message loop */
      while(WinGetMsg(CustomAPI_MSGQHandle, &qmsg, NULLHANDLE, 0UL, 0UL))
         WinDispatchMsg (CustomAPI_MSGQHandle, &qmsg);
   } while (0);

   if (WinIsWindow(CustomAPI_PMHandle, CustomAPI_WindowHandle))
      WinDestroyWindow (CustomAPI_WindowHandle);
   CustomAPI_WindowHandle = 0;

   if (CustomAPI_MSGQHandle)   WinDestroyMsgQueue (CustomAPI_MSGQHandle);
   if (CustomAPI_WindowHandle) WinTerminate (CustomAPI_WindowHandle);

   if (!CustomAPI_ThreadCreated)
      DosPostEventSem (CustomAPI_InitEventHandle);
   return;
 }

BOOL MINSTALL_CreateCustomAPIThread (void) {
   APIRET rc;

   CustomAPI_ThreadCreated = FALSE;
   if (!(DosCreateEventSem(NULL, &CustomAPI_InitEventHandle, DC_SEM_SHARED, FALSE))) {
      if ((CustomAPI_ThreadID = _beginthread ((THREADFUNC)&MINSTALL_CustomAPIThread, NULL, 8192, NULL))!=-1) {
         DosWaitEventSem (CustomAPI_InitEventHandle, -1);
       }
      DosCloseEventSem (CustomAPI_InitEventHandle);
    }
   return CustomAPI_ThreadCreated;
 }

VOID MINSTALL_RemoveCustomAPIThread (void) {
   if (!WinPostMsg(CustomAPI_WindowHandle, WM_QUIT, NULL, NULL)) {
      DosWaitThread (&CustomAPI_ThreadID, DCWW_WAIT);
    }
 }

BOOL MINSTALL_ExecuteCustomDLLs (void) {
   PMINSTGRP            CurGroupPtr = MCF_GroupArrayPtr;
   PMINSTFILE           CurFilePtr  = 0;
   USHORT               CurNo       = 0;
   USHORT               CurChangeNo = 0;
   CHAR                 DLLFileName[MINSTMAX_PATHLENGTH];
   HMODULE              DLLHandle   = 0;
   PCUSTOMDLL_ENTRYFUNC CustomDLLEntryPoint = 0;
   BOOL                 GotDLL = FALSE;

   while (CurNo<MCF_GroupCount) {
      if (CurGroupPtr->Flags & MINSTGRP_Flags_Selected) {
         if (CurGroupPtr->DLLFilePtr) {
            // CustomDLL got defined...
            if (!GotDLL) {
               // Initiate Custom-API Thread
               if (!MINSTALL_CreateCustomAPIThread()) {
               MINSTLOG_ToFile ("Custom-API: Thread init failed\n"); return FALSE; }
               MINSTLOG_ToFile ("Custom-API: Thread opened\n");
               GotDLL = TRUE;
             }
            CurFilePtr = CurGroupPtr->DLLFilePtr;
            if (STRING_CombinePSZ(DLLFileName, MINSTMAX_PATHLENGTH, CurFilePtr->SourcePtr->FQName, CurFilePtr->Name)) {
               if ((DLLHandle = DLL_Load(DLLFileName))!=0) {
                  if (!(CustomDLLEntryPoint = (PCUSTOMDLL_ENTRYFUNC)DLL_GetEntryPoint (DLLHandle, CurGroupPtr->DLLEntry))) {
                     MINSTLOG_ToFile ("Custom-API: Entrypoint not found\n");
                   } else {
                     MINSTLOG_ToFile ("Custom-API Entrypoint found\n");
                     CustomAPI_ConfigSysLine = 0;
                     (CustomDLLEntryPoint) (0, MINSTALL_SourcePath, MINSTALL_MMBaseDrive,
                      CurGroupPtr->DLLParms, CustomAPI_WindowHandle, CurGroupPtr->CustomData);
                   }
                  DLL_UnLoad (DLLHandle);
                }
             }
          }
       }
      CurGroupPtr++; CurNo++;
    }
   if (GotDLL) {
      MINSTALL_RemoveCustomAPIThread();
      MINSTLOG_ToFile ("Custom-API: Thread closed\n");
    }
   return TRUE;
 }

BOOL MINSTALL_ExecuteCustomTermDLLs (void) {
   PMINSTGRP            CurGroupPtr = MCF_GroupArrayPtr;
   PMINSTFILE           CurFilePtr  = 0;
   USHORT               CurNo       = 0;
   USHORT               CurChangeNo = 0;
   CHAR                 DLLFileName[MINSTMAX_PATHLENGTH];
   HMODULE              DLLHandle   = 0;
   PCUSTOMDLL_ENTRYFUNC CustomDLLEntryPoint = 0;
   CHAR                 CustomData[MINSTMAX_CUSTOMDATALENGTH];
   BOOL                 GotDLL = FALSE;

   while (CurNo<MCF_GroupCount) {
      if (CurGroupPtr->Flags & MINSTGRP_Flags_Selected) {
         if (CurGroupPtr->TermDLLFilePtr) {
            // CustomDLL got defined...
            if (!GotDLL) {
               // Initiate Custom-API Thread
               if (!MINSTALL_CreateCustomAPIThread()) {
               MINSTLOG_ToFile ("Custom-API: Thread init failed\n"); return FALSE; }
               MINSTLOG_ToFile ("Custom-API: Thread opened\n");
               GotDLL = TRUE;
             }
            CurFilePtr = CurGroupPtr->TermDLLFilePtr;
            if (STRING_CombinePSZ(DLLFileName, MINSTMAX_PATHLENGTH, CurFilePtr->SourcePtr->FQName, CurFilePtr->Name)) {
               if ((DLLHandle = DLL_Load(DLLFileName))!=0) {
                  if (!(CustomDLLEntryPoint = (PCUSTOMDLL_ENTRYFUNC)DLL_GetEntryPoint (DLLHandle, CurGroupPtr->TermDLLEntry))) {
                     MINSTLOG_ToFile ("Custom-API: Entrypoint not found\n");
                   } else {
                     MINSTLOG_ToFile ("Custom-API Entrypoint found\n");
                     memset (CustomData, 0, sizeof(CustomData));
                     CustomAPI_ConfigSysLine = 0;
                     (CustomDLLEntryPoint) (0, MINSTALL_SourcePath, MINSTALL_MMBaseDrive,
                      "", CustomAPI_WindowHandle, CustomData);
                   }
                  DLL_UnLoad (DLLHandle);
                }
             }
          }
       }
      CurGroupPtr++; CurNo++;
    }
   if (GotDLL) {
      MINSTALL_RemoveCustomAPIThread();
      MINSTLOG_ToFile ("Custom-API: Thread closed\n");
    }
   return TRUE;
 }
