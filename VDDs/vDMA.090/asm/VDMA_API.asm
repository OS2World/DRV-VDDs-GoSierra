
Public VDMA_VDDAPI

; -----------------------------------------------------------------------------

; Is called, when another VDD calls VDHRequestVDD() on VDMA-Handle
VDMA_VDDAPI                     Proc Near PASCAL  Uses ebx ecx edx esi edi, VDMHandle:dword, CommandNo:dword, ReqInPtr:dword, ReqOutPtr:dword
   ; Now we will switch to the actual requested API
   mov     eax, CommandNo
   mov     esi, ReqInPtr
   mov     edi, ReqOutPtr
   cmp     eax, VDMA_GetVChannelInfo
   je      GetVChannelInfo
   cmp     eax, VDMAX_DetectExtension
   je      DetectExtension
   cmp     eax, VDMAX_InstallTimedHook
   je      InstallTimedHook
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
   mov     ax, [ebx+VDMAslotStruc.CurLength]
   mov     [edi+VDMA_GetVChannelInfoOUT.ByteCount], ax
   movzx   ax, [ebx+VDMAslotStruc.Mode]
   shl     ax, 2                         ; Convert to DMA-mode
   mov     [edi+VDMA_GetVChannelInfoOUT.TransferMode], ax
   mov     eax, 1
   ret

  DetectExtension:
   mov     eax, 1
   ret

  InstallTimedHook:
   xor     eax, eax
   ret

;   or      esi, esi                      ; We need ReqInPtr here...
;   jz      Error
;   int 3
;   mov     ecx, VDMA_ForeignTimedHooks
;   mov     eax, [esi+VDMAX_InstallTimedHookIN.Duration]
;   mov     ebx, [esi+VDMAX_InstallTimedHookIN.CodePtr]
;   mov     edi, offset VDMA_TimedHooks
;
;   mov     [edi+TimedCallBackHookStruc.Duration], eax
;   mov     [edi+TimedCallBackHookStruc.CurCountdown], eax
;   mov     [edi+TimedCallBackHookStruc.CodePtr], ebx
;   cmp     VDMA_ForeignTimedHooks, 1
;   je      Done
;   mov     VDMA_ForeignTimedHooks, 1
;   inc     VDMA_TimedCallBacks
;   cmp     VDMA_TimedCallBacks, 1
;   jne     Done
;   call    PDMA_StartVTIMERCallOut
;  Done:
;   ret
VDMA_VDDAPI                     EndP
