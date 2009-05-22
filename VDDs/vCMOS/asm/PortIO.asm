
Public VCMOS_OutOnAddress,          VCMOS_InOnAddress
Public VCMOS_OutOnData,             VCMOS_InOnData

; -----------------------------------------------------------------------------

; This routine gets control, when a byte (AL) is OUTed to CMOS-address-port (DX)
VCMOS_OutOnAddress              Proc Near   Uses ebx ecx edx esi edi
   mov     VCMOS_CurRegister, al
   ret
VCMOS_OutOnAddress              EndP

; This routine gets control, when a byte (AL) is READ from CMOS-address-port
VCMOS_InOnAddress               Proc Near   Uses ebx ecx edx esi edi
   mov     al, VCMOS_CurRegister
   ret
VCMOS_InOnAddress               EndP

; This routine gets control, when a byte (AL) is OUTed to CMOS-data-port (DX)
VCMOS_OutOnData                 Proc Near   Uses ebx
   mov     ah, VCMOS_CurRegister
   cmp     ah, 0Eh              ; We dont allow physical access to RTC regs
   jb      RTCregisters
   cmp     PROPERTY_WriteProtection, 0
   jne     WriteDenied
   pushf
      cli                       ; We dont want to get interrupted here...
      out     70h, al
      out     0EDh, al          ; My way of doing a short wait (dummy-port!)
      mov     al, ah
      out     71h, al           ; Write byte from caller
      mov     al, 0Eh
      out     70h, al
      out     0EDh, al
      in      al, 71h           ; Switch to diagnostic port for safety reasons
   popf
  WriteDenied:
   ret

  RTCregisters:
   movzx      ebx, ah           ; EBX - Offset to Register
   mov        bptr [VCMOS_RTCArea+ebx], al
   cmp        ah, 0Bh
   je         RTCstatusBchange
  Done:
   ret

  RTCstatusBchange:
   xor        ebx, ebx                   ; 0 times per second -> disable
   test       al, 40h                    ; Application requests Periodic IRQ
   jz         DisableIRQ8
   ; Calculate TimeOut value (milliseconds to go till IRQ)
   mov        bl, [VCMOS_RTCArea+0Ah]    ; Status Register A
   and        bl, 0Fh                    ; Isolate lower 4 bits (Timer-Rate)
   mov        bx, [VCMOS_TimerRateTable+ebx*2]
  DisableIRQ8:
   push       ebx
   push       CurVDMHandle
   call       VCMOS_InstallIRQ8          ; Install/Remove IRQ8 from VDM
   add        esp, 8
   ret
VCMOS_OutOnData                 EndP

; This routine gets control, when a byte (AL) is READ from CMOS-data-port
VCMOS_InOnData                  Proc Near   Uses ebx
   call    DebugBeep
   mov     ah, VCMOS_CurRegister
   cmp     ah, 0Dh              ; We dont allow physical access to RTC regs,
   jb      RTCregisters         ;  but Status Register D (battery status)
   mov     al, ah
   pushf
      cli                       ; We dont want to get interrupted here...
      out     70h, al
      out     0EDh, al          ; My way of doing a short wait (dummy-port!)
      in      al, 71h
      mov     ah, al            ; AH - actual current data
      mov     al, 0Eh
      out     70h, al
      out     0EDh, al
      in      al, 71h           ; Switch to diagnostic port for safety reasons
   popf
   mov     al, ah               ; Reply current data      
   ret

   ; This routine will reply with virtual RTC registers. We can not allow any
   ;  VDM application to access the real deal.
  RTCregisters:
   movzx   ebx, ah              ; EBX - Offset to Register
   cmp     ah, 10               ; Check below Register 10
   jb      RTCprobablyTime
  RTCfromTable:
   mov     al, bptr [VCMOS_RTCArea+ebx]
   ret
  
   ; We have to calculate all current-time registers on-the-fly. We can not
   ;  take those values from the RTCArea-table.
  RTCprobablyTime:
   cmp     ah, 6                ; Calculate everything => Register 6
   jae     RTCcalculateValues
   test    ah, 1                ; Get Register 1,3,5 from table (alarm regs)
   jnz     RTCfromTable
  RTCcalculateValues:
   shl     ebx, 2               ; multiplicate by 4
   call    [VCMOS_InTimeRegisterCodePtr+ebx] ; Use specific code
   ret
