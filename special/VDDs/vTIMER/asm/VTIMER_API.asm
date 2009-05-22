
Public VTIMER_VDDAPI

; -----------------------------------------------------------------------------

; Is called, when another VDD calls VDHRequestVDD() on VTIMER-Handle
VTIMER_VDDAPI                   Proc Near PASCAL, VDMHandle:dword, CommandNo:dword, ReqInPtr:dword, ReqOutPtr:dword
   ; Now we will switch to the actual requested API
   mov     eax, CommandNo
   cmp     eax, 1
   jb      GetVDDHandler
   je      EnableVDMACallOut
   cmp     eax, 3
   jb      DisableVDMACallOut
   je      SeamlessNotificationFromVWIN
   cmp     eax, VTIMER_DetectReplacement
   je      ReplacementCheck
  Error:
   xor     eax, eax
   ret

  GetVDDHandler:
   mov     eax, ReqOutPtr
   mov     dptr [eax], offset VTIMER_VDDAPI
   mov     eax, 1
   ret

  EnableVDMACallOut:
   mov     eax, 1
   ret

  DisableVDMACallOut:
   mov     eax, 1
   ret

  SeamlessNotificationFromVWIN:
   ;  Supposingly unfreeze VDM, if previously frozen
   ;  Also remember and never freeze this VDM again
   xor     eax, eax
   ret

  ReplacementCheck:
   mov     eax, 1
   ret
VTIMER_VDDAPI                   EndP
