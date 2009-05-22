
#define INCL_NOPMAPI
#define INCL_BASE
#define INCL_DOSMODULEMGR
#define INCL_OS2MM
#define INCL_MMIO_CODEC
#define INCL_AUDIO_CODEC_ONLY
#include <os2.h>
#include <os2me.h>
#include <malloc.h>

#include <global.h>
#include <crcs.h>
#include <file.h>
#include <globstr.h>
#include <msg.h>
#include <mmi_public.h>
#include <mmi_types.h>
#include <mmi_main.h>
#include <mmi_inistuff.h>


MINSTINI_DEFENTRY MINSTINIEA_JoinEA[] = {
   { 0x0FD42A68, "JoinFileName",         NULL,                            0 },
   { 0xDF5CDE5B, "JoinEAFileName",       NULL,                            0 },
   { 0x00000000, NULL,                   NULL,                            0 }
 };

MINSTINI_DEFENTRY MINSTINIEA_JoinLongNameEA[] = {
   { 0xCACCF1F1, "JoinLongName",         NULL,                            0 },
   { 0xD5C2CE0C, "JoinLongFileName",     NULL,                            0 },
   { 0xF01882D8, "JoinEALongFileName",   NULL,                            0 },
   { 0x00000000, NULL,                   NULL,                            0 }
 };

MINSTINI_DEFENTRY MINSTINIMCI_MciInstallDrvClassArray[] = {
   { 0x2FC58D01, "DrvClassNumber",       NULL,                            0 },
   { 0x00000000, NULL,                   NULL,                            0 }
 };

MINSTINI_DEFENTRY MINSTINIMCI_MciInstallDrv[] = {
   { 0xCAECA131, "DrvInstallName",       NULL,                            0 },
   { 0xF1558F48, "DrvDeviceType",        NULL,                            0 },
   { 0xAC7F33FB, "DrvDeviceFlag",        NULL,                            0 },
   { 0xDD6E470A, "DrvVersionNumber",     NULL,                            0 },
   { 0xB377234D, "DrvProductInfo",       NULL,                            0 },
   { 0xB4BFB2C2, "DrvMCDDriver",         NULL,                            0 },
   { 0xE6915F45, "DrvVSDDriver",         NULL,                            0 },
   { 0xE8AB4FF7, "DrvPDDName",           NULL,                            0 },
   { 0x2552FF41, "DrvMCDTable",          NULL,                            0 },
   { 0x635D4EF2, "DrvVSDTable",          NULL,                            0 },
   { 0xC5E91968, "DrvShareType",         NULL,                            0 },
   { 0x25A89CAF, "DrvResourceName",      NULL,                            0 },
   { 0x7DAFC42F, "DrvResourceUnits",     NULL,                            0 },
   { 0x924AB2E1, "DrvClassArray",        MINSTINIMCI_MciInstallDrvClassArray, 10 },
   { 0x00000000, NULL,                   NULL,                            0 }
 };

MINSTINI_DEFENTRY MINSTINIMCI_MciInstallConnArray[] = {
   { 0x39EDF742, "ConnType",             NULL,                            0 },
   { 0x77E86C5D, "ConnInstallTo",        NULL,                            0 },
   { 0xDEB82C0C, "ConnIndexTo",          NULL,                            0 },
   { 0x00000000, NULL,                   NULL,                            0 }
 };

MINSTINI_DEFENTRY MINSTINIMCI_MciInstallConn[] = {
   { 0x7C9375DB, "ConnInstallName",      NULL,                            0 },
   { 0x40B7450F, "ConnArray",            &MINSTINIMCI_MciInstallConnArray,10 },
   { 0x00000000, NULL,                   NULL,                            0 }
 };

MINSTINI_DEFENTRY MINSTINIMCI_MciInstallParm[] = {
   { 0xBB3418BC, "ParmInstallName",      NULL,                            0 },
   { 0x7E2CCDF4, "ParmString",           NULL,                            0 },
   { 0x00000000, NULL,                   NULL,                            0 }
 };

