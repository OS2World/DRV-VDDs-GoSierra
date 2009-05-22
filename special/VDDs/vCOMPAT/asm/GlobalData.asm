
; vCOMPAT is for OS/2 only */
;  You may not reuse this source or parts of this source in any way and/or
;  (re)compile it for a different platform without the allowance of
;  kiewitz@netlabs.org. It's (c) Copyright by Martin Kiewitz.

Public OrgINT31RouterPtr
Public OrgINT31CreateTaskPtr
Public OrgINT31EndTaskPtr
Public OrgINT31QueryPtr
Public TRIGGER_VCDROMReplacement
Public TRIGGER_VSOUNDFound
Public TRIGGER_VDPMIHooked

; -----------------------------------------------------------------------------

OrgINT31RouterPtr               dd  0       ; Original INT31h DPMI Router
OrgINT31CreateTaskPtr           dd  0
OrgINT31EndTaskPtr              dd  0
OrgINT31QueryPtr                dd  0

TRIGGER_VCDROMReplacement       dd  0       ; is set, if new vCDROM detected
TRIGGER_VSOUNDFound             dd  0       ; is set, if vSOUND found
TRIGGER_VDPMIHooked             dd  0       ; is set, if vDPMI got hooked