VCMOS_InOnData                  EndP

;        In: *none*
;       Out: AL - calculated value
; Destroyed: ECX,EDX and upper EAX may get destroyed w/o saving registers
;
;      From: VCMOS_OutOnData, VCMOS_InOnData
;   Context: task
;  Function: Gets called via pointer-table VCMOS_XXXTimeRegisterCodePtr
;             Contains specific code to get various system variables and fit it
;             into the format of RTC.
VCMOS_InOnRegSeconds            Proc Near
   push    0
   push    VDHGSV_SECOND
   call    VDHQuerySysValue
   test    [VCMOS_RTCArea+0Bh], 100b     ; Check Status Register B, Bit 2
   jz      VCMOS_ConvertToBCD
   ret
VCMOS_InOnRegSeconds            EndP

VCMOS_InOnRegMinutes            Proc Near
   push    0
   push    VDHGSV_MINUTE
   call    VDHQuerySysValue
   test    [VCMOS_RTCArea+0Bh], 100b     ; Check Status Register B, Bit 2
   jz      VCMOS_ConvertToBCD
   ret
VCMOS_InOnRegMinutes            EndP

VCMOS_InOnRegHours              Proc Near
   push    0
   push    VDHGSV_HOUR
   call    VDHQuerySysValue
   test    [VCMOS_RTCArea+0Bh], 010b     ; Check Status Register B, Bit 1
   jnz     On24hourMode
   inc     al                            ; 00h->01h, 01h->02h
   cmp     al, 13                        ; No adjust, if hour <= 12
   jb      On24hourMode
   add     al, 74h                       ; 0Dh->81h, 0Eh->82h
  On24hourMode:
   test    [VCMOS_RTCArea+0Bh], 100b     ; Check Status Register B, Bit 2
   jz      VCMOS_ConvertToBCD
   ret
VCMOS_InOnRegHours              EndP

VCMOS_InOnRegDayOfWeek          Proc Near
   push    0
   push    VDHGSV_DAYOFWEEK
   call    VDHQuerySysValue     ; AL = 0-6
   inc     al                   ; Required: 1-7 (1-Sunday)
   ret
VCMOS_InOnRegDayOfWeek          EndP

VCMOS_InOnRegDate               Proc Near
   push    0
   push    VDHGSV_DAY
   call    VDHQuerySysValue     ; AL = 1-31
   test    [VCMOS_RTCArea+0Bh], 100b     ; Check Status Register B, Bit 2
   jz      VCMOS_ConvertToBCD
   ret
VCMOS_InOnRegDate               EndP

VCMOS_InOnRegMonth              Proc Near
   push    0
   push    VDHGSV_MONTH
   call    VDHQuerySysValue     ; AL = 1-12
   test    [VCMOS_RTCArea+0Bh], 100b     ; Check Status Register B, Bit 2
   jz      VCMOS_ConvertToBCD
   ret
VCMOS_InOnRegMonth              EndP

VCMOS_InOnRegYear               Proc Near
   push    0
   push    VDHGSV_YEAR
   call    VDHQuerySysValue     ; AL = 1980-xxxx
  CenturyRemoveLoop:
      sub     ax, 100
   jnc     CenturyRemoveLoop
   add     ax, 100              ; Pretty nice code? Will remove 19xx or 20xx
   test    [VCMOS_RTCArea+0Bh], 100b     ; Check Status Register B, Bit 2
   jz      VCMOS_ConvertToBCD
   ret
VCMOS_InOnRegYear               EndP

; This here will convert the result (AL) into BCD format
VCMOS_ConvertToBCD:
   mov     ah, 0F0h
  VCMOS_ConvertToBCDLoop:
      add     ah, 10h           ; Add to upper BCD
      sub     al, 10            ; Remove 10 from result
   jnc     VCMOS_ConvertToBCDLoop
   add     al, 10
   or      al, ah               ; Combine both
   ret
