
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


#define INCL_NOPMAPI
#define INCL_BASE
#define INCL_DOSMODULEMGR
#include <os2.h>
#include <malloc.h>

#include <global.h>
#include <cfgsys.h>
#include <crcs.h>
#include <dll.h>
#include <file.h>
#include <globstr.h>
#include <msg.h>
#include <mmi_public.h>
#include <mmi_types.h>
#include <mmi_main.h>
#include <mmi_helper.h>
#include <mmi_cardinfo.h>
#include <mmi_ctrlprc.h>
#include <mmi_msg.h>

VOID MINSTALL_SelectFiles (VOID) {
   PMINSTFILE CurFilePtr  = FCF_FileArrayPtr;
   PMINSTGRP  CurGroupPtr = MCF_GroupArrayPtr;
   USHORT        CurNo       = 0;

   MINSTCID_FileCount  = 0;
   MINSTCID_GroupCount = 0;

   // Count selected groups...
   while (CurNo<MCF_GroupCount) {
      if (CurGroupPtr->Flags & MINSTGRP_Flags_Selected)
         MINSTCID_GroupCount++;
      CurGroupPtr++; CurNo++;
    }

   // Select files & Directories depending on selected groups...
   CurNo = 0;
   while (CurNo<FCF_FileCount) {
      if (CurFilePtr->GroupPtr->Flags & MINSTGRP_Flags_Selected) {
         CurFilePtr->Flags               |= MINSTFILE_Flags_Selected;
         CurFilePtr->SourcePtr->Flags    |= MINSTDIR_Flags_Selected;
         CurFilePtr->DestinPtr->Flags    |= MINSTDIR_Flags_Selected;

         // We count all MINSTCID-DLLs together...
         if ((CurFilePtr->Flags & MINSTFILE_Flags_INSTDLL) || (CurFilePtr->Flags & MINSTFILE_Flags_INSTTermDLL))
            MINSTCID_FileCount++;
       }
      CurFilePtr++; CurNo++;
    }
 }

// Will create destination directories...
BOOL MINSTALL_CreateDestinDirectories (VOID) {
   PMINSTDIR  CurDirPtr     = MCF_DestinDirArrayPtr;
   USHORT        CurDirNo      = 0;

   while (CurDirNo<MCF_DestinDirCount) {
      if (CurDirPtr->Flags & MINSTDIR_Flags_Selected) {
         if (CurDirPtr->FQName[0]!=0) {
            if (!FILE_CreateDirectory ((PCHAR)CurDirPtr->FQName)) {
               MSG_SetInsertViaPSZ (1, CurDirPtr->FQName);
               MINSTALL_TrappedError (MINSTMSG_CouldNotCreateDirectory);
               return FALSE;                // If no success
             }
          }
       }
      CurDirPtr++; CurDirNo++;
    }
   return TRUE;
 }

