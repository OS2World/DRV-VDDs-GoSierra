
Public CurVDMHandle
Public DebugFileHandle
Public PROPERTY_DEBUG
Public PROPERTY_HW_SOUND_PASSTHRU
Public PROPERTY_HW_SOUND_ON
Public PROPERTY_HW_SOUND_TYPE
Public PROPERTY_HW_SOUND_MIXER
Public TIMER_VIRQHandle
Public TRIGGER_VIRQTimerActive
Public VSOUND_OutputSampleRate
Public VSOUND_OutputNSPerSample
Public VSOUND_OutputFlags
Public VSOUND_OutputSize

; -----------------------------------------------------------------------------

VDD_InstanceData:
CurVDMHandle                    dd  ?       ; Current VDM Handle
DebugFileHandle                 dd  ?
PROPERTY_DEBUG                  dd  ?       ; Debug-Mode
PROPERTY_HW_SOUND_PASSTHRU      dd  ?       ; Pass-Thru mode
PROPERTY_HW_SOUND_ON            dd  ?       ; defines, if emulation active
PROPERTY_HW_SOUND_TYPE          dd  ?       ; defines, what type of soundblaster
PROPERTY_HW_SOUND_MIXER         dd  ?       ; defines, if we act on mixer changes

TIMER_VIRQHandle                dd  ?       ; TIMER-HOOK: VIRQ

TRIGGER_VIRQTimerActive         dd  ?       ; VIRQ-Timer-Hook armed?

PASSTHRU_SBInitiated            dd  ?       ; PASSTHRU: Soundblaster inited?

SBreset                         db  0       ; Remembers Data written to ResetPort
SBready                         db  ?       ; remembers ready bit

;------------------------------------------------------------------------------
; QUEUE-DATA
;============
; Queue begins at Offset 0 (is not a circular buffer in here)
; Read-Length is total Length of bytes in Read-Queue
; Write-Length is REQUIRED Length, till OpCode-Execute
;
; Specials on Read-Queue:  Pointer will stay at LAST byte
; Specials on Write-Queue: Command will be executed, when we got all bytes

; Read-Queue for INs at DSP-Read-Data-Port (22Ah)
SBreadQueue                  db 16 dup (?) ; Data-Queue for Port-INs
SBreadLength                 dd  0         ; Total Bytes in ReadQueue
SBreadPos                    dd  0         ; Position in ReadQueue

; Write-Queue for OUTs on DSP-Write-Data-Port (22Ch)
SBwriteQueue:
SBopcode                     db  0
SBparameters                 db 15 dup (0) ; Data-Queue for OUTs
SBwriteLength                dd  0         ; Total Bytes in CommandQueue
SBwritePos                   dd  0         ; Position in ReadQueue

; Mixer-Chip Register Area (224h/225h)
SBmixerRegister              dd  0         ; Current Mixer-Registers
SBmixerData                  db 256 dup (0) ; Mixer-Chip registers...

; Additional variables that define the Output-Stream for VDM_PlaybackBuffer
;  Those are generic, actual soundblaster hardware is quite tricky in that
;  respect!
VSOUND_OutputSampleRate      dw  0         ; Current Sample-Rate of Output
VSOUND_OutputNSPerSample     dw  0         ; Nano-Seconds per sample (256-divisor)
VSOUND_OutputFlags           dw  0         ; Flags of Output
                                           ; Bit 0 - Normal   / Auto-Init
                                           ; Bit 1 - 8-Bit    / 16-Bit
                                           ; Bit 2 - Mono     / Stereo
                                           ; Bit 3 - Unsigned / Signed
VSOUND_OutputSize            dd  0         ; Length of Output

VSOUNDoutput_Flags_AutoInit      equ 00000001b
VSOUNDoutput_Flags_16bit         equ 00000010b
VSOUNDoutput_Flags_Stereo        equ 00000100b
VSOUNDoutput_Flags_Signed        equ 00001000b

VDD_InstanceDataEnd:
