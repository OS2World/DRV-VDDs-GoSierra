
Public VDDAPI

; -----------------------------------------------------------------------------

; Is called, when another VDD calls VDHRequestVDD() on us
VDDAPI                          Proc Near PASCAL  Uses ebx ecx edx esi edi, VDMHandle:dword, CommandNo:dword, ReqInPtr:dword, ReqOutPtr:dword
   ; Now we will switch to the actual requested API
   mov     eax, CommandNo
   mov     esi, ReqInPtr
   mov     edi, ReqOutPtr
   cmp     eax, VDMA_GetVChannelInfo
   je      GetVChannelInfo
   cmp     eax, VDMAAPI_DetectReplacement
   je      DetectExtension
  Error:
   xor     eax, eax
   ret

  GetVChannelInfo:
   or      esi, esi                      ; ReqInPtr & ReqOutPtr have to be set
   jz      Error
   or      edi, edi
   jz      Error
   cmp     [esi+VDMA_GetVChannelInfoIN.Address], 0
   je      Error                         ; Check, if address got set...
   mov     ebx, [esi+VDMA_GetVChannelInfoIN.ChannelNo]
   cmp     ebx, 8                        ; Check, that ChannelNo is 0-7
   jae     Error
   shl     ebx, VDMAslot_LengthShift
   add     ebx, offset VDMA_VDMAslots
   mov     eax, [ebx+VDMAslotStruc.BaseAddress]
   mov     [edi+VDMA_GetVChannelInfoOUT.BaseAddress], eax
   mov     ax, wptr [ebx+VDMAslotStruc.TransferLeft]
; TODO: TransferLeft is BYTE size, we require DMA-size
   mov     [edi+VDMA_GetVChannelInfoOUT.ByteCount], ax
   movzx   ax, [ebx+VDMAslotStruc.Mode]
   shl     ax, 2                         ; Convert to DMA-mode
   mov     [edi+VDMA_GetVChannelInfoOUT.TransferMode], ax
   mov     eax, 1
   ret

  DetectExtension:
   ; Remembers ReqInPtr, afterwards one may register that handler with
   ;  VDHRegisterDMAChannel. Otherwise handler will get ignored.
   mov     VDMA_AllowedDMAOwnerFunc, esi
   mov     eax, 1
   ret
VDDAPI                          EndP