// BOOL MINSTALL_GenerateMasterControlFile (VOID) {
//    FILE         *FileHandle = 0;
//    PMINSTDIR CurDirPtr   = 0;
//    PMINSTGRP CurGroupPtr = 0;
//    USHORT       CurNo       = 0;
//    CHAR         TempBuffer[MINSTMAX_PATHLENGTH];
// 
//    // Build full control.scr filename
//    if (!STRING_CombinePSZ ((PCHAR)&TempBuffer, MINSTMAX_PATHLENGTH, (PCHAR)&MINSTALL_InstallDir, "control.scr"))
//       return FALSE;
//    FileHandle = fopen(TempBuffer, "w+");      // Generate/Truncate file...
//    if (FileHandle==NULL)
//       return FALSE;
// 
//    fprintf (FileHandle, "/* MINSTALL normalized MCF - MK */\n\n");
//    if (!STRING_BuildEscaped ((PCHAR)&TempBuffer, MINSTMAX_PATHLENGTH, MCF_Package))
//       return FALSE;
//    fprintf (FileHandle, "package=\"%s\"\n", TempBuffer);
//    if (MCF_CodePage)
//       fprintf (FileHandle, "codepage=%d\n", MCF_CodePage);
//    fprintf (FileHandle, "filelist=\"control.fil\"\n");
//    fprintf (FileHandle, "groupcount=%d\n", MINSTCID_GroupCount);
//    fprintf (FileHandle, "munitcount=1\n");
//    if (!STRING_BuildEscaped ((PCHAR)&TempBuffer, MINSTMAX_PATHLENGTH, MCF_Medianame))
//       return FALSE;
//    fprintf (FileHandle, "medianame=\"%s\"\n", TempBuffer);
// 
//    // Write directories...
//    fprintf (FileHandle, "sourcedir=\"\\\\\"=0\n");
//    if (!STRING_BuildEscaped ((PCHAR)&TempBuffer, MINSTMAX_PATHLENGTH, (PCHAR)&MINSTALL_DLLDir+2))
//       return FALSE;
//    fprintf (FileHandle, "destindir=\"%s\"=0\n", TempBuffer);
// 
//    CurGroupPtr = MCF_GroupArrayPtr; CurNo = 0;
//    while (CurNo<MCF_GroupCount) {
//       if (CurGroupPtr->Flags & MINSTGRP_Flags_Included) {
//          // If group got included...
//          fprintf (FileHandle, "ssgroup=%d\n", CurGroupPtr->ID);
//          STRING_BuildEscaped ((PCHAR)&TempBuffer, MINSTMAX_PATHLENGTH, CurGroupPtr->Name);
//          fprintf (FileHandle, "ssname=\"%s\"\n", TempBuffer);
//          STRING_BuildEscaped ((PCHAR)&TempBuffer, MINSTMAX_PATHLENGTH, CurGroupPtr->Version);
//          fprintf (FileHandle, "ssversion=\"%s\"\n", TempBuffer);
//          if (CurGroupPtr->SpaceNeeded>0)
//             fprintf (FileHandle, "sssize=%d\n", CurGroupPtr->SpaceNeeded/1024);
//          if (CurGroupPtr->INIFilePtr!=0) {
//             fprintf (FileHandle, "ssinich=\"%.8X.$ci\"\n", CurGroupPtr->ID);
//           }
//          if (strlen(CurGroupPtr->CoReqs)>0) {
//             STRING_BuildEscaped ((PCHAR)&TempBuffer, MINSTMAX_PATHLENGTH, CurGroupPtr->CoReqs);
//             fprintf (FileHandle, "sscoreqs=\"%s\"\n", TempBuffer);
//           }
//          if (strlen(CurGroupPtr->ODInst)>0) {
//             STRING_BuildEscaped ((PCHAR)&TempBuffer, MINSTMAX_PATHLENGTH, CurGroupPtr->ODInst);
//             fprintf (FileHandle, "ssodinst=\"%s\"\n", TempBuffer);
//           }
//          if (CurGroupPtr->DLLFileName[0]!=0) {
//             STRING_BuildEscaped ((PCHAR)&TempBuffer, MINSTMAX_PATHLENGTH, CurGroupPtr->DLLFileName);
//             fprintf (FileHandle, "ssdll=\"%s\"\n", TempBuffer);
//             STRING_BuildEscaped ((PCHAR)&TempBuffer, MINSTMAX_PATHLENGTH, CurGroupPtr->DLLEntry);
//             fprintf (FileHandle, "ssdllentry=\"%s\"\n", TempBuffer);
//             STRING_BuildEscaped ((PCHAR)&TempBuffer, MINSTMAX_PATHLENGTH, CurGroupPtr->DLLParms);
//             fprintf (FileHandle, "ssdllinputparms=\"%s\"\n", TempBuffer);
//           }
//          if (CurGroupPtr->TermDLLFileName[0]!=0) {
//             STRING_BuildEscaped ((PCHAR)&TempBuffer, MINSTMAX_PATHLENGTH, CurGroupPtr->TermDLLFileName);
//             fprintf (FileHandle, "sstermdll=\"%s\"\n", TempBuffer);
//             STRING_BuildEscaped ((PCHAR)&TempBuffer, MINSTMAX_PATHLENGTH, CurGroupPtr->TermDLLEntry);
//             fprintf (FileHandle, "sstermdllentry=\"%s\"\n", TempBuffer);
//           }
//        }
//       CurGroupPtr++; CurNo++;
//     }
// 
//    if (fprintf(FileHandle, "/* End of file */\n")<=0) {
//       fclose (FileHandle);
//       return FALSE;
//     }
//    fclose (FileHandle);
//    return TRUE;
//  }
// 
// BOOL MINSTALL_GenerateFileListControlFile (VOID) {
//    FILE          *FileHandle  = 0;
//    CHAR          TempBuffer[MINSTMAX_PATHLENGTH];
//    PMINSTFILE CurFilePtr   = 0;
//    USHORT        CurNo        = 0;
//    ULONG         FirstGroupID = 0;
// 
//    // Build full control.scr filename
//    if (!STRING_CombinePSZ ((PCHAR)&TempBuffer, MINSTMAX_PATHLENGTH, (PCHAR)&MINSTALL_InstallDir, "control.fil"))
//       return FALSE;
//    FileHandle = fopen(TempBuffer, "w+");      // Generate/Truncate file...
//    if (FileHandle==NULL)
//       return FALSE;
// 
//    fprintf (FileHandle, "/* MINSTALL normalized FCF - MK */\n\n");
//    fprintf (FileHandle, "%d\n", MINSTCID_FileCount);
// 
//    CurFilePtr = FCF_FileArrayPtr;
//    while (CurNo<FCF_FileCount) {
//       if ((CurFilePtr->Flags & MINSTFILE_Flags_INSTDLL) || (CurFilePtr->Flags & MINSTFILE_Flags_INSTTermDLL)) {
//          STRING_BuildEscaped ((PCHAR)&TempBuffer, MINSTMAX_PATHLENGTH, CurFilePtr->Name);
//          fprintf (FileHandle, "0 0 0 0 \"%s\"\n", TempBuffer);
//        }
//       CurFilePtr++; CurNo++;
//     }
// 
//    if (fprintf(FileHandle, "/* End of file */\n")<=0) {
//       fclose (FileHandle);
//       return FALSE;
//     }
//    fclose (FileHandle);
//    return TRUE;
//  }
// 
// BOOL MINSTALL_GenerateResponseFile (VOID) {
//    FILE         *FileHandle = 0;
//    CHAR         TempBuffer[MINSTMAX_PATHLENGTH];
//    PMINSTGRP CurGroupPtr = 0;
//    USHORT       CurNo       = 0;
//    USHORT       CurOptionNo = 0;
//    
// 
//    // Build full control.scr filename
//    if (!STRING_CombinePSZ ((PCHAR)&TempBuffer, MINSTMAX_PATHLENGTH, (PCHAR)&MINSTALL_InstallDir, "control.rsp"))
//       return FALSE;
//    FileHandle = fopen(TempBuffer, "w+");      // Generate/Truncate file...
//    if (FileHandle==NULL)
//       return FALSE;
// 
//    fprintf (FileHandle, "/* MINSTALL normalized RSP - MK */\n\n");
//    STRING_BuildEscaped ((PCHAR)&TempBuffer, MINSTMAX_PATHLENGTH, (PCHAR)&MINSTALL_InstallPath);
//    fprintf (FileHandle, "MMINSTSOURCE = \"%s\"\n", TempBuffer);
//    fprintf (FileHandle, "MMINSTTARGET = \"%s\"\n", MINSTALL_MMBaseDrive);
//    fprintf (FileHandle, "CHANGECONFIG = \"N\"\n");
//    fprintf (FileHandle, "\nMMINSTGROUPS =\n(\n");
// 
//    CurGroupPtr = MCF_GroupArrayPtr; CurNo = 0;
//    while (CurNo<MCF_GroupCount) {
//       if ((CurGroupPtr->Flags & MINSTGRP_Flags_Selected) && (CurGroupPtr->ID!=0)) {
// //         fprintf (FileHandle, "GROUP.%d = \"minstall=NUM=%d", CurGroupPtr->ID, CurGroupPtr->SelectedAdapters);
// //         if (CurGroupPtr->PromptsCount==0) {
// //            // 0 User-Prompts
// //            fprintf (FileHandle, ",");      // Add comma (parse error)
// //          } else {
// //            CurOptionNo = 0;
// //            while (CurOptionNo<CurGroupPtr->PromptsCount) {
// //               fprintf (FileHandle, ",V1=%s", CurGroupPtr->PromptSelectedChoice[CurOptionNo]);
// //               CurOptionNo++;
// //             }
// //          }
// //         fprintf (FileHandle, "\"\n");
//        }
//       CurGroupPtr++; CurNo++;
//     }
//    fprintf (FileHandle, ")\n\n");
// 
//    if (fprintf(FileHandle, "/* End of file */\n")<=0) {
//       fclose (FileHandle);
//       return FALSE;
//     }
//    fclose (FileHandle);
//    return TRUE;
//  }

