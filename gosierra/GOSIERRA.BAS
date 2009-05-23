$COMPILE EXE

$LINK "DYNAMIX.obj"
DECLARE FUNCTION Dynamix_Unpack (STRING) as STRING
DECLARE FUNCTION Dynamix_Pack   (STRING) as STRING

Sub PATCH_Foreword
   print "Someyears before, I wanted to play an old classic Sierra game, but it did"
   print "not work using Soundblaster sound. Damn, I said. First I disabled, later I"
   print "slowed down my computer, so it won't crash anymore."
   print "Nowdays, I'm using OS/2 Warp. Great DOS box, but all slowdown programs do"
   print "not work in there. So I debugged the driver and exchanged a whole code part"
   print "in the driver. It was a 'fault' in the IRQ proof routine. That thing just did"
   print "not wait long enough and boom. My inserted code is so-called bullet-proof."
   print "It should work on P9 computers, if you know what I mean ;)"
   print "Every game which has an AUDBLAST.drv/SNDBLAST.drv (real mode only) can be"
   print "patched and it will work perfectly afterwards (without slowdown progs)."
   print "GOSIERRA v3 supports the driver format, which is used by Dynamix games."
End Sub

Sub PATCH_Copyright
   print
   print "I'm releasing this shit as freeware. If you publish it on a website, please"
   print "include my copyright. Thanks. Contact via Internet: kiewitz@netlabs.org."
   print "I'm dedicating this patch to my father."
End Sub

Sub PATCH_Help
   print "Call this program in a sierra game directory using the name of the driver,"
   print " you want to patch to make it work on Pentium+ machines. It will NOT backup"
   print " your original driver, so do it yourself."
   print "e.g. 'GOSIERRA SNDBLAST.DRV' to patch SNDBLAST.DRV"
   print "     If no parameter is specified AUDBLAST.DRV is used."
   print
   print "Dynamix games can now be patched using 'GOSIERRA DYNAMIX'."
End Sub

Dim Signature (1 to 80)          as shared INTEGER

Print "GOSIERRA v3 - Magic Driver Patcher - (c) Copyright by Kiewitz in year 2000-2003"
Print " (call 'gosierra help' to have help and info shown)
Print
If lcase$(command$)="help" Then
   PATCH_Foreword
   PATCH_Copyright
   end 0
End If

MyFile$ = ucase$(command$)
If Len(MyFile$)=0 Then MyFile$ = "AUDBLAST.DRV"

If ucase$(MyFile$)="DYNAMIX" Then ' =================== Special Dynamix Mode
   ' First try to open SX.OVL, otherwise extract from RESOURCE/VOLUME-file
   print "þ Special DYNAMIX-Mode"
   If Len(Dir$("SX.OVL"))=0 Then
      ' SX.OVL not already extracted, do so now...
      GOSIERRA_ExtractDynamixDriver
   End If
   ' SX.OVL is now in raw form...now we have to search for the SB-driver
   '  and patch it using GOSIERRA_PatchBuffer
   GOSIERRA_PatchDynamixDriver

  else ' ================================================ Normal SIERRA Mode
   If Len(Dir$(MyFile$))=0 Then
      PATCH_Help
      PATCH_Copyright
      end 1
   End If
   Open MyFile$ For BINARY As #1
   Get$ #1, 32000, Buffer$
   If eof(1)=0 Then
      print "Can't be. The file, you specified, is not a Sierra driver."
      end 1
   End If
   Select Case GOSIERRA_PatchBuffer(Buffer$)
     Case  0
      Seek #1, 0: Put$ #1, Buffer$
      print "File patched successfully.": end
     Case -1: Print "The "+MyFile$+" in the current directory is already patched."
     Case -2: Print "Could not patch file. Sorry."
   End Select
   end 1
End If
End