MINSTINI_DEFENTRY MINSTINIMCI_MciInstallAlias[] = {
   { 0xDE60EB0E, "AliasInstallName",     NULL,                            0 },
   { 0xA278C064, "AliasString",          NULL,                            0 },
   { 0x00000000, NULL,                   NULL,                            0 }
 };

MINSTINI_DEFENTRY MINSTINIMCI_MciInstallExtArray[] = {
   { 0xFCD1A3BD,  "ExtString",           NULL,                            0 },
   { 0x00000000,  NULL,                  NULL,                            0 }
 };

MINSTINI_DEFENTRY MINSTINIMCI_MciInstallExt[] = {
   { 0x8187B8FE, "ExtInstallName",       NULL,                            0 },
   { 0x130025CB, "ExtArray",             MINSTINIMCI_MciInstallExtArray, MCIMAX_EXTENSIONS },
   { 0x00000000, NULL,                   NULL,                            0 }
 };

MINSTINI_DEFENTRY MINSTINIMCI_MciInstallTypes[] = {
   { 0x3DA680F8, "TypesInstallName",     NULL,                            0 },
   { 0x84C253AD, "TypesTypeList",        NULL,                            0 },
   { 0x00000000, NULL,                   NULL,                            0 }
 };

MINSTINI_DEFENTRY MINSTINIMMIO_mmioInstall[] = {
   { 0x874AF32B, "mmioFourCC",           NULL,                            0 },
   { 0x83BC6E92, "mmioDllName",          NULL,                            0 },
   { 0x383FA8EC, "mmioDllEntryPoint",    NULL,                            0 },
   { 0x6EA2DBC6, "mmioFlags",            NULL,                            0 },
   { 0x953B087F, "mmioExtendLen",        NULL,                            0 },
   { 0xB1824C61, "mmioMediaType",        NULL,                            0 },
   { 0xCD997BB5, "mmioIOProcType",       NULL,                            0 },
   { 0xF1124958, "mmioDefExt",           NULL,                            0 },
   { 0x00000000, NULL,                   NULL,                            0 }
 };

MINSTINI_DEFENTRY MINSTINIMMIO_mmioCodecDelete[] = {
   { 0xB8420316, "mmioDelLength",        NULL,                            0 },
   { 0x5CCDD4CA, "mmioDelFourCC",        NULL,                            0 },
   { 0x546A3B5B, "mmioDelDllName",       NULL,                            0 },
   { 0x75D262DB, "mmioDelDllEntryPoint", NULL,                            0 },
   { 0xB3D96C53, "mmioDelCompTypeFcc",   NULL,                            0 },
   { 0x6CCF6654, "mmioDelCompSubType",   NULL,                            0 },
   { 0xB0BB52CB, "mmioDelMediaType",     NULL,                            0 },
   { 0x524CECEC, "mmioDelFlags",         NULL,                            0 },
   { 0x09007EEC, "mmioDelCapsFlags",     NULL,                            0 },
   { 0xD8CF2CF5, "mmioDelHWName",        NULL,                            0 },
   { 0x2841E06C, "mmioDelMaxSrcBuf",     NULL,                            0 },
   { 0xD9643500, "mmioDelSyncMethod",    NULL,                            0 },
   { 0xF7CAA0ED, "mmioDelReserved1",     NULL,                            0 },
   { 0xFD9EE47D, "mmioDelXAlign",        NULL,                            0 },
   { 0x36C237D8, "mmioDelYAlign",        NULL,                            0 },
   { 0x2DCCCF4F, "mmioDelSpecInfo",      NULL,                            0 },
   { 0x00000000, NULL,                   NULL,                            0 }
 };