// Will copy source files to our temporary location...
BOOL MINSTALL_CopyFiles (VOID) {
   PMINSTFILE CurFilePtr      = FCF_FileArrayPtr;
   USHORT     CurNo           = 0;
   PMINSTDIR  CurSourceDirPtr = 0;
   PMINSTGRP  CurGroupPtr     = 0;
   CHAR       ChangeControlFile[13];
   CHAR       TempSourceFile[MINSTMAX_PATHLENGTH];
   CHAR       TempDestinFile[MINSTMAX_PATHLENGTH];
   BOOL       AnythingDelayed = FALSE;
   APIRET     rc;
   CFGSYSRET  CfgSysRC;

   while (CurNo<FCF_FileCount) {
      if (CurFilePtr->Flags & MINSTFILE_Flags_Selected) {
         // This file is selected, so process it...
         if (!STRING_CombinePSZ ((PCHAR)&TempSourceFile, MINSTMAX_PATHLENGTH, CurFilePtr->SourcePtr->FQName, CurFilePtr->Name))
            return FALSE;

         if (CurFilePtr->Flags &MINSTFILE_Flags_Included) {
            // Is Included, so copy this file to its desired destination...
            if (!STRING_CombinePSZ ((PCHAR)&TempDestinFile, MINSTMAX_PATHLENGTH, CurFilePtr->DestinPtr->FQName, CurFilePtr->Name))
               return FALSE;
            MINSTLOG_ToAll (" -> %s\n", TempDestinFile);
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
          }
       }
      CurFilePtr++; CurNo++;
    }

   if (AnythingDelayed) {
      if (CONFIGSYS_DelayFinalize()!=CONFIGSYS_DONE)
         return FALSE;
      MINSTLOG_ToAll ("Files got delayed. System should reboot.\n");
    }
   return TRUE;
 }