Function GOSIERRA_PatchBuffer (DriverCode$) as INTEGER
   local PatchData$
   If Instr(DriverCode$,Chr$(&hEC,&h2E,&h80,&h3E))>0 Then
      FUNCTION = -1
      Exit Function
   End If

   ' First of all, check for Dynamix-IRQ-Restore bug...
   '  if it's found, it will be removed. Overall result depends on SB-bug
   '  to get removed

   PatchPos& = Instr(DriverCode$,Chr$(&hA1,&h00,&hB0,&h0A,&hBB))
   If PatchPos&>0 Then
      ' Original code as follows:
      '===========================
      ' 2EC706????A100 - MOV  Word Ptr CS:[????],00A1
      ' B00A           - MOV  AL,0A
      ' BB????         - MOV  BX,????
      ' 2E8A26????     - MOV  AH,Byte Ptr CS:[????]
      ' 0E             - PUSH CS
      ' E8????         - CALL ????
      ' Insert last line (MOV) in here and everything works...
      ' B007           - MOV  AL,07
      ' BB????         - MOV  BX,????
      ' 2E8A26????     - MOV  AH,Byte Ptr CS:[????]
      ' 0E             - PUSH CS
      ' E8????         - CALL ????
      ' B005           - MOV  AL,05
      ' BB????         - MOV  BX,????
      ' 2E8A26????     - MOV  AH,Byte Ptr CS:[????]
      ' 0E             - PUSH CS
      ' E8????         - CALL ????
      ' 2EC706????2100 - MOV  Word Ptr CS:[????],0021

      Decr PatchPos&, 5
      Signature( 1) = &h2E: Signature( 2) = &hC7: Signature( 3) = &h06
      Signature( 4) =   -1: Signature( 5) =   -1: Signature( 6) = &hA1
      Signature( 7) = &h00: Signature( 8) = &hB0: Signature( 9) = &h0A
      Signature(10) = &hBB: Signature(11) =   -1: Signature(12) =   -1
      Signature(13) = &h2E: Signature(14) = &h8A: Signature(15) = &h26
      Signature(16) =   -1: Signature(17) =   -1: Signature(18) = &h0E
      Signature(19) = &hE8: Signature(20) =   -1: Signature(21) =   -1
      Signature(22) = &hB0: Signature(23) = &h07: Signature(24) = &hBB
      Signature(25) =   -1: Signature(26) =   -1: Signature(27) = &h2E
      Signature(28) = &h8A: Signature(29) = &h26: Signature(30) =   -1
      Signature(31) =   -1: Signature(32) = &h0E: Signature(33) = &hE8
      Signature(34) =   -1: Signature(35) =   -1: Signature(36) = &hB0
      Signature(37) = &h05: Signature(38) = &hBB: Signature(39) =   -1
      Signature(40) =   -1: Signature(41) = &h2E: Signature(42) = &h8A
      Signature(43) = &h26: Signature(44) =   -1: Signature(45) =   -1
      Signature(46) = &h0E: Signature(47) = &hE8: Signature(48) =   -1
      Signature(49) =   -1: Signature(50) = &h2E: Signature(51) = &hC7
      Signature(52) = &h06: Signature(53) =   -1: Signature(54) =   -1
      Signature(55) = &h21: Signature(56) = &h00

      Compare$ = Mid$(DriverCode$,PatchPos&,56)
      If CheckSignature(Compare$) Then
         print "þ Fixed Dynamix-Extra-Bug[tm]"

         PatchData$ = Left$(Compare$,21)+Mid$(Compare$,50)+Mid$(Compare$,22,28)
         ' Now fix both CALLs
         Mid$(PatchData$,41,2) = MkWrd$(CvWrd(PatchData$,41)-7)
         Mid$(PatchData$,55,2) = MkWrd$(CvWrd(PatchData$,55)-7)
         Mid$(DriverCode$,PatchPos&) = PatchData$
      End If
   End If

   ' Here, normal SB-Bugs follow :)

   PatchPos& = Instr(DriverCode$,Chr$(&h00,&h75,&h07,&hE2,&hF6))
   If PatchPos&>0 Then
      print "þ Driver-Bug [TYPE 1]"
      ' Original code as follows:
      '===========================
      ' B900??       - MOV  CX, 0800 oder MOV  CX, 0200
      ' 2EC6062F0000 - MOV  BPTR CS:[????], 00
      ' 2E803E2F0000 - CMP  BPTR CS:[????], 00 -> 971              xxx??S
      ' 7507         - JNZ  0980                                   SS
      ' E2F6         - LOOP 0971                                   SS
      ' B80300       - MOV  AX, 0003
      ' EB02         - JMP  0982
      ' 33C0         - XOR  AX, AX   -> 980
      ' 50           - PUSH AX       -> 982

      ' Modified to:
      '==============
      ' B90008       - MOV  CX, 0800
      ' 33DB         - XOR  BX, BX
      ' 2EC606????00 - MOV  BPTR ...
      ' EC           - IN   AL, DX (trick to get standard clocking speed)
      ' 2E803E????00 - CMP  BPTR ...
      ' 7506         - JNZ  ???      -> to PUSH BX
      ' 49           - DEC  CX
      ' 75F4         - JNZ  ???      -> to IN AL, DX
      ' BB0300       - MOV  BX, 0003
      ' 53           - PUSH BX

      Decr PatchPos&, 14
      Signature( 1) = -1:   Signature( 2) = -1
      Signature( 3) = -1:   Signature( 4) = -1
      Signature( 5) = -1:   Signature( 6) = -1
      Signature( 7) = -1:   Signature( 8) = -1
      Signature( 9) = &h00: Signature(10) = &h2E
      Signature(11) = &h80: Signature(12) = &h3E
      Signature(13) = -1:   Signature(14) = -1
      Signature(15) = &h00: Signature(16) = &h75
      Signature(17) = &h07: Signature(18) = &hE2
      Signature(19) = &hF6: Signature(20) = &hB8
      Signature(21) = -1:   Signature(22) = &h00
      Signature(23) = &hEB: Signature(24) = &h02
      Signature(25) = &h33: Signature(26) = &hC0
      Signature(27) = &h50

      Compare$ = Mid$(DriverCode$,PatchPos&,27)
      If CheckSignature(Compare$)=0 Then
         FUNCTION = -2: Exit Function
      End If

      SaveWord?? = CvWrd(Compare$,7)
      PatchData$ = Chr$(&hB9,&h00,&h08)
      PatchData$ = PatchData$+Chr$(&h33,&hDB)
      PatchData$ = PatchData$+Chr$(&h2E,&hC6,&h06)+MkWrd$(SaveWord??)+Chr$(&h00)
      PatchData$ = PatchData$+Chr$(&hEC)
      PatchData$ = PatchData$+Chr$(&h2E,&h80,&h3E)+MkWrd$(SaveWord??)+Chr$(&h00)
      PatchData$ = PatchData$+Chr$(&h75,&h06)
      PatchData$ = PatchData$+Chr$(&h49)
      PatchData$ = PatchData$+Chr$(&h75,&hF4)
      PatchData$ = PatchData$+Chr$(&hBB,&h03,&h00)
      PatchData$ = PatchData$+Chr$(&h53)
      Mid$(DriverCode$,PatchPos&) = PatchData$
      Exit Function
   End If

   ' Try other routine-type-signature... (Space Quest 5...)
   PatchPos& = Instr(DriverCode$,Chr$(&h00,&hE1,&hF8,&h2E,&h80,&h3E))
   If PatchPos&>0 Then
      print "þ Driver-Bug [TYPE 2]"
      ' Original code as follows:
      '===========================
      ' B90008       - MOV  CX, 8000
      ' 2E803E????00 - CMP  BPTR CS:[????], 00                  xxx??S
      ' E1F8         - LOOPE  -> CMP BPTR                       SS
      ' 2E803E????00 - CMP  BPTR CS:[????], 00                  SSS
      ' 7505         - JNZ  -> XOR AX, AX
      ' B8??00       - MOV  AX, 0005 oder MOV  AX, 0003
      ' EB02         - JMP  -> PUSH AX
      ' 33C0         - XOR  AX, AX
      ' 50           - PUSH AX

      ' Modified to:
      '==============
      ' B90008       - MOV  CX, 8000
      ' 33DB         - XOR  BX, BX
      ' EC           - IN   AL, DX
      ' 2E803E????00 - CMP  BPTR CS:[????], 00
      ' 7506         - JNZ  -> PUSH BX
      ' 49           - DEC  CX
      ' 75F4         - JNZ  -> IN AL, DX
      ' BB0500       - MOV  BX, 0005
      ' 53           - PUSH BX
      ' EB04         - JMP  Further
      ' 'LEA!'       - Little Signature ;)
      ' Further      -

      Decr PatchPos&, 8

      Signature( 1) = -1:   Signature( 2) = -1
      Signature( 3) = -1:   Signature( 4) = -1
      Signature( 5) = -1:   Signature( 6) = -1
      Signature( 7) = -1:   Signature( 8) = -1
      Signature( 9) = -1:   Signature( 9) = &h00
      Signature(10) = &hE1: Signature(11) = &hF8
      Signature(12) = &h2E: Signature(13) = &h80
      Signature(14) = &h3E: Signature(15) = -1
      Signature(16) = -1:   Signature(17) = &h00
      Signature(18) = &h75: Signature(19) = &h05
      Signature(20) = &hB8: Signature(21) = -1
      Signature(22) = &h00: Signature(23) = &hEB
      Signature(24) = &h02: Signature(25) = &h33
      Signature(26) = &hC0: Signature(27) = &h50

      Compare$ = Mid$(DriverCode$,PatchPos&,27)
      If CheckSignature(Compare$)=0 Then
         FUNCTION = -2: Exit Function
      End If

      SaveWord?? = CvWrd(Compare$,7)
      PatchData$ = Chr$(&hB9,&h00,&h08)
      PatchData$ = PatchData$+Chr$(&h33,&hDB)
      PatchData$ = PatchData$+Chr$(&hEC)
      PatchData$ = PatchData$+Chr$(&h2E,&h80,&h3E)+MkWrd$(SaveWord??)+Chr$(&h00)
      PatchData$ = PatchData$+Chr$(&h75,&h06)
      PatchData$ = PatchData$+Chr$(&h49)
      PatchData$ = PatchData$+Chr$(&h75,&hF4)
      PatchData$ = PatchData$+Chr$(&hBB,&h05,&h00)
      PatchData$ = PatchData$+Chr$(&h53)
      PatchData$ = PatchData$+Chr$(&hEB,&h04)
      PatchData$ = PatchData$+"LEA!"
      Mid$(DriverCode$,PatchPos&) = PatchData$
      Exit Function
   End If

   ' Try other (old format) SNDBLAST.drv routine type... (Larry 5, etc.)
   PatchPos& = Instr(DriverCode$,Chr$(&h00,&h75,&h05,&hE2,&hF6,&hB8))
   If PatchPos&>0 Then
      print "þ Driver-Bug [TYPE 3]"
      ' Original code as follows:
      '===========================
      ' 33C0         - XOR  AX, AX
      ' B900??       - MOV  CX, 0200
      ' 2E803E????00 - CMP  BPTR CS:[????], 00               xxx??S
      ' 7505         - JNZ  21D1 -> PUSH AX                  SS
      ' E2F6         - LOOP 21C4 -> CMP BPTR                 SS
      ' B80300       - MOV  AX, 0003                         S
      ' 50           - PUSH AX

      ' Modified to:
      '==============
      ' 33DB         - XOR  BX, BX
      ' B90008       - MOV  CX, 0800
      ' EC           - IN   AL, DX
      ' 2E803E????00 - CMP  BPTR CS:[????], 00
      ' 7504         - JNZ  -> PUSH BX
      ' E2F5         - LOOP -> IN AL, DX
      ' B003         - MOV  BL, 03
      ' 53           - PUSH BX

      Decr PatchPos&, 10
      Signature( 1) = &h33: Signature( 2) = &hC0
      Signature( 3) = &hB9: Signature( 4) = -1
      Signature( 5) = -1:   Signature( 6) = &h2E
      Signature( 7) = &h80: Signature( 8) = &h3E
      Signature( 9) = -1:   Signature(10) = -1
      Signature(11) = &h00: Signature(12) = &h75
      Signature(13) = &h05: Signature(14) = &hE2
      Signature(15) = &hF6: Signature(16) = &hB8
      Signature(17) = -1:   Signature(18) = &h00
      Signature(19) = &h50

      Compare$ = Mid$(DriverCode$,PatchPos&,19)
      If CheckSignature(Compare$)=0 Then
         FUNCTION = -2: Exit Function
      End If

      SaveWord?? = CvWrd(Compare$,9)
      PatchData$ = Chr$(&h33,&hDB)
      PatchData$ = PatchData$+Chr$(&hB9,&h00,&h08)
      PatchData$ = PatchData$+Chr$(&hEC)
      PatchData$ = PatchData$+Chr$(&h2E,&h80,&h3E)+MkWrd$(SaveWord??)+Chr$(&h00)
      PatchData$ = PatchData$+Chr$(&h75,&h04)
      PatchData$ = PatchData$+Chr$(&hE2,&hF5)
      PatchData$ = PatchData$+Chr$(&hB0,&h03)
      PatchData$ = PatchData$+Chr$(&h53)
      Mid$(DriverCode$,PatchPos&) = PatchData$
      Exit Function
   End If