MINSTINI_DEFENTRY MINSTINIMMIO_mmioCodec1Install[] = {
   { 0xD1C05A78, "mmio1Length",          NULL,                            0 },
   { 0x354F8DA4, "mmio1FourCC",          NULL,                            0 },
   { 0xFE09F55D, "mmio1DllName",         NULL,                            0 },
   { 0x08D25727, "mmio1DllEntryPoint",   NULL,                            0 },
   { 0x487146E0, "mmio1CompTypeInt",     NULL,                            0 },
   { 0xAA46F050, "mmio1CompSubType",     NULL,                            0 },
   { 0x9A3DB099, "mmio1MediaType",       NULL,                            0 },
   { 0xD6D77C7F, "mmio1Flags",           NULL,                            0 },
   { 0x23869CBE, "mmio1CapsFlags",       NULL,                            0 },
   { 0xB14D759B, "mmio1HWName",          NULL,                            0 },
   { 0x02C7023E, "mmio1MaxSrcBuf",       NULL,                            0 },
   { 0x5C2B833A, "mmio1SyncMethod",      NULL,                            0 },
   { 0xDD4C42BF, "mmio1Reserved1",       NULL,                            0 },
   { 0x941CBD13, "mmio1XAlign",          NULL,                            0 },
   { 0x5F406EB6, "mmio1YAlign",          NULL,                            0 },
   { 0xC40509B4, "mmio1SpecInfo",        NULL,                            0 },
   { 0x00000000, NULL,                   NULL,                            0 }
 };

MINSTINI_DEFENTRY MINSTINIMMIO_mmioCodec2Install[] = {
   { 0xE02840E5, "mmio2Length",          NULL,                            0 },
   { 0x04A79739, "mmio2FourCC",          NULL,                            0 },
   { 0x7086F2BE, "mmio2DllName",         NULL,                            0 },
   { 0x74B372FC, "mmio2DllEntryPoint",   NULL,                            0 },
   { 0x02CE28A7, "mmio2CompTypeFcc",     NULL,                            0 },
   { 0xDDD822A0, "mmio2CompSubType",     NULL,                            0 },
   { 0x710A0B9A, "mmio2MediaType",       NULL,                            0 },
   { 0x50430ED1, "mmio2Flags",           NULL,                            0 },
   { 0xC8B127BD, "mmio2CapsFlags",       NULL,                            0 },
   { 0x80A56F06, "mmio2HWName",          NULL,                            0 },
   { 0xE9F0B93D, "mmio2MaxSrcBuf",       NULL,                            0 },
   { 0xC5C9E53B, "mmio2SyncMethod",      NULL,                            0 },
   { 0x367BF9BC, "mmio2Reserved1",       NULL,                            0 },
   { 0xA5F4A78E, "mmio2XAlign",          NULL,                            0 },
   { 0x6EA8742B, "mmio2YAlign",          NULL,                            0 },
   { 0xFD883571, "mmio2SpecInfo",        NULL,                            0 },
   { 0x00000000, NULL,                   NULL,                            0 }
 };

MINSTINI_DEFENTRY MINSTINIPRF_ProfileData[] = {
   { 0xE1F0F4E2, "ini",                  NULL,                            0 },
   { 0x027F2A21, "appname",              NULL,                            0 },
   { 0xF8048436, "keyname",              NULL,                            0 },
   { 0xAB74F1BC, "dll",                  NULL,                            0 },
   { 0x11D3633A, "id",                   NULL,                            0 },
   { 0x00000000, NULL,                   NULL,                            0 }
 };

MINSTINI_DEFENTRY MINSTINIPRF_ProfileString[] = {
   { 0x6E859C63, "inis",                 NULL,                            0 },
   { 0x6C0B80B7, "appnames",             NULL,                            0 },
   { 0xEF227EDE, "keynames",             NULL,                            0 },
   { 0x384CCEAA, "datas",                NULL,                            0 },
   { 0x00000000, NULL,                   NULL,                            0 }
 };

MINSTINI_DEFENTRY MINSTINISPI_SpiInstall[] = {
   { 0xE906AF16, "SpiDllName",           NULL,                            0 },
   { 0x00000000, NULL,                   NULL,                            0 }
 };

MINSTINI_DEFENTRY MINSTINIWPS_WPObject[] = { 
   { 0x441CEA42, "WPClassName",          NULL,                            0 },
   { 0x6DD04D76, "WPTitle",              NULL,                            0 },
   { 0x10108A85, "WPSetupString",        NULL,                            0 },
   { 0x379F7EDF, "WPLocation",           NULL,                            0 },
   { 0x4DE374A7, "WPFlags",              NULL,                            0 },
   { 0x00000000, NULL,                   NULL,                            0 }
 };

