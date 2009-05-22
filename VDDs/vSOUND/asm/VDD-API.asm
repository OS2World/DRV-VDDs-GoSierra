
Public VDDAPI

; -----------------------------------------------------------------------------

; Is called, when another VDD calls VDHRequestVDD() on us
VDDAPI                          Proc Near PASCAL  Uses ebx ecx edx esi edi, VDMHandle:dword, CommandNo:dword, ReqInPtr:dword, ReqOutPtr:dword
   ; Now we will switch to the actual requested API
   mov     eax, CommandNo
   mov     esi, ReqInPtr
   mov     edi, ReqOutPtr
   cmp     eax, VSOUNDAPI_SetVCOMPATEntry
   je      SetVCOMPATEntry
  Error:
   xor     eax, eax
   ret

   ; This function will set the vCOMPAT-API entry point, so we are able to
   ;  report IRQ Detection to vCOMPAT.
  SetVCOMPATEntry:
   or      esi, esi                                    ; ReqInPtr has to be set
   jz      Error
   mov     VDDAPI_vCOMPAT, esi
   mov     eax, 1
   ret
VDDAPI                          EndP