$IF 0 ' <--- The same like TYPE 2
   ' Try another routine type (found in The Incredible Machine II)
   PatchPos& = Instr(DriverCode$,Chr$(&h00,&h75,&h05,&hB8,&h05,&h00,&hEB,&h02))
   If PatchPos&>0 Then
      print "þ Driver-Bug [TYPE 4]"
      ' Original code as follows:
      '===========================
      ' B90008       - MOV   CX,0800
      ' 2E803E????00 - CMP   Byte Ptr CS:[????],00
      ' E1F8         - LOOPE -> CMP BPTR
      ' 2E803E????00 - CMP   Byte Ptr CS:[????],00
      ' 7505         - JNZ   -> XOR AX,AX
      ' B80500       - MOV   AX,0005
      ' EB02         - JMP   -> PUSH AX
      ' 33C0         - XOR   AX,AX
      ' 50           - PUSH  AX
      ' (Code-Length 27)

      ' Modified to:
      '==============
      ' 33DB         - XOR  BX, BX
      ' B90008       - MOV  CX, 0800
      ' EC           - IN   AL, DX
      ' 2E803E????00 - CMP  BPTR CS:[????], 00
      ' 7504         - JNZ  -> PUSH BX
      ' E2F5         - LOOP -> IN AL, DX
      ' B003         - MOV  BL, 05
      ' 53           - PUSH BX
      ' (Code-Length 19)
      ' EB06         - JMP  Further
      ' 'MARYSE'     - Little Signature ;)
      ' Further      -

      Decr PatchPos&, 16
      Signature( 1) = &hB9: Signature( 2) = &h00: Signature( 3) = &h08
      Signature( 4) = &h2E: Signature( 5) = &h80: Signature( 6) = &h3E
      Signature( 7) =   -1: Signature( 8) =   -1: Signature( 9) = &h00
      Signature(10) = &hE1: Signature(11) = &hF8: Signature(12) = &h2E
      Signature(13) = &h80: Signature(14) = &h3E: Signature(15) =   -1
      Signature(16) =   -1: Signature(17) = &h00: Signature(18) = &h75
      Signature(19) = &h05: Signature(20) = &hB8: Signature(21) = &h05
      Signature(22) = &h00: Signature(23) = &hEB: Signature(24) = &h02
      Signature(25) = &h33: Signature(26) = &hC0: Signature(27) = &h50

      Compare$ = Mid$(DriverCode$,PatchPos&,27)
      If CheckSignature(Compare$)=0 Then
         FUNCTION = -2: Exit Function
      End If

      SaveWord?? = CvWrd(Compare$,7)
      PatchData$ = Chr$(&h33,&hDB)
      PatchData$ = PatchData$+Chr$(&hB9,&h00,&h08)
      PatchData$ = PatchData$+Chr$(&hEC)
      PatchData$ = PatchData$+Chr$(&h2E,&h80,&h3E)+MkWrd$(SaveWord??)+Chr$(&h00)
      PatchData$ = PatchData$+Chr$(&h75,&h04)
      PatchData$ = PatchData$+Chr$(&hE2,&hF5)
      PatchData$ = PatchData$+Chr$(&hB0,&h05)
      PatchData$ = PatchData$+Chr$(&h53)
      PatchData$ = PatchData$+Chr$(&hEB,&h06)
      PatchData$ = PatchData$+"M’çYSî"
      Mid$(DriverCode$,PatchPos&) = PatchData$
      Exit Function
   End If
