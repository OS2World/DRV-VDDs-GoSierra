
Public VDDAPI

; -----------------------------------------------------------------------------

; Is called, when another VDD calls VDHRequestVDD() on us
VDDAPI                          Proc Near PASCAL  Uses ebx ecx edx esi edi, VDMHandle:dword, CommandNo:dword, ReqInPtr:dword, ReqOutPtr:dword
   ; Now we will switch to the actual requested API
   mov     eax, CommandNo
   mov     esi, ReqInPtr
   mov     edi, ReqOutPtr
   cmp     eax, VCOMPATAPI_ReportIRQDetection
   je      ReportIRQDetection
  Error:
   xor     eax, eax
   ret

   ; This function will get called by vSOUND, if an application seems to be
   ;  detecting IRQ.
  ReportIRQDetection:
   ; Give control to MagicVMP code
   push    ReqInPtr             ; Points to ClientRegisterFrame
   call    VCOMPAT_MagicVMPatcherInRM_IRQDetection
   add     esp, 4
   mov     eax, 1
   ret
VDDAPI                          EndP
