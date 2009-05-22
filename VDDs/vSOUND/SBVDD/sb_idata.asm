; Instance Data
InstanceData:
SBemulationSwitch            dd  0         ; Set to 1, if SB-emulation enabled

InVIRQDetection              dd  0         ; Set if Detection VIRQ duration
InVIRQDetectionCounter       dd  0         ; Counter for additional Det-VIRQ

SBreset                      db  0         ; Remembers Data written to ResetPort

; QUEUE-DATA
;============
;
; Queue begins at Offset 0 (is not a circular buffer in here)
; Read-Length is total Length of bytes in Read-Queue
; Write-Length is REQUIRED Length, till OpCode-Execute
;
; Specials on Read-Queue:  Pointer will stay at LAST byte
; Specials on Write-Queue: Command will be executed, when we got all bytes

; Read-Queue for INs at DSP-Read-Data-Port (22Ah)
SBreadQueue                  db 16 dup (0) ; Data-Queue for INs
SBreadLength                 dd  0         ; Total Bytes in ReadQueue
SBreadPos                    dd  0         ; Position in ReadQueue

; Write-Queue for OUTs on DSP-Write-Data-Port (22Ch)
SBwriteQueue:
SBopcode                     db  0
SBparameters                 db 15 dup (0) ; Data-Queue for OUTs
SBwriteLength                dd  0         ; Total Bytes in CommandQueue
SBwritePos                   dd  0         ; Position in ReadQueue

; Additional variables that define the Output-Stream for VDM_PlaybackBuffer
SBoutputRate                 dw  0         ; Current Sample-Rate of Output
SBoutputFlags                dw  0         ; Flags of Output
                                           ; Bit 0 - Normal   / Auto-Init
                                           ; Bit 1 - 8-Bit    / 16-Bit
                                           ; Bit 2 - Mono     / Stereo
                                           ; Bit 3 - Unsigned / Signed
SBoutputLength               dd  0         ; Length of Output

SBoutputDMAflipflop          dd  0         ; Flip-Flop...
SBoutputDMApos               dd  0         ; For faking DMA-CurPos

SBmixerRegister              dd  0         ; Current Mixer-Registers
SBmixerData                  db 256 dup (0) ; Mixer-Chip registers...

InstanceDataEnd:
