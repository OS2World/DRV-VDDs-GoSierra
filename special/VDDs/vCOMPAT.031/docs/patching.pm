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


typedef struct crf_s {
        ULONG crf_edi;
        ULONG crf_esi;
        ULONG crf_ebp;
        ULONG crf_padesp;
        ULONG crf_ebx;
        ULONG crf_edx;
        ULONG crf_ecx;
        ULONG crf_eax;
        ULONG crf_pad2[2];
        ULONG crf_eip;
        USHORT crf_cs;
        USHORT crf_padcs;
        ULONG crf_eflag;
        ULONG crf_esp;
        USHORT crf_ss;
        USHORT crf_padss;
        USHORT crf_es;
        USHORT crf_pades;
        USHORT crf_ds;
        USHORT crf_padds;
        USHORT crf_fs;
        USHORT crf_padfs;
        USHORT crf_gs;
        USHORT crf_padgs;
        ULONG crf_alteip;               /* other modes register set */
        USHORT crf_altcs;
        USHORT crf_altpadcs;
        ULONG crf_alteflag;
        ULONG crf_altesp;
        USHORT crf_altss;
        USHORT crf_altpadss;
        USHORT crf_altes;
        USHORT crf_altpades;
        USHORT crf_altds;
        USHORT crf_altpadds;
        USHORT crf_altfs;
        USHORT crf_altpadfs;
        USHORT crf_altgs;
        USHORT crf_altpadgs;
} CRF;


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