$ENDIF

   FUNCTION = -2
End Function

Function CheckSignature (byval Compare$) as INTEGER
   local Failed%
   For CurPos%=1 To Len(Compare$)
      If not Signature(CurPos%)=-1 Then
         If not Signature(CurPos%)=Asc(Compare$,CurPos%) Then
'            print CurPos%, Hex$(Asc(Compare$,CurPos%)), Hex$(Signature(CurPos%))
            Failed% = -1
         End If
      End If
   Next CurPos%
   FUNCTION = not Failed%
End Function

Sub GOSIERRA_ExtractDynamixDriver
   local FileBase$, FileNo$, DriverFileFound%
   local TempBuffer$, TempPos&, BaseOffset&
   local BundleFile$, BundleFileLen&

   ' Check, if RESOURCE or VOLUME-type used
   If Len(Dir$("VOLUME.001"))>0 Then
      FileBase$ = "VOLUME."
     elseif Len(Dir$("RESOURCE.001"))>0 Then
      FileBase$ = "RESOURCE."
     else
      print "þ No VOLUME/RESOURCE bundles found in current directory"
      end 1
   End If

   FileNo$ = "000"
   Do
      FileNo$ = "00"+ltrim$(Str$(Val(FileNo$)+1))
      If Len(Dir$(FileBase$+FileNo$))=0 Then
         print "þ No driver record found in bundles."
         end 1
      End If
      Open FileBase$+FileNo$ For BINARY As #1
      Do
         Get$ #1, 17, TempBuffer$: BaseOffset& = Seek(1)
         If not eof(1) Then
            BundleFile$ = Left$(TempBuffer$,13)
            TempPos& = Instr(BundleFile$,Chr$(0))
            If TempPos&>0 Then BundleFile$ = Left$(BundleFile$,TempPos&-1)
            If Mid$(TempBuffer$,14)=Chr$(255,255,255,255) Then
               BundleFileLen& = 0
              else
               BundleFileLen& = CvDwd(TempBuffer$,14)
            End If
            If BundleFile$="SX.OVL" Then ' Hit
               print "þ Driver record found."
               ' Extract SX.OVL...
               Open "SX.OVL" For BINARY As #2
               Do
                  If BundleFileLen&>32000 Then
                     Get$ #1, 32000, TempBuffer$
                    else
                     Get$ #1, BundleFileLen&, TempBuffer$
                  End If
                  Put$ #2, TempBuffer$
                  Decr BundleFileLen&, Len(TempBuffer$)
               Loop Until BundleFileLen&<=0
               Put$ #2, nul$
               Close #2
               DriverFileFound% = -1
            End If
            Seek #1, BaseOffset&+BundleFileLen&
         End If
      Loop Until eof(1) or DriverFileFound%
      Close #1
   Loop Until DriverFileFound%
   print "þ Driver file extracted."