MINSTINI_DEFENTRY MINSTINIWPS_WPDestroyObject[] = { 
   { 0x5BE681E8, "WPDestroyObjectID",    NULL,                            0 },
   { 0x00000000, NULL,                   NULL,                            0 }
 };

MINSTINI_DEFENTRY MINSTINIWPS_WPClass[] = {
   { 0x3ECA180C, "WPClassNameNew",       NULL,                            0 },
   { 0xB933A94C, "WPDllName",            NULL,                            0 },
   { 0x7F6632F4, "WPReplaceClass",       NULL,                            0 },
   { 0x00000000, NULL,                   NULL,                            0 }
 };

MINSTINI_DEFENTRY MINSTINI_FuncList[] = {
   { EA_JOINEA_ID,              "JoinEA",               MINSTINIEA_JoinEA,               sizeof(EA_JOINEA) },
   { EA_JOINLONGNAMEEA_ID,      "JoinLongNameEA",       MINSTINIEA_JoinLongNameEA,       sizeof(EA_JOINLONGNAMEEA) },
   { MCI_MCIINSTALLDRV_ID,      "MciInstallDrv",        MINSTINIMCI_MciInstallDrv,       sizeof(MCI_MCIINSTALLDRV) },
   { MCI_MCIINSTALLCONN_ID,     "MciInstallConn",       MINSTINIMCI_MciInstallConn,      sizeof(MCI_MCIINSTALLCONN) },
   { MCI_MCIINSTALLPARM_ID,     "MciInstallParm",       MINSTINIMCI_MciInstallParm,      sizeof(MCI_MCIINSTALLPARM) },
   { MCI_MCIINSTALLALIAS_ID,    "MciInstallAlias",      MINSTINIMCI_MciInstallAlias,     sizeof(MCI_MCIINSTALLALIAS) },
   { MCI_MCIINSTALLEXT_ID,      "MciInstallExt",        MINSTINIMCI_MciInstallExt,       sizeof(MCI_MCIINSTALLEXT) },
   { MCI_MCIINSTALLTYPES_ID,    "MciInstallTypes",      MINSTINIMCI_MciInstallTypes,     sizeof(MCI_MCIINSTALLTYPES) },
   { MMIO_MMIOINSTALL_ID,       "mmioInstall",          MINSTINIMMIO_mmioInstall,        sizeof(MMIO_MMIOINSTALL) },
   { MMIO_MMIOCODECDELETE_ID,   "mmioCodecDelete",      MINSTINIMMIO_mmioCodecDelete,    sizeof(MMIO_MMIOCODEC) },
   { MMIO_MMIOCODEC1INSTALL_ID, "mmioCodec1Install",    MINSTINIMMIO_mmioCodec1Install,  sizeof(MMIO_MMIOCODEC) },
   { MMIO_MMIOCODEC2INSTALL_ID, "mmioCodec2Install",    MINSTINIMMIO_mmioCodec2Install,  sizeof(MMIO_MMIOCODEC) },
   { PRF_PROFILEDATA_ID,        "ProfileData",          MINSTINIPRF_ProfileData,         sizeof(PRF_PROFILEDATA) },
   { PRF_PROFILESTRING_ID,      "ProfileString",        MINSTINIPRF_ProfileString,       sizeof(PRF_PROFILESTRING) },
   { SPI_SPIINSTALL_ID,         "SpiInstall",           MINSTINISPI_SpiInstall,          sizeof(SPI_SPIINSTALL) },
   { WPS_CREATEOBJECT_ID,       "WPObject",             MINSTINIWPS_WPObject,            sizeof(WPS_CREATEOBJECT) },
   { WPS_DESTROYOBJECT_ID,      "WPDestroyObject",      MINSTINIWPS_WPDestroyObject,     sizeof(WPS_DESTROYOBJECT) },
   { WPS_WPCLASS_ID,            "WPClass",              MINSTINIWPS_WPClass,             sizeof(WPS_WPCLASS) },
   { 0x00000000, NULL,                   NULL }
 };
