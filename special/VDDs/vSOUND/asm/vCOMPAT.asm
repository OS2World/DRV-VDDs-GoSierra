; vCOMPAT Reporting

;      From: VSOUND_RaiseDetectionVIRQ
;   Context: task
;  Function: Reports IRQ-Detection to vCOMPAT for further processing...
vCOMPAT_ReportIRQDetection      Proc Near   Uses eax, ClientRegisterFramePtr:dword
   mov     eax, VDDAPI_vCOMPAT
   or      eax, eax
   jz      SkipReport
   push    0
   push    VCOMPATAPI_ReportIRQDetection ; Function number
   push    ClientRegisterFramePtr
   push    0
   call    eax
  SkipReport:
   ret
vCOMPAT_ReportIRQDetection      EndP