End Sub

Sub GOSIERRA_PatchDynamixDriver
   local TempBuffer$, EndOfPackage%, PatchSuccess%, EndPos???
   local BundleID$, BundleLen???, BundleOffset???, EndOfBundle%
   local DriverID$, DriverLen???

   Open "SX.OVL" For BINARY As #1: Open "SX.TMP" For BINARY As #2
   Put$ #2, nul$

   Do
      BundleOffset??? = Seek(2)
      Get$ #1, 8, TempBuffer$
      BundleID$ = Left$(TempBuffer$,4): BundleLen??? = CvDwd(TempBuffer$,5)
      Bit Reset BundleLen???, 31

      ' Write temporary Bundle-Header
      Put$ #2, BundleID$+MkDwd$(BundleLen???)

      ' SSM: -> ASB:
      ' HDS: -> HSB:
      EndPos??? = seek(1)+BundleLen???: EndOfBundle% = 0
      Do
         Get$ #1, 8, TempBuffer$
         DriverID$ = Left$(TempBuffer$,4): DriverLen??? = CvDwd(TempBuffer$,5)
         Get$ #1, DriverLen???, DriverCode$

         Select Case DriverID$
           Case "ASB:"
            ' Packed Soundblaster Driver
            ' Supposed Format of driver compressed data:
            ' [BYTE]  - Type of compression
            ' [DWORD] - Length of uncompressed driver
            DriverCode$ = Dynamix_Unpack(DriverCode$)
            If Len(DriverCode$)=0 Then
               print "þ Dynamix_Unpack(): No result ?!?!"
               Close #2: Kill "SX.TMP"
               End 1
            End If

            print "þ Got compressed SoundBlaster-Driver from bundle"
            Select Case GOSIERRA_PatchBuffer(DriverCode$)
              Case  0: PatchSuccess% = -1
              Case -1
               Print "þ SoundBlaster-Driver already patched."
               Close #2: Kill "SX.TMP"
               End 1
              Case -2
               Print "þ Could not patch driver. Sorry."
               Close #2: Kill "SX.TMP"
               End 1
            End Select
            ' Put into UNPACKED-Form
            DriverCode$ = Chr$(0)+MkDwd$(Len(DriverCode$))+DriverCode$
