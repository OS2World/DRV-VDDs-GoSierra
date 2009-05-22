
Public VIRQ5Handle
Public VDDAPI_vCOMPAT

; -----------------------------------------------------------------------------

VIRQ5Handle                     dd  0       ; Handle for virtual IRQ5
VDDAPI_vCOMPAT                  dd  0       ; vCOMPAT entry point

RealSoundblasterVDMHandle       dd  0       ; VDMHandle of session that has
                                            ;  access to real soundblaster
                                            ;  HW_SOUND_PASSTHRU

; Mixer-Chip - All registers at Init-State (dumped from Original SB AWE 64)
;------------------------------------------------------------------------------
SBmixerChipDefaults:
db 0FFh,0FFh,0FFh,0FFh
db 0EEh      ; 04h     - Voice select (high nibble = left, low nibble = right)
db 0FFh,0FFh,0FFh,0FFh,0FFh
db 007h      ; 0Ah     - Microphone gain (bits 2-0 only)
db 0FFh,0FFh,0FFh
db 0FFh      ; 0Eh     - DMA transfer (bit 1 defines if stereo used)
db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
db 0EEh      ; 22h     - Master gain (high nibble = left, low nibble right)
db 0FFh,0FFh,0FFh
db 0EEh      ; 26h     - MIDI gain (high nibble = left, low nibble right)
db 0FFh
db 0EEh      ; 28h     - CD gain (high nibble = left, low nibble right)
db 0FFh,0FFh,0FFh,0FFh,0FFh
db 0EEh      ; 2Eh     - Line In (high nibble = left, low nibble = right)
db 0FFh
db 0E0h,0E0h ; 30h/31h - Volume Master Left/Right (bits 7-3) (-> REACTION!)
db 0E0h,0E0h ; 32h/33h - Volume Voice Left/Right (bits 7-3) (-> REACTION!)
db 0E0h,0E0h ; 34h/35h - Volume MIDI Left/Right (bits 7-3)
db 0E0h,0E0h ; 36h/37h - Volume CD Left/Right (bits 7-3)
db 0E0h,0E0h ; 38h/39h - Volume LineIn (bits 7-3)
db 0E0h      ; 3Ah     - Microphone gain (bits 7-3)
db 080h      ; 3Bh     - Volume PC Speaker (bits 7-3)
db 006h      ; 3Ch     - Sound output (bit-encoded)
db 055h,02Bh ; 3Dh/3Eh - Sound source Left/Right (bit-encoded)
             ;            Bit 7 - PC Speaker (not on sound output)
             ;            Bit 6 - MIDI left (not on sound output)
             ;            Bit 5 - MIDI right (not on sound output)
             ;            Bit 4 - LineIn left
             ;            Bit 3 - LineIn Right
             ;            Bit 2 - CD left
             ;            Bit 1 - CD right
             ;            Bit 0 - Microphone
db 040h      ; UNKNOWN
db 040h      ; 40h     - In Gain (bits 7-6 gain, 00=x1, 01=x2, 10=x4, 11=x8)
db 040h,040h ; 41h/42h - Out Gain Left/Right (bits 7-6)
db 000h      ; 43h     - Automatic gain control (bit 0 = enable)
db 0A0h,0A0h ; 44h/45h - Treble Left/Right (-> REACTION!)
db 0A0h,0A0h ; 46h/47h - Bass Left/Right (-> REACTION!)
db 01Fh,00Ch,000h,03Fh,0FFh,0FFh,0FFh,0FFh
db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
db 000h,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
db 0FFh,0FFh,0FFh,0FFh,0A2h,0FFh,0FFh,0FFh
db 0F2h     ; 80h      - IRQ of soundblaster
            ;             Value NOT -> interrupt number (13d/0Dh -> IRQ 5)
db 036h     ; 81h      - DMA of Soundblaster
            ;             Bit-Masked?!?! DMA 1 & DMA 5
db 070h     ; 82h      - IRQ Source register
            ;             Bit 0 - IRQ caused by 8-bit
            ;             Bit 1 - IRQ caused by 16-bit
            ;             Bit 2 - IRQ caused by MIDI
db 0FFh,0FFh,0FFh,0FFh,0FFh
db 0FCh,0E0h,0FCh,080h,078h,0CCh,0C0h,0FFh
db 0AAh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
db 0FFh,0FFh,0FFh,0FFh,0FFh,090h,011h,000h

; This tables gives conversion possibility between divisor rate and actual
;  sampling rate. Please note that sample rates over 44100 are turned down.
;  Actual divisor calculation: 256-(1000000/SampleRate)
SBSampleRates:
dw  3922,  3937,  3953,  3968,  3984,  4000,  4016,  4032,  4049,  4065 ;   0
dw  4082,  4098,  4115,  4132,  4149,  4167,  4184,  4202,  4219,  4237 ;  10
dw  4255,  4274,  4292,  4310,  4329,  4348,  4367,  4386,  4405,  4425 ;  20
dw  4444,  4464,  4484,  4505,  4525,  4545,  4566,  4587,  4608,  4630 ;  30
dw  4651,  4673,  4695,  4717,  4739,  4762,  4785,  4808,  4831,  4854 ;  40
dw  4878,  4902,  4926,  4950,  4975,  5000,  5025,  5051,  5076,  5102 ;  50
dw  5128,  5155,  5181,  5208,  5236,  5263,  5291,  5319,  5348,  5376 ;  60
dw  5405,  5435,  5464,  5495,  5525,  5556,  5587,  5618,  5650,  5682 ;  70
dw  5714,  5747,  5780,  5814,  5848,  5882,  5917,  5952,  5988,  6024 ;  80
dw  6061,  6098,  6135,  6173,  6211,  6250,  6289,  6329,  6369,  6410 ;  90
dw  6452,  6494,  6536,  6579,  6623,  6667,  6711,  6757,  6803,  6849 ; 100
dw  6897,  6944,  6993,  7042,  7092,  7143,  7194,  7246,  7299,  7353 ; 110
dw  7407,  7463,  7519,  7576,  7634,  7692,  7752,  7812,  7874,  7937 ; 120
dw  8000,  8065,  8130,  8197,  8264,  8333,  8403,  8475,  8547,  8621 ; 130
dw  8696,  8772,  8850,  8929,  9009,  9091,  9174,  9259,  9346,  9434 ; 140
dw  9524,  9615,  9709,  9804,  9901, 10000, 10101, 10204, 10309, 10417 ; 150
dw 10526, 10638, 10753, 10870, 10989, 11111, 11236, 11364, 11494, 11628 ; 160
dw 11765, 11905, 12048, 12195, 12346, 12500, 12658, 12821, 12987, 13158 ; 170
dw 13333, 13514, 13699, 13889, 14085, 14286, 14493, 14706, 14925, 15152 ; 180
dw 15385, 15625, 15873, 16129, 16393, 16667, 16949, 17241, 17544, 17857 ; 190
dw 18182, 18519, 18868, 19231, 19608, 20000, 20408, 20833, 21277, 21739 ; 200
dw 22222, 22727, 23256, 23810, 24390, 25000, 25641, 26316, 27027, 27778 ; 210
dw 28571, 29412, 30303, 31250, 32258, 33333, 34483, 35714, 37037, 38462 ; 220
dw 40000, 41667, 43478, 44100, 44100, 44100, 44100, 44100, 44100, 44100 ; 230
dw 44100, 44100, 44100, 44100, 44100, 44100, 44100, 44100, 44100, 44100 ; 240
dw 44100, 44100, 44100, 44100, 44100, 44100                             ; 250
