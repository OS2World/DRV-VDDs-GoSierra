Hook for Turbo Pascal:
=======================

AX = FB43h
BX = 0100h
INT 2Fh -> Borland TP TPD Hook

Search for Selector of that call, search for patch match <4-5 Selectors


 mov  ebx , cr0  ; get Cr0 regiter
   push ebx        ; save it
   and ebx , ~0x10000 ;clear WP bit
   mov cr0 , ebx  ; efectivly disable write protection
   ; your patch code here ....
  pop ebx          ;restore it
  mov cr0 , ebx    ; enable previous CPU state.


AX - 0501h - Allocate Memory Block
BX:CX - Size
-> BX:CX - Linear Address
-> SI:DI - Block Handle

AX - 0502h - Free Block
SI:DI - Block Handle

AX - 0503h - Resize Block
BX:CX - new size
SI:DI - Block Handle
-> BX:CX - new linear address
-> SI:DI - new block handle

;         movzx   eax, [esi+SelectorTableStruc.SelectorNo]
;         push    eax
;            push    eax
;            push    offset TempDWord
;            call    VDHGetSelBase
;         pop     eax
;         lsl     ecx, eax
;         mov     edi, TempDWord