'            DriverCode$ = Dynamix_Pack(DriverCode$)
'            If Len(DriverCode$)=0 Then
'               print "þ Dynamix_Pack(): No result ?!?!"
'               Close #2: Kill "SX.TMP"
'               End 1
'            End If
            DriverLen??? = Len(DriverCode$)

           Case "HSB:"
            print "þ Found uncompressed SoundBlaster-Driver from bundle"
            Select Case GOSIERRA_PatchBuffer(DriverCode$)
              Case  0: PatchSuccess% = -1
              Case -1
               Print "þ SoundBlaster-Driver already patched."
               Close #2: Kill "SX.TMP"
               End 1
              Case -2
               Print "þ Could not patch driver. Sorry."
               Close #2: Kill "SX.TMP"
               End 1
            End Select
         End Select

         ' Write driver-data to output file
         Put$ #2, DriverID$+MkDwd$(Len(DriverCode$))
         Put$ #2, DriverCode$

         if eof(1)             Then EndOfBundle% = -1
         if Seek(1)=>EndPos??? Then EndOfBundle% = -1
      Loop Until EndOfBundle%

      BundleLen??? = seek(2)-BundleOffset???-8
      Bit Set BundleLen???, 31
      Seek #2, BundleOffset???
      Put$ #2, BundleID$+MkDwd$(BundleLen???)
      Seek #2, lof(2)

      if (seek(1)=lof(1)) or eof(1) Then EndOfPackage% = -1
   Loop Until EndOfPackage%

   If PatchSuccess% Then
      print "þ Soundblaster driver patched SUCCESSFULLY."
     else
      print "þ No SoundBlaster-Driver found in driver bundle."
      Close #2: Kill "SX.TMP"
      end 1
   End If
   Close #2: Close #1
   Kill "SX.OVL"
   Name "SX.TMP" as "SX.OVL"
End Sub
