/* Rexx to combine all MODULES\*.bin files into modules.inc */

Call RxFuncAdd 'SysLoadFuncs','RexxUtil','SysLoadFuncs'
Call SysLoadFuncs

crlf=d2c(13)||d2c(10)          /* Carriage return - linefeed pair */

call SysFileTree "modules\*.bin", "Files", "fo"

ModulesFile = "modules.inc"
If length(stream(ModulesFile,"c","query exists"))>0 Then
   call SysFileDelete ModulesFile
ModulesHeader = "modules.h"
If length(stream(ModulesHeader,"c","query exists"))>0 Then
   call SysFileDelete ModulesHeader

call LineOut ModulesFile, "; Automatically generated file - do not modify"
call LineOut ModulesFile, ""
call LineOut ModulesHeader, "// Automatically generated file - do not modify"
call Lineout ModulesHeader, ""

Do CurFile=1 To Files.0
   Filename  = Files.CurFile
   Basename  = FileSpec("name",Filename)
   Basename  = Translate(Left(Basename,Length(Basename)-4))
   call CharOut ,"Processing "Basename"..."

   BinLength = Stream(Filename,"c","query size")
   BinData   = CharIn(Filename, 1, BinLength)
   call Stream Filename,"c","close"

   call LineOut ModulesFile, "public PATCH_"Basename"length"
   call LineOut ModulesFile, "public PATCH_"Basename
   call LineOut ModulesFile, ""
   call LineOut ModulesFile, "PATCH_"Basename"length dw "BinLength
   call CharOut ModulesFile, "PATCH_"Basename":"

   call LineOut ModulesHeader, "extern ushort PATCH_"Basename"length;"
   call LineOut ModulesHeader, "extern char   PATCH_"Basename";"

   LineChar = 0;
   Do CurPos=1 to BinLength by 2
      HexData  = c2x(substr(BinData,CurPos,2))
      if CurPos+1>BinLength Then
         HexData = "0"Left(HexData,2)"h"
        else
         HexData  = "0"Right(HexData,2)||Left(HexData,2)"h"

      If LineChar=0 Then Do
         call LineOut ModulesFile, ""
         call CharOut ModulesFile, "   dw "HexData
         LineChar = 20
      End
       else
         call CharOut ModulesFile, ", "HexData

      LineChar = LineChar-2;
   End
   call LineOut ModulesFile, ""
   call LineOut ModulesFile, ""
   call LineOut ModulesFile, ""

   call LineOut ,"ok!"
End
exit
