
Public VDDAPI

; -----------------------------------------------------------------------------

; Is called, when another VDD calls VDHRequestVDD() on us
VDDAPI                          Proc Near PASCAL  Uses ebx ecx edx, VDMHandle:dword, CommandNo:dword, ReqInPtr:dword, ReqOutPtr:dword
   ; Now we will switch to the actual requested API
   mov     eax, CommandNo
   cmp     eax, VCDROMAPI_DetectReplacement
   je      ReplacementCheck
  Error:
   xor     eax, eax
   ret

  ReplacementCheck:
   mov     eax, 1
   ret
VDDAPI                          EndP
