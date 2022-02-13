                      ORG $008000

I_RESET:              SEI                                       ; Disable interrupts
                      STZ.W HW_NMITIMEN                         ; Clear NMI and V/H Count, disable joypad
                      STZ.W HW_HDMAEN                           ; Disable HDMA
                      STZ.W HW_MDMAEN                           ; Disable DMA
                      STZ.W HW_APUIO0                           ; \
                      STZ.W HW_APUIO1                           ; |Clear APU I/O ports 1-4
                      STZ.W HW_APUIO2                           ; |
                      STZ.W HW_APUIO3                           ; /
                      LDA.B #$80                                ; \ Turn off screen
                      STA.W HW_INIDISP                          ; /
                      CLC                                       ; \ Turn off emulation mode
                      XCE                                       ; /
                      REP #$38                                  ; AXY->16, Decimal mode off
                      LDA.W #$0000                              ; \ Set direct page
                      TCD                                       ; /
                      LDA.W #$01FF                              ; \ Set stack location
                      TCS                                       ; /
                      LDA.W #$F0A9                              ; \ LDA.B #$F0
                      STA.L OAMResetRoutine                     ; |
                      LDX.W #$017D                              ; |
                      LDY.W #$03FD                              ; | $03FD (OAM)
                    - LDA.W #$008D                              ; | STA.W $addr
                      STA.L OAMResetRoutine+2,X                 ; |
                      TYA                                       ; |
                      STA.L OAMResetRoutine+3,X                 ; |Create routine in RAM
                      SEC                                       ; |
                      SBC.W #$0004                              ; |
                      TAY                                       ; |
                      DEX                                       ; |
                      DEX                                       ; |
                      DEX                                       ; |
                      BPL -                                     ; |
                      SEP #$30                                  ; | AXY->8
                      LDA.B #$6B                                ; | RTL
                      STA.L OAMResetRoutine+$182                ; /
                      JSR UploadSPCEngine                       ; SPC700 Bank 02 + Main code upload handler
                      STZ.W GameMode                            ; Set game mode to 0
                      STZ.W OverworldOverride                   ; Set secondary game mode to 0
                      JSR ClearStack
                      JSR UploadSamples
                      JSR CODE_009250
                      LDA.B #$03                                ; \ Set OAM Size and Data Area Designation to x03
                      STA.W HW_OBJSEL                           ; /
                      INC.B LagFlag                             ; Skip the following loop
                    - LDA.B LagFlag                             ; |Loop until the interrupt routine sets $10
                      BEQ -                                     ; / to a non-zero value.
                      CLI                                       ; Enable interrupts
                      INC.B TrueFrame                           ; Increase frame number
                      JSR GetGameMode                           ; The actual game
                      STZ.B LagFlag                             ; \ Wait for interrupt
                      BRA -                                     ; /

SPC700UploadLoop:     PHP
                      REP #$30                                  ; AXY->16
                      LDY.W #$0000
                      LDA.W #$BBAA
                    - CMP.W HW_APUIO0
                      BNE -
                      SEP #$20                                  ; A->8
                      LDA.B #$CC                                ; Load byte to start transfer
                      BRA CODE_0080B3

CODE_00808D:          LDA.B [_0],Y
                      INY
                      XBA
                      LDA.B #$00
                      BRA CODE_0080A0

CODE_008095:          XBA
                      LDA.B [_0],Y
                      INY
                      XBA
                    - CMP.W HW_APUIO0
                      BNE -
                      INC A
CODE_0080A0:          REP #$20                                  ; A->16
                      STA.W HW_APUIO0
                      SEP #$20                                  ; A->8
                      DEX
                      BNE CODE_008095
                    - CMP.W HW_APUIO0
                      BNE -
                    - ADC.B #$03
                      BEQ -
CODE_0080B3:          PHA
                      REP #$20                                  ; A->16
                      LDA.B [_0],Y
                      INY
                      INY
                      TAX
                      LDA.B [_0],Y
                      INY
                      INY
                      STA.W HW_APUIO2
                      SEP #$20                                  ; A->8
                      CPX.W #$0001
                      LDA.B #$00
                      ROL A
                      STA.W HW_APUIO1
                      ADC.B #$7F
                      PLA
                      STA.W HW_APUIO0
                    - CMP.W HW_APUIO0
                      BNE -
                      BVS CODE_00808D
                      STZ.W HW_APUIO0
                      STZ.W HW_APUIO1
                      STZ.W HW_APUIO2
                      STZ.W HW_APUIO3
                      PLP
                      RTS

UploadSPCEngine:      LDA.B #SPC700Engine                       ; \ this address (0E:8000) is the start of the SPC engine
                      %BorW(STA, _0)                            ; | instrument settings/sound effect data
                      LDA.B #SPC700Engine>>8                    ; | AND the code used for all music banks.
                      %BorW(STA, _1)                            ; |
                      LDA.B #SPC700Engine>>16                   ; |
                      %BorW(STA, _2)                            ; /
UploadDataToSPC:      SEI
                      JSR SPC700UploadLoop
                      CLI
                      RTS

UploadSamples:        LDA.B #MusicSamples                       ; \
                      %BorW(STA, _0)                            ; |
                      LDA.B #MusicSamples>>8                    ; |Loads The Address 0F:8000 to 00-02 (SAMPLE DATA + PTRS)
                      %BorW(STA, _1)                            ; |[SPC Sample Pointers/Data ROM Address, this is]
                      LDA.B #MusicSamples>>16                   ; |
                      %BorW(STA, _2)                            ; /
                      BRA StrtSPCMscUpld

UploadMusicBank1:     LDA.B #MusicBank1                         ; \
                      %BorW(STA, _0)                            ; |
                      LDA.B #MusicBank1>>8                      ; |Loads the Bank 1 music data (Map) to 00-02
                      %BorW(STA, _1)                            ; | ($0E:98B1)
                      LDA.B #MusicBank1>>16                     ; |
                      %BorW(STA, _2)                            ; /
StrtSPCMscUpld:       LDA.B #$FF
                      STA.W HW_APUIO1
                      JSR UploadDataToSPC
                      LDX.B #$03
                    - STZ.W HW_APUIO0,X
                      STZ.W SPCIO0,X
                      STZ.W Empty1DFD,X
                      DEX
                      BPL -
Return008133:         RTS

CODE_008134:          LDA.W BonusGameActivate
                      BNE UploadMusicBank2
                      LDA.W OverworldOverride
                      CMP.B #$E9
                      BEQ UploadMusicBank2
                      ORA.W SublevelCount
                      ORA.W ShowMarioStart
                      BNE Return008133
UploadMusicBank2:     LDA.B #MusicBank2                         ; \
                      %BorW(STA, _0)                            ; |Loads the Bank 2 music address(Levels)
                      LDA.B #MusicBank2>>8                      ; | (0E:AED6)
                      %BorW(STA, _1)                            ; |
                      LDA.B #MusicBank2>>16                     ; |
                      %BorW(STA, _2)                            ; /
                      BRA StrtSPCMscUpld

UploadMusicBank3:     LDA.B #MusicBank3                         ; \
                      %BorW(STA, _0)                            ; |Bank 3 music(Ending) ROM address
                      LDA.B #MusicBank3>>8                      ; |
                      %BorW(STA, _1)                            ; | ($03:E400)
                      LDA.B #MusicBank3>>16                     ; |
                      %BorW(STA, _2)                            ; /
                      BRA StrtSPCMscUpld


I_NMI:                SEI                                       ; Looks like this might be the NMI routine here. That is correct.
                      PHP                                       ; I thought it was, just from the address, but I wasn't too sure.
                      REP #$30                                  ; AXY->16
                      PHA
                      PHX
                      PHY
                      PHB
                      PHK
                      PLB
                      SEP #$30                                  ; AXY->8
                      LDA.W HW_RDNMI                            ; Load "NMI Enable."  This has the effect of clearing the Interrupt, so that ; NMI Enable
                      LDA.W SPCIO2                              ; \
                      BNE CODE_008186                           ; |
                      LDY.W HW_APUIO2                           ; |
                      CPY.W LastUsedMusic                       ; |Update SPC700 I/O port 2
                      BNE +                                     ; |
CODE_008186:          STA.W HW_APUIO2                           ; |
                      STA.W LastUsedMusic                       ; |
                      STZ.W SPCIO2                              ; |
                    + LDA.W SPCIO0                              ; \
                      STA.W HW_APUIO0                           ; |
                      LDA.W SPCIO1                              ; |
                      STA.W HW_APUIO1                           ; |Update SPC700 I/O ports 0, 1 and 3
                      LDA.W SPCIO3                              ; |
                      STA.W HW_APUIO3                           ; |
                      STZ.W SPCIO0                              ; |
                      STZ.W SPCIO1                              ; |
                      STZ.W SPCIO3                              ; /
                      LDA.B #$80                                ; \ Screen off, brightness=0
                      STA.W HW_INIDISP                          ; /
                      STZ.W HW_HDMAEN                           ; Zero The HDMA reg
                      LDA.B Layer12Window
                      STA.W HW_W12SEL
                      LDA.B Layer34Window
                      STA.W HW_W34SEL
                      LDA.B OBJCWWindow
                      STA.W HW_WOBJSEL
                      LDA.B ColorAddition
                      STA.W HW_CGSWSEL
                      LDA.W IRQNMICommand                       ; \
                      BPL +                                     ; |If in a "Special level",
                      JMP CODE_0082C4                           ; |jump to $82C4

                    + LDA.B ColorSettings                       ; \ Get the CGADSUB byte...
                      AND.B #$FB                                ; |Get the Add/Subtract Select and Enable part...
                      STA.W HW_CGADSUB                          ; / ...and store it to the A/SSaE register...
                      LDA.B #$09                                ; \ 8x8 tiles, Graphics mode 1
                      STA.W HW_BGMODE                           ; /
                      LDA.B LagFlag                             ; \ If there isn't any lag,
                      BEQ CODE_0081E7                           ; / branch to $81E7
                      LDA.W IRQNMICommand                       ; \
                      LSR A                                     ; |If not on a special level, branch to NMINotSpecialLv
                      BEQ NMINotSpecialLv                       ; /
                      JMP CODE_00827A

CODE_0081E7:          INC.B LagFlag
                      JSR CODE_00A488
                      LDA.W IRQNMICommand
                      LSR A
                      BNE CODE_008222
                      BCS +
                      JSR DrawStatusBar
                    + LDA.W CutsceneID                          ; \
                      CMP.B #$08                                ; |If the current cutscene isn't the ending,
                      BNE CODE_008209                           ; / branch to $8209
                      LDA.W CreditsUpdateBG                     ; \
                      BEQ CODE_00821A                           ; |Related to reloading the palettes when switching
                      JSL CODE_0C9567                           ; |to another background during the credits.
                      BRA CODE_00821A                           ; /

CODE_008209:          JSL CODE_0087AD
                      LDA.W UploadMarioStart
                      BEQ CODE_008217
                      JSR CODE_00A7C2
                      BRA CODE_00823D

CODE_008217:          JSR CODE_00A390
CODE_00821A:          JSR CODE_00A436
                      JSR MarioGFXDMA
                      BRA CODE_00823D

CODE_008222:          LDA.W OverworldProcess
                      CMP.B #$0A
                      BNE CODE_008237
                      LDY.W OWSubmapSwapProcess
                      DEY
                      DEY
                      CPY.B #$04
                      BCS CODE_008237
                      JSR CODE_00A529
                      BRA +

CODE_008237:          JSR CODE_00A4E3
                      JSR MarioGFXDMA
CODE_00823D:          JSR LoadScrnImage
                      JSR DoSomeSpriteDMA
                    + JSR ControllerUpdate
NMINotSpecialLv:      LDA.B Layer1XPos                          ; \
                      STA.W HW_BG1HOFS                          ; |Set BG 1 Horizontal Scroll Offset
                      LDA.B Layer1XPos+1                        ; |to X position of screen boundry
                      STA.W HW_BG1HOFS                          ; /
                      LDA.B Layer1YPos                          ; \
                      CLC                                       ; |
                      ADC.W ScreenShakeYOffset                  ; |Set BG 1 Vertical Scroll Offset
                      STA.W HW_BG1VOFS                          ; |to Y position of screen boundry + Layer 1 disposition
                      LDA.B Layer1YPos+1                        ; |
                      ADC.W ScreenShakeYOffset+1                ; |
                      STA.W HW_BG1VOFS                          ; /
                      LDA.B Layer2XPos                          ; \
                      STA.W HW_BG2HOFS                          ; |Set BG 2 Horizontal Scroll Offset
                      LDA.B Layer2XPos+1                        ; |to X position of Layer 2
                      STA.W HW_BG2HOFS                          ; /
                      LDA.B Layer2YPos                          ; \
                      STA.W HW_BG2VOFS                          ; |Set BG 2 Vertical Scroll Offset
                      LDA.B Layer2YPos+1                        ; |to Y position of Layer 2
                      STA.W HW_BG2VOFS                          ; /
                      LDA.W IRQNMICommand                       ; \ If in a normal (not special) level, branch
                      BEQ CODE_008292                           ; /
CODE_00827A:          LDA.B #$81
                      LDY.W CutsceneID                          ; \
                      CPY.B #$08                                ; |If not playing ending movie, branch to $82A1
                      BNE +                                     ; /
                      LDY.W Brightness                          ; \
                      STY.W HW_INIDISP                          ; / Set brightness to $0DAE
                      LDY.W HDMAEnable                          ; \
                      STY.W HW_HDMAEN                           ; / Set HDMA channel enable to $0D9F
                      JMP IRQNMIEnding

CODE_008292:          LDY.B #$24                                ; \  ; IRQ timer, at which scanline the IRQ will be fired.
CODE_008294:          LDA.W HW_TIMEUP                           ; |(i.e. below the status bar)
                      STY.W HW_VTIME                            ; |
                      STZ.W HW_VTIME+1                          ; /
                      STZ.B IRQType
                      LDA.B #$A1
                    + STA.W HW_NMITIMEN
                      STZ.W HW_BG3HOFS                          ; \
                      STZ.W HW_BG3HOFS                          ; |Set Layer 3 horizontal and vertical
                      STZ.W HW_BG3VOFS                          ; |scroll to x00
                      STZ.W HW_BG3VOFS                          ; /
                      LDA.W Brightness                          ; \
                      STA.W HW_INIDISP                          ; / Set brightness to $0DAE
                      LDA.W HDMAEnable                          ; \
                      STA.W HW_HDMAEN                           ; / Set HDMA channel enable to $0D9F
                      REP #$30                                  ; AXY->16
                      PLB                                       ; \ Pull all
                      PLY                                       ; |
                      PLX                                       ; |
                      PLA                                       ; |
                      PLP                                       ; /
I_EMPTY:              RTI                                       ; And return

CODE_0082C4:          LDA.B LagFlag                             ; \ If there is lag,
                      BNE CODE_0082F7                           ; / branch to $82F7
                      INC.B LagFlag
                      LDA.W UploadMarioStart                    ; \ If Mario Start! graphics shouldn't be loaded,
                      BEQ CODE_0082D4                           ; / branch to $82D4
                      JSR CODE_00A7C2
                      BRA CODE_0082E8

CODE_0082D4:          JSR CODE_00A436
                      JSR MarioGFXDMA
                      BIT.W IRQNMICommand
                      BVC CODE_0082E8
                      JSR CODE_0098A9
                      LDA.W IRQNMICommand
                      LSR A
                      BCS +
CODE_0082E8:          JSR DrawStatusBar
                    + JSR CODE_00A488
                      JSR LoadScrnImage
                      JSR DoSomeSpriteDMA
                      JSR ControllerUpdate
CODE_0082F7:          LDA.B #$09
                      STA.W HW_BGMODE
                      LDA.B Mode7CenterX
                      CLC
                      ADC.B #$80
                      STA.W HW_M7X
                      LDA.B Mode7CenterX+1
                      ADC.B #$00
                      STA.W HW_M7X
                      LDA.B Mode7CenterY
                      CLC
                      ADC.B #$80
                      STA.W HW_M7Y
                      LDA.B Mode7CenterY+1
                      ADC.B #$00
                      STA.W HW_M7Y
                      LDA.B Mode7ParamA
                      STA.W HW_M7A
                      LDA.B Mode7ParamA+1
                      STA.W HW_M7A
                      LDA.B Mode7ParamB
                      STA.W HW_M7B
                      LDA.B Mode7ParamB+1
                      STA.W HW_M7B
                      LDA.B Mode7ParamC
                      STA.W HW_M7C
                      LDA.B Mode7ParamC+1
                      STA.W HW_M7C
                      LDA.B Mode7ParamD
                      STA.W HW_M7D
                      LDA.B Mode7ParamD+1
                      STA.W HW_M7D
                      JSR SETL1SCROLL
                      LDA.W IRQNMICommand
                      LSR A
                      BCC +
                      LDA.W Brightness
                      STA.W HW_INIDISP
                      LDA.W HDMAEnable
                      STA.W HW_HDMAEN
                      LDA.B #$81
                      JMP CODE_0083F3

                    + LDY.B #$24
                      BIT.W IRQNMICommand
                      BVC +
                      LDA.W ActiveBoss
                      ASL A
                      TAX
                      LDA.W DATA_00F8E8,X
                      CMP.B #$2A
                      BNE +
                      LDY.B #$2D
                    + JMP CODE_008294

I_IRQ:                SEI                                       ; Set Interrupt flag so routine can start
                      PHP                                       ; \ Save A/X/Y/P/B
                      REP #$30                                  ; | AXY->16
                      PHA                                       ; |
                      PHX                                       ; |
                      PHY                                       ; |
                      PHB                                       ; |
                      PHK                                       ; |
                      PLB                                       ; / Set B to $00
                      SEP #$30                                  ; AXY->8
                      LDA.W HW_TIMEUP                           ; Read the IRQ register, 'unapply' the interrupt
                      BPL CODE_0083B2                           ; If "Timer IRQ" is clear, skip the next code block
                      LDA.B #$81
                      LDY.W IRQNMICommand
                      BMI +                                     ; If Bit 7 (negative flag) is set, branch to a different IRQ mode
IRQNMIEnding:         STA.W HW_NMITIMEN                         ; Enable NMI Interrupt and Automatic Joypad reading
                      LDY.B #$1F
                      JSR WaitForHBlank
                      LDA.B Layer3XPos                          ; \ Adjust scroll settings for layer 3
                      STA.W HW_BG3HOFS                          ; |
                      LDA.B Layer3XPos+1                        ; |
                      STA.W HW_BG3HOFS                          ; |
                      LDA.B Layer3YPos                          ; |
                      STA.W HW_BG3VOFS                          ; |
                      LDA.B Layer3YPos+1                        ; |
                      STA.W HW_BG3VOFS                          ; /
CODE_0083A8:          LDA.B MainBGMode                          ; \Set the layer BG sizes, L3 priority, and BG mode
                      STA.W HW_BGMODE                           ; /(Effectively, this is the screen mode)
                      LDA.B ColorSettings                       ; \Write CGADSUB
                      STA.W HW_CGADSUB                          ; /
CODE_0083B2:          REP #$30                                  ; AXY->16
                      PLB                                       ; \ Pull everything back
                      PLY                                       ; |
                      PLX                                       ; |
                      PLA                                       ; |
                      PLP                                       ; /
                      RTI                                       ; And Return

                    + BIT.W IRQNMICommand                       ; Get bit 6 of $0D9B
                      BVC CODE_0083E3                           ; If clear, skip the next code section
                      LDY.B IRQType                             ; \Skip if $11 = 0
                      BEQ CODE_0083D0                           ; /
                      STA.W HW_NMITIMEN                         ; #$81 -> NMI / Controller Enable reg
                      LDY.B #$14
                      JSR WaitForHBlank
                      JSR SETL1SCROLL
                      BRA CODE_0083A8

CODE_0083D0:          INC.B IRQType                             ; $11++
                      LDA.W HW_TIMEUP                           ; \ Set up the IRQ routine for layer 3
                      LDA.B #$AE                                ; |-\
                      SEC                                       ; |  |Vertical Counter trigger at 174 - $1888
                      SBC.W ScreenShakeYOffset                  ; |-/ Oddly enough, $1888 seems to be 16-bit, but the
                      STA.W HW_VTIME                            ; |Store to Vertical Counter Timer
                      STZ.W HW_VTIME+1                          ; / Make the high byte of said timer 0
                      LDA.B #$A1                                ; A = NMI enable, V count enable, joypad automatic read enable, H count disable
CODE_0083E3:          LDY.W EndLevelTimer                       ; if $1493 = 0 skip down
                      BEQ CODE_0083F3
                      LDY.W ColorFadeTimer                      ; \ If $1495 is <#$40
                      CPY.B #$40                                ; |
                      BCC CODE_0083F3                           ; / Skip down
                      LDA.B #$81
                      BRA IRQNMIEnding                          ; Jump up to IRQNMIEnding

CODE_0083F3:          STA.W HW_NMITIMEN                         ; A -> NMI/Joypad Auto-Read/HV-Count Control Register
                      JSR CODE_008439
                      NOP                                       ; \Not often you see NOP, I think there was a JSL here at one point maybe
                      NOP                                       ; /
                      LDA.B #$07                                ; \Write Screen register
                      STA.W HW_BGMODE                           ; /
                      LDA.B Mode7XPos                           ; \ Write L1 Horizontal scroll
                      STA.W HW_BG1HOFS                          ; |
                      LDA.B Mode7XPos+1                         ; |
                      STA.W HW_BG1HOFS                          ; /
                      LDA.B Mode7YPos                           ; \ Write L1 Vertical Scroll
                      STA.W HW_BG1VOFS                          ; |
                      LDA.B Mode7YPos+1                         ; |
                      STA.W HW_BG1VOFS                          ; /
                      BRA CODE_0083B2                           ; And exit IRQ

SETL1SCROLL:          LDA.B #$59                                ; \
                      STA.W HW_BG1SC                            ; /Write L1 GFX source address
                      LDA.B #$07                                ; \Write L1/L2 Tilemap address
                      STA.W HW_BG12NBA                          ; /
                      LDA.B Layer1XPos                          ; \ Write L1 Horizontal scroll
                      STA.W HW_BG1HOFS                          ; |
                      LDA.B Layer1XPos+1                        ; |
                      STA.W HW_BG1HOFS                          ; /
                      LDA.B Layer1YPos                          ; \ $1C + $1888 -> L1 Vert scroll
                      CLC                                       ; |$1888 = Some sort of vertioffset
                      ADC.W ScreenShakeYOffset                  ; |
                      STA.W HW_BG1VOFS                          ; /
                      LDA.B Layer1YPos+1                        ; \Other half of L1 vert scroll
                      STA.W HW_BG1VOFS                          ; /
                      RTS

CODE_008439:          LDY.B #$20                                ; <<- Could this be just to waste time?
WaitForHBlank:        BIT.W HW_HVBJOY                           ; So... LDY gets set with 20 if there is a H-Blank...?
                      BVS CODE_008439                           ; if in H-Blank, make Y #$20 and try again
                    - BIT.W HW_HVBJOY                           ; Now wait until not in H-Blank
                      BVC -
                    - DEY                                       ; |Y = 0
                      BNE -                                     ; / ...wait a second... why didn't they just do LDY #$00? ...waste more time?
                      RTS

DoSomeSpriteDMA:      STZ.W HW_DMAPARAM
                      REP #$20                                  ; A->16
                      STZ.W HW_OAMADD                           ; OAM address
                      LDA.W #$0004
                      STA.W HW_DMAREG                           ; Dest. address = $2104 (data write to OAM)
                      LDA.W #OAMTileXPos>>8&$FF
                      STA.W HW_DMAADDR+1                        ; Source address = $00:0200
                      LDA.W #$0220
                      STA.W HW_DMACNT                           ; $0220 bytes to transfer
                      LDY.B #$01
                      STY.W HW_MDMAEN                           ; Start DMA
                      SEP #$20                                  ; A->8
                      LDA.B #$80                                ; \
                      STA.W HW_OAMADD+1                         ; |
                      LDA.B OAMAddress                          ; |Change the OAM read/write address to #$8000 + $3F
                      STA.W HW_OAMADD                           ; /
                      RTS


DATA_008475:          dw $0000,$0008,$0010,$0018
                      dw $0020,$0028,$0030,$0038
                      dw $0040,$0048,$0050,$0058
                      dw $0060,$0068,$0070
                      db $78

CODE_008494:          LDY.B #$1E
                    - LDX.W DATA_008475,Y
                      LDA.W OAMTileSize+3,X
                      ASL A
                      ASL A
                      ORA.W OAMTileSize+2,X
                      ASL A
                      ASL A
                      ORA.W OAMTileSize+1,X
                      ASL A
                      ASL A
                      ORA.W OAMTileSize,X
                      STA.W OAMTileBitSize,Y
                      LDA.W OAMTileSize+7,X
                      ASL A
                      ASL A
                      ORA.W OAMTileSize+6,X
                      ASL A
                      ASL A
                      ORA.W OAMTileSize+5,X
                      ASL A
                      ASL A
                      ORA.W OAMTileSize+4,X
                      STA.W OAMTileBitSize+1,Y
                      DEY
                      DEY
                      BPL -
                      RTS

                   if ver_is_english(!_VER)                     ;\=============== U, SS, E0, & E1 ===============
CODE_0084C8:          PHB                                       ;!  Wrapper
                      PHK                                       ;!
                      PLB                                       ;!
                      JSR LoadScrnImage                         ;!
                      PLB                                       ;!
                      RTL                                       ;!
                   endif                                        ;/===============================================


StripeImages:         dl DynamicStripeImage                     ; 00 - Pointer to dynamic stripe image loader
                      dl TitleScreenStripe                      ; 03 - Title screen
                      dl OWBorderStripe                         ; 06 - OW border
                      dl ClearMessageStripe                     ; 09 - Blank space to clear a message box
                      dl ContinueEndStripe                      ; 0C - CONTINUE/END
                      dl LudwigCutBGStripe                      ; 0F - Ludwig Castle Cutscene BG
                      dl PlayerSelectStripe                     ; 12 - 1 PLAYER GAME/2 PLAYER GAME
                      dl OWScrollArrowStripe                    ; 15 - OW scroll arrows
                      dl OWScrollEraseStripe                    ; 18 - Remove OW scroll arrows
                      dl ClearOWBoxStripe                       ; 1B - Blank space to clear overworld boxes
                      dl ContinueSaveStripe                     ; 1E - CONTINUE AND SAVE
                   if ver_is_japanese(!_VER)                    ;\====================== J ======================
CutMessageStripes:    dl C1Message4Stripe                       ;! 21 - tabidatsunodearimashita.
                      dl C1Message3Stripe                       ;! 24 - nisareta nakamaotasukedashi doonatsuheiyae
                      dl C1Message2Stripe                       ;! 27 - taoshita mariotachiwa kuppanomahoude tamago
                      dl C1Message1Stripe                       ;! 2A - Yoosutaatouno oshirode saishonokokuppao
                      dl C2Message4Stripe                       ;! 2D - eteiruka? piichihimenounmeiya ikani!?
                      dl C2Message3Stripe                       ;! 30 - hetosusundeiku!konosaki donnawanagamachikama
                      dl C2Message2Stripe                       ;! 33 - doonatsuheiyakara chikanosekaino baniradoomu
                      dl C2Message1Stripe                       ;! 36 - mariotachiwa nibanmenokokuppamo yattsukete
                      dl C3Message4Stripe                       ;! 39 - shitara donnatabini narunodearouka!
                      dl C3Message3Stripe                       ;! 3C - moshimo midoriyaakanosuitchio totteinaito
                      dl C3Message2Stripe                       ;! 3F - hotto hitoiki. shikashikoosuwa kewashikunaru
                      dl C3Message1Stripe                       ;! 42 - mariotachiwa sanbanmenokokuppamo yattsukete
                      dl C4Message4Stripe                       ;! 45 - ginomori!hatashitemorionukerukotogadekirunoka?
                      dl C4Message3Stripe                       ;! 48 - nazootokanaito derukotogadekinaitoiu fushi
                      dl C4Message2Stripe                       ;! 4B - tachiwa korekara mayoinomorinihaitteiku!?
                      dl C4Message1Stripe                       ;! 4E - yonbanmenokokuppamo nantokakuriaa mario
                      dl C5Message4Stripe                       ;! 51 - pai. tsuginarutatakaino hojimarihajimarii!
                      dl C5Message3Stripe                       ;! 54 - chokoreetouwa nazonokoosuto doragondeip
                      dl C5Message2Stripe                       ;! 57 - to morionukerukotogadekita. daga konosakino
                      dl C5Message1Stripe                       ;! 5A - mariotachiwa gobanmenokokuppaoyattsuke yat
                      dl C6Message4Stripe                       ;! 5D - izoge mario! ganbare ruiji!
                      dl C6Message3Stripe                       ;! 60 - iriguchiohirakutameno kagigaarurashii.
                      dl C6Message2Stripe                       ;! 63 - konosakino chinbotsusenniwa kuppanotanino
                      dl C6Message1Stripe                       ;! 66 - rokubanmenokokuppaotaoshitamariotachi!
                      dl C7Message4Stripe                       ;! 69 - randoniheiwaotorimodosukotogadekirunoka?
                      dl C7Message3Stripe                       ;! 6C - bujinipiichihimeotasukedashi konokyouryuu
                      dl C7Message2Stripe                       ;! 6F - piichihimega torawareteiru kuppajounomi
                      dl C7Message1Stripe                       ;! 72 - tsuini saigonokokuppaotaoshita! nokosuwa
                   else                                         ;<================ U, SS, E0, & E1 ==============
CutMessageStripes:    dl BlankStripe                            ;! 21 - *empty*
                      dl C1Message7Stripe                       ;! 24 - travel to Donut Land.
                      dl C1Message6Stripe                       ;! 27 - Together, they now
                      dl C1Message5Stripe                       ;! 2A - still trapped in an egg.
                      dl C1Message4Stripe                       ;! 2D - Yoshi's friend who is
                      dl C1Message3Stripe                       ;! 30 - castle #1 and rescued
                      dl C1Message2Stripe                       ;! 33 - demented Iggy Koopa in
                      dl C1Message1Stripe                       ;! 36 - Mario has defeated the
                      dl C2Message8Stripe                       ;! 39 - Princess Toadstool?
                      dl C2Message7Stripe                       ;! 3C - What will become of
                      dl C2Message6Stripe                       ;! 3F - Mario in this new world?
                      dl C2Message5Stripe                       ;! 42 - Dome. What traps await
                      dl C2Message4Stripe                       ;! 45 - the underground Vanilla
                      dl C2Message3Stripe                       ;! 48 - memory. The next area is
                      dl C2Message2Stripe                       ;! 4B - castle #2 is now just a
                      dl C2Message1Stripe                       ;! 4E - Morton Koopa Jr. of
                      dl BlankStripe                            ;! 51 - *empty*
                      dl C3Message7Stripe                       ;! 54 - Green Switches yet?
                      dl C3Message6Stripe                       ;! 57 - you found the Red and
                      dl C3Message5Stripe                       ;! 5A - more difficult. Have
                      dl C3Message4Stripe                       ;! 5D - starting to get much
                      dl C3Message3Stripe                       ;! 60 - #3. Mario's quest is
                      dl C3Message2Stripe                       ;! 63 - Lemmy Koopa of castle
                      dl C3Message1Stripe                       ;! 66 - Mario has triumphed over
                      dl C4Message8Stripe                       ;! 69 - this perplexing forest.
                      dl C4Message7Stripe                       ;! 6C - to solve the puzzle of
                      dl C4Message6Stripe                       ;! 6F - Mario must use his brain
                      dl C4Message5Stripe                       ;! 72 - Illusion lies ahead.
                      dl C4Message4Stripe                       ;! 75 - are over. The Forest of
                      dl C4Message3Stripe                       ;! 78 - symphonies in castle #4
                      dl C4Message2Stripe                       ;! 7B - of composing Koopa
                      dl C4Message1Stripe                       ;! 7E - Ludwig von Koopa's days
                      dl BlankStripe                            ;! 81 - *empty*
                      dl C5Message7Stripe                       ;! 84 - tasty) Chocolate Island!
                      dl C5Message6Stripe                       ;! 87 - the dangerous (but
                      dl C5Message5Stripe                       ;! 8A - castle #5. Onward to
                      dl C5Message4Stripe                       ;! 8D - end to Roy Koopa of
                      dl C5Message3Stripe                       ;! 90 - Illusion and has put an
                      dl C5Message2Stripe                       ;! 93 - through the Forest of
                      dl C5Message1Stripe                       ;! 96 - Mario found his way
                      dl C6Message8Stripe                       ;! 99 - to the Valley of Bowser.
                      dl C6Message7Stripe                       ;! 9C - appears to be a gateway
                      dl C6Message6Stripe                       ;! 9F - is a sunken ship that
                      dl C6Message5Stripe                       ;! A2 - now before him. There
                      dl C6Message4Stripe                       ;! A5 - the challenge that is
                      dl C6Message3Stripe                       ;! A8 - song. Mario must meet
                      dl C6Message2Stripe                       ;! AB - #6 has sung her last
                      dl C6Message1Stripe                       ;! AE - Wendy O. Koopa in castle
                      dl C7Message8Stripe                       ;! B1 - Dinosaur Land?
                      dl C7Message7Stripe                       ;! B4 - restore peace to
                      dl C7Message6Stripe                       ;! B7 - Can Mario rescue her and
                      dl C7Message5Stripe                       ;! BA - Toadstool is being held.
                      dl C7Message4Stripe                       ;! BD - Castle where Princess
                      dl C7Message3Stripe                       ;! C0 - that is left is Bowser's
                      dl C7Message2Stripe                       ;! C3 - Koopa in castle #7. All
                      dl C7Message1Stripe                       ;! C6 - Mario has defeated Larry
                   endif                                        ;/===============================================
OtherStripes:         dl LemmyCutBGStripe                       ; J75/UC9 - Lemmy, Larry Castle Cutscene BG
                      dl WendyCutBGStripe                       ; J78/UCC - Wendy Castle Cutscene BG
                      dl CutsceneCastleStripe                   ; J7B/UCF - Castle Cutscene Castle
                      dl EraseAllStripe                         ; J7E/UD2 - Blank space to clear all of layers 1 and 2
                      dl TheEndStripe                           ; J81/UD5 - Ending: THE END
                      dl EnemyNameStripe00                      ; J84/UD8 - Ending: Enemies: Lakitu
                      dl EnemyNameStripe01                      ; J87/UDB - Ending: Enemies: Hammer Bro.
                      dl EnemyNameStripe02                      ; J8A/UDE - Ending: Enemies: Pokey
                      dl EnemyNameStripe03                      ; J8D/UE1 - Ending: Enemies: Rex
                      dl EnemyNameStripe04                      ; J90/UE4 - Ending: Enemies: Dino-Rhino
                      dl EnemyNameStripe05                      ; J93/UE7 - Ending: Enemies: Blargg
                      dl EnemyNameStripe06                      ; J96/UEA - Ending: Enemies: Urchin
                      dl EnemyNameStripe07                      ; J99/UED - Ending: Enemies: Boo
                      dl EnemyNameStripe08                      ; J9C/UF0 - Ending: Enemies: Dry Bones
                      dl EnemyNameStripe09                      ; J9F/UF3 - Ending: Enemies: Grinder
                      dl EnemyNameStripe0A                      ; JA2/UF6 - Ending: Enemies: Reznor
                      dl EnemyNameStripe0B                      ; JA5/UF9 - Ending: Enemies: Mechakoopa
                      dl EnemyNameStripe0C                      ; JA8/UFC - Ending: Enemies: Bowser
                      dl IggyCutBGStripe                        ; JAB/UFF - Iggy, Morton, Roy Castle Cutscene BG

LoadScrnImage:        LDY.B StripeImage                         ; 12 = Image loader
                      LDA.W StripeImages,Y                      ; \
                      STA.B _0                                  ; |
                      LDA.W StripeImages+1,Y                    ; |Load pointer
                      STA.B _1                                  ; |
                      LDA.W StripeImages+2,Y                    ; |
                      STA.B _2                                  ; /
                      JSR CODE_00871E
                      LDA.B StripeImage
                      BNE +
                      STA.L DynStripeImgSize
                      STA.L DynStripeImgSize+1
                      DEC A
                      STA.L DynamicStripeImage
                    + STZ.B StripeImage                         ; Do not reload the same thing next frame
                      RTS

CODE_0085FA:          JSR TurnOffIO
                      LDA.B #$FC
                      STA.B _0
                      STZ.W HW_VMAINC                           ; Set "VRAM Address Increment Value" to x00
                      STZ.W HW_VMADD                            ; Set "Address for VRAM Read/Write (Low Byte)" to x00
                      LDA.B #$50                                ; \ Set "Address for VRAM Read/Write (High Byte)" to x50
                      STA.W HW_VMADD+1                          ; /
                      LDX.B #$06
                    - LDA.W DATA_008649,X
                      STA.W HW_DMAPARAM+$10,X
                      DEX
                      BPL -
                      LDY.B #$02                                ; DMA something to VRAM, my guess is a tilemap...
                      STY.W HW_MDMAEN
                      LDA.B #$38
                      STA.B _0
                      LDA.B #$80
                      STA.W HW_VMAINC
                      STZ.W HW_VMADD                            ; \Change CRAM address
                      LDA.B #$50                                ; |
                      STA.W HW_VMADD+1                          ; /
                      LDX.B #$06                                ; And Repeat the DMA
                    - LDA.W DATA_008649,X
                      STA.W HW_DMAPARAM+$10,X
                      DEX
                      BPL -
                      LDA.B #$19                                ; \but change desination address to $2119
                      STA.W HW_DMAREG+$10                       ; /
                      STY.W HW_MDMAEN                           ; Start DMA
                      STZ.B OAMAddress                          ; $3B = 0 (not sure what $3B is)
                      JSL OAMResetRoutine                       ; and JSL to a RAM routine
                      JMP DoSomeSpriteDMA                       ; Jump to the next part of this routine


DATA_008649:          db $08,$18
                      dl $000000
                      dw $1000

ControllerUpdate:     LDA.W HW_CNTRL1                           ; \
                      AND.B #$F0                                ; |
                      STA.W axlr0000P1Hold                      ; |
                      TAY                                       ; |
                      EOR.W axlr0000P1Mask                      ; |
                      AND.W axlr0000P1Hold                      ; |
                      STA.W axlr0000P1Frame                     ; |
                      STY.W axlr0000P1Mask                      ; |
                      LDA.W HW_CNTRL1+1                         ; |
                      STA.W byetudlrP1Hold                      ; |
                      TAY                                       ; |
                      EOR.W byetudlrP1Mask                      ; |
                      AND.W byetudlrP1Hold                      ; |
                      STA.W byetudlrP1Frame                     ; |
                      STY.W byetudlrP1Mask                      ; |Read controller data
                      LDA.W HW_CNTRL2                           ; |
                      AND.B #$F0                                ; |
                      STA.W axlr0000P2Hold                      ; |
                      TAY                                       ; |
                      EOR.W axlr0000P2Mask                      ; |
                      AND.W axlr0000P2Hold                      ; |
                      STA.W axlr0000P2Frame                     ; |
                      STY.W axlr0000P2Mask                      ; |
                      LDA.W HW_CNTRL2+1                         ; |
                      STA.W byetudlrP2Hold                      ; |
                      TAY                                       ; |
                      EOR.W byetudlrP2Mask                      ; |
                      AND.W byetudlrP2Hold                      ; |
                      STA.W byetudlrP2Frame                     ; |
                      STY.W byetudlrP2Mask                      ; /
                      LDX.W ControllersPresent                  ; \
                      BPL +                                     ; |If $0DA0 is positive, set X to $0DA0
                      LDX.W PlayerTurnLvl                       ; |Otherwise, set X to current character
                    + LDA.W axlr0000P1Hold,X                    ; \
                      AND.B #$C0                                ; |
                      ORA.W byetudlrP1Hold,X                    ; |
                      STA.B byetudlrHold                        ; |
                      LDA.W axlr0000P1Hold,X                    ; |
                      STA.B axlr0000Hold                        ; |Update controller data bytes
                      LDA.W axlr0000P1Frame,X                   ; |
                      AND.B #$40                                ; |
                      ORA.W byetudlrP1Frame,X                   ; |
                      STA.B byetudlrFrame                       ; |
                      LDA.W axlr0000P1Frame,X                   ; |
                      STA.B axlr0000Frame                       ; /
                      RTS

CODE_0086C7:          REP #$30                                  ; AXY->16
                      LDX.W #$0062
                      LDA.W #$0202
                    - STA.W OAMTileSize,X
                      DEX
                      DEX
                      BPL -
                      SEP #$30                                  ; AXY->8
                      LDA.B #$F0
                      JSL OAMResetRoutine+$12E
                      RTS

ExecutePtr:           STY.B _3                                  ; "Push" Y
                      PLY
                      STY.B _0
                      REP #$30                                  ; AXY->16
                      AND.W #$00FF                              ; A = Game mode
                      ASL A                                     ; Multiply game mode by 2
                      TAY
                      PLA
                      STA.B _1
                      INY
                      LDA.B [_0],Y
                      STA.B _0                                  ; A is 16-bit
                      SEP #$30                                  ; AXY->8
                      LDY.B _3                                  ; "Pull" Y
                      JML.W [_0]                                ; Jump to the game mode's routine, which has been loaded into $00-02

ExecutePtrLong:       STY.B _5
                      PLY
                      STY.B _2
                      REP #$30                                  ; AXY->16
                      AND.W #$00FF                              ; \ A = Tileset/byte 3 (TB3)
                      STA.B _3                                  ; / Store A in $03
                      ASL A                                     ; \ Multiply A by 2
                      ADC.B _3                                  ; |Add TB3 to A
                      TAY                                       ; / Set Y to A
                      PLA
                      STA.B _3
                      INY
                      LDA.B [_2],Y
                      STA.B _0
                      INY
                      LDA.B [_2],Y
                      STA.B _1
                      SEP #$30                                  ; AXY->8
                      LDY.B _5
                      JML.W [_0]

CODE_00871E:          REP #$10                                  ; XY->16
                      STA.W HW_DMAADDR+$12
                      LDY.W #$0000                              ; Set index to 0
CODE_008726:          LDA.B [_0],Y                              ; \ Read line header byte 1
                      BPL +                                     ; |If the byte & %10000000 is true,
                      SEP #$30                                  ; | AXY->8
                      RTS                                       ; |

                    + STA.B _4                                  ; Store byte in !_4
                      INY                                       ; Move onto the next byte
                      LDA.B [_0],Y                              ; Read line header byte 2
                      STA.B _3                                  ; Store byte in $03
                      INY                                       ; Move onto the next byte
                      LDA.B [_0],Y                              ; Read line header byte 3
                      STZ.B _7                                  ; \
                      ASL A                                     ; |Store direction bit in $07
                      ROL.B _7                                  ; /
                      LDA.B #$18                                ; \ Set B address (DMA) to x18
                      STA.W HW_DMAREG+$10                       ; /
                      LDA.B [_0],Y                              ; Re-read line header byte 3
                      AND.B #$40                                ; \
                      LSR A                                     ; |
                      LSR A                                     ; |Store RLE bit << 3 in $05
                      LSR A                                     ; |
                      STA.B _5                                  ; /
                      STZ.B _6
                      ORA.B #$01
                      STA.W HW_DMAPARAM+$10
                      REP #$20                                  ; A->16
                      LDA.B _3
                      STA.W HW_VMADD
                      LDA.B [_0],Y
                      XBA
                      AND.W #$3FFF
                      TAX
                      INX
                      INY
                      INY
                      TYA
                      CLC
                      ADC.B _0
                      STA.W HW_DMAADDR+$10
                      STX.W HW_DMACNT+$10
                      LDA.B _5
                      BEQ +
                      SEP #$20                                  ; A->8
                      LDA.B _7
                      STA.W HW_VMAINC
                      LDA.B #$02
                      STA.W HW_MDMAEN
                      LDA.B #$19
                      STA.W HW_DMAREG+$10
                      REP #$21                                  ; A->16, CLC
                      LDA.B _3
                      STA.W HW_VMADD
                      TYA
                      ADC.B _0
                      INC A
                      STA.W HW_DMAADDR+$10
                      STX.W HW_DMACNT+$10
                      LDX.W #$0002
                    + STX.B _3
                      TYA
                      CLC
                      ADC.B _3
                      TAY
                      SEP #$20                                  ; A->8
                      LDA.B _7
                      ORA.B #$80
                      STA.W HW_VMAINC
                      LDA.B #$02
                      STA.W HW_MDMAEN
                      JMP CODE_008726

CODE_0087AD:          SEP #$30                                  ; AXY->8
                      LDA.W Layer1VramAddr                      ; \
                      BNE +                                     ; |If Layer 1 has to be updated,
                      JMP CODE_0088DD                           ; |jump to $88DD

                    + LDA.B ScreenMode                          ; \
                      AND.B #$01                                ; |
                      BEQ +                                     ; |If on a vertical level,
                      JMP CODE_008849                           ; |jump to $8849

                    + LDY.B #$81                                ; \ Set "VRAM Address Increment Value" to x81
                      STY.W HW_VMAINC                           ; /
                      LDA.W Layer1VramAddr+1
                      STA.W HW_VMADD
                      LDA.W Layer1VramAddr
                      STA.W HW_VMADD+1
                      LDX.B #$06
                    - LDA.W DATA_008A16,X
                      STA.W HW_DMAPARAM+$10,X
                      DEX
                      BPL -
                      LDA.B #$02                                ; \ Enable DMA channel 1
                      STA.W HW_MDMAEN                           ; /
                      STY.W HW_VMAINC
                      LDA.W Layer1VramAddr+1
                      STA.W HW_VMADD
                      LDA.W Layer1VramAddr
                      CLC
                      ADC.B #$08
                      STA.W HW_VMADD+1
                      LDX.B #$06
                    - LDA.W DATA_008A1D,X
                      STA.W HW_DMAPARAM+$10,X
                      DEX
                      BPL -
                      LDA.B #$02
                      STA.W HW_MDMAEN                           ; \ Enable DMA channel 1
                      STY.W HW_VMAINC                           ; /
                      LDA.W Layer1VramAddr+1
                      INC A
                      STA.W HW_VMADD
                      LDA.W Layer1VramAddr
                      STA.W HW_VMADD+1
                      LDX.B #$06
                    - LDA.W DATA_008A24,X
                      STA.W HW_DMAPARAM+$10,X
                      DEX
                      BPL -
                      LDA.B #$02                                ; \ Enable DMA channel 1
                      STA.W HW_MDMAEN                           ; /
                      STY.W HW_VMAINC
                      LDA.W Layer1VramAddr+1
                      INC A
                      STA.W HW_VMADD
                      LDA.W Layer1VramAddr
                      CLC
                      ADC.B #$08
                      STA.W HW_VMADD+1
                      LDX.B #$06
                    - LDA.W DATA_008A2B,X
                      STA.W HW_DMAPARAM+$10,X
                      DEX
                      BPL -
                      LDA.B #$02                                ; \ Enable DMA channel 1
                      STA.W HW_MDMAEN                           ; /
                      JMP CODE_0088DD

CODE_008849:          LDY.B #$80
                      STY.W HW_VMAINC
                      LDA.W Layer1VramAddr+1
                      STA.W HW_VMADD
                      LDA.W Layer1VramAddr
                      STA.W HW_VMADD+1
                      LDX.B #$06
                    - LDA.W DATA_008A16,X
                      STA.W HW_DMAPARAM+$10,X
                      DEX
                      BPL -
                      LDA.B #$02
                      STA.W HW_MDMAEN
                      STY.W HW_VMAINC
                      LDA.W Layer1VramAddr+1
                      STA.W HW_VMADD
                      LDA.W Layer1VramAddr
                      CLC
                      ADC.B #$04
                      STA.W HW_VMADD+1
                      LDX.B #$06
                    - LDA.W DATA_008A1D,X
                      STA.W HW_DMAPARAM+$10,X
                      DEX
                      BPL -
                      LDA.B #$40
                      STA.W HW_DMACNT+$10
                      LDA.B #$02
                      STA.W HW_MDMAEN
                      STY.W HW_VMAINC
                      LDA.W Layer1VramAddr+1
                      CLC
                      ADC.B #$20
                      STA.W HW_VMADD
                      LDA.W Layer1VramAddr
                      STA.W HW_VMADD+1
                      LDX.B #$06
                    - LDA.W DATA_008A24,X
                      STA.W HW_DMAPARAM+$10,X
                      DEX
                      BPL -
                      LDA.B #$02
                      STA.W HW_MDMAEN
                      STY.W HW_VMAINC
                      LDA.W Layer1VramAddr+1
                      CLC
                      ADC.B #$20
                      STA.W HW_VMADD
                      LDA.W Layer1VramAddr
                      CLC
                      ADC.B #$04
                      STA.W HW_VMADD+1
                      LDX.B #$06
                    - LDA.W DATA_008A2B,X
                      STA.W HW_DMAPARAM+$10,X
                      DEX
                      BPL -
                      LDA.B #$40
                      STA.W HW_DMACNT+$10
                      LDA.B #$02
                      STA.W HW_MDMAEN
CODE_0088DD:          LDA.B #$00
                      STA.W Layer1VramAddr
                      LDA.W Layer2VramAddr
                      BNE +
                      JMP CODE_008A10

                    + LDA.B ScreenMode
                      AND.B #$02
                      BEQ +
                      JMP CODE_00897C

                    + LDY.B #$81
                      STY.W HW_VMAINC
                      LDA.W Layer2VramAddr+1
                      STA.W HW_VMADD
                      LDA.W Layer2VramAddr
                      STA.W HW_VMADD+1
                      LDX.B #$06
                    - LDA.W DATA_008A32,X
                      STA.W HW_DMAPARAM+$10,X
                      DEX
                      BPL -
                      LDA.B #$02
                      STA.W HW_MDMAEN
                      STY.W HW_VMAINC
                      LDA.W Layer2VramAddr+1
                      STA.W HW_VMADD
                      LDA.W Layer2VramAddr
                      CLC
                      ADC.B #$08
                      STA.W HW_VMADD+1
                      LDX.B #$06
                    - LDA.W DATA_008A39,X
                      STA.W HW_DMAPARAM+$10,X
                      DEX
                      BPL -
                      LDA.B #$02
                      STA.W HW_MDMAEN
                      STY.W HW_VMAINC
                      LDA.W Layer2VramAddr+1
                      INC A
                      STA.W HW_VMADD
                      LDA.W Layer2VramAddr
                      STA.W HW_VMADD+1
                      LDX.B #$06
                    - LDA.W DATA_008A40,X
                      STA.W HW_DMAPARAM+$10,X
                      DEX
                      BPL -
                      LDA.B #$02
                      STA.W HW_MDMAEN
                      STY.W HW_VMAINC
                      LDA.W Layer2VramAddr+1
                      INC A
                      STA.W HW_VMADD
                      LDA.W Layer2VramAddr
                      CLC
                      ADC.B #$08
                      STA.W HW_VMADD+1
                      LDX.B #$06
                    - LDA.W DATA_008A47,X
                      STA.W HW_DMAPARAM+$10,X
                      DEX
                      BPL -
                      LDA.B #$02
                      STA.W HW_MDMAEN
                      JMP CODE_008A10

CODE_00897C:          LDY.B #$80
                      STY.W HW_VMAINC
                      LDA.W Layer2VramAddr+1
                      STA.W HW_VMADD
                      LDA.W Layer2VramAddr
                      STA.W HW_VMADD+1
                      LDX.B #$06
                    - LDA.W DATA_008A32,X
                      STA.W HW_DMAPARAM+$10,X
                      DEX
                      BPL -
                      LDA.B #$02
                      STA.W HW_MDMAEN
                      STY.W HW_VMAINC
                      LDA.W Layer2VramAddr+1
                      STA.W HW_VMADD
                      LDA.W Layer2VramAddr
                      CLC
                      ADC.B #$04
                      STA.W HW_VMADD+1
                      LDX.B #$06
                    - LDA.W DATA_008A39,X
                      STA.W HW_DMAPARAM+$10,X
                      DEX
                      BPL -
                      LDA.B #$40
                      STA.W HW_DMACNT+$10
                      LDA.B #$02
                      STA.W HW_MDMAEN
                      STY.W HW_VMAINC
                      LDA.W Layer2VramAddr+1
                      CLC
                      ADC.B #$20
                      STA.W HW_VMADD
                      LDA.W Layer2VramAddr
                      STA.W HW_VMADD+1
                      LDX.B #$06
                    - LDA.W DATA_008A40,X
                      STA.W HW_DMAPARAM+$10,X
                      DEX
                      BPL -
                      LDA.B #$02
                      STA.W HW_MDMAEN
                      STY.W HW_VMAINC
                      LDA.W Layer2VramAddr+1
                      CLC
                      ADC.B #$20
                      STA.W HW_VMADD
                      LDA.W Layer2VramAddr
                      CLC
                      ADC.B #$04
                      STA.W HW_VMADD+1
                      LDX.B #$06
                    - LDA.W DATA_008A47,X
                      STA.W HW_DMAPARAM+$10,X
                      DEX
                      BPL -
                      LDA.B #$40
                      STA.W HW_DMACNT+$10
                      LDA.B #$02
                      STA.W HW_MDMAEN
CODE_008A10:          LDA.B #$00
                      STA.W Layer2VramAddr
                      RTL


DATA_008A16:          db $01,$18
                      dl Layer1VramBuffer
                      dw $0040

DATA_008A1D:          db $01,$18
                      dl Layer1VramBuffer+$40
                      dw $002C

DATA_008A24:          db $01,$18
                      dl Layer1VramBuffer+$80
                      dw $0040

DATA_008A2B:          db $01,$18
                      dl Layer1VramBuffer+$C0
                      dw $002C

DATA_008A32:          db $01,$18
                      dl Layer2VramBuffer
                      dw $0040

DATA_008A39:          db $01,$18
                      dl Layer2VramBuffer+$40
                      dw $002C

DATA_008A40:          db $01,$18
                      dl Layer2VramBuffer+$80
                      dw $0040

DATA_008A47:          db $01,$18
                      dl Layer2VramBuffer+$C0
                      dw $002C

ClearStack:           REP #$30                                  ; AXY->16
                      LDX.W #$1FFE
CODE_008A53:          STZ.B _0,X
CODE_008A55:          DEX
                      DEX
                      CPX.W #$01FF
                      BPL CODE_008A61
                      CPX.W #$0100
                      BPL CODE_008A55
CODE_008A61:          CPX.W #$FFFE
                      BNE CODE_008A53
                      LDA.W #$0000
                      STA.L DynStripeImgSize
                      STZ.W DynPaletteIndex
                      SEP #$30                                  ; AXY->8
                      LDA.B #$FF
                      STA.L DynamicStripeImage
                      RTS

                   if ver_is_lores(!_VER)                       ;\=============== J, U, SS, & E0 ================
SetUpScreen:          STZ.W HW_SETINI                           ;! Set "Screen Initial Settings" to x00
                   else                                         ;<===================== E1 ======================
SetUpScreen:          LDA.B #$04                                ;! 239 lines
                      STA.W HW_SETINI                           ;!
                   endif                                        ;/===============================================
                      STZ.W HW_MOSAIC                           ; Turn off mosaic
                      LDA.B #$23
                      STA.W HW_BG1SC
                      LDA.B #$33
                      STA.W HW_BG2SC
                      LDA.B #$53
                      STA.W HW_BG3SC
                      LDA.B #$00
                      STA.W HW_BG12NBA
                      LDA.B #$04
                      STA.W HW_BG34NBA
                      STZ.B Layer12Window
                      STZ.B Layer34Window
                      STZ.B OBJCWWindow
                      STZ.W HW_WBGLOG
                      STZ.W HW_WOBJLOG
                      STZ.W HW_TMW
                      STZ.W HW_TSW
                      LDA.B #$02
                      STA.B ColorAddition
                      LDA.B #$80                                ; \ Set Mode7 "Screen Over" to %10000000, disable Mode7 flipping
                      STA.W HW_M7SEL                            ; /
                      RTS


DATA_008AB4:          dw $0000,$00FE,$0000,$00FE
DATA_008ABC:          dw $0000,$0002,$0000,$0002

                      db $00,$00,$00,$01,$FF,$FF,$00,$10        ; unused table?
                      db $F0

CODE_008ACD:          LDA.B Mode7YScale
                      STA.B _0
                      REP #$30                                  ; AXY->16
                      JSR CODE_008AE8
                      LDA.B Mode7XScale
                      STA.B _0
                      REP #$30                                  ; AXY->16
                      LDA.B Mode7ParamA
                      STA.B Mode7ParamD
                      LDA.B Mode7ParamB
                      EOR.W #$FFFF
                      INC A
                      STA.B Mode7ParamC
CODE_008AE8:          LDA.B Mode7Angle
                      ASL A
                      PHA
                      XBA
                      AND.W #$0003
                      ASL A
                      TAY
                      PLA
                      AND.W #$00FE
                      EOR.W DATA_008AB4,Y
                      CLC
                      ADC.W DATA_008ABC,Y
                      TAX
                      JSR CODE_008B2B
                      CPY.W #$0004
                      BCC +
                      EOR.W #$FFFF
                      INC A
                    + STA.B Mode7ParamB
                      TXA
                      EOR.W #$00FE
                      CLC
                      ADC.W #$0002
                      AND.W #$01FF
                      TAX
                      JSR CODE_008B2B
                      DEY
                      DEY
                      CPY.W #$0004
                      BCS +
                      EOR.W #$FFFF
                      INC A
                    + STA.B Mode7ParamA
                      SEP #$30                                  ; AXY->8
                      RTS

CODE_008B2B:          SEP #$20                                  ; A->8
                      LDA.W DATA_008B57+1,X
                      BEQ +
                      LDA.B _0
                    + STA.B _1
                      LDA.W DATA_008B57,X
                      STA.W HW_WRMPYA
                      LDA.B _0
                      STA.W HW_WRMPYB
                      NOP
                      NOP
                      NOP
                      NOP
                      LDA.W HW_RDMPY+1
                      CLC
                      ADC.B _1
                      XBA
                      LDA.W HW_RDMPY
                      REP #$20                                  ; A->16
                      LSR A
                      LSR A
                      LSR A
                      LSR A
                      LSR A
                      RTS

DATA_008B57:          dw $0000,$0003,$0006,$0009
                      dw $000C,$000F,$0012,$0015
                      dw $0019,$001C,$001F,$0022
                      dw $0025,$0028,$002B,$002E
                      dw $0031,$0035,$0038,$003B
                      dw $003E,$0041,$0044,$0047
                      dw $004A,$004D,$0050,$0053
                      dw $0056,$0059,$005C,$005F
                      dw $0061,$0064,$0067,$006A
                      dw $006D,$0070,$0073,$0075
                      dw $0078,$007B,$007E,$0080
                      dw $0083,$0086,$0088,$008B
                      dw $008E,$0090,$0093,$0095
                      dw $0098,$009B,$009D,$009F
                      dw $00A2,$00A4,$00A7,$00A9
                      dw $00AB,$00AE,$00B0,$00B2
                      dw $00B5,$00B7,$00B9,$00BB
                      dw $00BD,$00BF,$00C1,$00C3
                      dw $00C5,$00C7,$00C9,$00CB
                      dw $00CD,$00CF,$00D1,$00D3
                      dw $00D4,$00D6,$00D8,$00D9
                      dw $00DB,$00DD,$00DE,$00E0
                      dw $00E1,$00E3,$00E4,$00E6
                      dw $00E7,$00E8,$00EA,$00EB
                      dw $00EC,$00ED,$00EE,$00EF
                      dw $00F1,$00F2,$00F3,$00F4
                      dw $00F4,$00F5,$00F6,$00F7
                      dw $00F8,$00F9,$00F9,$00FA
                      dw $00FB,$00FB,$00FC,$00FC
                      dw $00FD,$00FD,$00FE,$00FE
                      dw $00FE,$00FF,$00FF,$00FF
                      dw $00FF,$00FF,$00FF,$00FF
                      dw $0100

TallNumbers:          db $B7,$3C,$B7,$BC,$B8,$3C,$B9,$3C
                      db $BA,$3C,$BB,$3C,$BA,$3C,$BA,$BC
                      db $BC,$3C,$BD,$3C,$BE,$3C,$BF,$3C
                      db $C0,$3C,$B7,$BC,$C1,$3C,$B9,$3C
                      db $C2,$3C,$C2,$BC,$B7,$3C,$C0,$FC

StatusBarRow1:        db $3A,$38,$3B,$38,$3B,$38,$3A,$78

StatusBarRow2:        db $30,$28,$31,$28,$32,$28,$33,$28
                      db $34,$28,$FC,$38,$FC,$3C,$FC,$3C
                      db $FC,$3C,$FC,$3C,$FC,$38,$FC,$38
                      db $4A,$38,$FC,$38,$FC,$38,$4A,$78
                      db $FC,$38,$3D,$3C,$3E,$3C,$3F,$3C
                      db $FC,$38,$FC,$38,$FC,$38,$2E,$3C
                      db $26,$38,$FC,$38,$FC,$38,$00,$38

StatusBarRow3:        db $26,$38,$FC,$38,$00,$38,$FC,$38
                      db $FC,$38,$FC,$38,$64,$28,$26,$38
                      db $FC,$38,$FC,$38,$FC,$38,$4A,$38
                      db $FC,$38,$FC,$38,$4A,$78,$FC,$38
                      db $FE,$3C,$FE,$3C,$00,$3C,$FC,$38
                      db $FC,$38,$FC,$38,$FC,$38,$FC,$38
                      db $FC,$38,$FC,$38,$00,$38

StatusBarRow4:        db $3A,$B8,$3B,$B8,$3B,$B8,$3A,$F8

GM04DoDMA:            LDA.B #$80                                ; More DMA
                      STA.W HW_VMAINC                           ; Increment when $2119 accessed
                      LDA.B #$2E                                ; \VRAM address = #$502E
                      STA.W HW_VMADD                            ; |
                      LDA.B #$50                                ; |
                      STA.W HW_VMADD+1                          ; /
                      LDX.B #$06
                    - LDA.W DATA_008D90,X
                      STA.W HW_DMAPARAM+$10,X                   ; Load up the DMA regs
                      DEX                                       ; DMA Source = 8C:8118 (...)
                      BPL -                                     ; Dest = $2118, Transfer: #$08 bytes
                      LDA.B #$02
                      STA.W HW_MDMAEN                           ; Do the DMA
                      LDA.B #$80                                ; \ Set VRAM mode = same as above
                      STA.W HW_VMAINC                           ; |Address = #$5042
                      LDA.B #$42                                ; |
                      STA.W HW_VMADD                            ; |
                      LDA.B #$50                                ; |
                      STA.W HW_VMADD+1                          ; /
                      LDX.B #$06                                ; \ Set up more DMA
                    - LDA.W DATA_008D97,X                       ; |Dest = $2100
                      STA.W HW_DMAPARAM+$10,X                   ; |Fixed source address = $89:1801 (Lunar Address: 7E:1801)
                      DEX                                       ; |#$808C bytes to transfer
                      BPL -                                     ; /Type = One reg write once
                      LDA.B #$02
                      STA.W HW_MDMAEN                           ; Start DMA
                      LDA.B #$80                                ; \prep VRAM for another write
                      STA.W HW_VMAINC                           ; |
                      LDA.B #$63                                ; |
                      STA.W HW_VMADD                            ; |
                      LDA.B #$50                                ; |
                      STA.W HW_VMADD+1                          ; /
                      LDX.B #$06                                ; \ Load up DMA again
                    - LDA.W DATA_008D9E,X                       ; |Dest = $2118
                      STA.W HW_DMAPARAM+$10,X                   ; |Source Address = $39:8CC1
                      DEX                                       ; |Size = #$0100 bytes
                      BPL -                                     ; /Type = Two reg write once
                      LDA.B #$02                                ; \Start Transfer
                      STA.W HW_MDMAEN                           ; /
                      LDA.B #$80                                ; \
                      STA.W HW_VMAINC                           ; |Set up VRAM once more ; VRAM Address Increment Value
                      LDA.B #$8E                                ; |
                      STA.W HW_VMADD                            ; |
                      LDA.B #$50                                ; |
                      STA.W HW_VMADD+1                          ; /
                      LDX.B #$06                                ; \Last DMA...
                    - LDA.W DATA_008DA5,X                       ; |Reg = $2118 Type = Two reg write once
                      STA.W HW_DMAPARAM+$10,X                   ; |Source Address = $08:8CF7
                      DEX                                       ; |Size = #$9C00 bytes (o_o)
                      BPL -                                     ; /
                      LDA.B #$02                                ; \Transfer
                      STA.W HW_MDMAEN                           ; /
                      LDX.B #$36                                ; \Copy some data into RAM
                      LDY.B #$6C                                ; |
                    - LDA.W StatusBarRow2,Y                     ; |
                      STA.W StatusBar,X                         ; | 59
                      DEY                                       ; |
                      DEY                                       ; |
                      DEX                                       ; |
                      BPL -                                     ; /
                      LDA.B #con($28,$28,$28,$22,$22)
                      STA.W InGameTimerFrames                   ; #$28 -> Timer frame counter
                      RTS

DATA_008D90:          db $01,$18
                      dl StatusBarRow1
                      dw $0008

DATA_008D97:          db $01,$18
                      dl StatusBarRow2
                      dw $0038

DATA_008D9E:          db $01,$18
                      dl StatusBarRow3
                      dw $0036

DATA_008DA5:          db $01,$18
                      dl StatusBarRow4
                      dw $0008

DrawStatusBar:        STZ.W HW_VMAINC                           ; Set VRAM Address Increment Value to x00
                      LDA.B #$42                                ; \
                      STA.W HW_VMADD                            ; |Set Address for VRAM Read/Write to x5042
                      LDA.B #$50                                ; |
                      STA.W HW_VMADD+1                          ; /
                      LDX.B #$06                                ; \
                    - LDA.W DMAdata_StBr1,X                     ; |Load settings from DMAdata_StBr1 into DMA channel 1
                      STA.W HW_DMAPARAM+$10,X                   ; |
                      DEX                                       ; |
                      BPL -                                     ; /
                      LDA.B #$02                                ; \ Activate DMA channel 1
                      STA.W HW_MDMAEN                           ; /
                      STZ.W HW_VMAINC                           ; Set VRAM Address Increment Value to x00
                      LDA.B #$63                                ; \
                      STA.W HW_VMADD                            ; |Set Address for VRAM Read/Write to x5063
                      LDA.B #$50                                ; |
                      STA.W HW_VMADD+1                          ; /
                      LDX.B #$06                                ; \
                    - LDA.W DMAdata_StBr2,X                     ; |Load settings from DMAdata_StBr2 into DMA channel 1
                      STA.W HW_DMAPARAM+$10,X                   ; |
                      DEX                                       ; |
                      BPL -                                     ; /
                      LDA.B #$02                                ; \ Activate DMA channel 1
                      STA.W HW_MDMAEN                           ; /
                      RTS

DMAdata_StBr1:        db $00,$18
                      dl StatusBar
                      dw $001C

DMAdata_StBr2:        db $00,$18
                      dl StatusBar+$1C
                      dw $001B

DATA_008DF5:          db $40,$41,$42,$43,$44                    ; "LUIGI"

DATA_008DFA:          db $24,$26,$48,$0E                        ; item box item OBJ numbers
DATA_008DFE:          db $00,$02,$04,$02                        ; star item box palettes
DATA_008E02:          db $08,$0A,$00,$04                        ; item box item palettes

DATA_008E06:          db $B7,$C3                                ; Tall numbers for status bar
                      db $B8,$B9
                      db $BA,$BB
                      db $BA,$BF
                      db $BC,$BD
                      db $BE,$BF
                      db $C0,$C3
                      db $C1,$B9
                      db $C2,$C4
                      db $B7,$C5

CODE_008E1A:          LDA.W EndLevelTimer                       ; \
                      ORA.B SpriteLock                          ; |If level is ending or sprites are locked,
                      BNE CODE_008E6F                           ; / branch to $8E6F
                      LDA.W IRQNMICommand
                      CMP.B #$C1
                      BEQ CODE_008E6F
                      DEC.W InGameTimerFrames
                      BPL CODE_008E6F
                      LDA.B #con($28,$28,$28,$22,$22)
                      STA.W InGameTimerFrames
                      LDA.W InGameTimerHundreds                 ; \
                      ORA.W InGameTimerTens                     ; |If time is 0,
                      ORA.W InGameTimerOnes                     ; |branch to $8E6F
                      BEQ CODE_008E6F                           ; /
                      LDX.B #$02
CODE_008E3F:          DEC.W InGameTimerHundreds,X
                      BPL CODE_008E4C
                      LDA.B #$09
                      STA.W InGameTimerHundreds,X
                      DEX
                      BPL CODE_008E3F
CODE_008E4C:          LDA.W InGameTimerHundreds                 ; \
                      BNE +                                     ; |
                      LDA.W InGameTimerTens                     ; |
                      AND.W InGameTimerOnes                     ; |If time is 99,
                      CMP.B #$09                                ; |speed up the music
                      BNE +                                     ; |
                      LDA.B #!SFX_HURRYUP                       ; |
                      STA.W SPCIO0                              ; |
                    + LDA.W InGameTimerHundreds                 ; \
                      ORA.W InGameTimerTens                     ; |
                      ORA.W InGameTimerOnes                     ; |If time is 0,
                      BNE CODE_008E6F                           ; |JSL to $00F606
                      JSL KillMario                             ; |
CODE_008E6F:          LDA.W InGameTimerHundreds                 ; \
                      STA.W StatusBar+$2C                       ; |
                      LDA.W InGameTimerTens                     ; |Copy time to $0F25-$0F27
                      STA.W StatusBar+$2D                       ; |
                      LDA.W InGameTimerOnes                     ; |
                      STA.W StatusBar+$2E                       ; /
                      LDX.B #$10
                      LDY.B #$00
CODE_008E85:          LDA.W InGameTimerHundreds,Y
                      BNE CODE_008E95
                      LDA.B #$FC
                      STA.W StatusBar+$1C,X
                      INY
                      INX
                      CPY.B #$02
                      BNE CODE_008E85
CODE_008E95:          LDX.B #$03
CODE_008E97:          LDA.W PlayerScore+2,X
                      STA.B _0
                      STZ.B _1
                      REP #$20                                  ; A->16
                      LDA.W PlayerScore,X
                      SEC
                      SBC.W #$423F
                      LDA.B _0
                      SBC.W #$000F
                      BCC +
                      SEP #$20                                  ; A->8
                      LDA.B #$0F
                      STA.W PlayerScore+2,X
                      LDA.B #$42
                      STA.W PlayerScore+1,X
                      LDA.B #$3F
                      STA.W PlayerScore,X
                    + SEP #$20                                  ; A->8
                      DEX
                      DEX
                      DEX
                      BPL CODE_008E97
                      LDA.W PlayerScore+2                       ; \ Store high byte of Mario's score in $00
                      STA.B _0                                  ; /
                      STZ.B _1                                  ; Store x00 in $01
                      LDA.W PlayerScore+1                       ; \ Store mid byte of Mario's score in $03
                      STA.B _3                                  ; /
                      LDA.W PlayerScore                         ; \ Store low byte of Mario's score in $02
                      STA.B _2                                  ; /
                      LDX.B #$14
                      LDY.B #$00
                      JSR CODE_009012
                      LDX.B #$00                                ; \
CODE_008EE0:          LDA.W StatusBar+$30,X                     ; |
                      BNE CODE_008EEF                           ; |
                      LDA.B #$FC                                ; |Replace all leading zeroes in the score with spaces
                      STA.W StatusBar+$30,X                     ; |
                      INX                                       ; |
                      CPX.B #$06                                ; |
                      BNE CODE_008EE0                           ; |
CODE_008EEF:          LDA.W PlayerTurnLvl                       ; Get current player
                      BEQ CODE_008F1D                           ; If player is Mario, branch to $8F1D
                      LDA.W PlayerScore+5                       ; \ Store high byte of Luigi's score in $00
                      STA.B _0                                  ; /
                      STZ.B _1                                  ; Store x00 in $01
                      LDA.W PlayerScore+4                       ; \ Store mid byte of Luigi's score in $03
                      STA.B _3                                  ; /
                      LDA.W PlayerScore+3                       ; \ Store low byte of Luigi's score in $02
                      STA.B _2                                  ; /
                      LDX.B #$14
                      LDY.B #$00
                      JSR CODE_009012
                      LDX.B #$00                                ; \
CODE_008F0E:          LDA.W StatusBar+$30,X                     ; |
                      BNE CODE_008F1D                           ; |
                      LDA.B #$FC                                ; |Replace all leading zeroes in the score with spaces
                      STA.W StatusBar+$30,X                     ; |
                      INX                                       ; |
                      CPX.B #$06                                ; |
                      BNE CODE_008F0E                           ; /
CODE_008F1D:          LDA.W CoinAdder                           ; \ If Coin increase isn't x00,
                      BEQ +                                     ; / branch to $8F3B
                      DEC.W CoinAdder                           ; Decrease "Coin increase"
                      INC.W PlayerCoins                         ; Increase coins by 1
                      LDA.W PlayerCoins                         ; \
                      CMP.B #$64                                ; |If coins<100, branch to $8F3B
                      BCC +                                     ; /
                      INC.W GivePlayerLives                     ; Increase lives by 1
                      LDA.W PlayerCoins                         ; \
                      SEC                                       ; |Decrease coins by 100
                      SBC.B #$64                                ; |
                      STA.W PlayerCoins                         ; /
                    + LDA.W PlayerLives                         ; \ If amount of lives is negative,
                      BMI +                                     ; / branch to $8F49
                      CMP.B #$62                                ; \ If amount of lives is less than 98,
                      BCC +                                     ; / branch to $8F49
                      LDA.B #$62                                ; \ Set amount of lives to 98
                      STA.W PlayerLives                         ; /
                    + LDA.W PlayerLives                         ; \
                      INC A                                     ; |Get amount of lives in decimal
                      JSR HexToDec                              ; /
                      TXY                                       ; \
                      BNE +                                     ; |If 10s is 0, replace with space
                      LDX.B #$FC                                ; |
                    + STX.W StatusBar+$1D                       ; \ Write lives to status bar
                      STA.W StatusBar+$1E                       ; /
                      LDX.W PlayerTurnLvl                       ; \ Get bonus stars
                      LDA.W PlayerBonusStars,X                  ; /
                      CMP.B #$64                                ; \ If bonus stars is less than 100,
                      BCC +                                     ; / branch to $8F73
                      LDA.B #$FF                                ; \ Start bonus game when the level ends
                      STA.W BonusGameActivate                   ; /
                      LDA.W PlayerBonusStars,X                  ; \
                      SEC                                       ; |Subtract bonus stars by 100
                      SBC.B #$64                                ; |
                      STA.W PlayerBonusStars,X                  ; /
                    + LDA.W PlayerCoins                         ; \ Get amount of coins in decimal
                      JSR HexToDec                              ; /
                      TXY                                       ; \
                      BNE +                                     ; |If 10s is 0, replace with space
                      LDX.B #$FC                                ; |
                    + STA.W StatusBar+$1B                       ; \ Write coins to status bar
                      STX.W StatusBar+$1A                       ; /
                      SEP #$20                                  ; A->8
                      LDX.W PlayerTurnLvl                       ; Load Character into X
                      STZ.B _0
                      STZ.B _1
                      STZ.B _3
                      LDA.W PlayerBonusStars,X
                      STA.B _2
                      LDX.B #$09
                      LDY.B #$10
                      JSR CODE_009051
                      LDX.B #$00
CODE_008F9D:          LDA.W StatusBar+$25,X
                      BNE CODE_008FAF
                      LDA.B #$FC
                      STA.W StatusBar+$25,X
                      STA.W StatusBar+$0A,X
                      INX
                      CPX.B #$01
                      BNE CODE_008F9D
CODE_008FAF:          LDA.W StatusBar+$25,X
                      ASL A
                      TAY
                      LDA.W DATA_008E06,Y
                      STA.W StatusBar+$0A,X
                      LDA.W DATA_008E06+1,Y
                      STA.W StatusBar+$25,X
                      INX
                      CPX.B #$02
                      BNE CODE_008FAF
                      JSR CODE_009079
                      LDA.W PlayerTurnLvl
                      BEQ CODE_008FD8
                      LDX.B #$04
                    - LDA.W DATA_008DF5,X
                      STA.W StatusBar,X
                      DEX
                      BPL -
CODE_008FD8:          LDA.W DragonCoinsShown
                      CMP.B #$05
                      BCC +
                      LDA.B #$00
                    + DEC A
                      STA.B _0
                      LDX.B #$00
CODE_008FE6:          LDY.B #$FC
                      LDA.B _0
                      BMI +
                      LDY.B #$2E
                    + TYA
                      STA.W StatusBar+6,X
                      DEC.B _0
                      INX
                      CPX.B #$04
                      BNE CODE_008FE6
                      RTS


ScorePlaces:          dw $0001,$86A0                            ; "100000"
                      dw $0000,$2710                            ; "10000"
                      dw $0000,$03E8                            ; "1000"
                      dw $0000,$0064                            ; "100"
                      dw $0000,$000A                            ; "10"
                      dw $0000,$0001                            ; "1"

CODE_009012:          SEP #$20                                  ; A->8
                      STZ.W StatusBar+$1C,X
CODE_009017:          REP #$20                                  ; A->16
                      LDA.B _2
                      SEC
                      SBC.W ScorePlaces+2,Y
                      STA.B _6
                      LDA.B _0
                      SBC.W ScorePlaces,Y
                      STA.B _4
                      BCC CODE_009039
                      LDA.B _6
                      STA.B _2
                      LDA.B _4
                      STA.B _0
                      SEP #$20                                  ; A->8
                      INC.W StatusBar+$1C,X
                      BRA CODE_009017

CODE_009039:          INX
                      INY
                      INY
                      INY
                      INY
                      CPY.B #$18
                      BNE CODE_009012
                      SEP #$20                                  ; A->8
                      RTS

HexToDec:             LDX.B #$00                                ; |
CODE_009047:          CMP.B #$0A                                ; |
                      BCC Return009050                          ; |Sets A to 10s of original A
                      SBC.B #$0A                                ; |Sets X to 1s of original A
                      INX                                       ; |
                      BRA CODE_009047                           ; |

Return009050:         RTS                                       ; /

CODE_009051:          SEP #$20                                  ; A->8
                      STZ.W StatusBar+$1C,X
CODE_009056:          REP #$20                                  ; A->16
                      LDA.B _2
                      SEC
                      SBC.W ScorePlaces+2,Y
                      STA.B _6
                      BCC CODE_00906D
                      LDA.B _6
                      STA.B _2
                      SEP #$20                                  ; A->8
                      INC.W StatusBar+$1C,X
                      BRA CODE_009056

CODE_00906D:          INX
                      INY
                      INY
                      INY
                      INY
                      CPY.B #$18
                      BNE CODE_009051
                      SEP #$20                                  ; A->8
                      RTS

CODE_009079:          LDY.B #$E0
                      BIT.W IRQNMICommand
                      BVC +
                      LDY.B #$00
                      LDA.W IRQNMICommand
                      CMP.B #$C1
                      BEQ +
                      LDA.B #$F0
                      STA.W OAMTileYPos,Y
                    + STY.B _1
                      LDY.W PlayerItembox
                      BEQ Return0090D0
                      LDA.W DATA_008E02-1,Y
                      STA.B _0
                      CPY.B #$03
                      BNE +
                      LDA.B TrueFrame
                      LSR A
                      AND.B #$03
                      PHY
                      TAY
                      LDA.W DATA_008DFE,Y
                      PLY
                      STA.B _0
                    + LDY.B _1
                      LDA.B #$78
                      STA.W OAMTileXPos,Y
                      LDA.B #$0F
                      STA.W OAMTileYPos,Y
                      LDA.B #$30
                      ORA.B _0
                      STA.W OAMTileAttr,Y
                      LDX.W PlayerItembox
                      LDA.W DATA_008DFA-1,X
                      STA.W OAMTileNo,Y
                      TYA
                      LSR A
                      LSR A
                      TAY
                      LDA.B #$02
                      STA.W OAMTileSize,Y
Return0090D0:         RTS


TitleTextTileTop:     db $00,$FF,$4D,$4C,$03,$4D,$5D,$FF        ; "MARIO START!" top
                      db $03,$00,$4C,$03,$04,$15

                      db $00,$02,$00,$4A,$4E,$FF                ; "LUIGI" top

                      db $4C,$4B,$4A,$03,$5F,$05,$04,$03        ; "GAME OVER" top
                      db $02

                      db $00,$FF,$01,$4A,$5F,$05,$04,$00        ; "TIME UP" top
                      db $4D

                      db $5D,$03,$02,$01,$00,$FF,$5B,$14        ; "BONUS GAME" top
                      db $5F,$01,$5E

                      db $FF,$FF,$FF

TitleTextTileBottom:  db $10,$FF,$00,$5C,$13,$00,$5D,$FF        ; "MARIO START!" bottom
                      db $03,$00,$5C,$13,$14,$15

                      db $00,$12,$00,$03,$5E,$FF                ; "LUIGI" bottom

                      db $5C,$4B,$5A,$03,$5F,$05,$14,$13        ; "GAME OVER" bottom
                      db $12

                      db $10,$FF,$11,$03,$5F,$05,$14,$00        ; "TIME UP" bottom
                      db $00

                      db $5D,$03,$12,$11,$10,$FF,$5B,$01        ; "BONUS GAME" bottom
                      db $5F,$01,$5E

                      db $FF,$FF,$FF

TitleTextPropTop:     db $34,$00,$34,$34,$34,$34,$30,$00        ; "MARIO START!" top
                      db $34,$34,$34,$34,$74,$34

                      db $34,$34,$34,$34,$34,$00                ; "LUIGI" top

                      db $34,$34,$34,$34,$34,$34,$34,$34        ; "GAME OVER" top
                      db $34

                      db $34,$00,$34,$34,$34,$34,$34,$34        ; "TIME UP" top
                      db $34

                      db $34,$34,$34,$34,$34,$34,$34,$34        ; "BONUS GAME" top
                      db $34,$34,$34

TitleTextPropBottom:  db $34,$00,$B4,$34,$34,$B4,$F0,$00        ; "MARIO START!" bottom
                      db $B4,$B4,$34,$34,$74,$B4

                      db $B4,$34,$B4,$B4,$34,$00                ; "LUIGI" bottom

                      db $34,$B4,$34,$B4,$B4,$B4,$34,$34        ; "GAME OVER" bottom
                      db $34

                      db $34,$00,$34,$B4,$B4,$B4,$34,$B4        ; "TIME UP" bottom
                      db $B4

                      db $B4,$B4,$34,$34,$34,$34,$F4,$B4        ; "BONUS GAME" bottom
                      db $F4,$B4,$B4

CODE_00919B:          LDA.B PlayerAnimation
                      CMP.B #$0A
                      BNE CODE_0091A6
                      JSR CODE_00C593
                      BRA +

CODE_0091A6:          LDA.W SublevelCount
                      BNE +
                      LDA.B #$1E
                      STA.W GreenStarBlockCoins
                    + RTS

CODE_0091B1:          JSR CODE_00A82D
                      LDX.B #$00
                      LDA.B #$B0
                      LDY.W BonusGameActivate
                      BEQ +
                      STZ.W InGameTimerHundreds                 ; \
                      STZ.W InGameTimerTens                     ; |Set timer to 000
                      STZ.W InGameTimerOnes                     ; /
                      LDX.B #$26
                      LDA.B #$A4
                    + STA.B _0
                      STZ.B _1
                      LDY.B #$70
CODE_0091D0:          JSR CODE_0091E9
                      INX
                      CPX.B #$08
                      BNE +
                      LDA.W PlayerTurnLvl
                      BEQ +
                      LDX.B #$0E
                    + TYA
                      SEC
                      SBC.B #$08
                      TAY
                      BNE CODE_0091D0
                      JMP CODE_008494

CODE_0091E9:          LDA.W TitleTextPropTop,X
                      STA.W OAMTileAttr+$108,Y
                      LDA.W TitleTextPropBottom,X
                      STA.W OAMTileAttr+$10C,Y
                      LDA.B _0
                      STA.W OAMTileXPos+$108,Y
                      STA.W OAMTileXPos+$10C,Y
                      SEC
                      SBC.B #$08
                      STA.B _0
                      BCS +
                      DEC.B _1
                    + PHY
                      TYA
                      LSR A
                      LSR A
                      TAY
                      LDA.B _1
                      AND.B #$01
                      STA.W OAMTileSize+$42,Y
                      STA.W OAMTileSize+$43,Y
                      PLY
                      LDA.W TitleTextTileTop,X
                      BMI +
                      STA.W OAMTileNo+$108,Y
                      LDA.W TitleTextTileBottom,X
                      STA.W OAMTileNo+$10C,Y
                      LDA.B #$68
                      STA.W OAMTileYPos+$108,Y
                      LDA.B #$70
                      STA.W OAMTileYPos+$10C,Y
                    + RTS

CODE_00922F:          STZ.W MainPalette
                      STZ.W MainPalette+1
                      STZ.W HW_CGADD                            ; Set "Address for CG-RAM Write" to 0
                      LDX.B #$06
                    - LDA.W DATA_009249,X
                      STA.W HW_DMAPARAM+$20,X
                      DEX
                      BPL -
                      LDA.B #$04
                      STA.W HW_MDMAEN
                      RTS


DATA_009249:          db $00,$22
                      dl MainPalette
                      dw $0200

CODE_009250:          LDX.B #$04
                    - LDA.W DATA_009277,X
                      STA.W HW_DMAPARAM+$70,X
                      DEX
                      BPL -
                      LDA.B #$00
                      STA.W HW_HDMABANK+$70
CODE_009260:          STZ.W HDMAEnable                          ; Disable all HDMA channels
CODE_009263:          REP #$10                                  ; XY->16
                      LDX.W #con($01BE,$01BE,$01BE,$01BE,$01DE) ; \
                      LDA.B #$FF                                ; |
                    - STA.W WindowTable,X                       ; |Clear "HDMA table for windowing effects"
                      STZ.W WindowTable+1,X                     ; |...hang on again.  It clears one set of RAM here, but not the same
                      DEX                                       ; |
                      DEX                                       ; |
                      BPL -                                     ; /
                      SEP #$10                                  ; \ XY->8
                      RTS                                       ; /


DATA_009277:          db $41,$26
                      dl DATA_00927C

                   if ver_is_lores(!_VER)                       ;\================ J, U, SS, & E0 ===============
DATA_00927C:          db $F0                                    ;!
                      db $A0,$04                                ;!
                      db $F0                                    ;!
                      db $80,$05                                ;!
                      db $00                                    ;!
                   else                                         ;<======================= E1 ====================
DATA_00927C:          db $F8                                    ;!
                      db $A0,$04                                ;!
                      db $F8                                    ;!
                      db $90,$05                                ;!
                      db $00                                    ;!
                   endif                                        ;/===============================================

CODE_009283:          JSR CODE_009263
                      LDA.W IRQNMICommand
                      LSR A
                      BCS CODE_0092A0
                      REP #$10                                  ; XY->16
                      LDX.W #con($01BE,$01BE,$01BE,$01BE,$01DE)
                    - STZ.W WindowTable,X                       ; out?
                      LDA.B #$FF                                ; *note to self: ctrl+insert, not shift+insert*
                      STA.W WindowTable+1,X                     ; ...  This is, uh, strange.  It pastes $00FF into the $04A0,x table
                      INX                                       ; instead of $FF00 o_O
                      INX
                      CPX.W #con($01C0,$01C0,$01C0,$01C0,$01E0)
                      BCC -
CODE_0092A0:          LDA.B #$80                                ;  Enable channel 7 in HDMA, disable all other HDMA channels
                      STA.W HDMAEnable                          ;  $7E:0D9F - H-DMA Channel Enable RAM Mirror
                      SEP #$10                                  ; XY->8
                      RTS

CODE_0092A8:          JSR CODE_009263                           ; these are somewhat the same subroutine, but also not >_>
                      REP #$10                                  ; XY->16
                      LDX.W #$0198
                      BRA -

CODE_0092B2:          LDA.B #$58
                      STA.W WindowTable
                      STA.W WindowTable+$0A
                      STA.W WindowTable+$14
                      STZ.W WindowTable+9
                      STZ.W WindowTable+$13
                      STZ.W WindowTable+$1D
                      LDX.B #$04
                    - LDA.W DATA_009313,X
                      STA.W HW_DMAPARAM+$50,X
                      LDA.W DATA_009318,X
                      STA.W HW_DMAPARAM+$60,X
                      LDA.W DATA_00931D,X
                      STA.W HW_DMAPARAM+$70,X
                      DEX
                      BPL -
                      LDA.B #$00
                      STA.W HW_HDMABANK+$50
                      STA.W HW_HDMABANK+$60
                      STA.W HW_HDMABANK+$70
                      LDA.B #$E0
                      STA.W HDMAEnable
CODE_0092ED:          REP #$30                                  ; AXY->16
                      LDY.W #$0008
                      LDX.W #$0014
                    - LDA.W Layer1XPos,Y
                      STA.W WindowTable+1,X
                      STA.W WindowTable+4,X
                      LDA.W NextLayer1XPos,Y
                      STA.W WindowTable+7,X
                      TXA
                      SEC
                      SBC.W #$000A
                      TAX
                      DEY
                      DEY
                      DEY
                      DEY
                      BPL -
                      SEP #$30                                  ; AXY->8
                      RTS


DATA_009313:          db $02,$0D
                      dl WindowTable

DATA_009318:          db $02,$0F
                      dl WindowTable+$0A

DATA_00931D:          db $02,$11
                      dl WindowTable+$14

GetGameMode:          LDA.W GameMode                            ; Load game mode
                      JSL ExecutePtr

                      dw GameMode00                             ; 00 - load nintendo presents
                      dw GameMode01                             ; 01 - nintendo presents
                      dw GMTransition                           ; 02 - fade out to title screen
                      dw GameMode03                             ; 03 - load title screen
                      dw GameMode04                             ; 04 - prepare title screen
                      dw GMTransition                           ; 05 - fade in to title screen
                      dw GameMode06                             ; 06 - title screen spotlight
                      dw GameMode07                             ; 07 - title screen
                      dw GameMode08                             ; 08 - file select
                      dw GameMode09                             ; 09 - file delete
                      dw GameMode0A                             ; 0A - player select
                      dw GMTransition                           ; 0B - fade out to overworld
                      dw GameMode0C                             ; 0C - load overworld
                      dw GMTransition                           ; 0D - fade in to overworld
                      dw GameMode0E                             ; 0E - overworld
                      dw TempFade                               ; 0F - fade out to level
                      dw GameMode10                             ; 10 - finish fade to level
                      dw GameMode11                             ; 11 - load level
                      dw GameMode12                             ; 12 - prepare level
                      dw TempFade                               ; 13 - fade in to level
                      dw GameMode14                             ; 14 - level
                      dw GMTransition                           ; 15 - fade out to game over/time up
                      dw GameMode16                             ; 16 - load game over/time up
                      dw GameMode17                             ; 17 - game over/time up
                      dw GMTransition                           ; 18 - fade out to credits
                      dw GameMode19                             ; 19 - load credits
                      dw GMTransition                           ; 1A - fade in to credits
                      dw GameMode1B                             ; 1B - staff credits
                      dw GMTransition                           ; 1C - fade out to credits yoshi house
                      dw GameMode1D                             ; 1D - load credits yoshi house
                      dw GMTransition                           ; 1E - fade in to credits yoshi house
                      dw GameMode1F                             ; 1F - credits yoshi house
                      dw GMTransition                           ; 20 - fade out to load credits enemy list
                      dw GameMode21                             ; 21 - load credits enemy list
                      dw GMTransition                           ; 22 - fade out to credits enemy list
                      dw GameMode23                             ; 23 - prepare credits enemy list
                      dw GMTransition                           ; 24 - fade in to credits enemy list
                      dw GameMode25                             ; 25 - credits enemy list
                      dw GMTransition                           ; 26 - fade out to the end screen
                      dw GameMode27                             ; 27 - load the end screen
                      dw GameMode28                             ; 28 - fade in to the end screen
                      dw GameMode29                             ; 29 - the end screen

TurnOffIO:            STZ.W HW_NMITIMEN                         ; Disable NMI ,VIRQ, HIRQ, Joypads
                      STZ.W HW_HDMAEN                           ; Turn off all HDMA
                      LDA.B #$80                                ; \
                      STA.W HW_INIDISP                          ; /Disable Screen
                      RTS                                       ; And return


NintendoPos:          db $60,$70,$80,$90
NintendoTile:         db $02,$04,$06,$08                        ; Nintendo Presents tilemap

GameMode00:           JSR CODE_0085FA
                      JSR SetUpScreen
                      JSR CODE_00A993
                      LDY.B #$0C                                ; \ Load Nintendo Presents logo
                      LDX.B #$03                                ; |
                    - LDA.W NintendoPos,X                       ; |
                      STA.W OAMTileXPos,Y                       ; |
                      LDA.B #$70                                ; |   <-Y position of logo
                      STA.W OAMTileYPos,Y                       ; |
                      LDA.W NintendoTile,X                      ; |
                      STA.W OAMTileNo,Y                         ; |
                      LDA.B #$30                                ; |
                      STA.W OAMTileAttr,Y                       ; |
                      DEY                                       ; |
                      DEY                                       ; |
                      DEY                                       ; |
                      DEY                                       ; |
                      DEX                                       ; |
                      BPL -                                     ; /
                      LDA.B #$AA                                ; \ Related to making the sprites 16x16?
                      STA.W OAMTileBitSize                      ; /
                      LDA.B #!SFX_COIN                          ;; \ Play "Bing" sound?
                      STA.W SPCIO3                              ; /
                      LDA.B #$40                                ; \ Set timer to x40
                      STA.W VariousPromptTimer                  ; /
CODE_0093CA:          LDA.B #$0F                                ; \ Set brightness to max
                      STA.W Brightness                          ; /
                      LDA.B #$01
                      STA.W MosaicDirection
                      STZ.W SpritePalette                       ; Sprite palette setting = 0
                      JSR LoadPalette                           ; Load the palette
                      STZ.W BackgroundColor                     ; \ Black background
                      STZ.W BackgroundColor+1                   ; /
                      JSR CODE_00922F
                      STZ.W BlinkCursorPos                      ; Set menu pointer position to 0
                      LDX.B #$10                                ; Enable sprites, disable layers
                      LDY.B #$04                                ; Set Layer 3 to subscreen
CODE_0093EA:          LDA.B #$01
                      STA.W IRQNMICommand
                      LDA.B #$20                                ; CGADSUB = 20
                      JSR ScreenSettings                        ; Apply above settings
CODE_0093F4:          INC.W GameMode                            ; Move on to Game Mode 01
Mode04Finish:         LDA.B #$81                                ; \ Enable NMI and joypad, Disable V-count and H-cout
                      STA.W HW_NMITIMEN                         ; /
                      RTS

ScreenSettings:       STA.W HW_CGADSUB                          ; \ Set CGADSUB settings to A
                      STA.B ColorSettings                       ; /
                      STX.W HW_TM                               ; Set "Background and Object Enable" to X
                      STY.W HW_TS                               ; Set "Sub Screen Designation" Y
                      STZ.W HW_TMW                              ; \ Set "Window Mask Designation" for main and sub screen to x00
                      STZ.W HW_TSW                              ; /
                      RTS

GameMode01:           DEC.W VariousPromptTimer                  ; Decrease timer
                      BNE Return00941A                          ; \ If timer is 0:
                      JSR CODE_00B888                           ; |Jump to sub $B888
CODE_009417:          INC.W GameMode                            ; |Move on to Game Mode 02
Return00941A:         RTS

GameMode06:           JSR SetUp0DA0GM4
                      JSR CODE_009CBE
                      BEQ +
                      LDA.B #$EC
                      JSR CODE_009440
                      INC.W GameMode
                      JMP CODE_009C9F

                    + DEC.W VariousPromptTimer
                      BNE Return00941A
                      INC.W VariousPromptTimer
                      LDA.W SpotlightSize
                      CLC
                      ADC.B #$04
                      CMP.B #$F0
                      BCS CODE_009417
CODE_009440:          STA.W SpotlightSize
CODE_009443:          JSR CODE_00CA61
                      LDA.B #$80                                ; \
                      STA.B _0                                  ; |Store x80 in $00,
                      LDA.B #con($70,$70,$70,$70,$78)           ; |Store x70 in $01
                      STA.B _1                                  ; /
                      JMP CODE_00CA88


CutsceneBgColor:      db $02,$00,$04,$01,$00,$06,$04,$03

CutsceneCastlePal:    db $06,$05,$06,$03,$03,$06,$06,$03        ; Castle palette to use for cutscenes ; Purpose of first byte is unknown

CutsceneBackground:   db OtherStripes-StripeImages+$36
                      db OtherStripes-StripeImages+$36
                      db OtherStripes-StripeImages
                      db OtherStripes-OtherStripes+$0F
                      db OtherStripes-StripeImages+$36
                      db OtherStripes-StripeImages+3
                      db OtherStripes-StripeImages

GameMode19:           JSR CODE_0085FA
                      JSR Clear_1A_13D3
                      JSR SetUpScreen
                      LDX.W CutsceneID                          ; Cutscene number
                      LDA.B #$18
                      STA.W ObjectTileset
                      LDA.B #$14
                      STA.W SpriteTileset
                      LDA.W CutsceneBgColor-1,X
                      STA.W BackAreaColor
                      LDA.W CutsceneCastlePal-1,X
                      STA.W BackgroundPalette
                      STZ.W SpritePalette
                      LDA.B #$01
                      STA.W ForegroundPalette
                      CPX.B #$08
                      BNE CODE_0094B2
                      JSR CODE_00955E
                      LDA.B #OtherStripes-StripeImages+9
                      STA.B StripeImage
                      JSR LoadScrnImage
                      JSR UploadMusicBank3
                      JSL CODE_0C93DD
                      JSR CODE_009260
                      INC.W ObjectTileset
                      INC.W SpriteTileset
                      BRA +

CODE_0094B2:          LDA.B #!BGM_CUTSCENEINTRO
                      STA.W SPCIO2
                      LDA.W CutsceneBackground-1,X
                      STA.B StripeImage
                      JSR LoadScrnImage
                      LDA.B #OtherStripes-StripeImages+6
                      STA.B StripeImage
                      JSR LoadScrnImage
                      REP #$20                                  ; A->16
                      LDA.W #$0090
                      STA.B PlayerXPosNext
                      LDA.W #$0058
                      STA.B PlayerYPosNext
                      SEP #$20                                  ; A->8
                      INC.W IsCarryingItem
                    + JSR UploadSpriteGFX
                      JSR LoadPalette
                      JSR CODE_00922F
                      LDX.B #$0B
                    - STZ.B Layer1XPos,X
                      DEX
                      BPL -
                      LDA.B #$20
                      STA.B SpriteProperties
                      JSR CODE_00A635
                      STZ.B PlayerDirection
                      STZ.B PlayerInAir
                      JSL CODE_00CEB1
                      LDX.B #$17
                      LDY.B #$00
                      JSR CODE_009622
GameMode1B:           JSL OAMResetRoutine
                      LDA.W CutsceneID
                      CMP.B #$08
                      BEQ CODE_009557
                      LDA.B axlr0000Hold
                      AND.B #$00                                ; Change to #$30 to enter debug region below
                      CMP.B #$30
                      BNE CODE_009529
                      LDA.B byetudlrHold                        ; \ Unreachable
                      AND.B #$08                                ; | Debug: Boss defeated scene select
                      BEQ ADDR_009523                           ; |
                      LDA.W CutsceneID                          ; |
                      INC A                                     ; |
                      CMP.B #$09                                ; |
                      BCC +                                     ; |
                      LDA.B #$01                                ; |
                    + STA.W CutsceneID                          ; |
ADDR_009523:          LDA.B #$18                                ; |
                      STA.W GameMode                            ; |
                      RTS                                       ; /

CODE_009529:          JSL CODE_0CC97E
                      REP #$20                                  ; A->16
                      LDA.B Layer1XPos
                      PHA
                      LDA.B Layer1YPos
                      PHA
                      LDA.B Layer2XPos
                      STA.B Layer1XPos
                      LDA.B Layer2YPos
                      STA.B Layer1YPos
                      SEP #$20                                  ; A->8
                      JSL CODE_00E2BD
                      REP #$20                                  ; A->16
                      PLA
                      STA.B Layer1YPos
                      PLA
                      STA.B Layer1XPos
                      SEP #$20                                  ; A->8
                      LDA.B #$0C
                      STA.B PlayerAnimation
                      JSR CODE_00C47E
                      JMP CODE_008494

CODE_009557:          JSL CODE_0C938D
                      JMP CODE_008494

CODE_00955E:          LDY.B #$2F
                      JSL CODE_00BA28
                      LDA.B #$80
                      STA.W HW_VMAINC
                      REP #$30                                  ; AXY->16
                      LDA.W #$4600
                      STA.W HW_VMADD
                      LDX.W #$0200
                    - LDA.B [_0]
                      STA.W HW_VMDATA
                      INC.B _0
                      INC.B _0
                      DEX
                      BNE -
                      SEP #$30                                  ; AXY->8
                      RTS

GameMode1D:           INC.W CutsceneID
                      LDA.B #$28
                      LDY.B #$01
                      JSR CODE_0096CF
                      DEC.W GameMode
                      LDA.B #$16
                      STA.W SpriteTileset
                      JSR GameMode12
                      DEC.W GameMode
                      JSR TurnOffIO
                      JSR CODE_0085FA
                      JSR CODE_00A993
                      JSL CODE_0CA3C9
                      JSR CODE_00961E
GameMode1F:           JSL OAMResetRoutine
                      JSL CODE_0C939A
                      INC.B EffFrame
                      JSL CODE_05BB39
                      JMP CODE_008494

GameMode21:           JSL CODE_0C93AD
                      RTS

GameMode23:           JSR CODE_0085FA
                      JSR Clear_1A_13D3
                      JSR SetUpScreen
                      JSL CODE_0CAD8C
                      JSL CODE_05801E
                      LDA.W CreditsScreenNumber
                      CMP.B #$0A
                      BNE CODE_0095E0
                      LDA.B #$13
                      STA.W SpriteTileset
                      BRA +

CODE_0095E0:          CMP.B #$0C
                      BNE +
                      LDA.B #$17
                      STA.W SpriteTileset
                    + JSR UploadSpriteGFX
                      JSR LoadPalette
                      JSL CODE_05809E
                      JSR CODE_00A5F9
                      JSL CODE_0CADF6
                      LDA.W CreditsScreenNumber
                      CMP.B #$0C
                      BNE CODE_009612
                      LDX.B #$0B
                    - LDA.W SpriteColors+$A8,X
                      STA.W MainPalette+$104,X
                      LDA.W SpriteColors+$B4,X
                      STA.W MainPalette+$124,X
                      DEX
                      BPL -
CODE_009612:          JSR CODE_00922F
                      JSR CODE_0092B2
                      JSR LoadScrnImage
                      JSR GameMode25
CODE_00961E:          LDX.B #$15
                      LDY.B #$02
CODE_009622:          JSR KeepGameModeActive
                      LDA.B #$09
                      STA.B MainBGMode
                      JMP CODE_0093EA

GameMode25:           STZ.W PlayerGfxTileCount
                      JSR CODE_0092ED
                      JSL OAMResetRoutine
                      JSL CODE_0C93A5
                      JMP CODE_008494

GameMode27:           JSR CODE_0085FA
                      JSR Clear_1A_13D3
                      JSR SetUpScreen
                      JSR CODE_00955E
                      LDA.B #$19
                      STA.W SpriteTileset
                      LDA.B #$03
                      STA.W BackAreaColor
                      LDA.B #$03
                      STA.W BackgroundPalette
                      JSR UploadSpriteGFX
                      JSR LoadPalette
                      LDX.B #$0B
                    - LDA.W TheEndColors,X
                      STA.W MainPalette+$1A4,X
                      LDA.W TheEndColors+$0C,X
                      STA.W MainPalette+$1C4,X
                      LDA.W TheEndColors+$18,X
                      STA.W MainPalette+$1E4,X
                      DEX
                      BPL -
                      JSR CODE_00922F
                      LDA.B #OtherStripes-StripeImages+$0C
                      STA.B StripeImage
                      JSR LoadScrnImage
                      JSL CODE_0CAADF
                      JSR CODE_008494
                      LDX.B #$14
                      LDY.B #$00
                      JMP CODE_009622

GameMode29:           RTS

GameMode10:           JSR CODE_0085FA
                      LDA.W BonusGameActivate
                      BNE CODE_0096A8
                      LDA.W SublevelCount
                      ORA.W ShowMarioStart
                      ORA.W OverworldOverride
                      BNE +
                      LDA.W OverworldLayer1Tile
                      CMP.B #$56
                      BEQ +
CODE_0096A8:          JSR CODE_0091B1
                    + JMP CODE_0093CA

GameMode03:           STZ.W HW_NMITIMEN
                      JSR ClearStack
                      LDX.B #$07
                      LDA.B #$FF
                    - STA.W SpriteGFXFile,X
                      DEX
                      BPL -
                      LDA.W OverworldOverride
                      BNE +
                      JSR UploadMusicBank1
                      LDA.B #!BGM_TITLESCREEN                   ; \ Set title screen music
                      STA.W SPCIO2                              ; /
                    + LDA.B #$EB
                      LDY.B #$00
CODE_0096CF:          STA.W OverworldOverride
                      STY.W OWPlayerSubmap
GameMode11:           STZ.W HW_NMITIMEN
                      JSR NoButtons
                      LDA.W SublevelCount
                      BNE +
                      LDA.W ShowMarioStart
                      BEQ +
                      JSL CODE_04DC09
                    + STZ.W Layer3ScrollType
                      STZ.W OverworldProcess
                      LDA.B #$50
                      STA.W DrumrollTimer
                      JSL CODE_05D796
                      LDX.B #$07
                    - LDA.B Layer1XPos,X
                      STA.W NextLayer1XPos,X
                      DEX
                      BPL -
                      JSR CODE_008134
                      JSR CODE_00A635
                      LDA.B #$20
                      STA.B LastScreenHoriz
                      JSR CODE_00A796
                      INC.W ScreenScrollAtWill
                      JSL CODE_00F6DB
                      JSL CODE_05801E
                      LDA.W OverworldOverride
                      BEQ CODE_009728
                      CMP.B #$E9
                      BNE CODE_009740
                      LDA.B #$13
                      STA.W MusicBackup
CODE_009728:          LDA.W MusicBackup
                      CMP.B #$40
                      BCS CODE_00973B
                      LDY.W IRQNMICommand
                      CPY.B #$C1
                      BNE +
                      LDA.B #!BGM_BOWSERINTERLUDE
                    + STA.W SPCIO2
CODE_00973B:          AND.B #$BF
                      STA.W MusicBackup
CODE_009740:          STZ.W Brightness
                      STZ.W MosaicDirection
                      INC.W GameMode
                      JMP Mode04Finish

CODE_00974C:          JSR HexToDec
                      RTL

GameMode16:           JSR CODE_0085FA
                      JSR CODE_00A82D
                      JMP CODE_0093CA

GameMode17:           JSL OAMResetRoutine
                      LDA.W GameOverAnimation
                      BNE CODE_00978B
                      DEC.W GameOverTimer
                   if ver_is_ntsc(!_VER)                        ;\================== J, U, & SS =================
                      BNE CODE_00978E                           ;!
                   else                                         ;<=================== E0, & E1 ==================
                      LDY.W GameOverTimer                       ;!
                      CPY.B #$30                                ;!
                      BCS CODE_00978E                           ;!
                   endif                                        ;/===============================================
                      LDA.W PlayerLives
                      BPL CODE_009788
                      STZ.W CarryYoshiThruLvls
                      LDA.W SavedPlayerLives
                      ORA.W SavedPlayerLives+1
                      BPL CODE_009788
                      LDX.B #$0C
                    - STZ.W AllDragonCoinsCollected,X
                   if ver_is_japanese(!_VER)                    ;\======================= J =====================
                      STZ.W Checkpoint1upCollected,X            ;! it was correct...
                   else                                         ;<=============== U, SS, E0, & E1 ===============
                      STZ.W _6,X                                ;! then they f'd it up
                   endif                                        ;/===============================================
                      STZ.W MoonCollected,X
                      DEX
                      BPL -
                      INC.W ShowContinueEnd
CODE_009788:          JMP CODE_009E62

CODE_00978B:          SEC
                      SBC.B #$04
CODE_00978E:          STA.W GameOverAnimation
                      CLC
                      ADC.B #$A0
                      STA.B _0
                      ROL.B _1
                      LDX.W DeathMessage
                      LDY.B #$48
CODE_00979D:          CPY.B #$28
                      BNE +
                      LDA.B #$78
                      SEC
                      SBC.W GameOverAnimation
                      STA.B _0
                      ROL A
                      EOR.B #$01
                      STA.B _1
                    + JSR CODE_0091E9
                      INX
                      TYA
                      SEC
                      SBC.B #$08
                      TAY
                      BNE CODE_00979D
                      JMP CODE_008494

CODE_0097BC:          LDA.B #$0F
                      STA.W Brightness                          ; Set brightness to full (RAM mirror)
                      STZ.W MosaicSize
                      JSR GM__Mosaic
                      LDA.B #$20                                ; \
                      STA.B Mode7XScale                         ; |Not sure what these bytes are used for yet, unless they're just more
                      STA.B Mode7YScale                         ; /scratch (I find that unlikely)
                      STZ.W ScreenShakeYOffset
                      JSR CODE_0085FA
                      LDA.B #$FF
                      STA.W ObjectTileset
                      JSL CODE_03D958
                      BIT.W IRQNMICommand
                      BVC CODE_009801
                      JSR CODE_009925
                      LDY.W ActiveBoss
                      CPY.B #$03
                      BCC CODE_0097F1
                      BNE CODE_00983B
                      LDA.B #$18
                      BRA +

CODE_0097F1:          LDA.B #$03
                      STA.W PlayerBehindNet
                      LDA.B #$C8
                      STA.B OAMAddress
                      LDA.B #$12
                    + DEC.W ObjectTileset
                      BRA +

CODE_009801:          JSR CODE_00ADD9
                      JSR CODE_0092A8
                      LDX.B #$50
                      JSR CODE_009A3D
                      REP #$20                                  ; A->16
                      LDA.W #$0050
                      STA.B PlayerXPosNext
                      LDA.W #$FFD0
                      STA.B PlayerYPosNext
                      STZ.B Layer1XPos
                      STZ.W NextLayer1XPos
                      LDA.W #$FF90
                      STA.B Layer1YPos
                      STA.W NextLayer1YPos
                      LDA.W #$0080
                      STA.B Mode7CenterX
                      LDA.W #$0050
                      STA.B Mode7CenterY
                      LDA.W #$0080
                      STA.B Mode7XPos
                      LDA.W #$0010
                      STA.B Mode7YPos
                      SEP #$20                                  ; A->8
CODE_00983B:          LDA.B #$13
                    + STA.W SpriteTileset
                      JSR UploadSpriteGFX
                      LDA.B #$11
                      STA.W HW_TMW
                      STZ.W HW_TS
                      STZ.W HW_TSW
                      LDA.B #$02
                      STA.B Layer12Window
                      LDA.B #$32
                      STA.B OBJCWWindow
                      LDA.B #$20
                      STA.B ColorAddition
                      JSR GM04DoDMA
                      JSR CODE_008ACD
CODE_009860:          JSL CODE_00E2BD
                      JSR CODE_00A2F3
                      JSR CODE_00C593
                      STZ.B PlayerYSpeed                        ; Y speed = 0
                      JSL CODE_01808C
                      JSL OAMResetRoutine
                      RTS


                      db $01,$00,$FF,$FF,$40,$00,$C0,$01

CODE_00987D:          JSR CODE_008ACD
                      BIT.W IRQNMICommand
                      BVC +
                      JMP CODE_009A52

                    + JSL OAMResetRoutine
                      JSL CODE_03C0C6
                      RTS


DATA_009891:          dw $129E,$121E,$119E,$111E
                      dw $161E,$159E,$151E,$149E
                      dw $141E,$139E,$131E,$169E

CODE_0098A9:          LDA.W IRQNMICommand                       ; \
                      LSR A                                     ; |If "Special level" is even,
                      BCS +                                     ; / branch to $98E1
                      LDA.B EffFrame
                      LSR A
                      LSR A
                      AND.B #$06
                      TAX
                      REP #$20                                  ; A->16
                      LDY.B #$80
                      STY.W HW_VMAINC
                      LDA.W #$1801
                      STA.W HW_DMAPARAM+$20
                      LDA.W #$7800
                      STA.W HW_VMADD
                      LDA.L DATA_05BA39,X
                      STA.W HW_DMAADDR+$20
                      LDY.B #AnimatedTiles>>16
                      STY.W HW_DMAADDR+$22
                      LDA.W #$0080
                      STA.W HW_DMACNT+$20
                      LDY.B #$04
                      STY.W HW_MDMAEN
                      CLC
                    + REP #$20                                  ; A->16
                      LDA.W #$0004
                      LDY.B #$06
                      BCC +
                      LDA.W #$0008
                      LDY.B #$16
                    + STA.B _0
                      LDA.W #Mode7BossTilemap
                      STA.B _2
                      STZ.W HW_VMAINC
                      LDA.W #$1800
                      STA.W HW_DMAPARAM+$20
                      LDX.B #Mode7BossTilemap>>16
                      STX.W HW_DMAADDR+$22
                      LDX.B #$04
                    - LDA.W DATA_009891,Y
                      STA.W HW_VMADD
                      LDA.B _2
                      STA.W HW_DMAADDR+$20
                      CLC
                      ADC.B _0
                      STA.B _2
                      LDA.B _0
                      STA.W HW_DMACNT+$20
                      STX.W HW_MDMAEN
                      DEY
                      DEY
                      BPL -
                      SEP #$20                                  ; A->8
                      RTS

CODE_009925:          STZ.B PlayerYPosNext+1
                      REP #$20                                  ; A->16
                      LDA.W #$0020
                      STA.B PlayerXPosNext
                      STZ.B Layer1XPos
                      STZ.W NextLayer1XPos
                      STZ.B Layer1YPos
                      STZ.W NextLayer1YPos
                      LDA.W #$0080
                      STA.B Mode7CenterX
                      LDA.W #$00A0
                      STA.B Mode7CenterY
                      SEP #$20                                  ; A->8
                      JSR CODE_00AE15
                      JSL CODE_01808C
                      LDA.W IRQNMICommand
                      LSR A
                      LDX.B #con($C0,$C0,$C0,$C0,$D0)
                      LDA.B #con($A0,$A0,$A0,$A0,$B0)
                      BCC +
                      STZ.W HorizLayer1Setting
                      JMP CODE_009A17

                    + REP #$30                                  ; AXY->16
                      LDA.W ActiveBoss
                      AND.W #$00FF
                      ASL A
                      TAX
                      LDY.W #con($02C0,$02C0,$02C0,$02C0,$0300)
                      LDA.W DATA_00F8E8,X
                      BPL +
                      LDY.W #con($FB80,$FB80,$FB80,$FB80,$FBC0)
                    + CMP.W #$0012
                      BNE +
                      LDY.W #con($0320,$0320,$0320,$0320,$0360)
                    + STY.B _0
                      LDX.W #$0000
                      LDA.W #$C05A
CODE_009980:          STA.L DynamicStripeImage,X
                      XBA
                      CLC
                      ADC.W #con($0080,$0080,$0080,$0080,$00C0)
                      XBA
                      STA.L DynamicStripeImage+$84,X
                      XBA
                      SEC
                      SBC.B _0
                      XBA
                      STA.L DynamicStripeImage+$108,X
                      LDA.W #$7F00
                      STA.L DynamicStripeImage+2,X
                      STA.L DynamicStripeImage+$86,X
                      STA.L DynamicStripeImage+$10A,X
                      LDY.W #$0010
                    - LDA.W #$38A2
                      STA.L DynamicStripeImage+4,X
                      INC A
                      STA.L DynamicStripeImage+6,X
                      LDA.W #$38B2
                      STA.L DynamicStripeImage+$44,X
                      INC A
                      STA.L DynamicStripeImage+$46,X
                      LDA.W #$2C80
                      STA.L DynamicStripeImage+$88,X
                      INC A
                      STA.L DynamicStripeImage+$8A,X
                      INC A
                      STA.L DynamicStripeImage+$C8,X
                      INC A
                      STA.L DynamicStripeImage+$CA,X
                      LDA.W #$28A0
                      STA.L DynamicStripeImage+$10C,X
                      INC A
                      STA.L DynamicStripeImage+$10E,X
                      LDA.W #$28B0
                      STA.L DynamicStripeImage+$14C,X
                      INC A
                      STA.L DynamicStripeImage+$14E,X
                      INX
                      INX
                      INX
                      INX
                      DEY
                      BNE -
                      TXA
                      CLC
                      ADC.W #$014C
                      TAX
                      LDA.W #$C05E
                      CPX.W #$0318
                      BCS +
                      JMP CODE_009980

                    + LDA.W #$00FF
                      STA.L DynamicStripeImage,X
                      SEP #$30                                  ; AXY->8
                      JSR LoadScrnImage
                      LDX.B #$B0
                      LDA.B #$90
CODE_009A17:          STA.B PlayerYPosNext
                      JSR CODE_009A1F
                      JMP CODE_009283

CODE_009A1F:          LDY.B #$10
                      LDA.B #$32
                    - STA.L Map16TilesLow,X
                      STA.L Map16TilesLow+$1B0,X
                      STA.L Map16TilesHigh,X
                      STA.L Map16TilesHigh+$1B0,X
                      INX
                      DEY
                      BNE -
                      CPX.B #$C0
                      BNE Return009A4D
                      LDX.B #con($D0,$D0,$D0,$D0,$E0)
CODE_009A3D:          LDY.B #$10
                      LDA.B #$05
                    - STA.L Map16TilesLow,X
                      STA.L Map16TilesLow+$1B0,X
                      INX
                      DEY
                      BNE -
Return009A4D:         RTS


                      db $FF,$01,$18,$30

CODE_009A52:          LDA.W IRQNMICommand
                      LSR A
                      BCS +
                      JSL CODE_00F6DB
                      JSL CODE_05BC00
                      LDA.W ActiveBoss
                      CMP.B #$04
                      BEQ +
                      JSR CODE_0086C7
                      JSL CODE_02827D
                      RTS

                    + JSL OAMResetRoutine
                      RTS

SetUp0DA0GM4:         LDA.W HW_JOY1                             ; \Read old-style controller register for player 1
                      LSR A                                     ; /LSR A, but then discard (Is this for carry flag or something?)
                      LDA.W HW_JOY2                             ; \Load And Rotate left A (player 2 old-style controller regs)
                      ROL A                                     ; /
                      AND.B #$03                                ; AND A with #$03
                      BEQ CODE_009A87                           ; If A AND #$03 = 0 Then STA $0DA0 (A=0)
                      CMP.B #$03
                      BNE +
                      ORA.B #$80
                    + DEC A
CODE_009A87:          STA.W ControllersPresent
                      RTS                                       ; *yawn*

GameMode04:           JSR SetUp0DA0GM4
                      JSR GameMode12
                      STZ.W InGameTimerHundreds                 ; Zero the timer
                      JSR CODE_0085FA
                      LDA.B #$03                                ; \ Load title screen Layer 3 image
                      STA.B StripeImage                         ; |
                      JSR LoadScrnImage                         ; /
                      JSR CODE_00ADA6
                      JSR CODE_00922F
                      JSL CODE_04F675                           ; todo: NOTE TO SELF: Check this routine out after making Bank4.asm
                      LDA.B #$01                                ; \ Set special level to x01
                      STA.W IRQNMICommand                       ; /
                      LDA.B #$33
                      STA.B Layer12Window
                      LDA.B #$00
                      STA.B Layer34Window
                      LDA.B #$23
                      STA.B OBJCWWindow
                      LDA.B #$12
                      STA.B ColorAddition
                      JSR CODE_009443
                      LDA.B #$10
                      STA.W VariousPromptTimer
                      JMP Mode04Finish


DATA_009AC8:          db $01,$FF,$FF

CODE_009ACB:          PHY
                      JSR SetUp0DA0GM4
                      PLY
CODE_009AD0:          INC.W BlinkCursorTimer                    ; Blinking cursor frame counter (file select, save prompt, etc)
                      JSR CODE_009E82
                      LDX.W BlinkCursorPos
                      LDA.B byetudlrFrame
                      AND.B #$90
                      BNE CODE_009AE3
                      LDA.B axlr0000Frame
                      BPL CODE_009AEA
CODE_009AE3:          LDA.B #!SFX_COIN
                      STA.W SPCIO3
                      BRA CODE_009B11

CODE_009AEA:          PLA
                      PLA
                      LDA.B byetudlrFrame
                      AND.B #$20
                      LSR A
                      LSR A
                      LSR A
                      ORA.B byetudlrFrame
                      AND.B #$0C
                      BEQ Return009B16
                      LDY.B #!SFX_FIREBALL
                      STY.W SPCIO3
                      STZ.W BlinkCursorTimer
                      LSR A
                      LSR A
                      TAY
                      TXA
                      ADC.W DATA_009AC8-1,Y
                      BPL +
                      LDA.B GraphicsCompPtr
                      DEC A
                    + CMP.B GraphicsCompPtr
                      BCC +
CODE_009B11:          LDA.B #$00
                    + STA.W BlinkCursorPos
Return009B16:         RTS

                   if ver_is_console(!_VER)                     ;\=============== J, U, E0, & E1 ================
DATA_009B17:          db $04,$02,$01                            ;!
                                                                ;!
GameMode09:           REP #$20                                  ;! A->16
                      LDA.W #$39C9                              ;!
                      LDY.B #$60                                ;!
                      JSR CODE_009D30                           ;!
                      LDA.B byetudlrFrame                       ;!
                      ORA.B axlr0000Frame                       ;!
                      AND.B #$40                                ;!
                      BEQ +                                     ;!
                   else                                         ;<======================== SS ===================
GameMode09:                                                     ;!
                   endif                                        ;/===============================================
CODE_009B2C:          DEC.W GameMode
                      DEC.W GameMode
                      JSR CODE_009B11
                      JMP CODE_009CB0

                   if ver_is_console(!_VER)                     ;\================= J, U, E0, & E1 ==============
                    + LDY.B #$08                                ;!
                      JSR CODE_009AD0                           ;!
                      CPX.B #$03                                ;!
                      BNE CODE_009B6D                           ;!
                      LDY.B #$02                                ;!
CODE_009B43:          LSR.W SaveFileDelete                      ;!
                      BCC CODE_009B67                           ;!
                      PHY                                       ;!
                      LDA.W DATA_009CCB,Y                       ;!
                      XBA                                       ;!
                      LDA.W DATA_009CCE,Y                       ;!
                      REP #$10                                  ;! XY->16
                      TAX                                       ;!
                      LDY.W #$008F                              ;!
                      LDA.B #$00                                ;!
                    - STA.L SaveData,X                          ;!
                      STA.L SaveDataBackup,X                    ;!
                      INX                                       ;!
                      DEY                                       ;!
                      BNE -                                     ;!
                      SEP #$10                                  ;! XY->8
                      PLY                                       ;!
CODE_009B67:          DEY                                       ;!
                      BPL CODE_009B43                           ;!
                      JMP CODE_009C89                           ;!
                                                                ;!
CODE_009B6D:          STX.W BlinkCursorPos                      ;!
                      LDA.W DATA_009B17,X                       ;!
                      ORA.W SaveFileDelete                      ;!
                      STA.W SaveFileDelete                      ;!
                      STA.B _5                                  ;!
                   if ver_is_japanese(!_VER)                    ;!\======================= J ====================
                      LDY.B #$0C                                ;!!
                   else                                         ;!<================== U, E0, & E1 ===============
                      LDX.B #$00                                ;!!
                   endif                                        ;!/==============================================
                      JMP CODE_009D3C                           ;!
                                                                ;!
CODE_009B80:          PHB                                       ;! Wrapper
                      PHK                                       ;!
                      PLB                                       ;!
                      JSR CODE_009B88                           ;!
                      PLB                                       ;!
                      RTL                                       ;!
                                                                ;!
CODE_009B88:          DEC A                                     ;!
                      JSL ExecutePtr                            ;!
                                                                ;!
                      dw CODE_009B91                            ;!
                      dw CODE_009B9A                            ;!
                                                                ;!
CODE_009B91:          LDY.B #$0C                                ;!
                      JSR CODE_009D29                           ;!
                      INC.W ShowContinueEnd                     ;!
                      RTS                                       ;!
                                                                ;!
CODE_009B9A:          LDY.B #$00                                ;!
                      JSR CODE_009AD0                           ;!
                      TXA                                       ;!
                      BNE +                                     ;!
                      JMP CODE_009E17                           ;!
                                                                ;!
                    + JMP CODE_009C89                           ;!
                                                                ;!
CODE_009BA8:          PHB                                       ;! Wrapper
                      PHK                                       ;!
                      PLB                                       ;!
                      JSR CODE_009BB0                           ;!
                      PLB                                       ;!
                      RTL                                       ;!
                                                                ;!
CODE_009BB0:          LDY.B #$06                                ;!
                      JSR CODE_009AD0                           ;!
                      TXA                                       ;!
                      BNE +                                     ;!
                      STZ.W SPCIO3                              ;!
                      LDA.B #!SFX_MIDWAY                        ;!
                      STA.W SPCIO0                              ;!
                      JSL CODE_009BC9                           ;!
                    + JSL CODE_009C13                           ;!
                      RTS                                       ;!
                                                                ;!
CODE_009BC9:          PHB                                       ;!
                      PHK                                       ;!
                      PLB                                       ;!
                      LDX.W SaveFile                            ;!
                      LDA.W DATA_009CCB,X                       ;!
                      XBA                                       ;!
                      LDA.W DATA_009CCE,X                       ;!
                      REP #$10                                  ;! XY->16
                      TAX                                       ;!
CODE_009BD9:          LDY.W #$0000                              ;!
                      STY.B GraphicsCompPtr                     ;!
CODE_009BDE:          LDA.W SaveDataBuffer,Y                    ;!
                      STA.L SaveData,X                          ;!
                      CLC                                       ;!
                      ADC.B GraphicsCompPtr                     ;!
                      STA.B GraphicsCompPtr                     ;!
                      BCC +                                     ;!
                      INC.B GraphicsCompPtr+1                   ;!
                    + INX                                       ;!
                      INY                                       ;!
                      CPY.W #$008D                              ;!
                      BCC CODE_009BDE                           ;!
                      REP #$20                                  ;! A->16
                      LDA.W #$5A5A                              ;!
                      SEC                                       ;!
                      SBC.B GraphicsCompPtr                     ;!
                      STA.L SaveData,X                          ;!
                      CPX.W #$01AD                              ;!
                      BCS CODE_009C0F                           ;!
                      TXA                                       ;!
                      ADC.W #$0120                              ;!
                      TAX                                       ;!
                      SEP #$20                                  ;! A->8
                      BRA CODE_009BD9                           ;!
                                                                ;!
CODE_009C0F:          SEP #$30                                  ;! AXY->8
                      PLB                                       ;!
                      RTL                                       ;!
                   else                                         ;<====================== SS =====================
CODE_009B80:          RTL                                       ;!
CODE_009B88:          RTS                                       ;! unused?
CODE_009BA8:          RTL                                       ;!
CODE_009BC9:          RTL                                       ;!
                   endif                                        ;/===============================================

CODE_009C13:          INC.W OverworldPromptProcess
                      INC.W MessageBoxExpand
                      LDY.B #$1B
                      JSR CODE_009D29
                      RTL


                   if ver_is_ntsc(!_VER)                        ;\=================== J, U, & SS ================
ItrCntrlrSqnc:        db $41,$0F,$C1,$30,$00,$10,$42,$20        ;!
                      db $41,$70,$81,$11,$00,$80,$82,$0C        ;!
                      db $00,$30,$C1,$30,$41,$60,$C1,$10        ;!
                      db $00,$40,$01,$30,$E1,$01,$00,$60        ;!
                      db $41,$4E,$80,$10,$00,$30,$41,$58        ;!
                      db $00,$20,$60,$01,$00,$30,$60,$01        ;!
                      db $00,$30,$60,$01,$00,$30,$60,$01        ;!
                      db $00,$30,$60,$01,$00,$30,$41,$1A        ;!
                      db $C1,$30,$00,$30,$FF                    ;!
                   else                                         ;<===================== E0 & E1 =================
ItrCntrlrSqnc:        db $41,$0D,$C1,$30,$00,$10,$42,$26        ;!
                      db $41,$58,$81,$17,$00,$7A,$82,$0C        ;!
                      db $00,$34,$C1,$2A,$41,$50,$C1,$0C        ;!
                      db $00,$30,$01,$20,$E1,$01,$00,$60        ;!
                      db $41,$30,$80,$10,$00,$30,$41,$4E        ;!
                      db $00,$20,$60,$01,$00,$30,$60,$01        ;!
                      db $00,$30,$60,$01,$00,$30,$60,$01        ;!
                      db $00,$30,$60,$01,$00,$30,$41,$15        ;!
                      db $C1,$30,$00,$30,$FF                    ;!
                   endif                                        ;/===============================================

GameMode07:           JSR SetUp0DA0GM4
                      JSR CODE_009CBE
                      BNE CODE_009C9F
                      JSR NoButtons                             ; Zero controller RAM mirror
                      LDX.W TitleInputIndex                     ; (Unknown byte) -> X
                      DEC.W VariousPromptTimer                  ; Decrement $1DF5 (unknown byte)
                      BNE +                                     ; if !=  0 branch forward
                      LDA.W ItrCntrlrSqnc+1,X                   ; Load $00/9C20,$1DF4
                      STA.W VariousPromptTimer                  ; And store to $1DF5
                      INX
                      INX                                       ; $1DF4+=2
                      STX.W TitleInputIndex
                    + LDA.W ItrCntrlrSqnc-2,X                   ; With the +=2 above, this is effectively LDA $9C20,$1DF4
                      CMP.B #$FF
                      BNE +
CODE_009C89:          LDY.B #$02                                ; If = #$FF, switch to game mode #$02...
CODE_009C8B:          STY.W GameMode
                      RTS                                       ; ...And finish

                    + AND.B #$DF
                      STA.B byetudlrHold                        ; Write to controller RAM byte 01
                      CMP.W ItrCntrlrSqnc-2,X
                      BNE +
                      AND.B #$9F
                    + STA.B byetudlrFrame                       ; Write to byte 01, Just-pressed variant
                      JMP GameMode14                            ; Jump to another section of this routine

CODE_009C9F:          JSL OAMResetRoutine                       ; IIRC, this contains a lot of STZ instructions
                      LDA.B #$04
                      STA.W HW_TM                               ; Zero something related to PPU
                      LDA.B #$13
                      STA.W HW_TS
                   if ver_is_japanese(!_VER)                    ;\======================= J =====================
CODE_009CB0:          LDA.B #$E9                                ;!
                      STA.W OverworldOverride                   ;!
                      JSR CODE_WRITEOW                          ;!
                      LDY.B #$0E                                ;!
                      JSR CODE_009D3A                           ;!
                      LDA.B #$FF                                ;!
                      STA.L DynamicStripeImage+$9C              ;!
                   elseif ver_is_arcade(!_VER)                  ;<====================== SS =====================
CODE_009CB0:          LDA.B #$E9                                ;!
                      STA.W OverworldOverride                   ;! #$E9 -> Uknown RAM byte
                      JSR CODE_WRITEOW                          ;!
                      JSR CODE_009D38                           ;! -> here
                   else                                         ;<================== U, E0, & E1 ================
                      STZ.W HDMAEnable                          ;! Disable all HDMA
CODE_009CB0:          LDA.B #$E9                                ;!
                      STA.W OverworldOverride                   ;! #$E9 -> Uknown RAM byte
                      JSR CODE_WRITEOW                          ;!
                      JSR CODE_009D38                           ;! -> here
                   endif                                        ;/===============================================
                      JMP CODE_009417                           ; Increase the Game mode and return (at jump point)

CODE_009CBE:          LDA.B axlr0000Hold
                      AND.B #$C0
                      BNE +
                      LDA.B byetudlrHold
                      AND.B #$F0
                      BNE +
                    + RTS


DATA_009CCB:          db SaveData>>8
                      db SaveDataFile2>>8
                      db SaveDataFile3>>8

DATA_009CCE:          db SaveData
                      db SaveDataFile2
                      db SaveDataFile3

                   if ver_is_arcade(!_VER)                      ;\======================= SS ====================
SSDATA_009BE2:        db $52,$06,$C0,$0C,$FC,$38,$52,$10        ;!
                      db $C0,$08,$FC,$38,$52,$06,$00,$01        ;!
                      db $FC,$38,$FF                            ;!
                                                                ;!
SSDATA_009BF5:        db $06,$46,$86,$C6,$10,$50,$90            ;!
                                                                ;!
SSDATA_009BFC:        db $07,$FF                                ;!
SSDATA_009BFE:        db $00,$06                                ;!
                                                                ;!
GameMode08:           REP #$20                                  ;! A->16
                      LDA.W #$7393                              ;!
                      LDY.B #$20                                ;!
                      JSR CODE_009D30                           ;!
                      LDA.B byetudlrFrame                       ;!
                      AND.B #$90                                ;!
                      BNE SSCODE_009C6D                         ;!
                      LDA.B axlr0000Frame                       ;!
                      BMI SSCODE_009C6D                         ;!
                      LDA.B byetudlrFrame                       ;!
                      AND.B #$0C                                ;!
                      BEQ SSCODE_009C3B                         ;!
                      LDY.B #!SFX_FIREBALL                      ;!
                      STY.W SPCIO3                              ;!
                      LSR A                                     ;!
                      LSR A                                     ;!
                      LSR A                                     ;!
                      TAX                                       ;!
                      LDY.W Layer2ScrollType                    ;!
                      INY                                       ;!
                      CMP.B #$01                                ;!
                      BNE +                                     ;!
                      DEY                                       ;!
                      DEY                                       ;!
                    + TYA                                       ;!
                      CMP.W SSDATA_009BFC,X                     ;!
                      BNE +                                     ;!
                      LDY.W SSDATA_009BFE,X                     ;!
                    + STY.W Layer2ScrollType                    ;!
SSCODE_009C3B:        REP #$10                                  ;! XY->16
                      LDY.W #$3D2E                              ;!
                      LDA.B TrueFrame                           ;!
                      AND.B #$1F                                ;!
                      CMP.B #$18                                ;!
                      BCC +                                     ;!
                      LDY.W #$38FC                              ;!
                    + LDX.W #$0000                              ;!
                    - LDA.W SSDATA_009BE2,X                     ;!
                      STA.L DynamicStripeImage,X                ;!
                      INX                                       ;!
                      CPX.W #$0013                              ;!
                      BNE -                                     ;!
                      LDX.W Layer2ScrollType                    ;!
                      LDA.W SSDATA_009BF5,X                     ;!
                      STA.L DynamicStripeImage+$0D              ;!
                      REP #$20                                  ;! A->16
                      TYA                                       ;!
                      STA.L DynamicStripeImage+$10              ;!
                      SEP #$30                                  ;! AXY->8
                      RTS                                       ;!
                                                                ;!
SSCODE_009C6D:        LDA.B #!SFX_COIN                          ;!
                      STA.W SPCIO3                              ;!
                      SEP #$10                                  ;! XY->8
                      LDA.W Layer2ScrollType                    ;!
                      BEQ +                                     ;!
                      STZ.W OverworldOverride                   ;!
                    + INC.W GameMode                            ;!
                      JSR CODE_WRITEOW                          ;!
                   else                                         ;<================= J, U, E0, & E1 ==============
GameMode08:           REP #$20                                  ;! A->16
                      LDA.W #$7393                              ;!
                      LDY.B #$20                                ;!
                      JSR CODE_009D30                           ;!
                      LDY.B #$02                                ;!
                      JSR CODE_009ACB                           ;!
                      INC.W GameMode                            ;!
                      CPX.B #$03                                ;!
                      BNE +                                     ;!
                      STZ.W SaveFileDelete                      ;!
                   if ver_is_japanese(!_VER)                    ;!\====================== J =====================
                      LDY.B #$0C                                ;!!
                   else                                         ;!<================= U, E0, & E1 ================
                      LDX.B #$00                                ;!!
                   endif                                        ;!/==============================================
                      JMP CODE_009D3A                           ;!
                                                                ;!
                    + STX.W SaveFile                            ;!
                      JSR CODE_009DB5                           ;!
                      BNE CODE_009D22                           ;!
                      PHX                                       ;!
                      STZ.W OverworldOverride                   ;!
                      LDA.B #$8F                                ;!
                      STA.B _0                                  ;!
                    - LDA.L SaveData,X                          ;!
                      PHX                                       ;!
                      TYX                                       ;!
                      STA.L SaveData,X                          ;!
                      PLX                                       ;!
                      INX                                       ;!
                      INY                                       ;!
                      DEC.B _0                                  ;!
                      BNE -                                     ;!
                      PLX                                       ;!
                      LDY.W #$0000                              ;!
                    - LDA.L SaveData,X                          ;!
                      STA.W SaveDataBuffer,Y                    ;!
                      INX                                       ;!
                      INY                                       ;!
                      CPY.W #$008D                              ;!
                      BCC -                                     ;!
CODE_009D22:          SEP #$10                                  ;! XY->8
                   endif                                        ;/===============================================
                      LDY.B #$12                                ; \ Draw 1 PLAYER GAME/2 PLAYER GAME text
                      INC.W GameMode                            ; |Increase Game Mode
CODE_009D29:          STY.B StripeImage                         ; /
                      LDX.B #$00
                      JMP CODE_009ED4

CODE_009D30:          STA.W BackgroundColor                     ; Store A in BG color
                      STY.B ColorSettings                       ; Store Y in CGADSUB
                      SEP #$20                                  ; A->8
                      RTS

                   if ver_is_japanese(!_VER)                    ;\======================== J ====================
DATA_009CD2:          db $D4,$31,$FC,$38,$9D,$31,$FC,$38        ;!
                      db $8D,$31,$FC,$38,$FC,$38,$FC,$38        ;!
                                                                ;!
CODE_009D3A:          STZ.B _5                                  ;!
CODE_009D3C:          STY.B _6                                  ;!
                      LDX.B #$B0                                ;!
                    - LDA.L DATA_05B6FE-1,X                     ;! X =  read index
                      STA.L DynamicStripeImage-1,X              ;! Layer 3-related table
                      DEX                                       ;!
                      BNE -                                     ;!
                      LDA.B #$76                                ;!
                   elseif ver_is_arcade(!_VER)                  ;<======================== SS ===================
CODE_009D38:          LDX.B #$CB                                ;!
CODE_009D3C:          REP #$10                                  ;! XY->16
                      LDY.W #$0000                              ;!
                    - LDA.L DATA_05B6FE,X                       ;! X =  read index
                      PHX                                       ;! Y = write index
                      TYX                                       ;!
                      STA.L DynamicStripeImage,X                ;! Layer 3-related table
                      PLX                                       ;!
                      INX                                       ;!
                      INY                                       ;!
                      CPY.W #$00CC                              ;! If not at end of loop, continue
                      BNE -                                     ;!
                      SEP #$10                                  ;! XY->8
                   else                                         ;<=================== U, E0, & E1 ===============
CODE_009D38:          LDX.B #$CB                                ;!
CODE_009D3A:          STZ.B _5                                  ;!
CODE_009D3C:          REP #$10                                  ;! XY->16
                      LDY.W #$0000                              ;!
                    - LDA.L DATA_05B6FE,X                       ;! X =  read index
                      PHX                                       ;! Y = write index
                      TYX                                       ;!
                      STA.L DynamicStripeImage,X                ;! Layer 3-related table
                      PLX                                       ;!
                      INX                                       ;!
                      INY                                       ;!
                      CPY.W #$00CC                              ;! If not at end of loop, continue
                      BNE -                                     ;!
                      SEP #$10                                  ;! XY->8
                      LDA.B #$84                                ;!
                   endif                                        ;/===============================================

                   if ver_is_console(!_VER)                     ;\================= J, U, E0, & E1 ==============
                      STA.B _0                                  ;!
                      LDX.B #$02                                ;!
CODE_009D5B:          STX.B _4                                  ;!
                      LSR.B _5                                  ;! $05 = $05 / 2
                      BCS CODE_009DA6                           ;!
                      JSR CODE_009DB5                           ;!
                      BNE CODE_009DA6                           ;!
                      LDA.L SaveDataChecksum,X                  ;!
                      SEP #$10                                  ;! XY->8
                   if ver_is_english(!_VER)                     ;!\=================== U, E0, & E1 ==============
                      CMP.B #$60                                ;!!
                      BCC CODE_009D76                           ;!!
                      LDY.B #$87                                ;!!
                      LDA.B #$88                                ;!!
                      BRA +                                     ;!!
                   endif                                        ;!/==============================================
                                                                ;!
CODE_009D76:          JSR HexToDec                              ;!
                      TXY                                       ;!
                    + LDX.B _0                                  ;!
                      STA.L DynamicStripeImage+4,X              ;!
                      TYA                                       ;!
                      BNE +                                     ;!
                      LDY.B #$FC                                ;!
                    + TYA                                       ;!
                      STA.L DynamicStripeImage+2,X              ;!
                      LDA.B #$38                                ;!
                      STA.L DynamicStripeImage+3,X              ;!
                      STA.L DynamicStripeImage+5,X              ;!
                      REP #$20                                  ;! A->16
                   if ver_is_japanese(!_VER)                    ;!\======================= J ====================
                      LDA.W #$38FC                              ;!!
                      STA.L DynamicStripeImage+$12,X            ;!!
                      LDY.B _6                                  ;!!
                    - LDA.W DATA_009CD2,Y                       ;!!
                      STA.L DynamicStripeImage+6,X              ;!!
                      INX                                       ;!!
                      INX                                       ;!!
                      DEY                                       ;!!
                      DEY                                       ;!!
                      DEY                                       ;!!
                      DEY                                       ;!!
                      BPL -                                     ;!!
                      SEP #$20                                  ;!! A->8
CODE_009DA6:          SEP #$10                                  ;!! XY->8
                      LDA.B _0                                  ;!!
                      SEC                                       ;!!
                      SBC.B #$2A                                ;!!
                   else                                         ;!<=================== U, E0, & E1 ==============
                      LDY.B #$03                                ;!!
                    - LDA.W #$38FC                              ;!!
                      STA.L DynamicStripeImage+6,X              ;!!
                      INX                                       ;!!
                      INX                                       ;!!
                      DEY                                       ;!!
                      BNE -                                     ;!!
                      SEP #$20                                  ;!! A->8
CODE_009DA6:          SEP #$10                                  ;!! XY->8
                      LDA.B _0                                  ;!!
                      SEC                                       ;!!
                      SBC.B #$24                                ;!!
                   endif                                        ;!/==============================================
                      STA.B _0                                  ;!
                      LDX.B _4                                  ;!
                      DEX                                       ;!
                      BPL CODE_009D5B                           ;!
                      RTS                                       ;!
                                                                ;!
CODE_009DB5:          LDA.W DATA_009CCB,X                       ;!
                      XBA                                       ;!
                      LDA.W DATA_009CCE,X                       ;!
                      REP #$30                                  ;! AXY->16
                      TAX                                       ;!
                      CLC                                       ;!
                      ADC.W #$01AD                              ;!
                      TAY                                       ;!
CODE_009DC4:          PHX                                       ;!
                      PHY                                       ;!
                      LDA.L SaveDataChecksum+1,X                ;!
                      STA.B GraphicsCompPtr                     ;!
                      SEP #$20                                  ;! A->8
                      LDY.W #$008D                              ;!
CODE_009DD1:          LDA.L SaveData,X                          ;!
                      CLC                                       ;!
                      ADC.B GraphicsCompPtr                     ;!
                      STA.B GraphicsCompPtr                     ;!
                      BCC +                                     ;!
                      INC.B GraphicsCompPtr+1                   ;!
                    + INX                                       ;!
                      DEY                                       ;!
                      BNE CODE_009DD1                           ;!
                      REP #$20                                  ;! A->16
                      PLY                                       ;!
                      PLX                                       ;!
                      LDA.B GraphicsCompPtr                     ;!
                      CMP.W #$5A5A                              ;!
                      BEQ CODE_009DF7                           ;!
                      CPX.W #$01AC                              ;!
                      BCS CODE_009DF7                           ;!
                      PHX                                       ;!
                      TYX                                       ;!
                      PLY                                       ;!
                      BRA CODE_009DC4                           ;!
                                                                ;!
CODE_009DF7:          SEP #$20                                  ;! A->8
                      RTS                                       ;!
                   else                                         ;<========================= SS ==================  ELSE
                      RTS                                       ;!
                                                                ;!
                      RTS                                       ;! unused?
                   endif                                        ;/=============================================== ENDIF

GameMode0A:           LDA.B byetudlrFrame
                      ORA.B axlr0000Frame
                      AND.B #$40
                      BEQ +
                      DEC.W GameMode
                      JMP CODE_009B2C

                    + LDY.B #$04
                      JSR CODE_009ACB
                      STX.W IsTwoPlayerGame
                      JSR CODE_00A195
                      JSL CODE_04DAAD
CODE_009E17:          LDA.B #!BGM_FADEOUT
                      STA.W SPCIO2
                      LDA.B #$FF
                      STA.W SavedPlayerLives+1
                      LDX.W IsTwoPlayerGame
                      LDA.B #$04
                    - STA.W SavedPlayerLives,X
                      DEX
                      BPL -
                      STA.W PlayerLives
                      STZ.W PlayerCoins
                      STZ.W CarryYoshiThruLvls
                      STZ.B Powerup
                      STZ.W PlayerItembox
                      STZ.W ShowContinueEnd
                      REP #$20                                  ; A->16
                      STZ.W SavedPlayerCoins
                      STZ.W SavedPlayerPowerup
                      STZ.W SavedPlayerYoshi
                      STZ.W PlayerItembox
                      STZ.W PlayerBonusStars
                      STZ.W PlayerScore
                      STZ.W PlayerScore+3
                      SEP #$20                                  ; A->8
                      STZ.W PlayerScore+2
                      STZ.W PlayerScore+5
                      STZ.W OWLevelExitMode
                      STZ.W PlayerTurnLvl
CODE_009E62:          JSR KeepGameModeActive
                      LDY.B #$0B
                      JMP CODE_009C8B

CursorOptCount:       dw $0002                                  ; continue/end
                      dw $0004                                  ; file select
                      dw $0002                                  ; 1/2 player
                      dw $0002                                  ; save/no save
                      dw $0004                                  ; erase file select

                   if ver_is_japanese(!_VER)                    ;\======================= J =====================
CursorCoords:         dw $51CC                                  ;! continue/end
                      dw $5208                                  ;! file select
                      dw $5228                                  ;! 1/2 player
                      dw $5208                                  ;! save/no save
                      dw $5208                                  ;! erase file select
                   elseif ver_is_arcade(!_VER)                  ;<====================== SS =====================
CursorCoords:         dw $51CB                                  ;! continue/end
                      dw $5208                                  ;! file select
                      dw $5208                                  ;! 1/2 player
                      dw $51C4                                  ;! save/no save
                      dw $5205                                  ;! erase file select
                   else                                         ;<================== U, E0, & E1 ================
CursorCoords:         dw $51CB                                  ;! continue/end
                      dw $51E8                                  ;! file select
                      dw $5208                                  ;! 1/2 player
                      dw $51C4                                  ;! save/no save
                      dw $51E5                                  ;! erase file select
                   endif                                        ;/===============================================

DATA_009E7E:          db $01,$02,$04,$08

CODE_009E82:          LDX.W BlinkCursorPos
                      LDA.W DATA_009E7E,X
                      TAX
                      LDA.W BlinkCursorTimer
                      EOR.B #$1F
                      AND.B #$18
                      BNE +
                      LDX.B #$00
                    + STX.B _0
                      LDA.L DynStripeImgSize
                      TAX
                      REP #$20                                  ; A->16
                      LDA.W CursorOptCount,Y
                      STA.B GraphicsCompPtr
                      STA.B _2
                      LDA.W CursorCoords,Y
CODE_009EA7:          XBA
                      STA.L DynamicStripeImage,X
                      XBA
                      CLC
                      ADC.W #$0040
                      PHA
                      LDA.W #$0100
                      STA.L DynamicStripeImage+2,X
                      LDA.W #$38FC
                      LSR.B _0
                      BCC +
                      LDA.W #$3D2E
                    + STA.L DynamicStripeImage+4,X
                      PLA
                      INX
                      INX
                      INX
                      INX
                      INX
                      INX
                      DEC.B _2
                      BNE CODE_009EA7
                      SEP #$20                                  ; A->8
CODE_009ED4:          TXA
                      STA.L DynStripeImgSize
                      LDA.B #$FF
                      STA.L DynamicStripeImage,X
                      RTS

                   if ver_is_console(!_VER)                     ;\================ J, U, E0, & E1 ===============
TBL_009EE0:           db $28,$03                                ;! enable left/right on yoshi's house
                      db $4D,$01                                ;! enable right on special world star warp
                      db $52,$01                                ;! enable right on star world top star warp
                      db $53,$01                                ;! enable right on star world left star warp
                      db $5B,$08                                ;! enable up on star world bottom left star warp
                      db $5C,$02                                ;! enable left on star world bottom right star warp
                      db $57,$04                                ;! enable down on star world right star warp
                      db $30,$01                                ;! enable right on valley of bowser star warp
                                                                ;!
TBL_009EF0:           db $01,$01,$02,$00,$02,$00,$68,$00        ;! players submap, animation
                      db $78,$00,$68,$00,$78,$00,$06,$00        ;! players overworld X & Y
                      db $07,$00,$06,$00,$07,$00                ;!
                                                                ;!
CODE_WRITEOW:         LDX.B #$8D                                ;!
                    - STZ.W SaveDataBuffer-1,X                  ;!
                      DEX                                       ;!
                      BNE -                                     ;!
                      LDX.B #$0E                                ;!
                    - LDY.W TBL_009EE0,X                        ;! \
                      LDA.W TBL_009EE0+1,X                      ;! |Write overworld settings to OW L1 table
                      STA.W SaveDataBuffer,Y                    ;! /
                      DEX                                       ;!
                      DEX                                       ;!
                      BPL -                                     ;!
                      LDX.B #$15                                ;!
                    - LDA.W TBL_009EF0,X                        ;!
                      STA.W SaveDataBufferSubmap,X              ;! <- This probably means that the table above ends at 1FB7
                      DEX                                       ;!
                      BPL -                                     ;!
                      RTS                                       ;!
                   else                                         ;<========================= SS ==================
TBL_009EE0:           db $28,$83,$4D,$81,$52,$81,$53,$81        ;!
                      db $5B,$88,$5C,$82,$57,$84,$30,$81        ;!
                      db $29,$89,$2A,$8A,$27,$85,$26,$8C        ;!
                      db $25,$89,$15,$04,$15,$86,$09,$8E        ;!
                      db $04,$83,$05,$83,$06,$8A,$07,$8A        ;!
                      db $3E,$04,$3E,$85,$3C,$8D,$2B,$85        ;!
                      db $2E,$8C,$3D,$8C,$40,$8C,$0F,$02        ;!
                      db $0F,$83,$10,$86,$0E,$85,$42,$08        ;!
                      db $42,$89,$44,$8D,$47,$85,$20,$85        ;!
                      db $22,$08,$22,$8A,$21,$85,$24,$8A        ;!
                      db $23,$83,$1B,$85,$1D,$8A,$1C,$89        ;!
                      db $1A,$8C,$18,$02                        ;!
                                                                ;!
SSTBL_009DF5:         db $00,$10,$1C,$2A,$38,$40,$4A,$5C        ;!
                                                                ;!
TBL_009EF0:           db $00,$00,$00,$00,$00,$00,$00,$00        ;!
                      db $00,$00,$00,$00,$00,$00,$00,$01        ;!
                      db $01,$02,$00,$02,$00,$68,$00,$78        ;!
                      db $00,$68,$00,$78,$00,$06,$00,$07        ;!
                      db $00,$06,$00,$07,$00,$00,$00,$00        ;!
                      db $00,$7E,$00,$00,$00,$00,$00,$00        ;!
                      db $00,$00,$00,$00,$00,$00,$00,$00        ;!
                      db $00,$00,$02,$00,$02,$00,$58,$00        ;!
                      db $18,$01,$58,$00,$18,$01,$05,$00        ;!
                      db $11,$00,$05,$00,$11,$00,$00,$01        ;!
                      db $00,$00,$7F,$6F,$00,$00,$00,$80        ;!
                      db $00,$00,$00,$00,$00,$00,$00,$00        ;!
                      db $00,$02,$02,$02,$00,$02,$00,$58        ;!
                      db $00,$28,$01,$58,$00,$28,$01,$05        ;!
                      db $00,$12,$00,$05,$00,$12,$00,$01        ;!
                      db $01,$00,$00,$7F,$6F,$05,$F8,$00        ;!
                      db $C0,$00,$00,$00,$00,$00,$00,$00        ;!
                      db $00,$00,$00,$00,$02,$00,$02,$00        ;!
                      db $48,$01,$58,$00,$48,$01,$58,$00        ;!
                      db $14,$00,$05,$00,$14,$00,$05,$00        ;!
                      db $01,$01,$00,$01,$7F,$6F,$05,$F8        ;!
                      db $0D,$C0,$00,$00,$00,$00,$00,$00        ;!
                      db $00,$00,$00,$03,$03,$02,$00,$02        ;!
                      db $00,$88,$00,$78,$01,$88,$00,$78        ;!
                      db $01,$08,$00,$17,$00,$08,$00,$17        ;!
                      db $00,$01,$01,$00,$01,$7F,$6F,$05        ;!
                      db $F8,$0D,$ED,$01,$00,$00,$00,$00        ;!
                      db $00,$40,$00,$00,$00,$00,$02,$00        ;!
                      db $02,$00,$88,$01,$68,$01,$88,$01        ;!
                      db $68,$01,$18,$00,$16,$00,$18,$00        ;!
                      db $16,$00,$01,$01,$01,$01,$7F,$6F        ;!
                      db $05,$F8,$0D,$ED,$01,$00,$02,$7C        ;!
                      db $00,$00,$70,$00,$00,$00,$00,$02        ;!
                      db $00,$02,$00,$E8,$00,$78,$01,$E8        ;!
                      db $00,$78,$01,$0E,$00,$17,$00,$0E        ;!
                      db $00,$17,$00,$01,$01,$01,$01            ;!
                                                                ;!
SSTBL_009F1C:         dw $0028,$0051,$007A,$00A3                ;!
                      dw $00CC,$00F5,$011E                      ;!
                                                                ;!
CODE_WRITEOW:         LDX.B #$8D                                ;!
                    - STZ.W SaveDataBuffer-1,X                  ;!
                      DEX                                       ;!
                      BNE -                                     ;!
                      LDX.W Layer2ScrollType                    ;!
                      LDA.W SSTBL_009DF5+1,X                    ;!
                      STA.B _0                                  ;!
                      LDA.W SSTBL_009DF5                        ;!
                      TAX                                       ;!
                    - LDY.W TBL_009EE0,X                        ;!
                      LDA.W TBL_009EE0+1,X                      ;!
                      STA.W SaveDataBuffer,Y                    ;!
                      INX                                       ;!
                      INX                                       ;!
                      CPX.B _0                                  ;!
                      BNE -                                     ;!
                      REP #$30                                  ;! AXY->16
                      LDA.W Layer2ScrollType                    ;!
                      ASL A                                     ;!
                      TAX                                       ;!
                      LDY.W SSTBL_009F1C,X                      ;!
                      LDX.W #$0028                              ;!
                    - LDA.W TBL_009EF0,Y                        ;!
                      STA.W SaveDataBufferEvents,X              ;!
                      DEY                                       ;!
                      DEX                                       ;!
                      BPL -                                     ;!
                      SEP #$30                                  ;! AXY->8
                      RTS                                       ;!
                   endif                                        ;/===============================================

KeepGameModeActive:   LDA.B #$01
CODE_009F2B:          STA.W KeepModeActive
                      RTS

DATA_009F2F:          db $01,$FF
DATA_009F31:          db $F0,$10
DATA_009F33:          db $0F,$00
                      db $00,$F0

TempFade:             DEC.W KeepModeActive                      ; \If 0DB1 = 0 Then Exit Ssub
                      BPL Return009F6E                          ; /Decrease it either way.
                      JSR KeepGameModeActive                    ; #$01 -> $0DB1
                      LDY.W MosaicDirection
                      LDA.W MosaicSize                          ; \
                      CLC                                       ; |Increase $0DB0 (mosaic size) by $9F31,y
                      ADC.W DATA_009F31,Y                       ; |
                      STA.W MosaicSize                          ; /
CODE_009F4C:          LDA.W Brightness                          ; Load Brightness byte from RAM
                      CLC                                       ; \Add $9F2F,Y
                      ADC.W DATA_009F2F,Y                       ; /
                      STA.W Brightness                          ; Store back to brightness RAM byte
                      CMP.W DATA_009F33,Y
                      BNE +
GM__Mosaic:           INC.W GameMode                            ; Game Mode += 1
                      LDA.W MosaicDirection                     ; \
                      EOR.B #$01                                ; |$0DAF = $0DAF XOR 1
                      STA.W MosaicDirection                     ; /
                    + LDA.B #$03                                ; \
                      ORA.W MosaicSize                          ; |Set mosaic size to $0DB0, enable mosaic on Layer 1 and 2.
                      STA.W HW_MOSAIC                           ; /
Return009F6E:         RTS                                       ; I think we're done here

GMTransition:         DEC.W KeepModeActive                      ; Decrement something...  Seems like it might be a timing counter
                      BPL Return009F6E                          ; If positive, return from subroutine.
                      JSR KeepGameModeActive                    ; Remain in this mode
CODE_009F77:          LDY.W MosaicDirection                     ; $0DAF -> Y,
                      BRA CODE_009F4C                           ; BRA to the fade control routine

GameMode28:           DEC.W KeepModeActive
                      BPL Return009F6E
                      LDA.B #$08
                      JSR CODE_009F2B
                      BRA CODE_009F77

DATA_009F88:          db $01,$02,$C0
                      db $01,$80,$81
                      db $01,$02,$C0
                      db $01,$02,$81
                      db $01,$02,$80
                      db $01,$02,$81
                      db $01,$02,$81
                      db $01,$02,$C0
                      db $01,$02,$C0
                      db $01,$02,$81
                      db $01,$02,$80
                      db $01,$02,$80
                      db $01,$02,$80
                      db $01,$02,$81
                      db $01,$02,$81
                      db $01,$02,$80

CODE_009FB8:          LDA.W ObjectTileset                       ; \
                      ASL A                                     ; |Get (Tileset*3), store in $00
                      CLC                                       ; |
                      ADC.W ObjectTileset                       ; |
                      STA.B _0                                  ; /
                      LDA.W Layer3Setting
                      BEQ CODE_00A012
                      DEC A
                      CLC
                      ADC.B _0
                      TAX
                      LDA.W DATA_009F88,X
                      BMI CODE_009FEA
                      STA.W Layer3TideSetting
                      LSR A
                      PHP
                      JSR CODE_00A045
                      LDA.B #$70
                      PLP
                      BEQ +
                      LDA.B #$40
                    + STA.B Layer3YPos
                      STZ.B Layer3YPos+1
                      JSL CODE_05BC72
                      BRA CODE_00A01B

CODE_009FEA:          ASL A
                      BMI CODE_00A012
                      BEQ CODE_00A007
                      LDA.W ObjectTileset
                      CMP.B #$01
                      BEQ CODE_009FFA
                      CMP.B #$03
                      BNE CODE_00A01F
CODE_009FFA:          REP #$20                                  ; A->16
                      LDA.B Layer1XPos
                      LSR A
                      STA.B Layer3XPos
                      SEP #$20                                  ; A->8
                      LDA.B #$C0
                      BRA CODE_00A017

CODE_00A007:          LDX.B #$07
                    - LDA.W BigCrusherColors,X
                      STA.W MainPalette+$18,X
                      DEX
                      BPL -
CODE_00A012:          INC.W Layer3ScrollType
                      LDA.B #$D0
CODE_00A017:          STA.B Layer3YPos
                      STZ.B Layer3YPos+1
CODE_00A01B:          LDA.B #$04
                      TRB.B ColorSettings
CODE_00A01F:          LDA.W Layer3Setting
                      BEQ +
                      DEC A
                      CLC
                      ADC.B _0
                      STA.B _1
                      ASL A
                      CLC
                      ADC.B _1
                      TAX
                      LDA.L Layer3Ptr,X
                      STA.B _0
                      LDA.L Layer3Ptr+1,X
                      STA.B _1
                      LDA.L Layer3Ptr+2,X
                      STA.B _2
                      JSR CODE_00871E
                    + RTS

CODE_00A045:          REP #$30                                  ; AXY->16
                      LDX.W #$0100
CODE_00A04A:          LDY.W #$0058
                      LDA.W #$0000
                    - STA.L OWLayer1VramBuffer-$100,X
                      INX
                      INX
                      DEY
                      BNE -
                      TXA
                      CLC
                      ADC.W #$0100
                      TAX
                      CPX.W #$1B00
                      BCC CODE_00A04A
                      SEP #$30                                  ; AXY->8
                      LDA.B #$80
                      TSB.B ScreenMode
                      RTS


DATA_00A06B:          dw $0000,$FFEF,$FFEF,$FFEF
                      dw $00F0,$00F0,$00F0

DATA_00A079:          dw $0000,$FFD8,$0080,$0128
                      dw $FFD8,$0080,$0128

GameMode0C:           JSR TurnOffIO
                      LDA.W EnteringStarWarp
                      BEQ +
                      JSL CODE_04853B
                    + JSR Clear_1A_13D3
                      LDA.W OverworldOverride
                      BEQ +
                      LDA.B #con($B0,$B0,$B0,$90,$90)
                      STA.W VariousPromptTimer
                      STZ.W OWPlayerSubmap
                      LDA.B #$F0
                      STA.W MosaicSize
                      LDA.B #$10
                      STA.W GameMode
                      JMP Mode04Finish

                    + JSR CODE_0085FA
                      JSR UploadMusicBank1
                      JSR SetUpScreen
                      STZ.W MusicBackup
                      LDX.W PlayerTurnLvl
                      LDA.W PlayerLives
                   if ver_is_console(!_VER)                     ;\================ J, U, E0, & E1 ===============
                      BPL +                                     ;!
                      INC.W OverworldPromptProcess              ;!
                   endif                                        ;/===============================================
                    + STA.W SavedPlayerLives,X
                      LDA.B Powerup
                      STA.W SavedPlayerPowerup,X
                      LDA.W PlayerCoins
                      STA.W SavedPlayerCoins,X
                      LDA.W CarryYoshiThruLvls
                      BEQ +
                      LDA.W YoshiColor
                    + STA.W SavedPlayerYoshi,X
                      LDA.W PlayerItembox
                      STA.W SavedPlayerItembox,X
                      LDA.B #$03
                      STA.B ColorAddition
                      LDA.B #$30
                      LDX.B #$15
                      LDY.W ShowContinueEnd
                      BEQ CODE_00A11B
                   if ver_is_console(!_VER)                     ;\================= J, U, E0, & E1 ==============
                      JSR CODE_00A195                           ;!
                      LDA.W ExitsCompleted                      ;!
                      BNE +                                     ;!
                      JSR CODE_009C89                           ;!
                      JMP CODE_0093F4                           ;!
                                                                ;!
                    + JSL CODE_04DAAD                           ;!
                      REP #$20                                  ;! A->16
                      LDA.W #$318C                              ;!
                      STA.W BackgroundColor                     ;!
                      SEP #$20                                  ;! A->8
                      LDA.B #$30                                ;!
                      STA.B OBJCWWindow                         ;!
                      LDA.B #$20                                ;!
                      STA.B ColorAddition                       ;!
                      LDA.B #$B3                                ;!
                      LDX.B #$17                                ;!
                   else                                         ;<======================== SS ===================
                      JSR CODE_009C89                           ;!
                      JMP CODE_0093F4                           ;!
                   endif                                        ;/===============================================
CODE_00A11B:          LDY.B #$02
                      JSR ScreenSettings
                      STX.W HW_TMW
                      STY.W HW_TSW
                      JSL CODE_04DC09
                      LDX.W PlayerTurnLvl
                      LDA.W OWPlayerSubmap,X
                      ASL A
                      TAX
                      REP #$20                                  ; A->16
                      LDA.W DATA_00A06B,X
                      STA.B Layer1XPos
                      STA.B Layer2XPos
                      LDA.W DATA_00A079,X
                      STA.B Layer1YPos
                      STA.B Layer2YPos
                      SEP #$20                                  ; A->8
                      JSR UploadSpriteGFX
                      LDY.B #$14
                      JSL CODE_00BA28
                      JSR CODE_00AD25
                      JSR CODE_00922F
                      LDA.B #$06                                ; \ Load overworld border
                      STA.B StripeImage                         ; |
                      JSR LoadScrnImage                         ; /
                      JSL CODE_05DBF2
                      JSR LoadScrnImage
                      JSL CODE_048D91
                      JSL CODE_04D6E9
                      LDA.B #$F0
                      STA.B OAMAddress
                      JSR CODE_008494
                      JSR LoadScrnImage
                      STZ.W OverworldProcess
                      JSR KeepGameModeActive
                      LDA.B #$02
                      STA.W IRQNMICommand
                      REP #$10                                  ; XY->16
                      LDX.W #con($01BE,$01BE,$01BE,$01BE,$01DE)
                      LDA.B #$FF
                    - STZ.W WindowTable,X
                      STA.W WindowTable+1,X
                      DEX
                      DEX
                      BPL -
                      JSR CODE_0092A0
                      JMP CODE_0093F4

CODE_00A195:          REP #$10                                  ; XY->16
                      LDX.W #$008C
                    - LDA.W SaveDataBuffer,X
                      STA.W OWLevelTileSettings,X
                      DEX
                      BPL -
                      SEP #$10                                  ; XY->8
                      RTS

Clear_1A_13D3:        REP #$10                                  ; XY->16
                      SEP #$20                                  ; A->8
                      LDX.W #$00BD                              ; \
                    - STZ.B Layer1XPos,X                        ; |Clear RAM addresses $1A-$D7
                      DEX                                       ; |
                      BPL -                                     ; /
                      LDX.W #$07CE                              ; \
                    - STZ.W PauseTimer,X                        ; |Clear RAM addresses $13D3-$1BA1
                      DEX                                       ; |
                      BPL -                                     ; /
                      SEP #$10                                  ; XY->8
                      RTS

GameMode0E:           JSR SetUp0DA0GM4
                      INC.B EffFrame                            ; Increase alternate frame counter
                      JSL OAMResetRoutine
                      JSL GameMode_0E_Prim                      ; (Bank 4.asm)
                      JMP CODE_008494


GrndShakeDispYLo:     db $FE,$00,$02,$00

GrndShakeDispYHi:     db $FF,$00,$00,$00

                      db $12,$22,$12,$02

GameMode14:           LDA.W MessageBoxTrigger
                      BEQ +
                      JSL CODE_05B10C
                      RTS

                    + LDA.W BonusGameActivate
                      BEQ +
                      LDA.W BonusFinishTimer
                      BEQ +
                      CMP.B #con($40,$40,$40,$48,$48)
                      BCS +
                      JSR NoButtons
                      CMP.B #con($1C,$1C,$1C,$24,$24)
                      BCS +
                      JSR SetMarioPeaceImg
                      LDA.B #$0D
                      STA.B PlayerAnimation
                    + ORA.B PlayerAnimation
                      ORA.W EndLevelTimer
                      BEQ +
                      LDA.B #$04
                      TRB.B byetudlrHold
                      LDA.B #$40
                      TRB.B byetudlrFrame
                      TRB.B axlr0000Frame
                    + LDA.W PauseTimer
                      BEQ CODE_00A21B
                      DEC.W PauseTimer
                      BRA CODE_00A242

CODE_00A21B:          LDA.B byetudlrFrame
                      AND.B #$10
                      BEQ CODE_00A242
                      LDA.W EndLevelTimer
                      BNE CODE_00A242
                      LDA.B PlayerAnimation
                      CMP.B #$09
                      BCS CODE_00A242
                      LDA.B #$3C
                      STA.W PauseTimer
                      LDY.B #!SFX_UNPAUSE
                      LDA.W PauseFlag
                      EOR.B #$01
                      STA.W PauseFlag
                      BEQ +
                      LDY.B #!SFX_PAUSE
                    + STY.W SPCIO0
CODE_00A242:          LDA.W PauseFlag
                      BEQ CODE_00A28A
                      BRA CODE_00A25B

                      BIT.W byetudlrP2Frame                     ; \ Unreachable
                      BVS ADDR_00A259                           ; | Debug: Slow motion
                      LDA.W byetudlrP2Hold                      ; |
                      BPL CODE_00A25B                           ; |
                      LDA.B TrueFrame                           ; |
                      AND.B #$0F                                ; |
                      BNE CODE_00A25B                           ; |
ADDR_00A259:          BRA CODE_00A28A                           ; /

CODE_00A25B:
                   if ver_is_console(!_VER)                     ;\================== J, U, E0, & E1 =============
                      LDA.B byetudlrHold                        ;!
                      AND.B #$20                                ;!
                      BEQ Return00A289                          ;!
                      LDY.W TranslevelNo                        ;!
                      LDA.W OWLevelTileSettings,Y               ;!
                      BPL Return00A289                          ;!
                      LDA.W OWLevelExitMode                     ;!
                      BEQ CODE_00A270                           ;!
                      BPL Return00A289                          ;!
CODE_00A270:          LDA.B #$80                                ;!
                      BRA CODE_00A27E                           ;!
                                                                ;!
                      LDA.B #$01                                ;! \ Unreachable
                      BIT.B byetudlrHold                        ;! | Debug: Beat level with Start+Select
                      BPL +                                     ;! |
                      INC A                                     ;! /
                    + STA.W MidwayFlag                          ;!
CODE_00A27E:          STA.W OWLevelExitMode                     ;!
                      INC.W CreditsScreenNumber                 ;!
                      LDA.B #$0B                                ;!
                      STA.W GameMode                            ;!
                   endif                                        ;/===============================================
Return00A289:         RTS

CODE_00A28A:          LDA.W IRQNMICommand
                      BPL +
                      JSR CODE_00987D
                      JMP CODE_00A2A9

                    + JSL OAMResetRoutine
                      JSL CODE_00F6DB
                      JSL CODE_05BC00
                      JSL CODE_0586F1
                      JSL CODE_05BB39
CODE_00A2A9:          LDA.B Layer1YPos
                      PHA
                      LDA.B Layer1YPos+1
                      PHA
                      STZ.W ScreenShakeYOffset                  ; \ Reset amout to shift level
                      STZ.W ScreenShakeYOffset+1                ; /
                      LDA.W ScreenShakeTimer                    ; \ If shake ground timer is set
                      BEQ +                                     ; |
                      DEC.W ScreenShakeTimer                    ; | Decrement timer
                      AND.B #$03                                ; |
                      TAY                                       ; |
                      LDA.W GrndShakeDispYLo,Y                  ; |
                      STA.W ScreenShakeYOffset                  ; | $1888-$1889 = Amount to shift level
                      CLC                                       ; |
                      ADC.B Layer1YPos                          ; |
                      STA.B Layer1YPos                          ; | Adjust screen boundry accordingly
                      LDA.W GrndShakeDispYHi,Y                  ; |
                      STA.W ScreenShakeYOffset+1                ; |
                      ADC.B Layer1YPos+1                        ; |
                      STA.B Layer1YPos+1                        ; /
                    + JSR CODE_008E1A
                      JSL CODE_00E2BD
                      JSR CODE_00A2F3
                      JSR CODE_00C47E
                      JSL CODE_01808C
                      JSL CODE_028AB1
                      PLA
                      STA.B Layer1YPos+1
                      PLA
                      STA.B Layer1YPos
                      JMP CODE_008494

CODE_00A2F3:          REP #$20                                  ; A->16
                      LDA.B PlayerXPosNext
                      STA.B PlayerXPosNow
                      LDA.B PlayerYPosNext
                      STA.B PlayerYPosNow
                      SEP #$20                                  ; A->8
                      RTS

MarioGFXDMA:          REP #$20                                  ; A->16
                      LDX.B #$04                                ; We're using DMA channel 2
                      LDY.W PlayerGfxTileCount
                      BEQ +
                      LDY.B #$86                                ; \ Set Address for CG-RAM Write to x86
                      STY.W HW_CGADD                            ; /
                      LDA.W #$2200
                      STA.W HW_DMAPARAM+$20
                      LDA.W PlayerPalletePtr                    ; \ Get location of palette from $0D82-$0D83
                      STA.W HW_DMAADDR+$20                      ; /
                      LDY.B #$00                                ; \ Palette is stored in bank x00
                      STY.W HW_DMAADDR+$22                      ; /
                      LDA.W #$0014                              ; \ x14 bytes will be transferred
                      STA.W HW_DMACNT+$20                       ; /
                      STX.W HW_MDMAEN                           ; Transfer the colors
                    + LDY.B #$80                                ; \ Set VRAM Address Increment Value to x80
                      STY.W HW_VMAINC                           ; /
                      LDA.W #$1801
                      STA.W HW_DMAPARAM+$20
                      LDA.W #$67F0
                      STA.W HW_VMADD
                      LDA.W DynGfxTile7FPtr
                      STA.W HW_DMAADDR+$20
                      LDY.B #$7E                                ; \ Set bank to x7E
                      STY.W HW_DMAADDR+$22                      ; /
                      LDA.W #$0020                              ; \ x20 bytes will be transferred
                      STA.W HW_DMACNT+$20                       ; /
                      STX.W HW_MDMAEN                           ; Transfer
                      LDA.W #$6000                              ; \ Set Address for VRAM Read/Write to x6000
                      STA.W HW_VMADD                            ; /
                      LDX.B #$00
                    - LDA.W DynGfxTilePtr,X                     ; \ Get address of graphics to copy
                      STA.W HW_DMAADDR+$20                      ; /
                      LDA.W #$0040                              ; \ x40 bytes will be transferred
                      STA.W HW_DMACNT+$20                       ; /
                      LDY.B #$04                                ; \ Transfer
                      STY.W HW_MDMAEN                           ; /
                      INX                                       ; \ Move to next address
                      INX                                       ; /
                      CPX.W PlayerGfxTileCount                  ; \ Repeat last segment while X<$0D84
                      BCC -                                     ; /
                      LDA.W #$6100                              ; \ Set Address for VRAM Read/Write to x6100
                      STA.W HW_VMADD                            ; /
                      LDX.B #$00
                    - LDA.W DynGfxTilePtr+$0A,X                 ; \ Get address of graphics to copy
                      STA.W HW_DMAADDR+$20                      ; /
                      LDA.W #$0040                              ; \ x40 bytes will be transferred
                      STA.W HW_DMACNT+$20                       ; /
                      LDY.B #$04                                ; \ Transfer
                      STY.W HW_MDMAEN                           ; /
                      INX                                       ; \ Move to next address
                      INX                                       ; /
                      CPX.W PlayerGfxTileCount                  ; \ Repeat last segment while X<$0D84
                      BCC -                                     ; /
                      SEP #$20                                  ; A->8
                      RTS

CODE_00A390:          REP #$20                                  ; A->16
                      LDY.B #$80
                      STY.W HW_VMAINC
                      LDA.W #$1801
                      STA.W HW_DMAPARAM+$20
                      LDY.B #$7E
                      STY.W HW_DMAADDR+$22
                      LDX.B #$04
                      LDA.W Gfx33DestAddrC
                      BEQ +
                      STA.W HW_VMADD
                      LDA.W Gfx33SrcAddrC
                      STA.W HW_DMAADDR+$20
                      LDA.W #$0080
                      STA.W HW_DMACNT+$20
                      STX.W HW_MDMAEN
                    + LDA.W Gfx33DestAddrB
                      BEQ +
                      STA.W HW_VMADD
                      LDA.W Gfx33SrcAddrB
                      STA.W HW_DMAADDR+$20
                      LDA.W #$0080
                      STA.W HW_DMACNT+$20
                      STX.W HW_MDMAEN
                    + LDA.W Gfx33DestAddrA
                      BEQ CODE_00A418
                      STA.W HW_VMADD
                      CMP.W #$0800
                      BEQ CODE_00A3F0
                      LDA.W Gfx33SrcAddrA
                      STA.W HW_DMAADDR+$20
                      LDA.W #$0080
                      STA.W HW_DMACNT+$20
                      STX.W HW_MDMAEN
                      BRA CODE_00A418

CODE_00A3F0:          LDA.W Gfx33SrcAddrA
                      STA.W HW_DMAADDR+$20
                      LDA.W #$0040
                      STA.W HW_DMACNT+$20
                      STX.W HW_MDMAEN
                      LDA.W #$0900
                      STA.W HW_VMADD
                      LDA.W Gfx33SrcAddrA
                      CLC
                      ADC.W #$0040
                      STA.W HW_DMAADDR+$20
                      LDA.W #$0040
                      STA.W HW_DMACNT+$20
                      STX.W HW_MDMAEN
CODE_00A418:          SEP #$20                                  ; A->8
                      LDA.B #$64
CODE_00A41C:          STZ.B _0
CODE_00A41E:          STA.W HW_CGADD
                      LDA.B EffFrame
                      AND.B #$1C
                      LSR A
                      ADC.B _0
                      TAY
                      LDA.W FlashingColors,Y
                      STA.W HW_CGDATA
                      LDA.W FlashingColors+1,Y
                      STA.W HW_CGDATA
                      RTS

CODE_00A436:          LDA.W MarioStartFlag
                      BEQ +
                      STZ.W MarioStartFlag
                      REP #$20                                  ; A->16
                      LDY.B #$80
                      STY.W HW_VMAINC
                      LDA.W #$64A0
                      STA.W HW_VMADD
                      LDA.W #$1801
                      STA.W HW_DMAPARAM+$20
                      LDA.W #$0BF6
                      STA.W HW_DMAADDR+$20
                      LDY.B #$00
                      STY.W HW_DMAADDR+$22
                      LDA.W #$00C0
                      STA.W HW_DMACNT+$20
                      LDX.B #$04
                      STX.W HW_MDMAEN
                      LDA.W #$65A0
                      STA.W HW_VMADD
                      LDA.W #$0CB6
                      STA.W HW_DMAADDR+$20
                      LDA.W #$00C0
                      STA.W HW_DMACNT+$20
                      STX.W HW_MDMAEN
                      SEP #$20                                  ; A->8
                    + RTS


DATA_00A47F:          dl DynPaletteTable
                      dl CopyPalette
                      dl MainPalette

CODE_00A488:          LDY.W PaletteIndexTable
                      LDX.W DATA_00A47F+2,Y
                      STX.B _2
                      STZ.B _1
                      STZ.B _0
                      STZ.B _4
                      LDA.W DATA_00A47F+1,Y
                      XBA
                      LDA.W DATA_00A47F,Y
                      REP #$10                                  ; XY->16
                      TAY
CODE_00A4A0:          LDA.B [_0],Y
                      BEQ CODE_00A4CF
                      STX.W HW_DMAADDR+$22
                      STA.W HW_DMACNT+$20
                      STA.B _3
                      STZ.W HW_DMACNT+$21
                      INY
                      LDA.B [_0],Y
                      STA.W HW_CGADD
                      REP #$20                                  ; A->16
                      LDA.W #$2200
                      STA.W HW_DMAPARAM+$20
                      INY
                      TYA
                      STA.W HW_DMAADDR+$20
                      CLC
                      ADC.B _3
                      TAY
                      SEP #$20                                  ; A->8
                      LDA.B #$04
                      STA.W HW_MDMAEN
                      BRA CODE_00A4A0

CODE_00A4CF:          SEP #$10                                  ; XY->8
                      JSR CODE_00AE47
                      LDA.W PaletteIndexTable
                      BNE +
                      STZ.W DynPaletteIndex
                      STZ.W DynPaletteTable
                    + STZ.W PaletteIndexTable
                    - RTS

CODE_00A4E3:          REP #$10                                  ; XY->16
                      LDA.B #$80
                      STA.W HW_VMAINC
                      LDY.W #$0750
                      STY.W HW_VMADD
                      LDY.W #$1801
                      STY.W HW_DMAPARAM+$20
                      LDY.W #GfxDecompOWAni
                      STY.W HW_DMAADDR+$20
                      STZ.W HW_DMAADDR+$22
                      LDY.W #$0160
                      STY.W HW_DMACNT+$20
                      LDA.B #$04
                      STA.W HW_MDMAEN
                      SEP #$10                                  ; XY->8
                      LDA.W OverworldProcess
                      CMP.B #$0A
                      BEQ -
                      LDA.B #$6D
                      JSR CODE_00A41C
                      LDA.B #$10
                      STA.B _0
                      LDA.B #$7D
                      JMP CODE_00A41E


DATA_00A521:          db $00,$04,$08,$0C
DATA_00A525:          db $00,$08,$10,$18

CODE_00A529:          LDA.B #$80
                      STA.W HW_VMAINC
                      STZ.W HW_VMADD
                      LDA.B #$30
                      CLC
                      ADC.W DATA_00A521,Y
                      STA.W HW_VMADD+1
                      LDX.B #$06
                    - LDA.W DATA_00A586,X
                      STA.W HW_DMAPARAM+$10,X
                      DEX
                      BPL -
                      LDA.W PlayerTurnOW
                      LSR A
                      LSR A
                      TAX
                      LDA.W OWPlayerSubmap,X
                      BEQ +
                      LDA.B #$60
                      STA.W HW_DMAADDR+$11
                    + LDA.W HW_DMAADDR+$11
                      CLC
                      ADC.W DATA_00A525,Y
                      STA.W HW_DMAADDR+$11
                      LDA.B #$02
                      STA.W HW_MDMAEN
                      LDA.B #$80
                      STA.W HW_VMAINC
                      STZ.W HW_VMADD
                      LDA.B #$20
                      CLC
                      ADC.W DATA_00A521,Y
                      STA.W HW_VMADD+1
                      LDX.B #$06
                    - LDA.W DATA_00A58D,X
                      STA.W HW_DMAPARAM+$10,X
                      DEX
                      BPL -
                      LDA.B #$02
                      STA.W HW_MDMAEN
                      RTS


DATA_00A586:          db $01,$18
                      dl OWLayer2Tilemap
                      dw $0800

DATA_00A58D:          db $01,$18
                      dl OWLayer1VramBuffer
                      dw $0800

CODE_00A594:          PHB                                       ; Wrapper
                      PHK
                      PLB
                      JSR CODE_00AD25
                      PLB
                      RTL

GameMode12:           JSR CODE_0085FA                           ; gah, stupid keyboard >_<
                      JSR NoButtons
                      STZ.W UploadMarioStart
                      JSR SetUpScreen
                      JSR GM04DoDMA
                      JSL CODE_05809E                           ; ->here
                      LDA.W IRQNMICommand
                      BPL CODE_00A5B9
                      JSR CODE_0097BC                           ; Working on this routine
                      BRA +

CODE_00A5B9:          JSR UploadSpriteGFX
                      JSR LoadPalette
                      JSL CODE_05BE8A
                      JSR CODE_009FB8
                      JSR CODE_00A5F9
                      JSR CODE_009260
                      JSR CODE_009860
                    + JSR CODE_00922F
                      JSR KeepGameModeActive
                      JSR CODE_008E1A
                      REP #$30                                  ; AXY->16
                      PHB
                      LDX.W #MainPalette
                      LDY.W #CopyPalette
                      LDA.W #$01EF
                      MVN $00,$00
                      PLB
                      LDX.W BackgroundColor
                      STX.W CopyBGColor
                      SEP #$30                                  ; AXY->8
                      JSR CODE_00919B
                      JSR CODE_008494
                      JMP CODE_0093F4

CODE_00A5F9:          LDA.B #$E7
                      TRB.B EffFrame
                    - JSL CODE_05BB39
                      JSR CODE_00A390
                      INC.B EffFrame
                      LDA.B EffFrame
                      AND.B #$07
                      BNE -
                      RTS


DATA_00A60D:          dw $0100,$0101,$000D,$FFF3
                      dw $FFFE,$FFFE,$0000,$0000

DATA_00A61D:          db $0A,$00,$00,$00,$1A,$1A,$0A,$0A
DATA_00A625:          db $00,$80,$40,$00,$01,$02,$40,$00
                      db $40,$00,$00,$00,$00,$02,$00,$00

CODE_00A635:          LDA.W BluePSwitchTimer                    ; If blue pow...
                      ORA.W SilverPSwitchTimer                  ; ...or silver pow...
                      ORA.W DirectCoinTimer
                      BNE CODE_00A64A
                      LDA.W InvinsibilityTimer                  ; \ Branch if Mario doesn't have star
                      BEQ CODE_00A660                           ; /
                      LDA.W MusicBackup
                      BPL +
CODE_00A64A:          LDA.W MusicBackup
                      AND.B #$7F
                    + ORA.B #$40
                      STA.W MusicBackup
                      STZ.W BluePSwitchTimer                    ; Zero out POW timer
                      STZ.W SilverPSwitchTimer                  ; Zero out silver POW timer
                      STZ.W DirectCoinTimer
                      STZ.W InvinsibilityTimer                  ; Zero out star timer
CODE_00A660:          LDA.W BonusRoomBlocks
                      ORA.W BonusRoomBlocks+1
                      ORA.W BonusRoomBlocks+2
                      ORA.W BonusRoomBlocks+3
                      ORA.W BonusRoomBlocks+4
                      BEQ +
                      STA.W DidPlayBonusGame
                    + LDX.B #$23
                    - STZ.B Map16HighPtr+2,X
                      DEX
                      BNE -
                      LDX.B #$37
                    - STZ.W OverworldProcess,X
                      DEX
                      BNE -
                      ASL.W UnusedStarCounter
                      STZ.W KickingTimer
                      STZ.W PickUpItemTimer
                      STZ.W ColorFadeTimer
                      STZ.W YoshiInPipeSetting
                      LDY.B #$01
                      LDX.W ObjectTileset
                      CPX.B #$10
                      BCS CODE_00A6CC
                      LDA.W DATA_00A625,X
                      LSR A
                      BEQ CODE_00A6CC
                      LDA.W ShowMarioStart
                      ORA.W SublevelCount
                      ORA.W DisableNoYoshiIntro
                      BNE CODE_00A6CC
                      LDA.W SkipMidwayCastleIntro
                      BEQ CODE_00A6B6
                      JSR CODE_00C90A
                      BRA CODE_00A6CC

CODE_00A6B6:          STZ.B PlayerInAir
                      STY.B PlayerDirection
                      STY.B PlayerPipeAction
                      LDX.B #$0A
                      LDY.B #$00
                      LDA.W CarryYoshiThruLvls
                      BEQ CODE_00A6C7
                      LDY.B #$0F
CODE_00A6C7:          STX.B PlayerAnimation
                      STY.B PipeTimer
                      RTS

CODE_00A6CC:          LDA.B Layer1YPos
                      CMP.B #$C0
                      BEQ +
                      INC.W VerticalScrollEnabled
                    + LDA.W LevelEntranceType
                      BEQ CODE_00A6E0
                      CMP.B #$05
                      BNE CODE_00A716
                      ROR.B LevelIsSlippery
CODE_00A6E0:          STY.B PlayerDirection
                      LDA.B #$24
                      STA.B PlayerInAir
                      STZ.B SpriteLock
                      LDA.W KeyholeTimer
                      BEQ +
                      LDA.W MusicBackup
                      ORA.B #$7F
                      STA.W MusicBackup
                      LDA.B PlayerXPosNext
                      ORA.B #$04
                      STA.W KeyholeXPos
                      LDA.B PlayerYPosNext
                      CLC
                      ADC.B #$10
                      STA.W KeyholeYPos
                    + LDA.W YoshiHeavenFlag
                      BEQ +
                      LDA.B #$08                                ; \ Animation = Rise off screen,
                      STA.B PlayerAnimation                     ; / for Yoshi Wing bonus stage
                      LDA.B #$A0
                      STA.B PlayerYPosNext
                      LDA.B #$90                                ; \ Set upward speed, #$90
                      STA.B PlayerYSpeed                        ; /
                    + RTS

CODE_00A716:          CMP.B #$06
                      BCC CODE_00A740
                      BNE CODE_00A734
                      STY.B PlayerDirection
                      STY.W PlayerCapePose
                      LDA.B #$FF
                      STA.W YoshiInPipeSetting
                      LDA.B #$08
                      TSB.B PlayerXPosNext
                      LDA.B #$02
                      TSB.B PlayerYPosNext
                      LDX.B #$07
                      LDY.B #$20
                      BRA CODE_00A6C7

CODE_00A734:          STY.B LevelIsWater
                      LDA.W SkipMidwayCastleIntro
                      ORA.W KeyholeTimer
                      BNE CODE_00A6E0
                      LDA.B #$04
CODE_00A740:          CLC
                      ADC.B #$03
                      STA.B PlayerPipeAction
                      TAY
                      LSR A
                      DEC A
                      STA.W YoshiInPipeSetting
                      LDA.W DATA_00A60D-4,Y
                      STA.B PlayerDirection
                      LDX.B #$05
                      CPY.B #$06
                      BCC CODE_00A768
                      LDA.B #$08
                      TSB.B PlayerXPosNext
                      LDX.B #$06
                      CPY.B #$07
                      LDY.B #$1E
                      BCC +
                      LDY.B #$0F
                      LDA.B Powerup
                      BEQ +
CODE_00A768:          LDY.B #$1C                                ; \ Set downward speed, #$1C
                    + STY.B PlayerYSpeed                        ; /
                      JSR CODE_00A6C7
                      LDA.W PlayerRidingYoshi
                      BEQ +
                      LDX.B PlayerPipeAction
                      LDA.B PipeTimer
                      CLC
                      ADC.W DATA_00A61D,X
                      STA.B PipeTimer
                      TXA
                      ASL A
                      TAX
                      REP #$20                                  ; A->16
                      LDA.B PlayerXPosNext
                      CLC
                      ADC.W DATA_00A60D-4,X
                      STA.B PlayerXPosNext
                      LDA.B PlayerYPosNext
                      CLC
                      ADC.W DATA_00A60D+4,X
                      STA.B PlayerYPosNext
                      SEP #$20                                  ; A->8
                    + RTS

CODE_00A796:          REP #$20                                  ; A->16
                      LDY.W VertLayer2Setting
                      BEQ CODE_00A7B9
                      DEY
                      BNE CODE_00A7A7
                      LDA.B Layer2YPos
                      SEC
                      SBC.B Layer1YPos
                      BRA CODE_00A7B6

CODE_00A7A7:          LDA.B Layer1YPos
                      LSR A
                      DEY
                      BEQ +
                      LSR A
                      LSR A
                    + EOR.W #$FFFF
                      INC A
                      CLC
                      ADC.B Layer2YPos
CODE_00A7B6:          STA.W BackgroundVertOffset
CODE_00A7B9:          LDA.W #$0080
                      STA.W CameraMoveTrigger
                      SEP #$20                                  ; A->8
                      RTS

CODE_00A7C2:          REP #$20                                  ; A->16
                      LDX.B #$80
                      STX.W HW_VMAINC
                      LDA.W #$6000
                      STA.W HW_VMADD
                      LDA.W #$1801
                      STA.W HW_DMAPARAM+$20
                      LDA.W #MarioStartGraphics
                      STA.W HW_DMAADDR+$20
                      LDX.B #MarioStartGraphics>>16
                      STX.W HW_DMAADDR+$22
                      LDA.W #$00C0
                      STA.W HW_DMACNT+$20
                      LDX.B #$04
                      STX.W HW_MDMAEN
                      LDA.W #$6100
                      STA.W HW_VMADD
                      LDA.W #MarioStartGraphics+$C0
                      STA.W HW_DMAADDR+$20
                      LDA.W #$00C0
                      STA.W HW_DMACNT+$20
                      STX.W HW_MDMAEN
                      LDA.W #$64A0
                      STA.W HW_VMADD
                      LDA.W #MarioStartGraphics+$180
                      STA.W HW_DMAADDR+$20
                      LDA.W #$00C0
                      STA.W HW_DMACNT+$20
                      STX.W HW_MDMAEN
                      LDA.W #$65A0
                      STA.W HW_VMADD
                      LDA.W #MarioStartGraphics+$240
                      STA.W HW_DMAADDR+$20
                      LDA.W #$00C0
                      STA.W HW_DMACNT+$20
                      STX.W HW_MDMAEN
                      SEP #$20                                  ; A->8
                      RTS

CODE_00A82D:          LDY.B #$0F
                      JSL CODE_00BA28
                      LDA.W BonusGameActivate
                      REP #$30                                  ; AXY->16
                      BEQ +
                      LDA.B _0
                      CLC
                      ADC.W #$0030
                      STA.B _0
                    + LDX.W #$0000
CODE_00A845:          LDY.W #$0008
                    - LDA.B [_0]
                      STA.L MarioStartGraphics,X
                      INX
                      INX
                      INC.B _0
                      INC.B _0
                      DEY
                      BNE -
                      LDY.W #$0008
                    - LDA.B [_0]
                      AND.W #$00FF
                      STA.L MarioStartGraphics,X
                      INX
                      INX
                      INC.B _0
                      DEY
                      BNE -
                      CPX.W #$0300
                      BCC CODE_00A845
                      SEP #$30                                  ; AXY->8
                      LDY.B #$00
                      JSL CODE_00BA28
                      REP #$30                                  ; AXY->16
                      LDA.W #$B3F0
                      STA.B _0
                      LDA.W #$7EB3
                      STA.B _1
                      LDX.W #$0000
CODE_00A886:          LDY.W #$0008
                    - LDA.B [_0]
                      STA.W GfxDecompSP1,X
                      INX
                      INX
                      INC.B _0
                      INC.B _0
                      DEY
                      BNE -
                      LDY.W #$0008
                    - LDA.B [_0]
                      AND.W #$00FF
                      STA.W GfxDecompSP1,X
                      INX
                      INX
                      INC.B _0
                      DEY
                      BNE -
                      CPX.W #$00C0
                      BNE +
                      LDA.W #$B570
                      STA.B _0
                    + CPX.W #$0180
                      BCC CODE_00A886
                      SEP #$30                                  ; AXY->8
                      LDA.B #$01
                      STA.W UploadMarioStart
                      STA.W MarioStartFlag
                      RTS


SPRITEGFXLIST:        db $00,$01,$13,$02                        ; Forest
                      db $00,$01,$12,$03                        ; Castle
                      db $00,$01,$13,$05                        ; Mushroom
                      db $00,$01,$13,$04                        ; Underground
                      db $00,$01,$13,$06                        ; Water
                      db $00,$01,$13,$09                        ; Pokey
                      db $00,$01,$13,$04                        ; Underground 2
                      db $00,$01,$06,$11                        ; Ghost House
                      db $00,$01,$13,$20                        ; Banzai Bill
                      db $00,$01,$13,$0F                        ; Yoshi's House
                      db $00,$01,$13,$23                        ; Dino-Rhino
                      db $00,$01,$0D,$14                        ; Switch Palace
                      db $00,$01,$24,$0E                        ; Mechakoopa
                      db $00,$01,$0A,$22                        ; Wendy/Lemmy
                      db $00,$01,$13,$0E                        ; Ninji
                      db $00,$01,$13,$14                        ; Unused
                      db $00,$00,$00,$08
                      db $10,$0F,$1C,$1D
                      db $00,$01,$24,$22
                      db $00,$01,$25,$22
                      db $00,$22,$13,$2D
                      db $00,$01,$0F,$22
                      db $00,$26,$2E,$22
                      db $21,$0B,$25,$0A
                      db $00,$0D,$24,$22
                      db $2C,$30,$2D,$0E
OBJECTGFXLIST:        db $14,$17,$19,$15                        ; Normal 1
                      db $14,$17,$1B,$18                        ; Castle 1
                      db $14,$17,$1B,$16                        ; Rope 1
                      db $14,$17,$0C,$1A                        ; Underground 1
                      db $14,$17,$1B,$08                        ; Switch Palace 1
                      db $14,$17,$0C,$07                        ; Ghost House 1
                      db $14,$17,$0C,$16                        ; Rope 2
                      db $14,$17,$1B,$15                        ; Normal 2
                      db $14,$17,$19,$16                        ; Rope 3
                      db $14,$17,$0D,$1A                        ; Underground 2
                      db $14,$17,$1B,$08                        ; Switch Palace 2
                      db $14,$17,$1B,$18                        ; Castle 2
                      db $14,$17,$19,$1F                        ; Cloud/Forest
                      db $14,$17,$0D,$07                        ; Ghost House 2
                      db $14,$17,$19,$1A                        ; Underground 2
                      db $14,$17,$14,$14
                      db $0E,$0F,$17,$17
                      db $1C,$1D,$08,$1E
                      db $1C,$1D,$08,$1E
                      db $1C,$1D,$08,$1E
                      db $1C,$1D,$08,$1E
                      db $1C,$1D,$08,$1E
                      db $1C,$1D,$08,$1E
                      db $1C,$1D,$08,$1E
                      db $14,$17,$19,$2C
                      db $19,$17,$1B,$18

CODE_00A993:          STZ.W HW_VMADD                            ; \
                      LDA.B #$40                                ; |Set "Address for VRAM Read/Write" to x4000
                      STA.W HW_VMADD+1                          ; /
                      LDA.B #$03
                      STA.B _F
                      LDA.B #$28
                      STA.B _E
CODE_00A9A3:          LDA.B _E
                      TAY
                      JSL CODE_00BA28
                      REP #$30                                  ; AXY->16
                      LDX.W #$03FF
                      LDY.W #$0000
                    - LDA.B [_0],Y
                      STA.W HW_VMDATA
                      INY
                      INY
                      DEX
                      BPL -
                      SEP #$30                                  ; AXY->8
                      INC.B _E
                      DEC.B _F
                      BPL CODE_00A9A3
                      STZ.W HW_VMADD                            ; \
                      LDA.B #$60                                ; |Set "Address for VRAM Read/Write" to x6000
                      STA.W HW_VMADD+1                          ; /
                      LDY.B #$00
                      JSR UploadGFXFile
                      RTS


DATA_00A9D2:          db $78,$70,$68,$60
DATA_00A9D6:          db $18,$10,$08,$00

UploadSpriteGFX:      LDA.B #$80                                ; Decompression as well?
                      STA.W HW_VMAINC                           ; VRAM transfer control port
                      LDX.B #$03
                      LDA.W SpriteTileset                       ; $192B = current sprite GFX list index
                      ASL A                                     ; \
                      ASL A                                     ;  }4A -> Y
                      TAY                                       ; /
                    - LDA.W SPRITEGFXLIST,Y                     ; |
                      STA.B _4,X                                ; |
                      INY                                       ; |
                      DEX                                       ; |
                      BPL -                                     ; /
                      LDA.B #$03                                ; #$03 -> A -> $0F
                      STA.B _F
GFXTransferLoop:      LDX.B _F                                  ; $0F -> X
                      STZ.W HW_VMADD                            ; #$00 -> $2116
                      LDA.W DATA_00A9D2,X                       ; My guess: Locations in VRAM to upload GFX to
                      STA.W HW_VMADD+1                          ; Set VRAM address to $??00
                      LDY.B _4,X                                ; Y is possibly which GFX file
                      LDA.W SpriteGFXFile,X                     ; to upload to a section in VRAM, used in
                      CMP.B _4,X                                ; the subroutine $00:BA28
                      BEQ +                                     ; don't upload when it''s not needed
                      JSR UploadGFXFile                         ; JSR to a JSL...
                    + DEC.B _F                                  ; Decrement $0F
                      BPL GFXTransferLoop                       ; if >= #$00, continue transfer
                      LDX.B #$03                                ; \
                    - LDA.B _4,X                                ; |Update $0101-$0104 to reflect the new sprite GFX
                      STA.W SpriteGFXFile,X                     ; |That's loaded now.
                      DEX                                       ; |
                      BPL -                                     ; /
                      LDA.W ObjectTileset                       ; LDA Tileset
                      CMP.B #$FE
                      BCS SetallFGBG80                          ; Branch to a routine that uploads file #$80 to every slot in FG/BG
                      LDX.B #$03
                      LDA.W ObjectTileset                       ; this routine is pretty close to the above
                      ASL A                                     ; one, I'm guessing this does
                      ASL A                                     ; object/BG GFX.
                      TAY                                       ; 4A -> Y
                    - LDA.W OBJECTGFXLIST,Y                     ; FG/BG GFX table
                      STA.B _4,X
                      INY
                      DEX
                      BPL -                                     ; FG/Bg to upload -> $04 - $07
                      LDA.B #$03
                      STA.B _F                                  ; #$03 -> $0F
CODE_00AA35:          LDX.B _F                                  ; $0F -> X
                      STZ.W HW_VMADD
                      LDA.W DATA_00A9D6,X                       ; Load + Store VRAM upload positions
                      STA.W HW_VMADD+1
                      LDY.B _4,X
                      LDA.W BackgroundGFXFile,X                 ; Check to see if the file to be uploaded already
                      CMP.B _4,X                                ; exists in the slot in VRAM - if so,
                      BEQ +                                     ; don't bother uploading it again.
                      JSR UploadGFXFile                         ; Upload the GFX file
                    + DEC.B _F                                  ; Next GFX file
                      BPL CODE_00AA35
                      LDX.B #$03
                    - LDA.B _4,X
                      STA.W BackgroundGFXFile,X
                      DEX
                      BPL -
                      RTS                                       ; Return from uploading the GFX

SetallFGBG80:         BEQ +                                     ; If zero flag set, don't update the tileset
                      JSR CODE_00AB42
                    + LDX.B #$03
                      LDA.B #$80                                ; my guess is that it gets called in the same set of routines
                    - STA.W BackgroundGFXFile,X
                      DEX
                      BPL -
                      RTS

UploadGFXFile:        JSL CODE_00BA28
                      CPY.B #$01
                      BNE +
                      LDA.W OWLevelTileSettings+$49
                      BPL +                                     ; handle the post-special world graphics and koopa color swap.
                      LDY.B #$31
                      JSL CODE_00BA28
                      LDY.B #$01
                    + REP #$20                                  ; A->16
                      LDA.W #$0000
                      LDX.W ObjectTileset                       ; LDX Tileset
                      CPX.B #$11                                ; CPX #$11
                      BCC CODE_00AA90                           ; If Tileset < #$11 skip to lower area
                      CPY.B #$08                                ; if Y = #$08 skip to JSR
                      BEQ JumpTo_____
CODE_00AA90:          CPY.B #$1E                                ; If Y = #$1E then
                      BEQ JumpTo_____                           ; JMP otherwise
                      BNE +                                     ; don't JMP
JumpTo_____:          JMP FilterSomeRAM

                    + STA.B _A
                      LDA.W #$FFFF
                      CPY.B #$01
                      BEQ +
                      CPY.B #$17
                      BEQ +
                      LDA.W #$0000
                    + STA.W GfxBppConvertFlag
                      LDY.B #$7F
CODE_00AAAE:          LDA.W GfxBppConvertFlag
                      BEQ CODE_00AACD
                      CPY.B #$7E
                      BCC CODE_00AABE
CODE_00AAB7:          LDA.W #$FF00
                      STA.B _A
                      BNE CODE_00AACD
CODE_00AABE:          CPY.B #$6E
                      BCC CODE_00AAC8
                      CPY.B #$70
                      BCS CODE_00AAC8
                      BCC CODE_00AAB7
CODE_00AAC8:          LDA.W #$0000
                      STA.B _A
CODE_00AACD:          LDX.B #$07
                    - LDA.B [_0]
                      STA.W HW_VMDATA
                      XBA
                      ORA.B [_0]
                      STA.W GfxBppConvertBuffer,X
                      INC.B _0
                      INC.B _0
                      DEX
                      BPL -
                      LDX.B #$07
                    - LDA.B [_0]
                      AND.W #$00FF
                      STA.B _C
                      LDA.B [_0]
                      XBA
                      ORA.W GfxBppConvertBuffer,X
                      AND.B _A
                      ORA.B _C
                      STA.W HW_VMDATA
                      INC.B _0
                      DEX
                      BPL -
                      DEY
                      BPL CODE_00AAAE
                      SEP #$20                                  ; A->8
                      RTS

FilterSomeRAM:        LDA.W #$FF00
                      STA.B _A
                      LDY.B #$7F
Upload____ToVRAM:     CPY.B #$08                                ; \Completely pointless code.
                      BCS +                                     ; /(Why not just NOPing it out, Nintendo?)
                    + LDX.B #$07
                    - LDA.B [_0]                                ; \ Okay, so take [$00], store
                      STA.W HW_VMDATA                           ; |it to VRAM, then bitwise
                      XBA                                       ; |OR the high and low bytes together
                      ORA.B [_0]                                ; |store in both bytes of A
                      STA.W GfxBppConvertBuffer,X               ; /and store to $1BB2,x
                      INC.B _0                                  ; \Increment $7E:0000 by 2
                      INC.B _0                                  ; /
                      DEX                                       ; \And continue on another 7 times (or 8 times total)
                      BPL -                                     ; /
                      LDX.B #$07                                ; hm..  It's like a FOR Y{FOR X{ } } thing ...yeah...
                    - LDA.B [_0]
                      AND.W #$00FF                              ; A normal byte becomes 2 anti-compressed bytes.
                      STA.B _C                                  ; I'm going up, to try and find out what's supposed to set $00-$02 for this routine.
                      LDA.B [_0]                                ; AHA, check $00/BA28.  It writes a RAM address to $00-$02, $7EAD00
                      XBA                                       ; So...  Now to find otu what sets *That*
                      ORA.W GfxBppConvertBuffer,X               ; ...this place gives me headaches... Can't we work on some other code? :(
                      AND.B _A                                  ; Sure, go ahead.  anyways, this seems to upload the decompressed GFX
                      ORA.B _C                                  ; while scrambling it afterwards (o_O).
                      STA.W HW_VMDATA                           ; Okay... WHAT THE HELL?
                      INC.B _0                                  ; I'll have nightmares about this routine for a few years. :(
                      DEX
                      BPL -                                     ; Ouch.
                      DEY
                      BPL Upload____ToVRAM
                      SEP #$20                                  ; A->8
                      RTS

CODE_00AB42:          LDY.B #$27
                      JSL CODE_00BA28
                      REP #$10                                  ; XY->16
                      LDY.W #$0000
                      LDX.W #$03FF
                    - LDA.B [_0],Y
                      STA.B _F
                      JSR CODE_00ABC4
                      LDA.B _4
                      STA.W HW_VMDATA+1
                      JSR CODE_00ABC4
                      LDA.B _4
                      STA.W HW_VMDATA+1
                      STZ.B _4
                      ROL.B _F
                      ROL.B _4
                      ROL.B _F
                      ROL.B _4
                      INY
                      LDA.B [_0],Y
                      STA.B _F
                      ROL.B _F
                      ROL.B _4
                      LDA.B _4
                      STA.W HW_VMDATA+1
                      JSR CODE_00ABC4
                      LDA.B _4
                      STA.W HW_VMDATA+1
                      JSR CODE_00ABC4
                      LDA.B _4
                      STA.W HW_VMDATA+1
                      STZ.B _4
                      ROL.B _F
                      ROL.B _4
                      INY
                      LDA.B [_0],Y
                      STA.B _F
                      ROL.B _F
                      ROL.B _4
                      ROL.B _F
                      ROL.B _4
                      LDA.B _4
                      STA.W HW_VMDATA+1
                      JSR CODE_00ABC4
                      LDA.B _4
                      STA.W HW_VMDATA+1
                      JSR CODE_00ABC4
                      LDA.B _4
                      STA.W HW_VMDATA+1
                      INY
                      DEX
                      BPL -
                      LDX.W #$2000
                    - STZ.W HW_VMDATA+1
                      DEX
                      BNE -
                      SEP #$10                                  ; XY->8
                      RTS

CODE_00ABC4:          STZ.B _4
                      ROL.B _F
                      ROL.B _4
                      ROL.B _F
                      ROL.B _4
                      ROL.B _F
                      ROL.B _4
                      RTS


DATA_00ABD3:          db $00,$18,$30,$48,$60,$78,$90,$A8        ; Offsets for FG, BG, Sprite Palettes

                      db $00,$14,$28,$3C                        ; Offsets for The End Palettes??

DATA_00ABDF:          dw $0000,$0038,$0070,$00A8                ; Offsets for Overworld Palettes
                      dw $00E0,$0118,$0150

LoadPalette:          REP #$30                                  ; AXY->16
                      LDA.W #$7FDD                              ; \
                      STA.B _4                                  ; |Set color 1 in all object palettes to white
                      LDX.W #$0002                              ; |
                      JSR LoadCol8Pal                           ; /
                      LDA.W #$7FFF                              ; \
                      STA.B _4                                  ; |Set color 1 in all sprite palettes to white
                      LDX.W #$0102                              ; |
                      JSR LoadCol8Pal                           ; /
                      LDA.W #StatusBarColors                    ; \
                      STA.B _0                                  ; |
                      LDA.W #$0010                              ; |Load colors 8-16 in the first two object palettes from 00/B170
                      STA.B _4                                  ; |(Layer 3 palettes)
                      LDA.W #$0007                              ; |
                      STA.B _6                                  ; |
                      LDA.W #$0001                              ; |
                      STA.B _8                                  ; |
                      JSR LoadColors                            ; /
                      LDA.W #StandardColors                     ; \
                      STA.B _0                                  ; |
                      LDA.W #$0084                              ; |Load colors 2-7 in palettes 4-D from 00/B250
                      STA.B _4                                  ; |(Object and sprite palettes)
                      LDA.W #$0005                              ; |
                      STA.B _6                                  ; |
                      LDA.W #$0009                              ; |
                      STA.B _8                                  ; |
                      JSR LoadColors                            ; /
                      LDA.W BackAreaColor                       ; \
                      AND.W #$000F                              ; |
                      ASL A                                     ; |Load background color
                      TAY                                       ; |
                      LDA.W BackAreaColors,Y                    ; |
                      STA.W BackgroundColor                     ; /
                      LDA.W #ForegroundPalettes                 ; \Store base address in $00, ...
                      STA.B _0                                  ; /
                      LDA.W ForegroundPalette                   ; \...get current object palette, ...
                      AND.W #$000F                              ; /
                      TAY                                       ; \
                      LDA.W DATA_00ABD3,Y                       ; |
                      AND.W #$00FF                              ; |...use it to figure out where to load from, ...
                      CLC                                       ; |
                      ADC.B _0                                  ; |...add it to the base address...
                      STA.B _0                                  ; / ...and store it in $00
                      LDA.W #$0044                              ; \
                      STA.B _4                                  ; |
                      LDA.W #$0005                              ; |
                      STA.B _6                                  ; |Load colors 2-7 in object palettes 2 and 3 from the address in $00
                      LDA.W #$0001                              ; |
                      STA.B _8                                  ; |
                      JSR LoadColors                            ; /
                      LDA.W #SpriteColors                       ; \Store base address in $00, ...
                      STA.B _0                                  ; /
                      LDA.W SpritePalette                       ; \...get current sprite palette, ...
                      AND.W #$000F                              ; /
                      TAY                                       ; \
                      LDA.W DATA_00ABD3,Y                       ; |
                      AND.W #$00FF                              ; |...use it to figure out where to load from, ...
                      CLC                                       ; |
                      ADC.B _0                                  ; |...add it to the base address...
                      STA.B _0                                  ; / ...and store it in $00
                      LDA.W #$01C4                              ; \
                      STA.B _4                                  ; |
                      LDA.W #$0005                              ; |
                      STA.B _6                                  ; |Load colors 2-7 in sprite palettes 6 and 7 from the address in $00
                      LDA.W #$0001                              ; |
                      STA.B _8                                  ; |
                      JSR LoadColors                            ; /
                      LDA.W #BackgroundPalettes                 ; \Store bade address in $00, ...
                      STA.B _0                                  ; /
                      LDA.W BackgroundPalette                   ; \...get current background palette, ...
                      AND.W #$000F                              ; /
                      TAY                                       ; \
                      LDA.W DATA_00ABD3,Y                       ; |
                      AND.W #$00FF                              ; |...use it to figure out where to load from, ...
                      CLC                                       ; |
                      ADC.B _0                                  ; |...add it to the base address...
                      STA.B _0                                  ; / ...and store it in $00
                      LDA.W #$0004                              ; \
                      STA.B _4                                  ; |
                      LDA.W #$0005                              ; |
                      STA.B _6                                  ; |Load colors 2-7 in object palettes 0 and 1 from the address in $00
                      LDA.W #$0001                              ; |
                      STA.B _8                                  ; |
                      JSR LoadColors                            ; /
                      LDA.W #BerryColors                        ; \
                      STA.B _0                                  ; |
                      LDA.W #$0052                              ; |
                      STA.B _4                                  ; |
                      LDA.W #$0006                              ; |Load colors 9-F in object palettes 2-4 from 00/B674
                      STA.B _6                                  ; |
                      LDA.W #$0002                              ; |
                      STA.B _8                                  ; |
                      JSR LoadColors                            ; /
                      LDA.W #BerryColors                        ; \
                      STA.B _0                                  ; |
                      LDA.W #$0132                              ; |
                      STA.B _4                                  ; |
                      LDA.W #$0006                              ; |Load colors 9-F in sprite palettes 1-3 from 00/B674
                      STA.B _6                                  ; |
                      LDA.W #$0002                              ; |
                      STA.B _8                                  ; |
                      JSR LoadColors                            ; /
                      SEP #$30                                  ; AXY->8
                      RTS

LoadCol8Pal:          LDY.W #$0007
                    - LDA.B _4
                      STA.W MainPalette,X
                      TXA
                      CLC
                      ADC.W #$0020
                      TAX
                      DEY
                      BPL -
                      RTS

LoadColors:           LDX.B _4
                      LDY.B _6
                    - LDA.B (_0)
                      STA.W MainPalette,X
                      INC.B _0
                      INC.B _0
                      INX
                      INX
                      DEY
                      BPL -
                      LDA.B _4
                      CLC
                      ADC.W #$0020
                      STA.B _4
                      DEC.B _8
                      BPL LoadColors
                      RTS


DATA_00AD1E:          db $01,$00,$03,$04,$03,$05,$02            ; Palette Indices for Overworld Maps

CODE_00AD25:          REP #$30                                  ; AXY->16
                      LDY.W #OverworldColors
                      LDA.W OWLevelTileSettings+$48
                      BPL +
                      LDY.W #OWSpecialColors
                    + STY.B _0
                      LDA.W ObjectTileset
                      AND.W #$000F
                      DEC A
                      TAY
                      LDA.W DATA_00AD1E,Y
                      AND.W #$00FF
                      ASL A
                      TAY
                      LDA.W DATA_00ABDF,Y
                      CLC
                      ADC.B _0
                      STA.B _0
                      LDA.W #$0082
                      STA.B _4
                      LDA.W #$0006
                      STA.B _6
                      LDA.W #$0003
                      STA.B _8
                      JSR LoadColors
                      LDA.W #OWStdColors
                      STA.B _0
                      LDA.W #$0052
                      STA.B _4
                      LDA.W #$0006
                      STA.B _6
                      LDA.W #$0005
                      STA.B _8
                      JSR LoadColors
                      LDA.W #OWStdColors2
                      STA.B _0
                      LDA.W #$0102
                      STA.B _4
                      LDA.W #$0006
                      STA.B _6
                      LDA.W #$0007
                      STA.B _8
                      JSR LoadColors
                      LDA.W #OverworldHudColors
                      STA.B _0
                      LDA.W #$0010
                      STA.B _4
                      LDA.W #$0007
                      STA.B _6
                      LDA.W #$0001
                      STA.B _8
                      JSR LoadColors
                      SEP #$30                                  ; AXY->8
                      RTS

CODE_00ADA6:          REP #$30                                  ; AXY->16
                      LDA.W #TitleScreenColors+$10
                      STA.B _0
                      LDA.W #$0010
                      STA.B _4
                      LDA.W #$0007
                      STA.B _6
                      LDA.W #$0000
                      STA.B _8
                      JSR LoadColors
                      LDA.W #TitleScreenColors
                      STA.B _0
                      LDA.W #$0030
                      STA.B _4
                      LDA.W #$0007
                      STA.B _6
                      LDA.W #$0000
                      STA.B _8
                      JSR LoadColors
                      SEP #$30                                  ; AXY->8
                      RTS

CODE_00ADD9:          JSR LoadPalette
                      REP #$30                                  ; AXY->16
                      LDA.W #$0017
                      STA.W BackgroundColor
                      LDA.W #StatusBarColors
                      STA.B _0
                      LDA.W #$0010
                      STA.B _4
                      LDA.W #$0007
                      STA.B _6
                      LDA.W #$0001
                      STA.B _8
                      JSR LoadColors
                      LDA.W #IggyLarryPlatColors
                      STA.B _0
                      LDA.W #$0000
                      STA.B _4
                      LDA.W #$0007
                      STA.B _6
                      LDA.W #$0000
                      STA.B _8
                      JSR LoadColors
                      SEP #$30                                  ; AXY->8
                      RTS

CODE_00AE15:          LDA.B #$02
                      STA.W SpritePalette
                      LDA.B #$07
                      STA.W ForegroundPalette
                      JSR LoadPalette
                      REP #$30                                  ; AXY->16
                      LDA.W #$0017
                      STA.W BackgroundColor
                      LDA.W #OverworldHudColors+8
                      STA.B _0
                      LDA.W #$0018
                      STA.B _4
                      LDA.W #$0003
                      STA.B _6
                      STZ.B _8
                      JSR LoadColors
                      SEP #$30                                  ; AXY->8
                      RTS


DATA_00AE41:          db $00,$05,$0A
DATA_00AE44:          db $20,$40,$80

CODE_00AE47:          LDX.B #$02
CODE_00AE49:          REP #$20                                  ; A->16
                      LDA.W BackgroundColor
                      LDY.W DATA_00AE41,X
CODE_00AE51:          DEY
                      BMI CODE_00AE57
                      LSR A
                      BRA CODE_00AE51

CODE_00AE57:          SEP #$20                                  ; A->8
                      AND.B #$1F
                      ORA.W DATA_00AE44,X
                      STA.W HW_COLDATA
                      DEX
                      BPL CODE_00AE49
                      RTS


DATA_00AE65:          dw $001F,$03E0,$7C00

DATA_00AE6B:          dw $FFFF,$FFE0,$FC00

DATA_00AE71:          dw $0001,$0020,$0400

DATA_00AE77:          dw $0000,$0000,$0001,$0000
                      dw $8000,$8000,$8020,$0400
                      dw $8080,$8080,$8208,$1040
                      dw $8420,$8420,$8844,$2210
                      dw $8888,$8888,$9122,$4488
                      dw $9248,$9248,$A492,$4924
                      dw $A4A4,$A4A4,$A949,$5294
                      dw $AAAA,$5294,$AAAA,$5554
                      dw $AAAA,$AAAA,$D5AA,$AAAA
                      dw $D5AA,$D5AA,$D6B5,$AD6A
                      dw $DADA,$DADA,$DB6D,$B6DA
                      dw $EDB6,$EDB6,$EEDD,$BB76
                      dw $EEEE,$EEEE,$F7BB,$DDEE
                      dw $FBDE,$FBDE,$FDF7,$EFBE
                      dw $FEFE,$FEFE,$FFDF,$FBFE
                      dw $FFFE,$FFFE,$FFFF,$FFFE

DATA_00AEF7:          dw $8000,$4000,$2000,$1000
                      dw $0800,$0400,$0200,$0100
                      dw $0080,$0040,$0020,$0010
                      dw $0008,$0004,$0002,$0001

CODE_00AF17:          LDY.W EndLevelTimer
                      LDA.B TrueFrame
                      LSR A
                      BCC +
                      DEY
                      BEQ +
                      STY.W EndLevelTimer
                    + CPY.B #con($A0,$A0,$A0,$B0,$B0)
                      BCS CODE_00AF35
                      LDA.B #$04
                      TRB.B ColorSettings
                      LDA.B #$09
                      STA.B MainBGMode
                      JSL CODE_05CBFF
CODE_00AF35:          LDA.B TrueFrame
                      AND.B #$03
                      BNE Return00AFA2
                      LDA.W ColorFadeTimer
                      CMP.B #$40
                      BCS Return00AFA2
                      JSR CODE_00AFA3
                      LDA.W #$01FE
                      STA.W CopyPalette
                      LDX.W #$00EE
CODE_00AF4E:          LDA.W #$0007
                      STA.B _0
                    - LDA.W CopyPalette,X
                      STA.B _2
                      LDA.W MainPalette,X
                      JSR CODE_00AFC0
                      LDA.B _4
                      STA.W CopyPalette,X
                      DEX
                      DEX
                      DEC.B _0
                      BNE -
                      TXA
                      SEC
                      SBC.W #$0012
                      TAX
                      BPL CODE_00AF4E
                      LDX.W #$0004
                    - LDA.W CopyPalette+$1A,X
                      STA.B _2
                      LDA.W MainPalette+$1A,X
                      JSR CODE_00AFC0
                      LDA.B _4
                      STA.W CopyPalette+$1A,X
                      DEX
                      DEX
                      BPL -
                      LDA.W BackgroundColor
                      STA.B _2
                      LDA.W CopyBGColor
                      JSR CODE_00AFC0
                      LDA.B _4
                      STA.W BackgroundColor
                      SEP #$30                                  ; AXY->8
                      STZ.W CopyPalette+$100
                      LDA.B #$03
                      STA.W PaletteIndexTable
Return00AFA2:         RTS

CODE_00AFA3:          TAY
                      INC A
                      INC A
                      STA.W ColorFadeTimer
                      TYA
                      LSR A
                      LSR A
                      LSR A
                      LSR A
                      REP #$30                                  ; AXY->16
                      AND.W #$0002
                      STA.B _C
                      TYA
                      AND.W #$001E
                      TAY
                      LDA.W DATA_00AEF7,Y
                      STA.B _E
                      RTS

CODE_00AFC0:          STA.B _A
                      AND.W #$001F
                      ASL A
                      ASL A
                      STA.B _6
                      LDA.B _A
                      AND.W #$03E0
                      LSR A
                      LSR A
                      LSR A
                      STA.B _8
                      LDA.B _B
                      AND.W #$007C
                      STA.B _A
                      STZ.B _4
                      LDY.W #$0004
CODE_00AFDF:          PHY
                      LDA.W _6,Y
                      ORA.B _C
                      TAY
                      LDA.W DATA_00AE77,Y
                      PLY
                      AND.B _E
                      BEQ +
                      LDA.W DATA_00AE6B,Y
                      BIT.W EndLevelTimer
                      BPL +
                      LDA.W DATA_00AE71,Y
                    + CLC
                      ADC.B _2
                      AND.W DATA_00AE65,Y
                      TSB.B _4
                      DEY
                      DEY
                      BPL CODE_00AFDF
                      RTS

CODE_00B006:          PHB
                      PHK
                      PLB
                      JSR CODE_00AFA3
                      LDX.W #$006E
CODE_00B00F:          LDY.W #$0008
                    - LDA.W CopyPalette+2,X
                      STA.B _2
                      LDA.W MainPalette+$80,X
                      PHY
                      JSR CODE_00AFC0
                      PLY
                      LDA.B _4
                      STA.W CopyPalette+2,X
                      LDA.W MainPalette+$80,X
                      SEC
                      SBC.B _4
                      STA.W CopyPalette+$74,X
                      DEX
                      DEX
                      DEY
                      BNE -
                      TXA
                      SEC
                      SBC.W #$0010
                      TAX
                      BPL CODE_00B00F
                      SEP #$30                                  ; AXY->8
                      PLB
                      RTL

CODE_00B03E:          JSR CODE_00AF35
                      LDA.W PaletteIndexTable
                      CMP.B #$03
                      BNE Return00B090
                      LDA.B #$00
                      STA.B _2
                      REP #$30                                  ; AXY->16
                      LDA.W PlayerPalletePtr
                      STA.B _0
                      LDY.W #$0014
                    - LDA.B [_0],Y
                      STA.W CopyPalette+$10C,Y
                      DEY
                      DEY
                      BPL -
                      LDA.W #$81EE
                      STA.W CopyPalette+$100
                      LDX.W #$00CE
CODE_00B068:          LDA.W #$0007
                      STA.B _0
                    - LDA.W CopyPalette+$120,X
                      STA.B _2
                      LDA.W MainPalette+$120,X
                      JSR CODE_00AFC0
                      LDA.B _4
                      STA.W CopyPalette+$120,X
                      DEX
                      DEX
                      DEC.B _0
                      BNE -
                      TXA
                      SEC
                      SBC.W #$0012
                      TAX
                      BPL CODE_00B068
                      SEP #$30                                  ; AXY->8
                      STZ.W Empty0AF5
Return00B090:         RTS

                      %insert_empty($11,$0F,$36,$1D,$1B)

BackAreaColors:       %incpal("col/misc/back_area.pal")

BackgroundPalettes:   %incpal("col/lvl/bg_00.pal")
                      %incpal("col/lvl/bg_01.pal")
                      %incpal("col/lvl/bg_02.pal")
                      %incpal("col/lvl/bg_03.pal")
                      %incpal("col/lvl/bg_04.pal")
                      %incpal("col/lvl/bg_05.pal")
                      %incpal("col/lvl/bg_06.pal")
                      %incpal("col/lvl/bg_07.pal")

StatusBarColors:      %incpal("col/misc/status_bar.pal")

ForegroundPalettes:   %incpal("col/lvl/fg_00.pal")
                      %incpal("col/lvl/fg_01.pal")
                      %incpal("col/lvl/fg_02.pal")
                      %incpal("col/lvl/fg_03.pal")
                      %incpal("col/lvl/fg_04.pal")
                      %incpal("col/lvl/fg_05.pal")
                      %incpal("col/lvl/fg_06.pal")
                      %incpal("col/lvl/fg_07.pal")

StandardColors:       %incpal("col/lvl/std_04.pal")
                      %incpal("col/lvl/std_05.pal")
                      %incpal("col/lvl/std_06.pal")
                      %incpal("col/lvl/std_07.pal")
                      %incpal("col/lvl/std_08.pal")
                      %incpal("col/lvl/std_09.pal")
                      %incpal("col/lvl/std_0A.pal")
                      %incpal("col/lvl/std_0B.pal")
                      %incpal("col/lvl/std_0C.pal")
                      %incpal("col/lvl/std_0D.pal")

PlayerColors:         %incpal("col/misc/mario_normal.pal")
                      %incpal("col/misc/luigi_normal.pal")
                      %incpal("col/misc/mario_fire.pal")
                      %incpal("col/misc/luigi_fire.pal")

SpriteColors:         %incpal("col/lvl/spr_00.pal")
                      %incpal("col/lvl/spr_01.pal")
                      %incpal("col/lvl/spr_02.pal")
                      %incpal("col/lvl/spr_03.pal")
                      %incpal("col/lvl/spr_04.pal")
                      %incpal("col/lvl/spr_05.pal")
                      %incpal("col/lvl/spr_06.pal")
                      %incpal("col/lvl/spr_07.pal")

OverworldColors:      %incpal("col/ow/YI_normal.pal")
                      %incpal("col/ow/main_normal.pal")
                      %incpal("col/ow/star_normal.pal")
                      %incpal("col/ow/caves_normal.pal")
                      %incpal("col/ow/FoI_normal.pal")
                      %incpal("col/ow/special_normal.pal")

OWStdColors:          %incpal("col/ow/std_02.pal")
                      %incpal("col/ow/std_03.pal")
                      %incpal("col/ow/std_04.pal")
                      %incpal("col/ow/std_05.pal")
                      %incpal("col/ow/std_06.pal")
                      %incpal("col/ow/std_07.pal")

OWStdColors2:         %incpal("col/ow/std_08.pal")
                      %incpal("col/ow/std_09.pal")
                      %incpal("col/ow/std_0A.pal")
                      %incpal("col/ow/std_0B.pal")
                      %incpal("col/ow/std_0C.pal")
                      %incpal("col/ow/std_0D.pal")
                      %incpal("col/ow/std_0E.pal")

OverworldLightning:   %incpal("col/ow/lightning.pal")           ; Also Palette F Colors 1-7

OverworldHudColors:   %incpal("col/ow/border.pal")

FlashingColors:       %incpal("col/misc/flashing_yellow.pal")
                      %incpal("col/misc/flashing_red.pal")

TitleScreenColors:    %incpal("col/misc/title_screen.pal")

                      %incpal("col/misc/blue_gradient.pal")     ; Unknown Blue Gradient

IggyLarryPlatColors:  %incpal("col/misc/iggy_platform.pal")

BigCrusherColors:     %incpal("col/misc/castle_crusher.pal")

BerryColors:          %incpal("col/misc/berry_red.pal")
                      %incpal("col/misc/berry_pink.pal")
                      %incpal("col/misc/berry_green.pal")

BowserColors:         %incpal("col/misc/bowser.pal")

TheEndColors:         %incpal("col/misc/the_end_0D.pal")
                      %incpal("col/misc/the_end_0E.pal")
                      %incpal("col/misc/the_end_0F.pal")

OWSpecialColors:      %incpal("col/ow/YI_special.pal")
                      %incpal("col/ow/main_special.pal")
                      %incpal("col/ow/star_special.pal")
                      %incpal("col/ow/caves_special.pal")
                      %incpal("col/ow/FoI_special.pal")
                      %incpal("col/ow/special_special.pal")

                      dl GFX33&$7FFFFF
                      dl GFX32&$7FFFFF

CODE_00B888:          REP #$10                                  ; XY->16
                      LDY.W #GFX33                              ; \
                      STY.B GraphicsCompPtr                     ; |Store the address 08/BFC0 at $8A-$8C
                      LDA.B #GFX33>>16&$7F                      ; |
                      STA.B GraphicsCompPtr+2                   ; /
                      LDY.W #MarioGraphics                      ; \
                      STY.B _0                                  ; |Store the address 7E/2000 at $00-$02
                      LDA.B #MarioGraphics>>16&$7F              ; |
                      STA.B _2                                  ; /
                      JSR CODE_00B8DE
                      LDA.B #MarioGraphics>>16&$7F              ; \
                      STA.B GraphicsUncompPtr+2                 ; |
                      REP #$30                                  ; |AXY->16, Store the address 7E/ACFE at $8D-$8F
                      LDA.W #MarioGraphics+$8CFE                ; |
                      STA.B GraphicsUncompPtr                   ; /
                      LDX.W #$23FF
CODE_00B8AD:          LDY.W #$0008
                    - LDA.L MarioGraphics,X
                      AND.W #$00FF
                      STA.B [GraphicsUncompPtr]
                      DEX
                      DEC.B GraphicsUncompPtr
                      DEC.B GraphicsUncompPtr
                      DEY
                      BNE -
                      LDY.W #$0008
CODE_00B8C4:          DEX
                      LDA.L MarioGraphics,X
                      STA.B [GraphicsUncompPtr]
                      DEX
                      BMI CODE_00B8D7
                      DEC.B GraphicsUncompPtr
                      DEC.B GraphicsUncompPtr
                      DEY
                      BNE CODE_00B8C4
                      BRA CODE_00B8AD

CODE_00B8D7:          LDA.W #$8000
                      STA.B GraphicsCompPtr
                      SEP #$20                                  ; A->8
CODE_00B8DE:          REP #$10                                  ; XY->16
                      LDY.W #$0000                              ; \
CODE_00B8E3:          JSR ReadByte                              ; |
                      CMP.B #$FF                                ; |If the next byte is xFF, return.
                      BNE +                                     ; |Compressed graphics files ends with xFF IIRC
                      SEP #$10                                  ; | XY->8
                      RTS                                       ; /

                    + STA.B GraphicsUncompPtr+2
                      AND.B #$E0
                      CMP.B #$E0
                      BEQ CODE_00B8FF
                      PHA
                      LDA.B GraphicsUncompPtr+2
                      REP #$20                                  ; A->16
                      AND.W #$001F
                      BRA +

CODE_00B8FF:          LDA.B GraphicsUncompPtr+2
                      ASL A
                      ASL A
                      ASL A
                      AND.B #$E0
                      PHA
                      LDA.B GraphicsUncompPtr+2
                      AND.B #$03
                      XBA
                      JSR ReadByte
                      REP #$20                                  ; A->16
                    + INC A
                      STA.B GraphicsUncompPtr
                      SEP #$20                                  ; A->8
                      PLA
                      BEQ CODE_00B930
                      BMI CODE_00B966
                      ASL A
                      BPL CODE_00B93F
                      ASL A
                      BPL CODE_00B94C
                      JSR ReadByte
                      LDX.B GraphicsUncompPtr
                    - STA.B [_0],Y
                      INC A
                      INY
                      DEX
                      BNE -
                      JMP CODE_00B8E3

CODE_00B930:          JSR ReadByte
                      STA.B [_0],Y
                      INY
                      LDX.B GraphicsUncompPtr
                      DEX
                      STX.B GraphicsUncompPtr
                      BNE CODE_00B930
                      BRA CODE_00B8E3

CODE_00B93F:          JSR ReadByte
                      LDX.B GraphicsUncompPtr
                    - STA.B [_0],Y
                      INY
                      DEX
                      BNE -
                      BRA CODE_00B8E3

CODE_00B94C:          JSR ReadByte
                      XBA
                      JSR ReadByte
                      LDX.B GraphicsUncompPtr
CODE_00B955:          XBA
                      STA.B [_0],Y
                      INY
                      DEX
                      BEQ CODE_00B963
                      XBA
                      STA.B [_0],Y
                      INY
                      DEX
                      BNE CODE_00B955
CODE_00B963:          JMP CODE_00B8E3

CODE_00B966:          JSR ReadByte
                      XBA
                      JSR ReadByte
                   if ver_has_rev_gfx(!_VER)                    ;\==================== J & E1 ===================
                      XBA                                       ;! ThinkingFace
                   endif                                        ;/===============================================
                      TAX
                    - PHY
                      TXY
                      LDA.B [_0],Y
                      TYX
                      PLY
                      STA.B [_0],Y
                      INY
                      INX
                      REP #$20                                  ; A->16
                      DEC.B GraphicsUncompPtr
                      SEP #$20                                  ; A->8
                      BNE -
                      JMP CODE_00B8E3

ReadByte:             LDA.B [GraphicsCompPtr]                   ; Read the byte
                      LDX.B GraphicsCompPtr                     ; \ Go to next byte
                      INX                                       ; |
                      BNE +                                     ; |   \
                      LDX.W #$8000                              ; |    |Handle bank crossing
                      INC.B GraphicsCompPtr+2                   ; |   /
                    + STX.B GraphicsCompPtr                     ; /
                      RTS

GFXFilesLow:          db GFX00
                      db GFX01
                      db GFX02
                      db GFX03
                      db GFX04
                      db GFX05
                      db GFX06
                      db GFX07
                      db GFX08
                      db GFX09
                      db GFX0A
                      db GFX0B
                      db GFX0C
                      db GFX0D
                      db GFX0E
                      db GFX0F
                      db GFX10
                      db GFX11
                      db GFX12
                      db GFX13
                      db GFX14
                      db GFX15
                      db GFX16
                      db GFX17
                      db GFX18
                      db GFX19
                      db GFX1A
                      db GFX1B
                      db GFX1C
                      db GFX1D
                      db GFX1E
                      db GFX1F
                      db GFX20
                      db GFX21
                      db GFX22
                      db GFX23
                      db GFX24
                      db GFX25
                      db GFX26
                      db GFX27
                      db GFX28
                      db GFX29
                      db GFX2A
                      db GFX2B
                      db GFX2C
                      db GFX2D
                      db GFX2E
                      db GFX2F
                      db GFX30
                      db GFX31

GFXFilesHigh:         db GFX00>>8
                      db GFX01>>8
                      db GFX02>>8
                      db GFX03>>8
                      db GFX04>>8
                      db GFX05>>8
                      db GFX06>>8
                      db GFX07>>8
                      db GFX08>>8
                      db GFX09>>8
                      db GFX0A>>8
                      db GFX0B>>8
                      db GFX0C>>8
                      db GFX0D>>8
                      db GFX0E>>8
                      db GFX0F>>8
                      db GFX10>>8
                      db GFX11>>8
                      db GFX12>>8
                      db GFX13>>8
                      db GFX14>>8
                      db GFX15>>8
                      db GFX16>>8
                      db GFX17>>8
                      db GFX18>>8
                      db GFX19>>8
                      db GFX1A>>8
                      db GFX1B>>8
                      db GFX1C>>8
                      db GFX1D>>8
                      db GFX1E>>8
                      db GFX1F>>8
                      db GFX20>>8
                      db GFX21>>8
                      db GFX22>>8
                      db GFX23>>8
                      db GFX24>>8
                      db GFX25>>8
                      db GFX26>>8
                      db GFX27>>8
                      db GFX28>>8
                      db GFX29>>8
                      db GFX2A>>8
                      db GFX2B>>8
                      db GFX2C>>8
                      db GFX2D>>8
                      db GFX2E>>8
                      db GFX2F>>8
                      db GFX30>>8
                      db GFX31>>8

GFXFilesBank:         db GFX00>>16&$7F
                      db GFX01>>16&$7F
                      db GFX02>>16&$7F
                      db GFX03>>16&$7F
                      db GFX04>>16&$7F
                      db GFX05>>16&$7F
                      db GFX06>>16&$7F
                      db GFX07>>16&$7F
                      db GFX08>>16&$7F
                      db GFX09>>16&$7F
                      db GFX0A>>16&$7F
                      db GFX0B>>16&$7F
                      db GFX0C>>16&$7F
                      db GFX0D>>16&$7F
                      db GFX0E>>16&$7F
                      db GFX0F>>16&$7F
                      db GFX10>>16&$7F
                      db GFX11>>16&$7F
                      db GFX12>>16&$7F
                      db GFX13>>16&$7F
                      db GFX14>>16&$7F
                      db GFX15>>16&$7F
                      db GFX16>>16&$7F
                      db GFX17>>16&$7F
                      db GFX18>>16&$7F
                      db GFX19>>16&$7F
                      db GFX1A>>16&$7F
                      db GFX1B>>16&$7F
                      db GFX1C>>16&$7F
                      db GFX1D>>16&$7F
                      db GFX1E>>16&$7F
                      db GFX1F>>16&$7F
                      db GFX20>>16&$7F
                      db GFX21>>16&$7F
                      db GFX22>>16&$7F
                      db GFX23>>16&$7F
                      db GFX24>>16&$7F
                      db GFX25>>16&$7F
                      db GFX26>>16&$7F
                      db GFX27>>16&$7F
                      db GFX28>>16&$7F
                      db GFX29>>16&$7F
                      db GFX2A>>16&$7F
                      db GFX2B>>16&$7F
                      db GFX2C>>16&$7F
                      db GFX2D>>16&$7F
                      db GFX2E>>16&$7F
                      db GFX2F>>16&$7F
                      db GFX30>>16&$7F
                      db GFX31>>16&$7F

CODE_00BA28:          PHB
                      PHY
                      PHK
                      PLB
                      LDA.W GFXFilesLow,Y
                      STA.B GraphicsCompPtr
                      LDA.W GFXFilesHigh,Y
                      STA.B GraphicsCompPtr+1
                      LDA.W GFXFilesBank,Y
                      STA.B GraphicsCompPtr+2
                      LDA.B #$00
                      STA.B _0
                      LDA.B #$AD
                      STA.B _1
                      LDA.B #$7E
                      STA.B _2
                      JSR CODE_00B8DE
                      PLY
                      PLB
                      RTL

                      %insert_empty($12,$13,$03,$00,$00)

DATA_00BA60:          db Map16TilesLow
                      db Map16TilesLow+$1B0
                      db Map16TilesLow+$360
                      db Map16TilesLow+$510
                      db Map16TilesLow+$6C0
                      db Map16TilesLow+$870
                      db Map16TilesLow+$A20
                      db Map16TilesLow+$BD0
                      db Map16TilesLow+$D80
                      db Map16TilesLow+$F30
                      db Map16TilesLow+$10E0
                      db Map16TilesLow+$1290
                      db Map16TilesLow+$1440
                      db Map16TilesLow+$15F0
                      db Map16TilesLow+$17A0
                      db Map16TilesLow+$1950
DATA_00BA70:          db Map16TilesLow+$1B00
                      db Map16TilesLow+$1CB0
                      db Map16TilesLow+$1E60
                      db Map16TilesLow+$2010
                      db Map16TilesLow+$21C0
                      db Map16TilesLow+$2370
                      db Map16TilesLow+$2520
                      db Map16TilesLow+$26D0
                      db Map16TilesLow+$2880
                      db Map16TilesLow+$2A30
                      db Map16TilesLow+$2BE0
                      db Map16TilesLow+$2D90
                      db Map16TilesLow+$2F40
                      db Map16TilesLow+$30F0
                      db Map16TilesLow+$32A0
                      db Map16TilesLow+$3450

DATA_00BA80:          db Map16TilesLow
                      db Map16TilesLow+$200
                      db Map16TilesLow+$400
                      db Map16TilesLow+$600
                      db Map16TilesLow+$800
                      db Map16TilesLow+$A00
                      db Map16TilesLow+$C00
                      db Map16TilesLow+$E00
                      db Map16TilesLow+$1000
                      db Map16TilesLow+$1200
                      db Map16TilesLow+$1400
                      db Map16TilesLow+$1600
                      db Map16TilesLow+$1800
                      db Map16TilesLow+$1A00
DATA_00BA8E:          db Map16TilesLow+$1C00
                      db Map16TilesLow+$1E00
                      db Map16TilesLow+$2000
                      db Map16TilesLow+$2200
                      db Map16TilesLow+$2400
                      db Map16TilesLow+$2600
                      db Map16TilesLow+$2800
                      db Map16TilesLow+$2A00
                      db Map16TilesLow+$2C00
                      db Map16TilesLow+$2E00
                      db Map16TilesLow+$3000
                      db Map16TilesLow+$3200
                      db Map16TilesLow+$3400
                      db Map16TilesLow+$3600

DATA_00BA9C:          db Map16TilesLow>>8
                      db Map16TilesLow+$1B0>>8
                      db Map16TilesLow+$360>>8
                      db Map16TilesLow+$510>>8
                      db Map16TilesLow+$6C0>>8
                      db Map16TilesLow+$870>>8
                      db Map16TilesLow+$A20>>8
                      db Map16TilesLow+$BD0>>8
                      db Map16TilesLow+$D80>>8
                      db Map16TilesLow+$F30>>8
                      db Map16TilesLow+$10E0>>8
                      db Map16TilesLow+$1290>>8
                      db Map16TilesLow+$1440>>8
                      db Map16TilesLow+$15F0>>8
                      db Map16TilesLow+$17A0>>8
                      db Map16TilesLow+$1950>>8
DATA_00BAAC:          db Map16TilesLow+$1B00>>8
                      db Map16TilesLow+$1CB0>>8
                      db Map16TilesLow+$1E60>>8
                      db Map16TilesLow+$2010>>8
                      db Map16TilesLow+$21C0>>8
                      db Map16TilesLow+$2370>>8
                      db Map16TilesLow+$2520>>8
                      db Map16TilesLow+$26D0>>8
                      db Map16TilesLow+$2880>>8
                      db Map16TilesLow+$2A30>>8
                      db Map16TilesLow+$2BE0>>8
                      db Map16TilesLow+$2D90>>8
                      db Map16TilesLow+$2F40>>8
                      db Map16TilesLow+$30F0>>8
                      db Map16TilesLow+$32A0>>8
                      db Map16TilesLow+$3450>>8

DATA_00BABC:          db Map16TilesLow>>8
                      db Map16TilesLow+$200>>8
                      db Map16TilesLow+$400>>8
                      db Map16TilesLow+$600>>8
                      db Map16TilesLow+$800>>8
                      db Map16TilesLow+$A00>>8
                      db Map16TilesLow+$C00>>8
                      db Map16TilesLow+$E00>>8
                      db Map16TilesLow+$1000>>8
                      db Map16TilesLow+$1200>>8
                      db Map16TilesLow+$1400>>8
                      db Map16TilesLow+$1600>>8
                      db Map16TilesLow+$1800>>8
                      db Map16TilesLow+$1A00>>8
DATA_00BACA:          db Map16TilesLow+$1C00>>8
                      db Map16TilesLow+$1E00>>8
                      db Map16TilesLow+$2000>>8
                      db Map16TilesLow+$2200>>8
                      db Map16TilesLow+$2400>>8
                      db Map16TilesLow+$2600>>8
                      db Map16TilesLow+$2800>>8
                      db Map16TilesLow+$2A00>>8
                      db Map16TilesLow+$2C00>>8
                      db Map16TilesLow+$2E00>>8
                      db Map16TilesLow+$3000>>8
                      db Map16TilesLow+$3200>>8
                      db Map16TilesLow+$3400>>8
                      db Map16TilesLow+$3600>>8

DATA_00BAD8:          dl Map16TilesLow
                      dl Map16TilesLow+$1B0
                      dl Map16TilesLow+$360
                      dl Map16TilesLow+$510
                      dl Map16TilesLow+$6C0
                      dl Map16TilesLow+$870
                      dl Map16TilesLow+$A20
                      dl Map16TilesLow+$BD0
                      dl Map16TilesLow+$D80
                      dl Map16TilesLow+$F30
                      dl Map16TilesLow+$10E0
                      dl Map16TilesLow+$1290
                      dl Map16TilesLow+$1440
                      dl Map16TilesLow+$15F0
                      dl Map16TilesLow+$17A0
                      dl Map16TilesLow+$1950

DATA_00BB08:          dl Map16TilesLow+$1B00
                      dl Map16TilesLow+$1CB0
                      dl Map16TilesLow+$1E60
                      dl Map16TilesLow+$2010
                      dl Map16TilesLow+$21C0
                      dl Map16TilesLow+$2370
                      dl Map16TilesLow+$2520
                      dl Map16TilesLow+$26D0
                      dl Map16TilesLow+$2880
                      dl Map16TilesLow+$2A30
                      dl Map16TilesLow+$2BE0
                      dl Map16TilesLow+$2D90
                      dl Map16TilesLow+$2F40
                      dl Map16TilesLow+$30F0
                      dl Map16TilesLow+$32A0
                      dl Map16TilesLow+$3450

DATA_00BB38:          dl Map16TilesLow
                      dl Map16TilesLow+$200
                      dl Map16TilesLow+$400
                      dl Map16TilesLow+$600
                      dl Map16TilesLow+$800
                      dl Map16TilesLow+$A00
                      dl Map16TilesLow+$C00
                      dl Map16TilesLow+$E00
                      dl Map16TilesLow+$1000
                      dl Map16TilesLow+$1200
                      dl Map16TilesLow+$1400
                      dl Map16TilesLow+$1600
                      dl Map16TilesLow+$1800
                      dl Map16TilesLow+$1A00

DATA_00BB62:          dl Map16TilesLow+$1B00
                      dl Map16TilesLow+$1CB0
                      dl Map16TilesLow+$1E60
                      dl Map16TilesLow+$2010
                      dl Map16TilesLow+$21C0
                      dl Map16TilesLow+$2370
                      dl Map16TilesLow+$2520
                      dl Map16TilesLow+$26D0
                      dl Map16TilesLow+$2880
                      dl Map16TilesLow+$2A30
                      dl Map16TilesLow+$2BE0
                      dl Map16TilesLow+$2D90
                      dl Map16TilesLow+$2F40
                      dl Map16TilesLow+$30F0
                      dl Map16TilesLow+$32A0
                      dl Map16TilesLow+$3450

DATA_00BB92:          dl Map16TilesLow
                      dl Map16TilesLow+$1B0
                      dl Map16TilesLow+$360
                      dl Map16TilesLow+$510
                      dl Map16TilesLow+$6C0
                      dl Map16TilesLow+$870
                      dl Map16TilesLow+$A20
                      dl Map16TilesLow+$BD0
                      dl Map16TilesLow+$D80
                      dl Map16TilesLow+$F30
                      dl Map16TilesLow+$10E0
                      dl Map16TilesLow+$1290
                      dl Map16TilesLow+$1440
                      dl Map16TilesLow+$15F0
                      dl Map16TilesLow+$17A0
                      dl Map16TilesLow+$1950

DATA_00BBC2:          dl Map16TilesLow+$1C00
                      dl Map16TilesLow+$1E00
                      dl Map16TilesLow+$2000
                      dl Map16TilesLow+$2200
                      dl Map16TilesLow+$2400
                      dl Map16TilesLow+$2600
                      dl Map16TilesLow+$2800
                      dl Map16TilesLow+$2A00
                      dl Map16TilesLow+$2C00
                      dl Map16TilesLow+$2E00
                      dl Map16TilesLow+$3000
                      dl Map16TilesLow+$3200
                      dl Map16TilesLow+$3400
                      dl Map16TilesLow+$3600

DATA_00BBEC:          dl Map16TilesLow
                      dl Map16TilesLow+$200
                      dl Map16TilesLow+$400
                      dl Map16TilesLow+$600
                      dl Map16TilesLow+$800
                      dl Map16TilesLow+$A00
                      dl Map16TilesLow+$C00
                      dl Map16TilesLow+$E00
                      dl Map16TilesLow+$1000
                      dl Map16TilesLow+$1200
                      dl Map16TilesLow+$1400
                      dl Map16TilesLow+$1600
                      dl Map16TilesLow+$1800
                      dl Map16TilesLow+$1A00

DATA_00BC16:          dl Map16TilesLow+$1C00
                      dl Map16TilesLow+$1E00
                      dl Map16TilesLow+$2000
                      dl Map16TilesLow+$2200
                      dl Map16TilesLow+$2400
                      dl Map16TilesLow+$2600
                      dl Map16TilesLow+$2800
                      dl Map16TilesLow+$2A00
                      dl Map16TilesLow+$2C00
                      dl Map16TilesLow+$2E00
                      dl Map16TilesLow+$3000
                      dl Map16TilesLow+$3200
                      dl Map16TilesLow+$3400
                      dl Map16TilesLow+$3600

DATA_00BC40:          dl Map16TilesHigh
                      dl Map16TilesHigh+$1B0
                      dl Map16TilesHigh+$360
                      dl Map16TilesHigh+$510
                      dl Map16TilesHigh+$6C0
                      dl Map16TilesHigh+$870
                      dl Map16TilesHigh+$A20
                      dl Map16TilesHigh+$BD0
                      dl Map16TilesHigh+$D80
                      dl Map16TilesHigh+$F30
                      dl Map16TilesHigh+$10E0
                      dl Map16TilesHigh+$1290
                      dl Map16TilesHigh+$1440
                      dl Map16TilesHigh+$15F0
                      dl Map16TilesHigh+$17A0
                      dl Map16TilesHigh+$1950

DATA_00BC70:          dl Map16TilesHigh+$1B00
                      dl Map16TilesHigh+$1CB0
                      dl Map16TilesHigh+$1E60
                      dl Map16TilesHigh+$2010
                      dl Map16TilesHigh+$21C0
                      dl Map16TilesHigh+$2370
                      dl Map16TilesHigh+$2520
                      dl Map16TilesHigh+$26D0
                      dl Map16TilesHigh+$2880
                      dl Map16TilesHigh+$2A30
                      dl Map16TilesHigh+$2BE0
                      dl Map16TilesHigh+$2D90
                      dl Map16TilesHigh+$2F40
                      dl Map16TilesHigh+$30F0
                      dl Map16TilesHigh+$32A0
                      dl Map16TilesHigh+$3450

DATA_00BCA0:          dl Map16TilesHigh
                      dl Map16TilesHigh+$200
                      dl Map16TilesHigh+$400
                      dl Map16TilesHigh+$600
                      dl Map16TilesHigh+$800
                      dl Map16TilesHigh+$A00
                      dl Map16TilesHigh+$C00
                      dl Map16TilesHigh+$E00
                      dl Map16TilesHigh+$1000
                      dl Map16TilesHigh+$1200
                      dl Map16TilesHigh+$1400
                      dl Map16TilesHigh+$1600
                      dl Map16TilesHigh+$1800
                      dl Map16TilesHigh+$1A00

DATA_00BCCA:          dl Map16TilesHigh+$1B00
                      dl Map16TilesHigh+$1CB0
                      dl Map16TilesHigh+$1E60
                      dl Map16TilesHigh+$2010
                      dl Map16TilesHigh+$21C0
                      dl Map16TilesHigh+$2370
                      dl Map16TilesHigh+$2520
                      dl Map16TilesHigh+$26D0
                      dl Map16TilesHigh+$2880
                      dl Map16TilesHigh+$2A30
                      dl Map16TilesHigh+$2BE0
                      dl Map16TilesHigh+$2D90
                      dl Map16TilesHigh+$2F40
                      dl Map16TilesHigh+$30F0
                      dl Map16TilesHigh+$32A0
                      dl Map16TilesHigh+$3450

DATA_00BCFA:          dl Map16TilesHigh
                      dl Map16TilesHigh+$1B0
                      dl Map16TilesHigh+$360
                      dl Map16TilesHigh+$510
                      dl Map16TilesHigh+$6C0
                      dl Map16TilesHigh+$870
                      dl Map16TilesHigh+$A20
                      dl Map16TilesHigh+$BD0
                      dl Map16TilesHigh+$D80
                      dl Map16TilesHigh+$F30
                      dl Map16TilesHigh+$10E0
                      dl Map16TilesHigh+$1290
                      dl Map16TilesHigh+$1440
                      dl Map16TilesHigh+$15F0
                      dl Map16TilesHigh+$17A0
                      dl Map16TilesHigh+$1950

DATA_00BD2A:          dl Map16TilesHigh+$1C00
                      dl Map16TilesHigh+$1E00
                      dl Map16TilesHigh+$2000
                      dl Map16TilesHigh+$2200
                      dl Map16TilesHigh+$2400
                      dl Map16TilesHigh+$2600
                      dl Map16TilesHigh+$2800
                      dl Map16TilesHigh+$2A00
                      dl Map16TilesHigh+$2C00
                      dl Map16TilesHigh+$2E00
                      dl Map16TilesHigh+$3000
                      dl Map16TilesHigh+$3200
                      dl Map16TilesHigh+$3400
                      dl Map16TilesHigh+$3600

DATA_00BD54:          dl Map16TilesHigh
                      dl Map16TilesHigh+$200
                      dl Map16TilesHigh+$400
                      dl Map16TilesHigh+$600
                      dl Map16TilesHigh+$800
                      dl Map16TilesHigh+$A00
                      dl Map16TilesHigh+$C00
                      dl Map16TilesHigh+$E00
                      dl Map16TilesHigh+$1000
                      dl Map16TilesHigh+$1200
                      dl Map16TilesHigh+$1400
                      dl Map16TilesHigh+$1600
                      dl Map16TilesHigh+$1800
                      dl Map16TilesHigh+$1A00

DATA_00BD7E:          dl Map16TilesHigh+$1C00
                      dl Map16TilesHigh+$1E00
                      dl Map16TilesHigh+$2000
                      dl Map16TilesHigh+$2200
                      dl Map16TilesHigh+$2400
                      dl Map16TilesHigh+$2600
                      dl Map16TilesHigh+$2800
                      dl Map16TilesHigh+$2A00
                      dl Map16TilesHigh+$2C00
                      dl Map16TilesHigh+$2E00
                      dl Map16TilesHigh+$3000
                      dl Map16TilesHigh+$3200
                      dl Map16TilesHigh+$3400
                      dl Map16TilesHigh+$3600

Ptrs00BDA8:           dw DATA_00BAD8
                      dw DATA_00BAD8
                      dw DATA_00BAD8
                      dw DATA_00BB38
                      dw DATA_00BB38
                      dw DATA_00BB92
                      dw DATA_00BB92
                      dw DATA_00BBEC
                      dw DATA_00BBEC
                      dw $0000
                      dw DATA_00BBEC
                      dw $0000
                      dw DATA_00BAD8
                      dw DATA_00BBEC
                      dw DATA_00BAD8
                      dw DATA_00BAD8
                      dw $0000
                      dw DATA_00BAD8
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw DATA_00BAD8
                      dw DATA_00BAD8

Ptrs00BDE8:           dw DATA_00BB08
                      dw DATA_00BB08
                      dw DATA_00BB08
                      dw DATA_00BB62
                      dw DATA_00BB62
                      dw DATA_00BBC2
                      dw DATA_00BBC2
                      dw DATA_00BC16
                      dw DATA_00BC16
                      dw $0000
                      dw DATA_00BC16
                      dw $0000
                      dw DATA_00BB08
                      dw DATA_00BC16
                      dw DATA_00BB08
                      dw DATA_00BB08
                      dw $0000
                      dw DATA_00BB08
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw DATA_00BB08
                      dw DATA_00BB08

Ptrs00BE28:           dw DATA_00BC40
                      dw DATA_00BC40
                      dw DATA_00BC40
                      dw DATA_00BCA0
                      dw DATA_00BCA0
                      dw DATA_00BCFA
                      dw DATA_00BCFA
                      dw DATA_00BD54
                      dw DATA_00BD54
                      dw $0000
                      dw DATA_00BD54
                      dw $0000
                      dw DATA_00BC40
                      dw DATA_00BD54
                      dw DATA_00BC40
                      dw DATA_00BC40
                      dw $0000
                      dw DATA_00BC40
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw DATA_00BC40
                      dw DATA_00BC40

Ptrs00BE68:           dw DATA_00BC70
                      dw DATA_00BC70
                      dw DATA_00BC70
                      dw DATA_00BCCA
                      dw DATA_00BCCA
                      dw DATA_00BD2A
                      dw DATA_00BD2A
                      dw DATA_00BD7E
                      dw DATA_00BD7E
                      dw $0000
                      dw DATA_00BD7E
                      dw $0000
                      dw DATA_00BC70
                      dw DATA_00BD7E
                      dw DATA_00BC70
                      dw DATA_00BC70
                      dw $0000
                      dw DATA_00BC70
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw $0000
                      dw DATA_00BC70
                      dw DATA_00BC70

LoadBlkPtrs:          dw Ptrs00BDA8
                      dw Ptrs00BDE8
LoadBlkTable2:        dw Ptrs00BE28
                      dw Ptrs00BE68

GenerateTile:         PHP
                      REP #$30                                  ; AXY->16
                      PHX
                      LDA.B Map16TileGenerate
                      AND.W #$00FF
                      BNE +
ADDR_00BEBB:          JMP CODE_00BFB9

                    + LDA.B TouchBlockXPos
                      STA.B _C
                      LDA.B TouchBlockYPos
                      STA.B _E
                      LDA.W #$0000
                      SEP #$20                                  ; A->8
                      LDA.B ScreenMode
                      STA.B _9
                      LDA.W LayerProcessing
                      BEQ +
                      LSR.B _9
                    + LDY.B _E
                      LDA.B _9
                      AND.B #$01
                      BEQ +
                      LDA.B TouchBlockXPos+1
                      STA.B _0
                      LDA.B TouchBlockYPos+1
                      STA.B TouchBlockXPos+1
                      LDA.B _0
                      STA.B TouchBlockYPos+1
                      LDY.B _C
                    + CPY.W #$0200
                      BCS ADDR_00BEBB
                      LDA.W LayerProcessing
                      ASL A
                      TAX
                      LDA.L LoadBlkPtrs,X                       ; Set low byte of pointer
                      STA.B Layer1DataPtr
                      LDA.L LoadBlkPtrs+1,X                     ; Set middle byte of pointer
                      STA.B Layer1DataPtr+1
                      STZ.B Layer1DataPtr+2                     ; High byte of pointer = #$00
                      LDA.W LevelModeSetting
                      ASL A
                      TAY
                      LDA.B [Layer1DataPtr],Y
                      STA.B _4
                      INY
                      LDA.B [Layer1DataPtr],Y
                      STA.B _5
                      STZ.B _6
                      LDA.B TouchBlockXPos+1
                      STA.B _7
                      ASL A
                      CLC
                      ADC.B _7
                      TAY
                      LDA.B [_4],Y
                      STA.B Map16LowPtr
                      STA.B Map16HighPtr
                      INY
                      LDA.B [_4],Y
                      STA.B Map16LowPtr+1
                      STA.B Map16HighPtr+1
                      LDA.B #$7E
                      STA.B Map16LowPtr+2
                      INC A
                      STA.B Map16HighPtr+2
                      LDA.B _9
                      AND.B #$01
                      BEQ +
                      LDA.B TouchBlockYPos+1
                      LSR A
                      LDA.B TouchBlockXPos+1
                      AND.B #$01
                      JMP CODE_00BF46

                    + LDA.B TouchBlockXPos+1
                      LSR A
                      LDA.B TouchBlockYPos+1
CODE_00BF46:          ROL A
                      ASL A
                      ASL A
                      ORA.B #$20
                      STA.B _4
                      CPX.W #$0000
                      BEQ +
                      CLC
                      ADC.B #$10
                      STA.B _4
                    + LDA.B TouchBlockYPos
                      AND.B #$F0
                      CLC
                      ASL A
                      ROL A
                      STA.B _5
                      ROL A
                      AND.B #$03
                      ORA.B _4
                      STA.B _6
                      LDA.B TouchBlockXPos
                      AND.B #$F0
                      LSR A
                      LSR A
                      LSR A
                      STA.B _4
                      LDA.B _5
                      AND.B #$C0
                      ORA.B _4
                      STA.B _7
                      REP #$20                                  ; A->16
                      LDA.B _9
                      AND.W #$0001
                      BNE CODE_00BF9B
                      LDA.B Layer1XPos
                      SEC
                      SBC.W #$0080
                      TAX
                      LDY.B Layer1YPos
                      LDA.W LayerProcessing
                      BEQ CODE_00BFB2
                      LDX.B Layer2XPos
                      LDA.B Layer2YPos
                      SEC
                      SBC.W #$0080
                      TAY
                      JMP CODE_00BFB2

CODE_00BF9B:          LDX.B Layer1XPos
                      LDA.B Layer1YPos
                      SEC
                      SBC.W #$0080
                      TAY
                      LDA.W LayerProcessing
                      BEQ CODE_00BFB2
                      LDA.B Layer2XPos
                      SEC
                      SBC.W #$0080
                      TAX
                      LDY.B Layer2YPos
CODE_00BFB2:          STX.B _8
                      STY.B _A
                      JSR CODE_00BFBC
CODE_00BFB9:          PLX
                      PLP
                      RTL

CODE_00BFBC:          SEP #$30                                  ; AXY->8
                      LDA.B Map16TileGenerate
                      DEC A
                      PHK
                      PER $0003
                      JML ExecutePtr                            ; $9C - Tile generated


GeneratedTiles:       dw CODE_00C074                            ; 01 - empty space
                      dw CODE_00C077                            ; 02 - empty space
                      dw CODE_00C077                            ; 03 - vine
                      dw CODE_00C077                            ; 04 - tree background, for berries
                      dw CODE_00C077                            ; 05 - always turning block
                      dw CODE_00C077                            ; 06 - coin
                      dw CODE_00C077                            ; 07 - Mushroom scale base
                      dw CODE_00C077                            ; 08 - mole hole
                      dw CODE_00C0C4                            ; 09 - invisible solid
                      dw CODE_00C0C4                            ; 0a - multiple coin turnblock
                      dw CODE_00C0C4                            ; 0b - multiple coin q block
                      dw CODE_00C0C4                            ; 0c - turn block
                      dw CODE_00C0C4                            ; 0d - used block
                      dw CODE_00C0C4                            ; 0e - music block
                      dw CODE_00C0C4                            ; 0f - music
                      dw CODE_00C0C4                            ; 10 - all way music block
                      dw CODE_00C0C4                            ; 11 - sideways turn block
                      dw CODE_00C0C4                            ; 12 - tranlucent
                      dw CODE_00C0C4                            ; 13 - on off
                      dw CODE_00C0C4                            ; 14 - side of pipe, left
                      dw CODE_00C0C4                            ; 15 - side of pipe, right
                      dw CODE_00C0C1                            ; 16 - used
                      dw CODE_00C0C1                            ; 17 - O block from 1up game
                      dw CODE_00C1AC                            ; 18 - invisible block containing wings
                      dw CODE_00C334                            ; 19 - cage
                      dw CODE_00C334                            ; 1a - cage
                      dw CODE_00C3D1                            ; 1b -

DATA_00BFFF:          dw $0000,$0080,$0100

DATA_00C005:          db $80,$40,$20,$10,$08,$04,$02,$01

CODE_00C00D:          REP #$30                                  ; AXY->16
                      LDA.B TouchBlockXPos
                      AND.W #$FF00
                      LSR A
                      LSR A
                      LSR A
                      LSR A
                      LSR A
                      LSR A
                      STA.B _4
                      LDA.B TouchBlockXPos
                      AND.W #$0080
                      LSR A
                      LSR A
                      LSR A
                      LSR A
                      LSR A
                      LSR A
                      LSR A
                      ORA.B _4
                      STA.B _4
                      LDA.B TouchBlockYPos
                      AND.W #$0100
                      BEQ +
                      LDA.B _4
                      ORA.W #$0002
                      STA.B _4
                    + LDA.W ItemMemorySetting
                      AND.W #$000F
                      ASL A
                      TAX
                      LDA.L DATA_00BFFF,X
                      CLC
                      ADC.B _4
                      STA.B _4
                      TAY
                      LDA.B TouchBlockXPos
                      AND.W #$0070
                      LSR A
                      LSR A
                      LSR A
                      LSR A
                      TAX
                      SEP #$20                                  ; A->8
                      LDA.W ItemMemoryTable,Y
                      ORA.L DATA_00C005,X
                      STA.W ItemMemoryTable,Y
                      RTS


                      db $7F,$BF,$DF,$EF,$F7,$FB,$FD,$FE
TileToGeneratePg0:    db $25,$25,$25,$06,$49,$48,$2B,$A2
                      db $C6

CODE_00C074:          JSR CODE_00C00D
CODE_00C077:          REP #$30                                  ; AXY->16
                      LDA.B TouchBlockYPos
                      AND.W #$01F0
                      STA.B _4
                      LDA.B TouchBlockXPos
                      LSR A
                      LSR A
                      LSR A
                      LSR A
                      AND.W #$000F
                      ORA.B _4
                      TAY
                      LDA.B Map16TileGenerate                   ; \ X = index of tile to generate
                      AND.W #$00FF                              ; |
                      TAX                                       ; /
                      SEP #$20                                  ; A->8
                      LDA.B [Map16HighPtr],Y                    ; \ Reset #$01 bit
                      AND.B #$FE                                ; |
                      STA.B [Map16HighPtr],Y                    ; /
                      LDA.L TileToGeneratePg0,X                 ; \ Store tile
                      STA.B [Map16LowPtr],Y                     ; /
                      REP #$20                                  ; A->16
                      AND.W #$00FF
                      ASL A
                      TAY
                      JMP CODE_00C0FB


                      db $80,$40,$20,$10,$08,$04,$02,$01
TileToGeneratePg1:    db $52,$1B,$23,$1E,$32,$13,$15,$16
                      db $2B,$2C,$12,$68,$69,$32,$5E

CODE_00C0C1:          JSR CODE_00C00D
CODE_00C0C4:          REP #$30                                  ; AXY->16
                      LDA.B TouchBlockYPos
                      AND.W #$01F0
                      STA.B _4
                      LDA.B TouchBlockXPos
                      LSR A
                      LSR A
                      LSR A
                      LSR A
                      AND.W #$000F
                      ORA.B _4
                      TAY
                      LDA.B Map16TileGenerate                   ; \ X = index of tile to generate
                      SEC                                       ; |
                      SBC.W #$0009                              ; |
                      AND.W #$00FF                              ; |
                      TAX                                       ; /
                      SEP #$20                                  ; A->8
                      LDA.B [Map16HighPtr],Y                    ; \ Set #$01 bit
                      ORA.B #$01                                ; |
                      STA.B [Map16HighPtr],Y                    ; /
                      LDA.L TileToGeneratePg1,X                 ; \ Store tile
                      STA.B [Map16LowPtr],Y                     ; /
                      REP #$20                                  ; A->16
                      AND.W #$00FF
                      ORA.W #$0100
                      ASL A
                      TAY
CODE_00C0FB:          LDA.B ScreenMode
                      STA.B _0
                      LDA.W LayerProcessing
                      BEQ +
                      LSR.B _0
                    + LDA.B _0
                      AND.W #$0001
                      BNE CODE_00C127
                      LDA.B _8
                      AND.W #$FFF0
                      BMI CODE_00C11A
                      CMP.B _C
                      BEQ CODE_00C13E
                      BCS CODE_00C124
CODE_00C11A:          CLC
                      ADC.W #$0200
                      CMP.B _C
                      BEQ CODE_00C124
                      BCS CODE_00C13E
CODE_00C124:          JMP Return00C1AB

CODE_00C127:          LDA.B _A
                      AND.W #$FFF0
                      BMI CODE_00C134
                      CMP.B _E
                      BEQ CODE_00C13E
                      BCS Return00C1AB
CODE_00C134:          CLC
                      ADC.W #$0200
                      CMP.B _E
                      BEQ Return00C1AB
                      BCC Return00C1AB
CODE_00C13E:          LDA.L DynStripeImgSize
                      TAX
                      SEP #$20                                  ; A->8
                      LDA.B _6
                      STA.L DynamicStripeImage,X
                      STA.L DynamicStripeImage+8,X
                      LDA.B _7
                      STA.L DynamicStripeImage+1,X
                      CLC
                      ADC.B #$20
                      STA.L DynamicStripeImage+9,X
                      LDA.B #$00
                      STA.L DynamicStripeImage+2,X
                      STA.L DynamicStripeImage+$0A,X
                      LDA.B #$03
                      STA.L DynamicStripeImage+3,X
                      STA.L DynamicStripeImage+$0B,X
                      LDA.B #$FF
                      STA.L DynamicStripeImage+$10,X
                      LDA.B #$0D
                      STA.B _6
                      REP #$20                                  ; A->16
                      LDA.W Map16Pointers,Y
                      STA.B _4
                      LDY.W #$0000
                      LDA.B [_4],Y
                      STA.L DynamicStripeImage+4,X
                      INY
                      INY
                      LDA.B [_4],Y
                      STA.L DynamicStripeImage+$0C,X
                      INY
                      INY
                      LDA.B [_4],Y
                      STA.L DynamicStripeImage+6,X
                      INY
                      INY
                      LDA.B [_4],Y
                      STA.L DynamicStripeImage+$0E,X
                      TXA
                      CLC
                      ADC.W #$0010
                      STA.L DynStripeImgSize
Return00C1AB:         RTS

CODE_00C1AC:          JSR CODE_00C00D
                      REP #$30                                  ; AXY->16
                      LDA.B TouchBlockYPos
                      AND.W #$01F0
                      STA.B _4
                      LDA.B TouchBlockXPos
                      LSR A
                      LSR A
                      LSR A
                      LSR A
                      AND.W #$000F
                      ORA.B _4
                      TAY
                      SEP #$20                                  ; A->8
                      LDA.B #$25
                      STA.B [Map16LowPtr],Y
                      REP #$20                                  ; A->16
                      TYA
                      CLC
                      ADC.W #$0010
                      TAY
                      SEP #$20                                  ; A->8
                      LDA.B #$25
                      STA.B [Map16LowPtr],Y
                      REP #$20                                  ; A->16
                      AND.W #$00FF
                      ASL A
                      TAY
                      LDA.B ScreenMode
                      STA.B _0
                      LDA.W LayerProcessing
                      BEQ +
                      LSR.B _0
                    + LDA.B _0
                      AND.W #$0001
                      BNE CODE_00C20B
                      LDA.B _8
                      AND.W #$FFF0
                      BMI CODE_00C1FE
                      CMP.B _C
                      BEQ CODE_00C222
                      BCS Return00C1AB
CODE_00C1FE:          CLC
                      ADC.W #$0200
                      CMP.B _C
                      BCC Return00C1AB
                      BEQ Return00C1AB
                      JMP CODE_00C222

CODE_00C20B:          LDA.B _A
                      AND.W #$FFF0
                      BMI CODE_00C218
                      CMP.B _E
                      BEQ CODE_00C222
                      BCS Return00C1AB
CODE_00C218:          CLC
                      ADC.W #$0200
                      CMP.B _E
                      BEQ Return00C1AB
                      BCC Return00C1AB
CODE_00C222:          LDA.L DynStripeImgSize
                      TAX
                      SEP #$20                                  ; A->8
                      LDA.B _6
                      STA.L DynamicStripeImage,X
                      STA.L DynamicStripeImage+$0C,X
                      LDA.B _7
                      STA.L DynamicStripeImage+1,X
                      INC A
                      STA.L DynamicStripeImage+$0D,X
                      LDA.B #$80
                      STA.L DynamicStripeImage+2,X
                      STA.L DynamicStripeImage+$0E,X
                      LDA.B #$07
                      STA.L DynamicStripeImage+3,X
                      STA.L DynamicStripeImage+$0F,X
                      LDA.B #$FF
                      STA.L DynamicStripeImage+$18,X
                      LDA.B #$0D
                      STA.B _6
                      REP #$20                                  ; A->16
                      LDA.W Map16Pointers,Y
                      STA.B _4
                      LDY.W #$0000
                      LDA.B [_4],Y
                      STA.L DynamicStripeImage+4,X
                      STA.L DynamicStripeImage+8,X
                      INY
                      INY
                      LDA.B [_4],Y
                      STA.L DynamicStripeImage+$10,X
                      STA.L DynamicStripeImage+$14,X
                      INY
                      INY
                      LDA.B [_4],Y
                      STA.L DynamicStripeImage+6,X
                      STA.L DynamicStripeImage+$0A,X
                      INY
                      INY
                      LDA.B [_4],Y
                      STA.L DynamicStripeImage+$12,X
                      STA.L DynamicStripeImage+$16,X
                      TXA
                      CLC
                      ADC.W #$0018
                      STA.L DynStripeImgSize
                      RTS


DATA_00C29E:          db $99,$9C,$8B,$1C,$8B,$1C,$8B,$1C
                      db $8B,$1C,$99,$DC,$9B,$1C,$F8,$1C
                      db $F8,$1C,$F8,$1C,$F8,$1C,$9B,$5C
                      db $9B,$1C,$F8,$1C,$F8,$1C,$F8,$1C
                      db $F8,$1C,$9B,$5C,$9B,$1C,$F8,$1C
                      db $F8,$1C,$F8,$1C,$F8,$1C,$9B,$5C
                      db $9B,$1C,$F8,$1C,$F8,$1C,$F8,$1C
                      db $F8,$1C,$9B,$5C,$99,$1C,$8B,$9C
                      db $8B,$9C,$8B,$9C,$8B,$9C,$99,$5C
DATA_00C2E6:          db $BA,$9C,$AB,$1C,$AB,$1C,$AB,$1C
                      db $AB,$1C,$BA,$DC,$AA,$1C,$82,$1C
                      db $82,$1C,$82,$1C,$82,$1C,$AA,$5C
                      db $AA,$1C,$82,$1C,$82,$1C,$82,$1C
                      db $82,$1C,$AA,$5C,$AA,$1C,$82,$1C
                      db $82,$1C,$82,$1C,$82,$1C,$AA,$5C
                      db $AA,$1C,$82,$1C,$82,$1C,$82,$1C
                      db $82,$1C,$AA,$5C,$BA,$1C,$AB,$9C
                      db $AB,$9C,$AB,$9C,$AB,$9C,$BA,$5C

DATA_00C32E:          dl DATA_00C29E
                      dl DATA_00C2E6

CODE_00C334:          INC.B _7
                      LDA.B _7
                      CLC
                      ADC.B #$20
                      STA.B _7
                      LDA.B _6
                      ADC.B #$00
                      STA.B _6
                      LDA.B Map16TileGenerate
                      SEC
                      SBC.B #$19
                      STA.B _0
                      ASL A
                      CLC
                      ADC.B _0
                      TAX
                      LDA.L DATA_00C32E+2,X
                      STA.B _4
                      REP #$30                                  ; AXY->16
                      LDA.L DATA_00C32E,X
                      STA.B _2
                      LDA.L DynStripeImgSize
                      TAX
                      LDY.W #$0005
                    - SEP #$20                                  ; A->8
                      LDA.B _6
                      STA.L DynamicStripeImage,X
                      LDA.B _7
                      STA.L DynamicStripeImage+1,X
                      LDA.B #$00
                      STA.L DynamicStripeImage+2,X
                      LDA.B #$0B
                      STA.L DynamicStripeImage+3,X
                      LDA.B _7
                      CLC
                      ADC.B #$20
                      STA.B _7
                      LDA.B _6
                      ADC.B #$00
                      STA.B _6
                      REP #$20                                  ; A->16
                      TXA
                      CLC
                      ADC.W #$0010
                      TAX
                      DEY
                      BPL -
                      LDA.L DynStripeImgSize
                      TAX
                      LDY.W #$0000
CODE_00C39F:          LDA.W #$0005
                      STA.B _0
                    - LDA.B [_2],Y
                      STA.L DynamicStripeImage+4,X
                      INY
                      INY
                      INX
                      INX
                      DEC.B _0
                      BPL -
                      TXA
                      CLC
                      ADC.W #$0004
                      TAX
                      CPY.W #$0048
                      BNE CODE_00C39F
                      LDA.W #$00FF
                      STA.L DynamicStripeImage,X
                      LDA.L DynStripeImgSize
                      CLC
                      ADC.W #$0060
                      STA.L DynStripeImgSize
                      RTS

CODE_00C3D1:          REP #$30                                  ; AXY->16
                      LDA.B TouchBlockYPos
                      AND.W #$01F0
                      STA.B _4
                      LDA.B TouchBlockXPos
                      LSR A
                      LSR A
                      LSR A
                      LSR A
                      AND.W #$000F
                      ORA.B _4
                      TAY
                      LDA.L DynStripeImgSize
                      TAX
                      SEP #$20                                  ; A->8
                      LDA.B #$25
                      STA.B [Map16LowPtr],Y
                      INY
                      LDA.B #$25
                      STA.B [Map16LowPtr],Y
                      REP #$20                                  ; A->16
                      TYA
                      CLC
                      ADC.W #$0010
                      TAY
                      SEP #$20                                  ; A->8
                      LDA.B #$25
                      STA.B [Map16LowPtr],Y
                      DEY
                      LDA.B #$25
                      STA.B [Map16LowPtr],Y
                      LDY.W #$0003
                    - LDA.B _6
                      STA.L DynamicStripeImage,X
                      LDA.B _7
                      STA.L DynamicStripeImage+1,X
                      LDA.B #$40
                      STA.L DynamicStripeImage+2,X
                      LDA.B #$06
                      STA.L DynamicStripeImage+3,X
                      REP #$20                                  ; A->16
                      LDA.W #$18F8
                      STA.L DynamicStripeImage+4,X
                      TXA
                      CLC
                      ADC.W #$0006
                      TAX
                      SEP #$20                                  ; A->8
                      LDA.B _7
                      CLC
                      ADC.B #$20
                      STA.B _7
                      LDA.B _6
                      ADC.B #$00
                      STA.B _6
                      DEY
                      BPL -
                      LDA.B #$FF
                      STA.L DynamicStripeImage,X
                      REP #$20                                  ; A->16
                      TXA
                      STA.L DynStripeImgSize
                      RTS

                      %insert_empty($0D,$0D,$0D,$0D,$0C)

                      db $80,$40,$20,$10,$08,$04,$02,$01
                      db $80,$40,$20,$10,$08,$04,$02,$01

DATA_00C470:          db $90,$00,$90,$00

DATA_00C474:          db $04,$FC,$04,$FC

DATA_00C478:          db $30,$33,$33,$30,$01,$00

CODE_00C47E:          STZ.B PlayerHiddenTiles
                      LDA.W UnusedStarCounter
                      BPL +
                      JSL CODE_01C580
                      STZ.W UnusedStarCounter
                    + LDY.W KeyholeTimer
                      BEQ CODE_00C4BA
                      STY.W PlayerIsFrozen
                      STY.B SpriteLock
                      LDX.W KeyholeDirection
                      LDA.W SpotlightSize
                      CMP.W DATA_00C470,X
                      BNE CODE_00C4BC
                      DEY
                      BNE CODE_00C4B7
                      INC.W KeyholeDirection
                      TXA
                      LSR A
                      BCC +
                      JSR CODE_00FCEC
                      LDA.B #$02
                      LDY.B #$0B
                      JSR CODE_00C9FE
                      LDY.B #$00
CODE_00C4B7:          STY.W KeyholeTimer
CODE_00C4BA:          BRA +

CODE_00C4BC:          CLC
                      ADC.W DATA_00C474,X
                      STA.W SpotlightSize
                      LDA.B #$22
                      STA.B Layer12Window
                      LDA.B #$02
                      STA.B Layer34Window
                      LDA.W DATA_00C478,X
                      STA.B OBJCWWindow
                      LDA.B #$12
                      STA.B ColorAddition
                      REP #$20                                  ; A->16
                      LDA.W #DATA_00CB93
                      STA.B _4
                      STZ.B _6
                      SEP #$20                                  ; A->8
                      LDA.W KeyholeXPos
                      SEC
                      SBC.B Layer1XPos
                      CLC
                      ADC.B #$04
                      STA.B _0
                      LDA.W KeyholeYPos
                      SEC
                      SBC.B Layer1YPos
                      CLC
                      ADC.B #$10
                      STA.B _1
                      JSR CODE_00CA88
                    + LDA.W PlayerIsFrozen
                      BEQ +
                      JMP CODE_00C58F

                    + LDA.B SpriteLock                          ; \ Branch if sprites locked
                      BNE CODE_00C569                           ; /
                      INC.B EffFrame
                      LDX.B #$13
CODE_00C508:          LDA.W ColorFadeTimer,X
                      BEQ +
                      DEC.W ColorFadeTimer,X
                    + DEX
                      BNE CODE_00C508
                      LDA.B EffFrame
                      AND.B #$03
                      BNE CODE_00C569
                      LDA.W BonusGameActivate
                      BEQ CODE_00C533
                      LDA.W BonusFinishTimer
                      CMP.B #$44
                      BNE +
                      LDY.B #!BGM_BONUSOVER
                      STY.W SPCIO2                              ; / Change music
                    + CMP.B #con($01,$01,$01,$08,$08)
                      BNE CODE_00C533
                      LDY.B #$0B
                      STY.W GameMode
CODE_00C533:          LDY.W BluePSwitchTimer
                      CPY.W SilverPSwitchTimer
                      BCS +
                      LDY.W SilverPSwitchTimer
                    + LDA.W MusicBackup
                      BMI +
                      CPY.B #$01
                      BNE +
                      LDY.W DirectCoinTimer
                      BNE +
                      STA.W SPCIO2                              ; / Change music
                    + CMP.B #$FF
                      BEQ +
                      CPY.B #con($1E,$1E,$1E,$18,$18)
                      BNE +
                      LDA.B #!SFX_RUNNINGOUT                    ; \ Play sound effect
                      STA.W SPCIO3                              ; /
                    + LDX.B #$06
CODE_00C55E:          LDA.W EmptyTimer14A8,X
                      BEQ +
                      DEC.W EmptyTimer14A8,X
                    + DEX
                      BNE CODE_00C55E
CODE_00C569:          JSR CODE_00C593
                      LDA.B byetudlrFrame
                      AND.B #$20
                      BEQ CODE_00C58F
                   if ver_is_ntsc(!_VER)                        ;\================== J, U, & SS =================
                      LDA.B byetudlrHold                        ;!
                      AND.B #$08                                ;!
                      BRA CODE_00C585                           ;! Change to BEQ to reach debug routine below
                                                                ;!
                      LDA.B Powerup                             ;! \ Unreachable
                      INC A                                     ;! | Debug: Cycle through powerups
                      CMP.B #$04                                ;! |
                      BCC +                                     ;! |
                      LDA.B #$00                                ;! |
                    + STA.B Powerup                             ;! |
                      BRA CODE_00C58F                           ;! /
                   endif                                        ;/===============================================

CODE_00C585:          PHB
                      LDA.B #$02
                      PHA
                      PLB
                      JSL CODE_028008
                      PLB
CODE_00C58F:          STZ.W NoteBlockActive
Return00C592:         RTS

CODE_00C593:          LDA.B PlayerAnimation
                      JSL ExecutePtr

                      dw ResetAni                               ; 0 - Reset
                      dw PowerDownAni                           ; 1 - Power down
                      dw MushroomAni                            ; 2 - Mushroom power up
                      dw CapeAni                                ; 3 - Cape power up
                      dw FlowerAni                              ; 4 - Flower power up
                      dw DoorPipeAni                            ; 5 - Door/Horizontal pipe exit
                      dw VertPipeAni                            ; 6 - Vertical pipe exit
                      dw PipeCannonAni                          ; 7 - Shot out of diagonal pipe
                      dw YoshiWingsAni                          ; 8 - Yoshi wings exit
                      dw MarioDeathAni                          ; 9 - Mario Death
                      dw EnterCastleAni                         ; A - Enter Castle
                      dw UnknownAniB                            ; B - freeze forever
                      dw UnknownAniC                            ; C - random movement??
                      dw Return00C592                           ; D - freeze forever

UnknownAniB:          STZ.W PlayerOverworldPose
                      STZ.W PlayerSlopePose
                      LDA.W EndLevelTimer
                      BEQ CODE_00C5CE
                      JSL CODE_0CAB13
                      LDA.W GameMode
                      CMP.B #$14
                      BEQ +
                      JMP CODE_00C95B

CODE_00C5CE:          STZ.W HDMAEnable
                    + LDA.B #$01
                      STA.W MessageBoxExpand
                      LDA.B #$07
                      STA.W LevelLoadObject
                      JSR NoButtons
                      JMP CODE_00CD24


DATA_00C5E1:          db $10,$30,$31,$32,$33,$34,$0E

                   if ver_is_ntsc(!_VER)                        ;\================== J, U, & SS =================
DATA_00C5E8:          db $26,$11,$02,$48,$00,$60,$01,$09        ;!
                      db $80,$08,$00,$20,$04,$60,$00,$01        ;!
                      db $FF,$01                                ;!
                                                                ;!
DATA_00C5F9:          db $02,$48,$00,$60,$41,$2C,$C1,$04        ;!
                      db $27,$04,$2F,$08,$25,$01,$2F,$04        ;!
                      db $27,$04,$00,$08,$41,$1B,$C1,$04        ;!
                      db $27,$04,$2F,$08,$25,$01,$2F,$04        ;!
                      db $27,$04,$00,$04,$01,$08,$20,$01        ;!
                      db $01,$10,$00,$08,$41,$12,$81,$0A        ;!
                      db $00,$40,$82,$10,$02,$20,$00,$30        ;!
                      db $01,$01,$00,$50,$22,$01,$FF,$01        ;!
                                                                ;!
DATA_00C639:          db $02,$48,$00,$60,$01,$09,$80,$08        ;!
                      db $00,$20,$04,$60,$00,$20,$10,$20        ;!
                      db $01,$58,$00,$2C,$31,$01,$3A,$10        ;!
                      db $31,$01,$3A,$10,$31,$01,$3A,$20        ;!
                      db $28,$A0,$28,$40,$29,$04,$28,$04        ;!
                      db $29,$04,$28,$04,$29,$04,$28,$40        ;!
                      db $22,$01,$FF,$01                        ;!
                                                                ;!
DATA_00C66D:          db $02,$48,$00,$60,$01,$09,$80,$08        ;!
                      db $00,$20,$04,$60,$10,$20,$31,$01        ;!
                      db $18,$60,$31,$01,$3B,$80,$31,$01        ;!
                      db $3C,$40,$FF,$01                        ;!
                                                                ;!
DATA_00C689:          db $02,$48,$00,$60,$02,$30,$01,$84        ;!
                      db $00,$20,$23,$01,$01,$16,$02,$20        ;!
                      db $20,$01,$01,$20,$02,$20,$01,$02        ;!
                      db $00,$80,$FF,$01                        ;!
                                                                ;!
DATA_00C6A5:          db $02,$48,$00,$60,$02,$28,$01,$83        ;!
                      db $00,$28,$24,$01,$02,$01,$00,$FF        ;!
                      db $00,$40,$20,$01,$00,$40,$02,$60        ;!
                      db $00,$30,$FF,$01                        ;!
                                                                ;!
DATA_00C6C1:          db $02,$48,$00,$60,$01,$4E,$00,$40        ;!
                      db $26,$01,$00,$1E,$20,$01,$00,$20        ;!
                      db $08,$10,$20,$01,$2D,$18,$00,$A0        ;!
                      db $20,$01,$2E,$01,$FF,$01                ;!
                   else                                         ;<===================== E0 & E1 =================
DATA_00C5E8:          db $26,$11,$02,$3E,$00,$60,$01,$09        ;!
                      db $80,$08,$00,$20,$04,$60,$00,$01        ;!
                      db $FF,$01                                ;!
                                                                ;!
DATA_00C5F9:          db $02,$3E,$00,$60,$41,$25,$C1,$04        ;!
                      db $27,$04,$2F,$08,$25,$01,$2F,$04        ;!
                      db $27,$04,$00,$08,$41,$16,$C1,$04        ;!
                      db $27,$04,$2F,$08,$25,$01,$2F,$04        ;!
                      db $27,$04,$00,$04,$01,$04,$20,$01        ;!
                      db $01,$04,$00,$08,$41,$14,$81,$1A        ;!
                      db $00,$40,$82,$10,$02,$20,$00,$30        ;!
                      db $01,$01,$00,$50,$22,$01,$FF,$01        ;!
                                                                ;!
DATA_00C639:          db $02,$3E,$00,$60,$01,$09,$80,$08        ;!
                      db $00,$20,$04,$60,$00,$20,$10,$20        ;!
                      db $01,$44,$00,$2C,$31,$01,$3A,$10        ;!
                      db $31,$01,$3A,$10,$31,$01,$3A,$20        ;!
                      db $28,$A0,$28,$40,$29,$04,$28,$04        ;!
                      db $29,$04,$28,$04,$29,$04,$28,$40        ;!
                      db $22,$01,$FF,$01                        ;!
                                                                ;!
DATA_00C66D:          db $02,$3E,$00,$60,$01,$09,$80,$08        ;!
                      db $00,$20,$04,$60,$10,$20,$31,$01        ;!
                      db $18,$60,$31,$01,$3B,$80,$31,$01        ;!
                      db $3C,$40,$FF,$01                        ;!
                                                                ;!
DATA_00C689:          db $02,$3E,$00,$60,$02,$30,$01,$6E        ;!
                      db $00,$20,$23,$01,$01,$16,$02,$20        ;!
                      db $20,$01,$01,$20,$02,$20,$01,$02        ;!
                      db $00,$80,$FF,$01                        ;!
                                                                ;!
DATA_00C6A5:          db $02,$3E,$00,$60,$02,$27,$01,$69        ;!
                      db $00,$28,$24,$01,$02,$01,$00,$FF        ;!
                      db $00,$40,$20,$01,$00,$30,$02,$40        ;!
                      db $00,$30,$FF,$01                        ;!
                                                                ;!
DATA_00C6C1:          db $02,$3E,$00,$4C,$01,$43,$00,$40        ;!
                      db $26,$01,$00,$1E,$20,$01,$00,$20        ;!
                      db $08,$10,$20,$01,$2D,$18,$00,$A0        ;!
                      db $20,$01,$2E,$01,$FF,$01                ;!
                   endif                                        ;/===============================================

DATA_00C6E0:          db DATA_00C5E8-DATA_00C5E8
                      db DATA_00C5F9-DATA_00C5E8-2
                      db DATA_00C689-DATA_00C5E8-2
                      db DATA_00C66D-DATA_00C5E8-2
                      db DATA_00C639-DATA_00C5E8-2
                      db DATA_00C6A5-DATA_00C5E8-2
                      db DATA_00C6C1-DATA_00C5E8-2

UnknownAniC:          JSR NoButtons
                      STZ.W PlayerOverworldPose
                      JSR CODE_00DC2D
                      LDA.B PlayerYSpeed                        ; \ Branch if Mario has upward speed
                      BMI CODE_00C73F                           ; /
                      LDA.B PlayerYPosNext
                      CMP.B #$58
                      BCS CODE_00C739
                      LDY.B PlayerXPosNext
                      CPY.B #$40
                      BCC CODE_00C73F
                      CPY.B #$60
                      BCC CODE_00C71C
                      LDY.B Layer1YPos
                      BEQ CODE_00C73F
                      CLC
                      ADC.B Layer1YPos
                      CMP.B #$1C
                      BMI CODE_00C73F
                      SEC
                      SBC.B Layer1YPos
                      LDX.B #$D0
                      LDY.B PlayerDirection
                      BEQ CODE_00C730
                      LDY.B #$00
                      BRA CODE_00C72E

CODE_00C71C:          CMP.B #$4C
                      BCC CODE_00C73F
                      LDA.B #!SFX_CUTSCENEFUSE                  ; \ Play sound effect
                      STA.W SPCIO3                              ; /
                      INC.W Layer1ScrollCmd
                      LDA.B #$4C
                      LDY.B #$F4
                      LDX.B #$C0
CODE_00C72E:          STY.B PlayerXSpeed
CODE_00C730:          STX.B PlayerYSpeed
                      LDX.B #!SFX_BONK                          ; \ Play sound effect
                      STX.W SPCIO0                              ; /
                      BRA +

CODE_00C739:          STZ.B PlayerInAir
                      LDA.B #$58
                    + STA.B PlayerYPosNext
CODE_00C73F:          LDX.W CutsceneID
                      LDA.B GraphicsUncompPtr+2
                      CLC
                      ADC.W DATA_00C6E0-1,X
                      TAX
                      LDA.B PipeTimer
                      BNE +
                      INC.B GraphicsUncompPtr+2
                      INC.B GraphicsUncompPtr+2
                      INX
                      INX
                      LDA.W DATA_00C5E8+1,X
                      STA.B PipeTimer
                      LDA.W DATA_00C5E8,X
                      CMP.B #$2D
                      BNE +
                      LDA.B #!SFX_PBALLOON                      ; \ Play sound effect
                      STA.W SPCIO0                              ; /
                    + LDA.W DATA_00C5E8,X
                      CMP.B #$FF
                      BNE +
                      JMP Return00C7F8

                    + PHA
                      AND.B #$10
                      BEQ +
                      JSL CODE_0CD4A4
                    + PLA
                      TAY
                      AND.B #$20
                      BNE CODE_00C789
                      STY.B byetudlrHold
                      TYA
                      AND.B #$BF
                      STA.B byetudlrFrame
                      JSR CODE_00CD39
                      BRA CODE_00C7F6

CODE_00C789:          TYA
                      AND.B #$0F
                      CMP.B #$07
                      BCS CODE_00C7E9
                      DEC A
                      BPL CODE_00C7A2
                      LDA.W PickUpItemTimer
                      BEQ CODE_00C79D
                      LDA.B #!SFX_CAPE                          ; \ Play sound effect
                      STA.W SPCIO0                              ; /
CODE_00C79D:          INC.W Layer1ScrollCmd
                      BRA CODE_00C7F6

CODE_00C7A2:          BNE CODE_00C7A9
                      INC.W Layer2ScrollTimer
                      BRA CODE_00C7F6

CODE_00C7A9:          DEC A
                      BNE CODE_00C7B6
                      LDA.B #!SFX_SWIM                          ; \ Play sound effect
                      STA.W SPCIO0                              ; /
                      INC.W Layer1ScrollXSpeed
                      BRA CODE_00C7F6

CODE_00C7B6:          DEC A
                      BNE CODE_00C7C0
                      LDY.B #$88
                      STY.W Layer2ScrollTimer
                      BRA CODE_00C7F6

CODE_00C7C0:          DEC A
                      BNE CODE_00C7CE
                      LDA.B #$38
                      STA.W Layer1ScrollXSpeed
                      LDA.B #$07
                      TRB.B PlayerXPosNext
                      BRA CODE_00C7F6

CODE_00C7CE:          DEC A
                      BNE CODE_00C7DF
                      LDA.B #!SFX_KAPOW                         ; \ Play sound effect
                      STA.W SPCIO3                              ; /
                      LDA.B #con($D8,$D8,$D8,$D2,$D2)
                      STA.B PlayerXSpeed
                      INC.W Layer1ScrollCmd
                      BRA CODE_00C79D

CODE_00C7DF:          LDA.B #$20
                      STA.W PickUpItemTimer
                      INC.W IsCarryingItem
                      BRA CODE_00C7F6

CODE_00C7E9:          TAY
                      LDA.W DATA_00C5E1-7,Y
                      STA.W PlayerPose
                      STZ.W IsCarryingItem
                      JSR CODE_00D7E4
CODE_00C7F6:          DEC.B PipeTimer
Return00C7F8:         RTS


DATA_00C7F9:          db $C0,$FF,$A0,$00

YoshiWingsAni:        JSR NoButtons
                      LDA.B #$0B
                      STA.B PlayerInAir
                      JSR CODE_00D7E4
                      LDA.B PlayerYSpeed                        ; \ Branch if Mario has downward speed
                      BPL CODE_00C80F                           ; /
                      CMP.B #$90                                ; \ Branch if Y speed < #$90
                      BCC +                                     ; /
CODE_00C80F:          SEC                                       ; \ Y Speed -= #$0D
                      SBC.B #con($0D,$0D,$0D,$0F,$0F)           ; |
                      STA.B PlayerYSpeed                        ; /
                    + LDA.B #$02
                      LDY.B PlayerXSpeed
                      BEQ CODE_00C827
                      BMI +
                      LDA.B #$FE
                    + CLC
                      ADC.B PlayerXSpeed
                      STA.B PlayerXSpeed
                      BVC CODE_00C827
                      STZ.B PlayerXSpeed
CODE_00C827:          JSR CODE_00DC2D
                      REP #$20                                  ; A->16
                      LDY.W YoshiHeavenFlag
                      LDA.B PlayerYPosScrRel
                      CMP.W DATA_00C7F9,Y
                      SEP #$20                                  ; A->8
                      BPL +
                      STZ.B PlayerAnimation
                      TYA
                      BNE +
                      INY
                      INY
                      STY.W YoshiHeavenFlag
                      JSR CODE_00D273
                    + JMP CODE_00CD8F

                   if ver_is_ntsc(!_VER)                        ;\================== J, U, & SS =================
DATA_00C848:          db $01,$5F,$00,$30,$08,$30,$00,$20        ;!
                      db $40,$01,$00,$30,$01,$80,$FF,$01        ;!
                      db $3F,$00,$30,$20,$01,$80,$06,$00        ;!
                      db $3A,$01,$38,$00,$30,$08,$30,$00        ;!
                      db $20,$40,$01,$00,$30,$01,$80,$FF        ;!
                   else                                         ;<=================== E0 & E1 ===================
DATA_00C848:          db $01,$4C,$00,$30,$08,$30,$00,$20        ;!
                      db $40,$01,$00,$30,$01,$80,$FF,$01        ;!
                      db $2C,$00,$30,$20,$01,$80,$06,$00        ;!
                      db $3A,$01,$30,$00,$30,$08,$30,$00        ;!
                      db $20,$40,$01,$00,$30,$01,$80,$FF        ;!
                   endif                                        ;/===============================================

EnterCastleAni:       STZ.W SpinjumpFireball
                      LDX.W ObjectTileset
                      BIT.W DATA_00A625,X
                      BMI CODE_00C889
                      BVS ADDR_00C883
                      JSL CODE_02F57C
                      BRA +

ADDR_00C883:          JSL ADDR_02F58C
                      BRA +

CODE_00C889:          JSL CODE_02F584
                    + LDX.B PipeTimer
                      LDA.B byetudlrFrame
                      ORA.B axlr0000Frame
                      JSR NoButtons
                      BMI CODE_00C8FB
                      STZ.W PlayerOverworldPose
                      DEC.B PlayerPipeAction
                      BNE +
                      INX
                      INX
                      STX.B PipeTimer
                      LDA.W DATA_00C848-1,X
                      STA.B PlayerPipeAction
                    + LDA.W DATA_00C848-2,X
                      CMP.B #$FF
                      BEQ CODE_00C8FB
                      AND.B #$DF
                      STA.B byetudlrHold
                      CMP.W DATA_00C848-2,X
                      BEQ +
                      LDY.B #$80
                      STY.B axlr0000Frame
                    + ASL A
                      BPL CODE_00C8D1
                      JSR NoButtons
                      LDY.B #$B0
                      LDX.W ObjectTileset
                      BIT.W DATA_00A625,X
                      BMI +
                      LDY.B #$7F
                    + STY.W NoYoshiIntroTimer
CODE_00C8D1:          JSR CODE_00DC2D
                      LDA.B #$24
                      STA.B PlayerInAir
                      LDA.B #$6F
                      LDY.W PlayerRidingYoshi
                      BEQ +
                      LDA.B #$5F
                    + LDX.W ObjectTileset
                      BIT.W DATA_00A625,X
                      BVC +
                      SEC
                      SBC.B #$10
                    + CMP.B PlayerYPosNext
                      BCS +
                      INC A
                      STA.B PlayerYPosNext
                      STZ.B PlayerInAir
                      STZ.W SpinJumpFlag
                    + JMP CODE_00CD82

CODE_00C8FB:          INC.W ShowMarioStart
                      LDA.B #$0F
                      STA.W GameMode
                      CPX.B #$11
                      BCC CODE_00C90A
                      INC.W CarryYoshiThruLvls
CODE_00C90A:          LDA.B #$01
                      STA.W RemoveYoshiFlag
                      LDA.B #!SFX_YOSHIDRUMOFF                  ; \ Play sound effect
                      STA.W SPCIO1                              ; /
                      RTS

CODE_00C915:          JSR NoButtons
                      STZ.W PlayerInCloud
                      STZ.W PlayerOverworldPose
                      STZ.W PlayerSlopePose
                      LDA.B ScreenMode
                      LSR A
                      BCS CODE_00C944
                      LDA.W CutsceneID
                      ORA.W SwitchPalaceColor
                      BEQ CODE_00C96B
                      LDA.B PlayerInAir
                      BEQ +
                      JSR CODE_00CCE0
                    + LDA.W SwitchPalaceColor
                      BNE CODE_00C948
                      JSR CODE_00B03E
                      LDA.W ColorFadeTimer
                      CMP.B #$40
                      BCC Return00C96A
CODE_00C944:          JSL CODE_05CBFF
CODE_00C948:          LDY.B #$01
                      STY.B SpriteLock
                      LDA.B TrueFrame
                      LSR A
                      BCC Return00C96A
                      DEC.W EndLevelTimer
                   if ver_is_ntsc(!_VER)                        ;\=================== J, U, & SS ================
                      BNE Return00C96A                          ;!
                   else                                         ;<==================== E0 & E1 ==================
                      LDA.W EndLevelTimer                       ;!
                      CMP.B #$50                                ;!
                      BCS Return00C96A                          ;!
                   endif                                        ;/===============================================
                      LDA.W SwitchPalaceColor
                      BNE +
CODE_00C95B:          LDY.B #$0B
                      LDA.B #$01
                      JMP CODE_00C9FE

                    + LDA.B #con($70,$A0,$A0,$6A,$6A)
                      STA.W VariousPromptTimer
                      INC.W MessageBoxTrigger
Return00C96A:         RTS

CODE_00C96B:          JSR CODE_00AF17
                      LDA.W ShowPeaceSign
                      BNE CODE_00C9AF
                      LDA.W EndLevelTimer
                      CMP.B #con($28,$28,$28,$50,$50)
                      BCC +
                      LDA.B #$01
                      STA.B PlayerDirection
                      STA.B byetudlrHold
                      LDA.B #$05
                      STA.B PlayerXSpeed
                    + LDA.B PlayerInAir
                      BEQ +
                      JSR CODE_00D76B
                    + LDA.B PlayerXSpeed
                      BNE +
                      STZ.W HorizLayer1Setting
                      JSR CODE_00CA3E
                      INC.W ShowPeaceSign
                      LDA.B #con($40,$40,$40,$6E,$6E)
                      STA.W PlayerPeaceSign
                   if ver_is_ntsc(!_VER)                        ;\=================== J, U, & SS ================
                      ASL A                                     ;!
                   else                                         ;<==================== E0 & E1 ==================
                      LDA.B #$80                                ;!
                   endif                                        ;/===============================================
                      STA.W ColorFadeDir
                      STZ.W ColorFadeTimer
                    + JMP CODE_00CD24

DATA_00C9A7:          db $25,$07,$40,$0E,$20,$1A,$34,$32

CODE_00C9AF:          JSR SetMarioPeaceImg
                      LDA.W PlayerPeaceSign
                      BEQ CODE_00C9C2
                      DEC.W PlayerPeaceSign
                      BNE +
                      LDA.B #!BGM_SPOTLIGHT
                      STA.W SPCIO2                              ; / Change music
                    + RTS

CODE_00C9C2:          JSR CODE_00CA44
                      LDA.B #$01
                      STA.B byetudlrHold
                      JSR CODE_00CD24
                      LDA.W SpotlightSize
                      BNE Return00CA30
                      LDA.W SecretGoalTape                      ; \ Branch if Goal Tape extra bits == #$02
                      INC A                                     ; | (never happens)
                      CMP.B #$03                                ; |
                      BNE +                                     ; /
                      LDA.B #$01                                ; \ Unreachable
                      STA.W OWPlayerSubmap                      ; | Set submap to be Yoshi's Island
                      LSR A                                     ; /
                    + LDY.B #$0C
                      LDX.W BonusGameActivate
                      BEQ +
                      LDX.B #$FF
                      STX.W BonusGameActivate
                      LDX.B #$F0
                      STX.W MosaicSize
                      STZ.W EndLevelTimer
                      STZ.W MusicBackup
                      LDY.B #$10
                    + STZ.W Brightness
                      STZ.W MosaicDirection
CODE_00C9FE:          STA.W OWLevelExitMode                     ; Store secret/normal exit info
                      LDA.W CutsceneID
                      BEQ CODE_00CA25
                      LDX.B #$08
                      LDA.W TranslevelNo
                      CMP.B #$13
                      BNE +
                      INC.W OWLevelExitMode
                    + CMP.B #$31
                      BEQ CODE_00CA20
CODE_00CA16:          CMP.W DATA_00C9A7-1,X
                      BEQ CODE_00CA20
                      DEX
                      BNE CODE_00CA16
                      BRA CODE_00CA25

CODE_00CA20:          STX.W CutsceneID
                      LDY.B #$18
CODE_00CA25:          STY.W GameMode
                      INC.W CreditsScreenNumber
CODE_00CA2B:          LDA.B #$01
                      STA.W MidwayFlag
Return00CA30:         RTS

SetMarioPeaceImg:     LDA.B #$26                                ; \ Mario's image = Peace Sign, or
                      LDY.W PlayerRidingYoshi                   ; |
                      BEQ +                                     ; |
                      LDA.B #$14                                ; | Mario's image = Peace Sign on Yoshi
                    + STA.W PlayerPose                          ; /
                      RTS

CODE_00CA3E:          LDA.B #$F0
                      STA.W SpotlightSize
                      RTS

CODE_00CA44:          LDA.W SpotlightSize
                      BNE +
                      RTS

                    + JSR CODE_00CA61
                      LDA.B #$FC
                      JSR CODE_00CA6D
                      LDA.B #$33
                      STA.B Layer12Window
                      STA.B OBJCWWindow
                      LDA.B #$03
                      STA.B Layer34Window
                      LDA.B #$22
                      STA.B ColorAddition
                      RTS

CODE_00CA61:          REP #$20                                  ; A->16
                      LDA.W #DATA_00CB12                        ; \
                      STA.B _4                                  ; |Load xCB12 into $04 and $06
                      STA.B _6                                  ; /
                      SEP #$20                                  ; A->8
                      RTS

CODE_00CA6D:          CLC
                      ADC.W SpotlightSize
                      STA.W SpotlightSize
                      LDA.B PlayerXPosScrRel
                      CLC
                      ADC.B #$08
                      STA.B _0
                      LDA.B #$18
                      LDY.B Powerup
                      BEQ +
                      LDA.B #$10
                    + CLC
                      ADC.B PlayerYPosScrRel
                      STA.B _1
CODE_00CA88:          REP #$30                                  ; AXY->16
                      AND.W #$00FF                              ; Keep lower byte of A
                      ASL A                                     ; \
                      DEC A                                     ; |Set Y to ((2A-1)*2)
                      ASL A                                     ; |
                      TAY                                       ; /
                      SEP #$20                                  ; A->8
                      LDX.W #$0000
CODE_00CA96:          LDA.B _1
                      CMP.W SpotlightSize
                      BCC CODE_00CABD
                      LDA.B #$FF
                      STA.W WindowTable,X
                      STZ.W WindowTable+1,X
                      CPY.W #con($01C0,$01C0,$01C0,$01C0,$01E0)
                      BCS +
                      STA.W WindowTable,Y
                      INC A
                      STA.W WindowTable+1,Y
                    + INX
                      INX
                      DEY
                      DEY
                      LDA.B _1
                      BEQ CODE_00CB0A
                      DEC.B _1
                      BRA CODE_00CA96

CODE_00CABD:          JSR CODE_00CC14
                      CLC
                      ADC.B _0
                      BCC +
                      LDA.B #$FF
                    + STA.W WindowTable+1,X
                      LDA.B _0
                      SEC
                      SBC.B _2
                      BCS +
                      LDA.B #$00
                    + STA.W WindowTable,X
                      CPY.W #$01E0
                      BCS CODE_00CAFE
                      LDA.B _7
                      BNE CODE_00CAE7
                      LDA.B #$00
                      STA.W WindowTable+1,Y
                      DEC A
                      BRA CODE_00CAFB

CODE_00CAE7:          LDA.B _3
                      ADC.B _0
                      BCC +
                      LDA.B #$FF
                    + STA.W WindowTable+1,Y
                      LDA.B _0
                      SEC
                      SBC.B _3
                      BCS CODE_00CAFB
                      LDA.B #$00
CODE_00CAFB:          STA.W WindowTable,Y
CODE_00CAFE:          INX
                      INX
                      DEY
                      DEY
                      LDA.B _1
                      BEQ CODE_00CB0A
                      DEC.B _1
                      BNE CODE_00CABD
CODE_00CB0A:          LDA.B #$80
                      STA.W HDMAEnable
                      SEP #$10                                  ; XY->8
                      RTS


DATA_00CB12:          db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
                      db $FF,$FF,$FF,$FF,$FE,$FE,$FE,$FE
                      db $FD,$FD,$FD,$FD,$FC,$FC,$FC,$FB
                      db $FB,$FB,$FA,$FA,$F9,$F9,$F8,$F8
                      db $F7,$F7,$F6,$F6,$F5,$F5,$F4,$F3
                      db $F3,$F2,$F1,$F1,$F0,$EF,$EE,$EE
                      db $ED,$EC,$EB,$EA,$E9,$E9,$E8,$E7
                      db $E6,$E5,$E4,$E3,$E2,$E1,$DF,$DE
                      db $DD,$DC,$DB,$DA,$D8,$D7,$D6,$D5
                      db $D3,$D2,$D0,$CF,$CD,$CC,$CA,$C9
                      db $C7,$C6,$C4,$C2,$C1,$BF,$BD,$BB
                      db $B9,$B7,$B6,$B4,$B1,$AF,$AD,$AB
                      db $A9,$A7,$A4,$A2,$9F,$9D,$9A,$97
                      db $95,$92,$8F,$8C,$89,$86,$82,$7F
                      db $7B,$78,$74,$70,$6C,$67,$63,$5E
                      db $59,$53,$4D,$46,$3F,$37,$2D,$1F
                      db $00

DATA_00CB93:          db $54,$53,$52,$52,$51,$50,$50
                      db $4F,$4E,$4E,$4D,$4C,$4C,$4B,$4A
                      db $4A,$4B,$48,$48,$47,$46,$46,$45
                      db $44,$44,$43,$42,$42,$41,$40,$40
                      db $3F,$3E,$3E,$3D,$3C,$3C,$3B,$3A
                      db $3A,$39,$38,$38,$37,$36,$36,$35
                      db $34,$34,$33,$32,$32,$31,$33,$35
                      db $38,$3A,$3C,$3E,$3F,$41,$43,$44
                      db $45,$47,$48,$49,$4A,$4B,$4C,$4D
                      db $4E,$4E,$4F,$50,$50,$51,$51,$52
                      db $52,$53,$53,$53,$53,$53,$53,$53
                      db $53,$53,$53,$53,$53,$53,$52,$52
                      db $51,$51,$50,$50,$4F,$4E,$4E,$4D
                      db $4C,$4B,$4A,$49,$48,$47,$45,$44
                      db $43,$41,$3F,$3E,$3C,$3A,$38,$35
                      db $33,$30,$2D,$2A,$26,$23,$1E,$18
                      db $11,$00

CODE_00CC14:          PHY
                      LDA.B _1
                      STA.W HW_WRDIV+1
                      STZ.W HW_WRDIV
                      LDA.W SpotlightSize
                      STA.W HW_WRDIV+2
                      NOP
                      NOP
                      NOP
                      NOP
                      NOP
                      NOP
                      REP #$20                                  ; A->16
                      LDA.W HW_RDDIV
                      LSR A
                      TAY
                      SEP #$20                                  ; A->8
                      LDA.B (_6),Y
                      STA.W HW_WRMPYA
                      LDA.W SpotlightSize
                      STA.W HW_WRMPYB
                      NOP
                      NOP
                      NOP
                      NOP
                      LDA.W HW_RDMPY+1
                      STA.B _3
                      LDA.B (_4),Y
                      STA.W HW_WRMPYA
                      LDA.W SpotlightSize
                      STA.W HW_WRMPYB
                      NOP
                      NOP
                      NOP
                      NOP
                      LDA.W HW_RDMPY+1
                      STA.B _2
                      PLY
                      RTS


DATA_00CC5C:          db $00,$00,$00,$00,$02,$00,$06,$00
                      db $FE,$FF,$FA,$FF

ResetAni:
                   if ver_is_ntsc(!_VER)                        ;\=================== J, U, & SS ================
                      LDA.B axlr0000Hold                        ;!
                      AND.B #$20                                ;!
                      BEQ +                                     ;!
                      LDA.B axlr0000Frame                       ;!
                      CMP.B #$80                                ;!
                      BNE +                                     ;!
                      INC.W DebugFreeRoam                       ;!
                      LDA.W DebugFreeRoam                       ;!
                      CMP.B #$03                                ;!
                      BCC +                                     ;!
                      STZ.W DebugFreeRoam                       ;!
                    + LDA.W DebugFreeRoam                       ;!
                      BRA CODE_00CCBB                           ;! Change to BEQ to enable debug code below
                                                                ;!
                      LSR A                                     ;! \ Unreachable
                      BEQ ADDR_00CCB3                           ;! | Debug: Free roaming mode
                      LDA.B #$FF                                ;! |
                      STA.W IFrameTimer                         ;! |
                      LDA.B byetudlrHold                        ;! |
                      AND.B #$03                                ;! |
                      ASL A                                     ;! |
                      ASL A                                     ;! |
                      LDX.B #$00                                ;! |
                      JSR ADDR_00CC9F                           ;! |
                      LDA.B byetudlrHold                        ;! |
                      AND.B #$0C                                ;! |
                      LDX.B #$02                                ;! |
ADDR_00CC9F:          BIT.B byetudlrHold                        ;! |
                      BVC +                                     ;! |
                      ORA.B #$02                                ;! |
                    + TAY                                       ;! |
                      REP #$20                                  ;! | A->16
                      LDA.B PlayerXPosNext,X                    ;! |
                      CLC                                       ;! |
                      ADC.W DATA_00CC5C,Y                       ;! |
                      STA.B PlayerXPosNext,X                    ;! |
                      SEP #$20                                  ;! | A->8
                      RTS                                       ;! /
                                                                ;!
ADDR_00CCB3:          LDA.B #$70                                ;!
                      STA.W PlayerPMeter                        ;!
                      STA.W TakeoffTimer                        ;!
                   endif                                        ;/===============================================
CODE_00CCBB:          LDA.W EndLevelTimer
                      BEQ +
                      JMP CODE_00C915

                    + JSR CODE_00CDDD
                      LDA.B SpriteLock                          ; \ Branch if sprites locked
                      BNE Return00CCDF                          ; /
                      STZ.W CapeInteracts
                      STZ.W PlayerOverworldPose
                      LDA.W PlayerStunnedTimer                  ; \ If lock Mario timer is set...
                      BEQ CODE_00CCE0                           ; |
                      DEC.W PlayerStunnedTimer                  ; | Decrease the timer
                      STZ.B PlayerXSpeed                        ; | X speed = 0
                      LDA.B #$0F                                ; | Mario's image = Going down tube
                      STA.W PlayerPose                          ; /
Return00CCDF:         RTS

CODE_00CCE0:          LDA.W IRQNMICommand
                      BPL CODE_00CD24
                      LSR A
                      BCS CODE_00CD24
                      BIT.W IRQNMICommand
                      BVS CODE_00CD1C
                      LDA.B PlayerInAir
                      BNE CODE_00CD1C
                      REP #$20                                  ; A->16
                      LDA.W KeyholeXPos
                      STA.B PlayerXPosNext
                      LDA.W KeyholeYPos
                      STA.B PlayerYPosNext
                      SEP #$20                                  ; A->8
                      JSR CODE_00DC2D
                      REP #$20                                  ; A->16
                      LDA.B PlayerXPosNext
                      STA.W KeyholeXPos
                      STA.W BrSwingXDist
                      LDA.B PlayerYPosNext
                      AND.W #$FFF0
                      STA.W KeyholeYPos
                      STA.W BrSwingYDist
                      JSR CODE_00F9C9
                      BRA +

CODE_00CD1C:          JSR CODE_00DC2D
                    + JSR CODE_00F8F2
                      BRA CODE_00CD36

CODE_00CD24:          LDA.B PlayerYSpeed                        ; \ Branch if Mario has downward speed
                      BPL +                                     ; /
                      LDA.B PlayerBlockedDir
                      AND.B #$08
                      BEQ +
                      STZ.B PlayerYSpeed                        ; Y speed = 0
                    + JSR CODE_00DC2D
                      JSR CODE_00E92B
CODE_00CD36:          JSR CODE_00F595
CODE_00CD39:          STZ.W PlayerTurningPose
                      LDY.W PBalloonInflating
                      BNE CODE_00CD95
                      LDA.W PlayerClimbingRope
                      BEQ +
                      LDA.B #$1F
                      STA.B GraphicsCompPtr+1
                    + LDA.B PlayerIsClimbing
                      BNE CODE_00CD72
                      LDA.W IsCarryingItem
                      ORA.W PlayerRidingYoshi
                      BNE CODE_00CD79
                      LDA.B GraphicsCompPtr+1
                      AND.B #$1B
                      CMP.B #$1B
                      BNE CODE_00CD79
                      LDA.B byetudlrHold
                      AND.B #$0C
                      BEQ CODE_00CD79
                      LDY.B PlayerInAir
                      BNE CODE_00CD72
                      AND.B #$08
                      BNE CODE_00CD72
                      LDA.B GraphicsCompPtr+1
                      AND.B #$04
                      BEQ CODE_00CD79
CODE_00CD72:          LDA.B GraphicsCompPtr+1
                      STA.B PlayerIsClimbing
                      JMP CODE_00DB17

CODE_00CD79:          LDA.B PlayerInWater
                      BEQ CODE_00CD82
                      JSR CODE_00D988
                      BRA CODE_00CD8F

CODE_00CD82:          JSR CODE_00D5F2
                      JSR CODE_00D062
                      JSR CODE_00D7E4
CODE_00CD8B:          JSL CODE_00CEB1
CODE_00CD8F:          LDY.W PlayerRidingYoshi
                      BNE CODE_00CDAD
                      RTS

CODE_00CD95:          LDA.B #$42
                      LDX.B Powerup
                      BEQ +
                      LDA.B #$43
                    + DEY
                      BEQ +
                      STY.W PBalloonInflating
                      LDA.B #$0F                                ; \ Mario's image = Going down tube
                    + STA.W PlayerPose                          ; /
CODE_00CDA8:          RTS


                      db $20,$21,$27,$28

CODE_00CDAD:          LDX.W YoshiTongueTimer
                      BEQ +
                      LDY.B #$03
                      CPX.B #$0C
                      BCS +
                      LDY.B #$04
                    + LDA.W CODE_00CDA8,Y
                      DEY
                      BNE +
                      LDY.B PlayerIsDucking
                      BEQ +
                      LDA.B #$1D                                ; \ Mario's image = Picking up object
                    + STA.W PlayerPose                          ; /
                      LDA.W YoshiHasWingsEvt                    ; \ Check Yoshi wing ability address for #$01,
                      CMP.B #$01                                ; / but this is an impossible value
                      BNE Return00CDDC                          ; \ Unreachable/unused code
                      BIT.B byetudlrFrame                       ; | Lets Mario (any power) shoot fireballs while on Yoshi
                      BVC Return00CDDC                          ; |
                      LDA.B #$08                                ; |
                      STA.W Empty18DB                           ; |
                      JSR ShootFireball                         ; /
Return00CDDC:         RTS

CODE_00CDDD:          LDA.W HorizLayer1Setting
                      BEQ Return00CDDC
                      LDY.W CameraScrollDir
                      LDA.W CameraIsScrolling
                      STA.B SpriteLock
                      BNE CODE_00CE4C
                      LDA.W CameraProperMove
                      BEQ CODE_00CDF6
                      STZ.W CameraScrollDir
                      BRA CODE_00CE48

CODE_00CDF6:          LDA.B axlr0000Hold                        ; \ Branch if anything besides L/R being held
                      AND.B #$CF                                ; |
                      ORA.B byetudlrHold                        ; |
                      BNE CODE_00CE49                           ; /
                      LDA.B axlr0000Hold                        ; \ Branch if L/R not being held
                      AND.B #$30                                ; |
                      BEQ CODE_00CE49                           ; |
                      CMP.B #$30                                ; |
                      BEQ CODE_00CE49                           ; /
                      LSR A
                      LSR A
                      LSR A
                      INC.W CameraScrollTimer
                      LDX.W CameraScrollTimer
                      CPX.B #$10
                      BCC CODE_00CE4C
                      TAX
                      REP #$20                                  ; A->16
                      LDA.W CameraMoveTrigger
                      CMP.W DATA_00F6CB,X
                      SEP #$20                                  ; A->8
                      BEQ CODE_00CE4C
                      LDA.B #$01
                      TRB.W CameraMoveTrigger
                      INC.W CameraIsScrolling
                      LDA.B #$00
                      CPX.B #$02
                      BNE +
                      LDA.B LastScreenHoriz
                      DEC A
                    + REP #$20                                  ; A->16
                      XBA
                      AND.W #$FF00
                      CMP.B Layer1XPos
                      SEP #$20                                  ; A->8
                      BEQ +
                      LDY.B #!SFX_SCREENSCROLL                  ; \ Play sound effect
                      STY.W SPCIO3                              ; /
                    + TXA
                      STA.W CameraScrollDir
CODE_00CE48:          TAY
CODE_00CE49:          STZ.W CameraScrollTimer
CODE_00CE4C:          LDX.B #$00
                      LDA.B PlayerDirection
                      ASL A
                      STA.W CameraScrollPlayerDir
                      REP #$20                                  ; A->16
                      LDA.W CameraMoveTrigger
                      CMP.W DATA_00F6CB,Y
                      BEQ CODE_00CE6D
                      CLC
                      ADC.W DATA_00F6BF,Y
                      LDY.W CameraScrollPlayerDir
                      CMP.W DATA_00F6B3,Y
                      BNE +
                      STX.W CameraScrollDir
CODE_00CE6D:          STX.W CameraIsScrolling
                    + STA.W CameraMoveTrigger
                      STX.W CameraProperMove
                      SEP #$20                                  ; A->8
CODE_00CE78:          RTS


                      db $2A,$2B,$2C,$2D,$2E,$2F

DATA_00CE7F:          db $2C,$2C,$2C,$2B,$2B,$2C,$2C,$2B
                      db $2B,$2C,$2D,$2A,$2A,$2D,$2D,$2A
                      db $2A,$2D,$2D,$2A,$2A,$2D,$2E,$2A
                      db $2A,$2E

DATA_00CE99:          db $00,$00,$25,$44,$00,$00,$0F,$45
DATA_00CEA1:          db $00,$00,$00,$00,$01,$01,$01,$01
DATA_00CEA9:          db $02,$07,$06,$09,$02,$07,$06,$09

CODE_00CEB1:          LDA.W CapeAniTimer                        ; Related to cape animation?
                      BNE lbl14A2Not0
                      LDX.W PlayerCapePose                      ; Cape image
                      LDA.B PlayerInAir                         ; If Mario isn't in air, branch to $CEDE
                      BEQ MarioAnimAir                          ; branch to $CEDE
                      LDY.B #$04
                      BIT.B PlayerYSpeed                        ; \ If Mario is falling (and thus not on ground)
                      BPL CODE_00CECD                           ; / branch down
                      CMP.B #$0C                                ; \ If making a "run jump",
                      BEQ CODE_00CEFD                           ; / branch to $CEFD
                      LDA.B PlayerInWater                       ; \ If Mario is in water,
                      BNE CODE_00CEFD                           ; |branch to $CEFD
                      BRA MrioNtInWtr                           ; / otherwise, branch to $CEE4

CODE_00CECD:          INX                                       ; \
                      CPX.B #$05                                ; |if X >= #$04 and != #$FF then jump down <- counting the INX
                      BCS CODE_00CED6                           ; /
                      LDX.B #$05                                ; X = #$05
                      BRA CODE_00CF0A                           ; Branch to $CF04

CODE_00CED6:          CPX.B #$0B                                ; \ If X is less than #$0B,
                      BCC CODE_00CF0A                           ; / branch to $CF0A
                      LDX.B #$07                                ; X = #$07
                      BRA CODE_00CF0A                           ; Mario is not in the air, branch to $CF0A

MarioAnimAir:         LDA.B PlayerXSpeed                        ; \ If Mario X speed isn't 0,
                      BNE CODE_00CEF0                           ; / branch to $CEF0
                      LDY.B #$08                                ; Otherwise Y = #$08
MrioNtInWtr:          TXA                                       ; A = X = #13DF
                      BEQ CODE_00CF0A                           ; If $13DF (now A) = 0 branch to $CF04
                      DEX                                       ; \
                      CPX.B #$03                                ; |If X - 1 < #$03 Then Branch $CF04
                      BCC CODE_00CF0A                           ; /
                      LDX.B #$02                                ; X = #$02
                      BRA CODE_00CF0A                           ; Branch to $CF04

CODE_00CEF0:          BPL +                                     ; \
                      EOR.B #$FF                                ; |A = abs(A)
                      INC A                                     ; |
                    + LSR A                                     ; \
                      LSR A                                     ; |Divide a by 8
                      LSR A                                     ; /
                      TAY                                       ; Y = A
                      LDA.W DATA_00DC7C,Y                       ; A = Mario animation speed? (I didn't know it was a table...)
                      TAY                                       ; Load Y with this table
CODE_00CEFD:          INX                                       ; \
                      CPX.B #$03                                ; |
                      BCS +                                     ; |If X is < #$02 and != #$FF <- counting the INX
                      LDX.B #$05                                ; |then X = #$05
                    + CPX.B #$07                                ; \
                      BCC CODE_00CF0A                           ; |If X is greater than or equal to #$07 then X = #$03
                      LDX.B #$03                                ; |
CODE_00CF0A:          STX.W PlayerCapePose                      ; And X goes right back into $13DF (cape image) after being modified
                      TYA                                       ; Now Y goes back into A
                      LDY.B PlayerInWater                       ; \
                      BEQ +                                     ; |If mario is in water then A = 2A
                      ASL A                                     ; |
                    + STA.W CapeAniTimer                        ; A -> $14A2 (do we know this byte yet?) no.
lbl14A2Not0:          LDA.W SpinJumpFlag                        ; A = Spin Jump Flag
                      ORA.W CapeSpinTimer
                      BEQ CODE_00CF4E                           ; If $140D OR $14A6 = 0 then branch to $CF4E
                      STZ.B PlayerIsDucking                     ; 0 -> Ducking while jumping flag
                      LDA.B EffFrame                            ; \
                      AND.B #$06                                ; |X = Y = Alternate frame counter AND #$06
                      TAX                                       ; |
                      TAY                                       ; /
                      LDA.B PlayerInAir                         ; \ If on ground branch down
                      BEQ +                                     ; /
                      LDA.B PlayerYSpeed                        ; \ If Mario moving upwards branch down
                      BMI +                                     ; /
                      INY                                       ; Y = Y + 1
                    + LDA.W DATA_00CEA9,Y                       ; \ After loading from this table,
                      STA.W PlayerCapePose                      ; / Store A in cape image
                      LDA.B Powerup                             ; A = Mario's powerup status
                      BEQ +                                     ; \
                      INX                                       ; |If not small, increase X
                    + LDA.W DATA_00CEA1,X                       ; \ Load from another table
                      STA.B PlayerDirection                     ; / store to Mario's Direction
                      LDY.B Powerup                             ; \
                      CPY.B #$02                                ; |
                      BNE +                                     ; |If Mario has cape, JSR
                      JSR CODE_00D044                           ; |to possibly the graphics handler
                    + LDA.W DATA_00CE99,X                       ; \ Load from a table again
                      JMP CODE_00D01A                           ; / And jump

CODE_00CF4E:          LDA.W PlayerSlopePose                     ; \ If $13ED is #$01 - #$7F then
                      BEQ CODE_00CF62                           ; |branch to $CF85
                      BPL CODE_00CF85                           ; |
                      LDA.W SlopeType
                      LSR A
                      LSR A
                      ORA.B PlayerDirection
                      TAY
                      LDA.W DATA_00CE7F,Y
                      BRA CODE_00CF85

CODE_00CF62:          LDA.B #$3C                                ; \ Select Case $148F
                      LDY.W IsCarryingItem                      ; |Case 0:A = #$3C
                      BEQ +                                     ; |Case Else: A = #$1D
                      LDA.B #$1D                                ; |End Select
                    + LDY.B PlayerIsDucking                     ; \ If Ducking while jumping
                      BNE CODE_00CF85                           ; / Branch to $CF85
                      LDA.W ShootFireTimer                      ; \ If (Unknown) = 0
                      BEQ CODE_00CF7E                           ; / Branch to $CF7E
                      LDA.B #$3F                                ; A = #$3F
                      LDY.B PlayerInAir                         ; \ If Mario isn't in air,
                      BEQ CODE_00CF85                           ; |branch to $CF85
                      LDA.B #$16                                ; |Otherwise, set A to #$16 and
                      BRA CODE_00CF85                           ; / branch to $CF85

CODE_00CF7E:          LDA.B #$0E                                ; A = #$0E
                      LDY.W KickingTimer                        ; \ If Time to show Mario's current pose is 00,
                      BEQ +                                     ; | Don't jump to $D01A
CODE_00CF85:          JMP CODE_00D01A                           ; |

                    + LDA.B #$1D                                ; A = #$1D
                      LDY.W PickUpItemTimer                     ; \ If $1499 != 0 then Jump to $D01A
                      BNE CODE_00CF85                           ; /
                      LDA.B #$0F                                ; A = #$0F
                      LDY.W FaceScreenTimer                     ; \ If $1499 != 0 then Jump to $D01A
                      BNE CODE_00CF85                           ; /
                      LDA.B #$00                                ; A = #$00
                      LDX.W PlayerInCloud                       ; X = $18C2 (Unknown)
                      BNE MarioAnimNoAbs1                       ; If X != 0 then branch down
                      LDA.B PlayerInAir                         ; \ If Mario is flying branch down
                      BEQ CODE_00CFB7                           ; /
                      LDY.W RunTakeoffTimer                     ; \ If $14A0 != 0 then
                      BNE CODE_00CFBC                           ; / Skip down
                      LDY.W FlightPhase                         ; Spaghetticode(tm)
                      BEQ +
                      LDA.W CODE_00CE78,Y
                    + LDY.W IsCarryingItem                      ; \ If Mario isn't holding something,
                      BEQ CODE_00D01A                           ; |branch to $D01A
                      LDA.B #$09                                ; |Otherwise, set A to #$09 and
                      BRA CODE_00D01A                           ; / branch to $D01A

CODE_00CFB7:          LDA.W PlayerTurningPose
                      BNE CODE_00D01A
CODE_00CFBC:          LDA.B PlayerXSpeed                        ; \
                      BPL MarioAnimNoAbs1                       ; |
                      EOR.B #$FF                                ; |Set A to absolute value of Mario's X speed
                      INC A                                     ; |
MarioAnimNoAbs1:      TAX                                       ; Copy A to X
                      BNE CODE_00CFD4                           ; If Mario isn't standing still, branch to $CFD4
                      XBA                                       ; "Push" A
                      LDA.B byetudlrHold                        ; \
                      AND.B #$08                                ; |If player isn't pressing up,
                      BEQ CODE_00D002                           ; |branch to $D002
                      LDA.B #$03                                ; |Otherwise, store x03 in $13DE and
                      STA.W PlayerOverworldPose                 ; |branch to $D002
                      BRA CODE_00D002                           ; /

CODE_00CFD4:          LDA.B LevelIsSlippery                     ; \ If level isn't slippery,
                      BEQ CODE_00CFE3                           ; / branch to $CFE3
                      LDA.B byetudlrHold
                      AND.B #$03
                      BEQ CODE_00D003
                      LDA.B #$68
                      STA.W PlayerPoseLenTimer
CODE_00CFE3:          LDA.W PlayerWalkingPose                   ; A = $13DB
                      LDY.W PlayerAniTimer                      ; \ If Mario is hurt (flashing),
                      BNE CODE_00D003                           ; / branch to $D003
                      DEC A                                     ; A = A - 1
                      BPL +                                     ; \If bit 7 is clear,
                      LDY.B Powerup                             ; | Load amount of walking frames
                      LDA.W NumWalkingFrames,Y                  ; | for current powerup
                    + XBA                                       ; \ >>-This code puts together an index to a table further down-<<
                      TXA                                       ; |-\ Above Line: "Push" frame amount
                      LSR A                                     ; |  |A = X / 8
                      LSR A                                     ; |  |
                      LSR A                                     ; |-/
                      ORA.W PlayerPoseLenTimer                  ; |ORA with $13E5
                      TAY                                       ; |And store A to Y
                      LDA.W DATA_00DC7C,Y                       ; |
                      STA.W PlayerAniTimer                      ; /
CODE_00D002:          XBA                                       ; \ Switch in frame amount and store it to $13DB
CODE_00D003:          STA.W PlayerWalkingPose                   ; /
                      CLC                                       ; \ Add walking animation type
                      ADC.W PlayerOverworldPose                 ; / (Walking, running...)
                      LDY.W IsCarryingItem                      ; \
                      BEQ CODE_00D014                           ; |
                      CLC                                       ; |If Mario is carrying something, add #$07
                      ADC.B #$07                                ; |
                      BRA CODE_00D01A                           ; |

CODE_00D014:          CPX.B #con($2F,$2F,$2F,$3A,$3A)           ; \
                      BCC CODE_00D01A                           ; |If X is greater than #$2F, add #$04
                      ADC.B #$03                                ; / <-Carry is always set here, adding #$01 to (#$03 + A)
CODE_00D01A:          LDY.W WallrunningType                     ; \ If Mario isn't rotated 45 degrees (triangle
                      BEQ +                                     ; / block), branch to $D030
                      TYA                                       ; \ Y AND #$01 -> Mario's Direction RAM Byte
                      AND.B #$01                                ; |
                      STA.B PlayerDirection                     ; /
                      LDA.B #$10                                ; \
                      CPY.B #$06                                ; |If Y < 6 then
                      BCC +                                     ; |    A = #13DB + $11
                      LDA.W PlayerWalkingPose                   ; |Else
                      CLC                                       ; |    A = #$10
                      ADC.B #$11                                ; |End If
                    + STA.W PlayerPose                          ; Store in Current animation frame
                      RTL                                       ; And Finish


DATA_00D034:          db $0C,$00,$F4,$FF,$08,$00,$F8,$FF
DATA_00D03C:          db $10,$00,$10,$00,$02,$00,$02,$00

CODE_00D044:          LDY.B #$01
                      STY.W CapeInteracts
                      ASL A
                      TAY
                      REP #$20                                  ; A->16
                      LDA.B PlayerXPosNext                      ; \
                      CLC                                       ; |
                      ADC.W DATA_00D034,Y                       ; |
                      STA.W CapeInteractionXPos                 ; |Set cape<->sprite collision coordinates
                      LDA.B PlayerYPosNext                      ; |
                      CLC                                       ; |
                      ADC.W DATA_00D03C,Y                       ; |
                      STA.W CapeInteractionYPos                 ; /
                      SEP #$20                                  ; A->8
                      RTS

CODE_00D062:          LDA.B Powerup
                      CMP.B #$02
                      BNE CODE_00D081
                      BIT.B byetudlrFrame
                      BVC Return00D0AD
                      LDA.B PlayerIsDucking
                      ORA.W PlayerRidingYoshi
                      ORA.W SpinJumpFlag
                      BNE Return00D0AD
                      LDA.B #$12
                      STA.W CapeSpinTimer
                      LDA.B #!SFX_SPIN                          ; \ Play sound effect
                      STA.W SPCIO3                              ; /
                      RTS

CODE_00D081:          CMP.B #$03
                      BNE Return00D0AD
                      LDA.B PlayerIsDucking
                      ORA.W PlayerRidingYoshi
                      BNE Return00D0AD
                      BIT.B byetudlrFrame
                      BVS CODE_00D0AA
                      LDA.W SpinJumpFlag
                      BEQ Return00D0AD
                      INC.W SpinjumpFireball
                      LDA.W SpinjumpFireball
                      AND.B #$0F
                      BNE Return00D0AD
                      TAY
                      LDA.W SpinjumpFireball
                      AND.B #$10
                      BEQ +
                      INY
                    + STY.B PlayerDirection
CODE_00D0AA:          JSR ShootFireball                         ; haha, I read this as "FEAR" at first
Return00D0AD:         RTS


                      db $7C,$00,$80,$00,$00,$06,$00,$01

MarioDeathAni:        STZ.B Powerup                             ; Set powerup to 0
                      LDA.B #$3E                                ; \
                      STA.W PlayerPose                          ; / Set Mario image to death image
                      LDA.B TrueFrame                           ; \
                      AND.B #$03                                ; |Decrease "Death fall timer" every four frames
                      BNE +                                     ; |
                      DEC.W PlayerAniTimer                      ; |
                    + LDA.W PlayerAniTimer                      ; \ If Death fall timer isn't #$00,
                      BNE DeathNotDone                          ; / branch to $D108
                      LDA.B #$80
                      STA.W OWLevelExitMode
                      LDA.W RemoveYoshiFlag
                      BNE +
                      STZ.W CarryYoshiThruLvls                  ; Set reserve item to 0
                    + DEC.W PlayerLives                         ; Decrease amount of lifes
                      BPL DeathNotGameOver                      ; If not Game Over, branch to $D0E6
                      LDA.B #!BGM_GAMEOVER
                      STA.W SPCIO2                              ; / Change music
                      LDX.B #$14                                ; Set X (Death message) to x14 (Game Over)
                      BRA DeathShowMessage

DeathNotGameOver:     LDY.B #$0B                                ; Set Y (game mode) to x0B (Fade to overworld)
                      LDA.W InGameTimerHundreds                 ; \
                      ORA.W InGameTimerTens                     ; |If time isn't zero,
                      ORA.W InGameTimerOnes                     ; |branch to $D104
                      BNE +                                     ; /
                      LDX.B #$1D                                ; Set X (Death message) to x1D (Time Up)
DeathShowMessage:     STX.W DeathMessage                        ; Store X in Death message
                      LDA.B #$C0                                ; \ Set Death message animation to xC0
                      STA.W GameOverAnimation                   ; /(Must be divisable by 4)
                      LDA.B #$FF                                ; \ Set Death message timer to xFF
                      STA.W GameOverTimer                       ; /
                      LDY.B #$15                                ; Set Y (game mode) to x15 (Fade to Game Over)
                    + STY.W GameMode                            ; Store Y in Game Mode
                      RTS

DeathNotDone:         CMP.B #$26                                ; \ If Death fall timer >= x26,
                      BCS +                                     ; / return
                      STZ.B PlayerXSpeed                        ; Set Mario X speed to 0
                      JSR CODE_00DC2D
                      JSR CODE_00D92E
                      LDA.B TrueFrame                           ; \
                      LSR A                                     ; |
                      LSR A                                     ; |Flip death image every four frames
                      AND.B #$01                                ; |
                      STA.B PlayerDirection                     ; /
                    + RTS


GrowingAniImgs:       db $00,$3D,$00,$3D,$00,$3D,$46,$3D
                      db $46,$3D,$46,$3D

PowerDownAni:         LDA.W PlayerAniTimer
                      BEQ CODE_00D140
                      LSR A
                      LSR A
CODE_00D130:          TAY
                      LDA.W GrowingAniImgs,Y                    ; \ Set Mario's image
                      STA.W PlayerPose                          ; /
CODE_00D137:          LDA.W PlayerAniTimer
                      BEQ +
                      DEC.W PlayerAniTimer
                    + RTS

CODE_00D140:          LDA.B #$7F
                      STA.W IFrameTimer
                      BRA CODE_00D158

MushroomAni:          LDA.W PlayerAniTimer
                      BEQ CODE_00D156
                      LSR A
                      LSR A
                      EOR.B #$FF
                      INC A
                      CLC
                      ADC.B #$0B
                      BRA CODE_00D130

CODE_00D156:          INC.B Powerup
CODE_00D158:          LDA.B #$00
                      STA.B PlayerAnimation
                      STZ.B SpriteLock
                    - RTS

CapeAni:              LDA.B #$7F
                      STA.B PlayerHiddenTiles
                      DEC.W PlayerAniTimer
                      BNE -
                      LDA.B Powerup
                      LSR A
                      BEQ CODE_00D140
                      BNE CODE_00D158
FlowerAni:            LDA.W PlayerSlopePose
                      AND.B #$80
                      ORA.W FlightPhase
                      BEQ +
                      STZ.W FlightPhase
                      LDA.W PlayerSlopePose
                      AND.B #$7F
                      STA.W PlayerSlopePose
                      STZ.W PlayerPose
                    + DEC.W CyclePaletteTimer
                      BEQ CODE_00D158
                      RTS


PipeSpeed:            db $F8,$08                                ; horizontal pipe X speed
                      db $00,$00                                ; horizontal pipe Y speed, vertical pipe X speed
                   if ver_is_ntsc(!_VER)                        ;\================== J, U, & SS =================
                      db $F0,$10                                ;! vertical pipe Y speed
                   else                                         ;<=================== E0 & E1 ===================
                      db $F2,$0E                                ;! vertical pipe Y speed
                   endif                                        ;/===============================================

DATA_00D193:          db $00,$63,$1C,$00

DoorPipeAni:          JSR NoButtons
                      STZ.W PlayerOverworldPose
                      JSL CODE_00CEB1
                      JSL CODE_00CFBC
                      JSR CODE_00D1F4
                      LDA.W PlayerRidingYoshi
                      BEQ +
                      LDA.B #$29                                ; \ Mario's image = Entering horizontal pipe on Yoshi
                      STA.W PlayerPose                          ; /
                    + REP #$20                                  ; A->16
                      LDA.B PlayerYPosNext
                      SEC
                      SBC.W #$0008
                      AND.W #$FFF0
                      ORA.W #$000E
                      STA.B PlayerYPosNext
                      SEP #$20                                  ; A->8
                      LDA.B PlayerPipeAction
                      LSR A
                      TAY
                      INY
                      LDA.W DATA_00D193-1,Y
                      LDX.W IsCarryingItem
                      BEQ +
                      EOR.B #$1C
                      DEC.W FaceScreenTimer
                      BPL +
                      INC.W FaceScreenTimer
                    + LDX.B PipeTimer
                      CPX.B #$1D
                      BCS CODE_00D1F0
                      CPY.B #$03
                      BCC +
                      REP #$20                                  ; A->16
                      INC.B PlayerYPosNext
                      INC.B PlayerYPosNext
                      SEP #$20                                  ; A->8
                    + LDA.W DATA_00D193,Y
CODE_00D1F0:          STA.B PlayerHiddenTiles
                      BRA CODE_00D22D

CODE_00D1F4:          LDA.W CapeAniTimer
                      BEQ +
                      DEC.W CapeAniTimer
                    + JMP CODE_00D137


PipeCntrBoundryX:     db $0A,$06

PipeCntringSpeed:     db $FF,$01

VertPipeAni:          JSR NoButtons
                      STZ.W PlayerCapePose
                      LDA.B #$0F
                      LDY.W PlayerRidingYoshi
                      BEQ CODE_00D22A
                      LDX.B #$00
                      LDY.B PlayerDirection                     ; \
                      LDA.B PlayerXPosNext                      ; | If not relativly centered on the pipe...
                      AND.B #$0F                                ; |
                      CMP.W PipeCntrBoundryX,Y                  ; |
                      BEQ CODE_00D228                           ; |
                      BPL +                                     ; |
                      INX                                       ; |
                    + LDA.B PlayerXPosNext                      ; | ...adjust Mario's X postion
                      CLC                                       ; |
                      ADC.W PipeCntringSpeed,X                  ; |
                      STA.B PlayerXPosNext                      ; /
CODE_00D228:          LDA.B #$21                                ; \ Mario's image = going down pipe
CODE_00D22A:          STA.W PlayerPose                          ; /
CODE_00D22D:          LDA.B #$40                                ; \ Set holding X/Y on controller
                      STA.B byetudlrHold                        ; /
                      LDA.B #$02                                ; \ Set behind scenery flag
                      STA.W PlayerBehindNet                     ; /
                      LDA.B PlayerPipeAction
                      CMP.B #$04
                      LDY.B PipeTimer
                      BEQ CODE_00D268
                      AND.B #$03
                      TAY
                      DEC.B PipeTimer
                      BNE +
                      BCS +
                      LDA.B #$7F
                      STA.B PlayerHiddenTiles
                      INC.W DrawYoshiInPipe
                    + LDA.B PlayerXSpeed                        ; \ If Mario has no speed...
                      ORA.B PlayerYSpeed                        ; |
                      BNE +                                     ; |
                      LDA.B #!SFX_PIPE                          ; | ...play sound effect
                      STA.W SPCIO0                              ; /
                    + LDA.W PipeSpeed,Y                         ; \ Set X speed
                      STA.B PlayerXSpeed                        ; /
                      LDA.W PipeSpeed+2,Y                       ; \ Set Y speed
                      STA.B PlayerYSpeed                        ; /
                      STZ.B PlayerInAir                         ; Mario flying = false
                      JMP CODE_00DC2D

CODE_00D268:          BCC CODE_00D273
CODE_00D26A:          STZ.W PlayerBehindNet                     ; \ In new level, reset values
                      STZ.W YoshiInPipeSetting                  ; /
                      JMP CODE_00D158

CODE_00D273:          INC.W SublevelCount
                      LDA.B #$0F
                      STA.W GameMode
                      RTS

                      LDA.B PlayerYPosNext                      ; \ Unreachable
                      SEC                                       ; |
                      SBC.B PlayerYPosNow                       ; |
                      CLC                                       ; |
                      ADC.B PipeTimer                           ; |
                      STA.B PipeTimer                           ; |
                      RTS                                       ; /

PipeCannonAni:        JSR NoButtons
                      LDA.B #$02
                      STA.W PlayerBehindNet
                      LDA.B #$0C
                      STA.B PlayerInAir
                      JSR CODE_00CD8B
                      DEC.B PipeTimer
                      BNE +
                      JMP CODE_00D26A

                    + LDA.B PipeTimer
                      CMP.B #$18
                      BCC CODE_00D2AA
                      BNE +
                      LDA.B #!SFX_KAPOW                         ; \ Play sound effect
                      STA.W SPCIO3                              ; /
CODE_00D2AA:          STZ.W PlayerBehindNet
                      STZ.W YoshiInPipeSetting
                      STZ.B SpriteLock                          ; Set sprites not locked
                    + LDA.B #$40                                ; \ X speed = #$40
                      STA.B PlayerXSpeed                        ; /
                      LDA.B #$C0                                ; \ Y speed = #$C0
                      STA.B PlayerYSpeed                        ; /
                      JMP CODE_00DC2D


DATA_00D2BD:          db $B0,$B6,$AE,$B4,$AB,$B2,$A9,$B0
                      db $A6,$AE,$A4,$AB,$A1,$A9,$9F,$A6

                   if ver_is_ntsc(!_VER)                        ;\=================== J, U, & SS ================
DATA_00D2CD:          dw $FF00,$0100,$FF00,$0100                ;!
                      dw $FF00,$0100,$FE80,$00C0                ;!
                      dw $FF40,$0180,$FE00,$0040                ;!
                      dw $FFC0,$0200,$FE00,$0040                ;!
                      dw $FE00,$0040,$FFC0,$0200                ;!
                      dw $FFC0,$0200,$FC00,$FF00                ;!
                      dw $0100,$0400,$FF00,$0100                ;!
                      dw $FF00,$0100                            ;!
                                                                ;!
DATA_00D309:          dw $FFE0,$0020,$FFE0,$0020                ;!
                      dw $FFE0,$0020,$FFC0,$0020                ;!
                      dw $FFE0,$0040,$FF80,$0020                ;!
                      dw $FFE0,$0080,$FF80,$0020                ;!
                      dw $FF80,$0020,$FFE0,$0080                ;!
                      dw $FFE0,$0080,$FE00,$FF80                ;!
                      dw $0080,$0200,$FF00,$0100                ;!
                      dw $FF00,$0100                            ;!
                                                                ;!
MarioAccel_:          dw $FE80,$FE80,$0180,$0180                ;!
                      dw $FE80,$FE80,$0180,$0180                ;!
                      dw $FE80,$FE80,$0180,$0180                ;!
                      dw $FE80,$FE80,$0140,$0140                ;!
                      dw $FEC0,$FEC0,$0180,$0180                ;!
                      dw $FE80,$FE80,$0100,$0100                ;!
                      dw $FF00,$FF00,$0180,$0180                ;!
                      dw $FE80,$FE80,$0100,$0100                ;!
                      dw $FE80,$FE80,$0100,$0100                ;!
                      dw $FF00,$FF00,$0180,$0180                ;!
                      dw $FF00,$FF00,$0180,$0180                ;!
                      dw $FC00,$FC00,$FD00,$FD00                ;!
                      dw $0300,$0300,$0400,$0400                ;!
                      dw $FC00,$FC00,$0600,$0600                ;!
                      dw $FA00,$FA00,$0400,$0400                ;!
                      dw $FF80,$0080,$FF00,$0100                ;!
                      dw $FE80,$0180,$FE80,$FE80                ;!
                      dw $0180,$0180,$FE80,$0280                ;!
                      dw $FD80,$FB00,$0280,$0500                ;!
                      dw $FD80,$FB00,$0280,$0500                ;!
                      dw $FD80,$FB00,$0280,$0500                ;!
                      dw $FD40,$FA80,$0240,$0480                ;!
                      dw $FDC0,$FB80,$02C0,$0580                ;!
                      dw $FD00,$FA00,$0200,$0400                ;!
                      dw $FE00,$FC00,$0300,$0600                ;!
                      dw $FD00,$FA00,$0200,$0400                ;!
                      dw $FD00,$FA00,$0200,$0400                ;!
                      dw $FE00,$FC00,$0300,$0600                ;!
                      dw $FE00,$FC00,$0300,$0600                ;!
                      dw $FD00,$FA00,$FD00,$FA00                ;!
                      dw $0300,$0600,$0300,$0600                ;!
                                                                ;!
DATA_00D43D:          dw $FF80,$FE80,$0080,$0180                ;!
                      dw $FF80,$FE80,$0080,$0180                ;!
                      dw $FF80,$FE80,$0080,$0180                ;!
                      dw $FE80,$FE80,$0080,$0140                ;!
                      dw $FF80,$FEC0,$0180,$0180                ;!
                      dw $FE80,$FE80,$0080,$0100                ;!
                      dw $FF80,$FF00,$0180,$0180                ;!
                      dw $FE80,$FE80,$0080,$0100                ;!
                      dw $FE80,$FE80,$0080,$0100                ;!
                      dw $FF80,$FF00,$0180,$0180                ;!
                      dw $FF80,$FF00,$0180,$0180                ;!
                      dw $FC00,$FC00,$FE00,$FD00                ;!
                      dw $0300,$0300,$0400,$0400                ;!
                      dw $FC00,$FC00,$0080,$0080                ;!
                      dw $FF80,$FF80,$0400,$0400                ;!
                      dw $FF80,$0080,$FF00,$0100                ;!
                      dw $FE80,$0180,$FE80,$FE80                ;!
                      dw $0180,$0180,$FE80,$0280                ;!
                      dw $FFC0,$FD80,$0040,$0280                ;!
                      dw $FFC0,$FD80,$0040,$0280                ;!
                      dw $FFC0,$FD80,$0040,$0280                ;!
                      dw $FF80,$FD40,$0040,$0240                ;!
                      dw $FFC0,$FDC0,$0080,$02C0                ;!
                      dw $FD00,$FD00,$0040,$0200                ;!
                      dw $FFC0,$FE00,$0300,$0300                ;!
                      dw $FD00,$FD00,$0040,$0200                ;!
                      dw $FD00,$FD00,$0040,$0200                ;!
                      dw $FFC0,$FE00,$0300,$0300                ;!
                      dw $FFC0,$FE00,$0300,$0300                ;!
                      dw $FD00,$FD00,$FD00,$FD00                ;!
                      dw $0300,$0300,$0300,$0300                ;!
                                                                ;!
DATA_00D535:          db $EC,$14,$DC,$24,$DC,$24,$D0,$30        ;!
                      db $EC,$14,$DC,$24,$DC,$24,$D0,$30        ;!
                      db $EC,$14,$DC,$24,$DC,$24,$D0,$30        ;!
                      db $E8,$12,$DC,$20,$DC,$20,$D0,$2C        ;!
                      db $EE,$18,$E0,$24,$E0,$24,$D4,$30        ;!
                      db $DC,$10,$DC,$1C,$DC,$1C,$D0,$28        ;!
                      db $F0,$24,$E4,$24,$E4,$24,$D8,$30        ;!
                      db $DC,$10,$DC,$1C,$DC,$1C,$D0,$28        ;!
                      db $DC,$10,$DC,$1C,$DC,$1C,$D0,$28        ;!
                      db $F0,$24,$E4,$24,$E4,$24,$D8,$30        ;!
                      db $F0,$24,$E4,$24,$E4,$24,$D8,$30        ;!
                      db $DC,$F0,$DC,$F8,$DC,$F8,$D0,$FC        ;!
                      db $10,$24,$08,$24,$08,$24,$04,$30        ;!
                      db $D0,$08,$D0,$08,$D0,$08,$D0,$08        ;!
                      db $F8,$30,$F8,$30,$F8,$30,$F8,$30        ;!
                      db $F8,$08,$F0,$10,$F4,$04,$E8,$08        ;!
                      db $F0,$10,$E0,$20,$EC,$0C,$D8,$18        ;!
                      db $D8,$28,$D4,$2C,$D0,$30,$D0,$D0        ;!
                      db $30,$30,$E0,$20                        ;!
                                                                ;!
DATA_00D5C9:          db $00,$00,$00,$00,$00,$00,$00,$00        ;!
                      db $00,$00,$00,$F0,$00,$10,$00,$00        ;!
                      db $00,$00,$00,$00,$00,$00,$00,$E0        ;!
                      db $00,$20,$00,$00,$00,$00,$00,$F0        ;!
                      db $00,$F8                                ;!
                   else                                         ;<====================== E0 & E1 ================
DATA_00D2CD:          dw $FEC0,$0140,$FEC0,$0140                ;!
                      dw $FEC0,$0140,$FE20,$00F0                ;!
                      dw $FF10,$01E0,$FD80,$0050                ;!
                      dw $FFB0,$0280,$FD80,$0050                ;!
                      dw $FD80,$0050,$FFB0,$0280                ;!
                      dw $FFB0,$0280,$FB00,$FEC0                ;!
                      dw $0140,$0500,$FEC0,$0140                ;!
                      dw $FEC0,$0140                            ;!
                                                                ;!
DATA_00D309:          dw $FFD8,$0028,$FFD8,$0028                ;!
                      dw $FFD8,$0028,$FFB0,$0028                ;!
                      dw $FFD8,$0050,$FF60,$0028                ;!
                      dw $FFD8,$00A0,$FF60,$0028                ;!
                      dw $FF60,$0028,$FFD8,$00A0                ;!
                      dw $FFD8,$00A0,$FD80,$FF60                ;!
                      dw $00A0,$0280,$FEC0,$0140                ;!
                      dw $FEC0,$0140                            ;!
                                                                ;!
MarioAccel_:          dw $FE20,$FE20,$01E0,$01E0                ;!
                      dw $FE20,$FE20,$01E0,$01E0                ;!
                      dw $FE20,$FE20,$01E0,$01E0                ;!
                      dw $FE20,$FE20,$0190,$0190                ;!
                      dw $FE70,$FE70,$01E0,$01E0                ;!
                      dw $FE20,$FE20,$0140,$0140                ;!
                      dw $FEC0,$FEC0,$01E0,$01E0                ;!
                      dw $FE20,$FE20,$0140,$0140                ;!
                      dw $FE20,$FE20,$0140,$0140                ;!
                      dw $FEC0,$FEC0,$01E0,$01E0                ;!
                      dw $FEC0,$FEC0,$01E0,$01E0                ;!
                      dw $FB00,$FB00,$FC40,$FC40                ;!
                      dw $03C0,$03C0,$0500,$0500                ;!
                      dw $FB00,$FB00,$0780,$0780                ;!
                      dw $F880,$F880,$0500,$0500                ;!
                      dw $FF60,$00A0,$FEC0,$0140                ;!
                      dw $FE20,$01E0,$FE20,$FE20                ;!
                      dw $01E0,$01E0,$FE20,$0320                ;!
                      dw $FCE0,$F9C0,$0320,$0640                ;!
                      dw $FCE0,$F9C0,$0320,$0640                ;!
                      dw $FCE0,$F9C0,$0320,$0640                ;!
                      dw $FC90,$F920,$02D0,$05A0                ;!
                      dw $FDC0,$F920,$0370,$06E0                ;!
                      dw $FC40,$F880,$0280,$0500                ;!
                      dw $FD80,$FB00,$03C0,$0780                ;!
                      dw $FC40,$F880,$0280,$0500                ;!
                      dw $FC40,$F880,$0280,$0500                ;!
                      dw $FD80,$FB00,$03C0,$0780                ;!
                      dw $FD80,$FB00,$03C0,$0780                ;!
                      dw $FC40,$F880,$FC40,$F880                ;!
                      dw $03C0,$0780,$03C0,$0780                ;!
                                                                ;!
DATA_00D43D:          dw $FF60,$FE20,$00A0,$01E0                ;!
                      dw $FF60,$FE20,$00A0,$01E0                ;!
                      dw $FF60,$FE20,$00A0,$01E0                ;!
                      dw $FE20,$FE20,$00A0,$0190                ;!
                      dw $FF60,$FE70,$01E0,$01E0                ;!
                      dw $FE20,$FE20,$00A0,$0140                ;!
                      dw $FF60,$FEC0,$01E0,$01E0                ;!
                      dw $FE20,$FE20,$00A0,$0140                ;!
                      dw $FE20,$FE20,$00A0,$0140                ;!
                      dw $FF60,$FEC0,$01E0,$01E0                ;!
                      dw $FF60,$FEC0,$01E0,$01E0                ;!
                      dw $FB00,$FB00,$FD80,$FC40                ;!
                      dw $03C0,$03C0,$0500,$0500                ;!
                      dw $FB00,$FB00,$00A0,$00A0                ;!
                      dw $FF60,$FF60,$0500,$0500                ;!
                      dw $FF60,$00A0,$FEC0,$0140                ;!
                      dw $FE20,$01E0,$FE20,$FE20                ;!
                      dw $01E0,$01E0,$FE20,$0320                ;!
                      dw $FFB0,$FCE0,$0050,$0320                ;!
                      dw $FFB0,$FCE0,$0050,$0320                ;!
                      dw $FFB0,$FCE0,$0050,$0320                ;!
                      dw $FF60,$FC90,$0050,$02D0                ;!
                      dw $FFB0,$FD30,$00A0,$0370                ;!
                      dw $FC40,$FC40,$0050,$0280                ;!
                      dw $FFB0,$FD80,$03C0,$03C0                ;!
                      dw $FC40,$FC40,$0050,$0280                ;!
                      dw $FC40,$FC40,$0050,$0280                ;!
                      dw $FFB0,$FD80,$03C0,$03C0                ;!
                      dw $FFB0,$FD80,$03C0,$03C0                ;!
                      dw $FC40,$FC40,$FC40,$FC40                ;!
                      dw $03C0,$03C0,$03C0,$03C0                ;!
                                                                ;!
DATA_00D535:          db $E7,$19,$D3,$2D,$D3,$2D,$C4,$3C        ;!
                      db $E7,$19,$D3,$2D,$D3,$2D,$C4,$3C        ;!
                      db $E7,$19,$D3,$2D,$D3,$2D,$C4,$3C        ;!
                      db $E2,$16,$D3,$28,$D3,$28,$C4,$38        ;!
                      db $EA,$1E,$D8,$2D,$D8,$2D,$C8,$3C        ;!
                      db $D3,$14,$D3,$23,$D3,$23,$C4,$34        ;!
                      db $EC,$2D,$DD,$2D,$DD,$2D,$CC,$3C        ;!
                      db $D3,$14,$D3,$23,$D3,$23,$C4,$34        ;!
                      db $D3,$14,$D3,$23,$D3,$23,$C4,$34        ;!
                      db $EC,$2D,$DD,$2D,$DD,$2D,$CC,$3C        ;!
                      db $EC,$2D,$DD,$2D,$DD,$2D,$CC,$3C        ;!
                      db $D3,$EC,$D3,$F6,$D3,$F6,$C4,$FC        ;!
                      db $14,$2D,$0A,$2D,$0A,$2D,$05,$3C        ;!
                      db $C4,$0A,$C4,$0A,$C4,$0A,$C4,$0A        ;!
                      db $F6,$3C,$F6,$3C,$F6,$3C,$F6,$3C        ;!
                      db $F6,$0A,$EC,$14,$F1,$05,$E2,$0A        ;!
                      db $EC,$14,$D8,$28,$E7,$0F,$CE,$1E        ;!
                      db $CE,$32,$C9,$37,$C4,$3C,$C4,$C4        ;!
                      db $3C,$3C,$D8,$28                        ;!
                                                                ;!
DATA_00D5C9:          db $00,$00,$00,$00,$00,$00,$00,$00        ;!
                      db $00,$00,$00,$EC,$00,$14,$00,$00        ;!
                      db $00,$00,$00,$00,$00,$00,$00,$D8        ;!
                      db $00,$28,$00,$00,$00,$00,$00,$EC        ;!
                      db $00,$F6                                ;!
                   endif                                        ;/===============================================

                   if ver_is_lores(!_VER)                       ;\================= J, U, SS, & E0 ==============
DATA_00D5EB:          db $FF,$FF,$02                            ;!
                   else                                         ;<======================= E1 ====================
DATA_00D5EB:          db $FF,$FF,$03                            ;!
                   endif                                        ;/===============================================

DATA_00D5EE:          db $68,$70

DATA_00D5F0:          db $1C,$0C

CODE_00D5F2:          LDA.B PlayerInAir
                      BEQ +
                      JMP CODE_00D682

                    + STZ.B PlayerIsDucking
                      LDA.W PlayerSlopePose
                      BNE +
                      LDA.B byetudlrHold
                      AND.B #$04
                      BEQ +
                      STA.B PlayerIsDucking
                      STZ.W CapeInteracts
                    + LDA.W StandOnSolidSprite
                      CMP.B #$02
                      BEQ CODE_00D61E
                      LDA.B PlayerBlockedDir
                      AND.B #$08
                      BNE CODE_00D61E
                      LDA.B byetudlrFrame
                      ORA.B axlr0000Frame
                      BMI CODE_00D630
CODE_00D61E:          LDA.B PlayerIsDucking
                      BEQ CODE_00D682
                      LDA.B PlayerXSpeed
                      BEQ +
                      LDA.B LevelIsSlippery
                      BNE +
                      JSR CODE_00FE4A
                    + JMP CODE_00D764

CODE_00D630:          LDA.B PlayerXSpeed
                      BPL +
                      EOR.B #$FF
                      INC A
                    + LSR A
                      LSR A
                      AND.B #$FE
                      TAX
                      LDA.B axlr0000Frame
                      BPL CODE_00D65E
                      LDA.W IsCarryingItem
                      BNE CODE_00D65E
                      INC A
                      STA.W SpinJumpFlag
                      LDA.B #!SFX_SPIN                          ; \ Play sound effect
                      STA.W SPCIO3                              ; /
                      LDY.B PlayerDirection
                      LDA.W DATA_00D5F0,Y
                      STA.W SpinjumpFireball
                      LDA.W PlayerRidingYoshi
                      BNE CODE_00D682
                      INX
                      BRA +

CODE_00D65E:          LDA.B #!SFX_JUMP                          ; \ Play sound effect
                      STA.W SPCIO1                              ; /
                    + LDA.W DATA_00D2BD,X
                      STA.B PlayerYSpeed
                      LDA.B #$0B
                      LDY.W PlayerPMeter
                      CPY.B #con($70,$70,$70,$40,$68)
                      BCC CODE_00D67D
                      LDA.W TakeoffTimer
                      BNE +
                      LDA.B #$50
                      STA.W TakeoffTimer
                    + LDA.B #$0C
CODE_00D67D:          STA.B PlayerInAir
                      STZ.W PlayerSlopePose
CODE_00D682:          LDA.W PlayerSlopePose
                      BMI CODE_00D692
                      LDA.B byetudlrHold
                      AND.B #$03
                      BNE CODE_00D6B1
CODE_00D68D:          LDA.W PlayerSlopePose
                      BEQ +
CODE_00D692:          JSR CODE_00FE4A
                      LDA.W CurrentSlope
                      BEQ +
                      JSR CODE_00D968
                      LDA.W SlopeType
                      LSR A
                      LSR A
                      TAY
                      ADC.B #$76
                      TAX
                      TYA
                      LSR A
                      ADC.B #$87
                      TAY
                      JMP CODE_00D742

                    + JMP CODE_00D764

CODE_00D6B1:          STZ.W PlayerSlopePose
                      AND.B #$01
                      LDY.W FlightPhase
                      BEQ CODE_00D6D5
                      CMP.B PlayerDirection
                      BEQ CODE_00D6C3
                      LDY.B byetudlrFrame
                      BPL CODE_00D68D
CODE_00D6C3:          LDX.B PlayerDirection
                      LDY.W DATA_00D5EE,X
                      STY.W SlopeType
                      STA.B _1
                      ASL A
                      ASL A
                      ORA.W SlopeType
                      TAX
                      BRA CODE_00D713

CODE_00D6D5:          LDY.B PlayerDirection
                      CMP.B PlayerDirection
                      BEQ CODE_00D6EC
                      LDY.W IsCarryingItem
                      BEQ CODE_00D6EA
                      LDY.W FaceScreenTimer
                      BNE CODE_00D6EC
                      LDY.B #$08
                      STY.W FaceScreenTimer
CODE_00D6EA:          STA.B PlayerDirection
CODE_00D6EC:          STA.B _1
                      ASL A
                      ASL A
                      ORA.W SlopeType
                      TAX
                      LDA.B PlayerXSpeed
                      BEQ CODE_00D713
                      EOR.W MarioAccel_+1,X
                      BPL CODE_00D713
                      LDA.W SkidTurnTimer
                      BNE CODE_00D713
                      LDA.B LevelIsSlippery
                      BNE +
                      LDA.B #$0D
                      STA.W PlayerTurningPose
                      JSR CODE_00FE4A
                    + TXA
                      CLC
                      ADC.B #$90
                      TAX
CODE_00D713:          LDY.B #$00
                      BIT.B byetudlrHold
                      BVC CODE_00D737
                      INX
                      INX
                      INY
                      LDA.B PlayerXSpeed
                      BPL +
                      EOR.B #$FF
                      INC A
                    + CMP.B #con($23,$23,$23,$2C,$2C)
                      BMI CODE_00D737
                      LDA.B PlayerInAir
                      BNE CODE_00D732
                      LDA.B #$10
                      STA.W RunTakeoffTimer
                      BRA CODE_00D736

CODE_00D732:          CMP.B #$0C
                      BNE CODE_00D737
CODE_00D736:          INY
CODE_00D737:          JSR CODE_00D96A
                      TYA
                      ASL A
                      ORA.W SlopeType
                      ORA.B _1
                      TAY
CODE_00D742:          LDA.B PlayerXSpeed
                      SEC
                      SBC.W DATA_00D535,Y
                      BEQ CODE_00D76B
                      EOR.W DATA_00D535,Y
                      BPL CODE_00D76B
                      REP #$20                                  ; A->16
                      LDA.W MarioAccel_,X
                      LDY.B LevelIsSlippery
                      BEQ +
                      LDY.B PlayerInAir
                      BNE +
                      LDA.W DATA_00D43D,X
                    + CLC
                      ADC.B PlayerXPosSpx
                      BRA CODE_00D7A0

CODE_00D764:          JSR CODE_00D968
                      LDA.B PlayerInAir
                      BNE Return00D7A4
CODE_00D76B:          LDA.W SlopeType
                      LSR A
                      TAY
                      LSR A
                      TAX
CODE_00D772:          LDA.B PlayerXSpeed
                      SEC
                      SBC.W DATA_00D5C9+1,X
                      BPL +
                      INY
                      INY
                    + LDA.W EndLevelTimer
                      ORA.B PlayerInAir
                      REP #$20                                  ; A->16
                      BNE CODE_00D78C
                      LDA.W DATA_00D309,Y
                      BIT.B LevelIsWater
                      BMI +
CODE_00D78C:          LDA.W DATA_00D2CD,Y
                    + CLC
                      ADC.B PlayerXPosSpx
                      STA.B PlayerXPosSpx
                      SEC
                      SBC.W DATA_00D5C9,X
                      EOR.W DATA_00D2CD,Y
                      BMI +
                      LDA.W DATA_00D5C9,X
CODE_00D7A0:          STA.B PlayerXPosSpx
                    + SEP #$20                                  ; A->8
Return00D7A4:         RTS


                   if ver_is_ntsc(!_VER)                        ;\==================== J, U, & SS ===============
DATA_00D7A5:          db $06,$03,$04,$10,$F4,$01,$03,$04        ;!
                      db $05,$06                                ;!
                                                                ;!
DATA_00D7AF:          db $40,$40,$20,$40,$40,$40,$40,$40        ;!
                      db $40,$40                                ;!
                                                                ;!
DATA_00D7B9:          db $10,$C8,$E0,$02,$03,$03,$04,$03        ;!
                      db $02,$00,$01,$00,$00,$00,$00            ;!
                                                                ;!
DATA_00D7C8:          db $01,$10,$30,$30,$38,$38,$40            ;!
                   else                                         ;<===================== E0 & E1 =================
DATA_00D7A5:          dw $06E6,$0373,$0499,$1266                ;!
                      dw $F220,$0126,$0373,$0499                ;!
                      dw $05C0,$06E6                            ;!
                                                                ;!
DATA_00D7AF:          dw $4000,$4000,$2000,$4000                ;!
                      dw $4000,$4000,$4000,$4000                ;!
                      dw $4000,$4000                            ;!
                                                                ;!
DATA_00D7B9:          db $10,$C8,$E0,$02,$03,$03,$04,$03        ;!
                      db $02,$00,$01,$00,$00,$00,$00            ;!
                                                                ;!
DATA_00D7C8:          dw $0001,$0010,$0030,$0030                ;!
                      dw $0038,$0038                            ;!
                      db $40                                    ;!
                   endif                                        ;/===============================================

CapeSpeed:            db $FF,$01,$01,$FF,$FF

DATA_00D7D4:          db $01,$06,$03,$01,$00

DATA_00D7D9:          db $00,$00,$00,$F8,$F8,$F8,$F4,$F0
                      db $C8,$02,$01

CODE_00D7E4:          LDY.W FlightPhase
                      BNE CODE_00D824
                      LDA.B PlayerInAir
                      BEQ CODE_00D811
                      LDA.W IsCarryingItem
                      ORA.W PlayerRidingYoshi
                      ORA.W SpinJumpFlag
                      BNE CODE_00D811
                      LDA.W PlayerSlopePose
                      BMI CODE_00D7FF
                      BNE CODE_00D811
CODE_00D7FF:          STZ.W PlayerSlopePose
                      LDX.B Powerup
                      CPX.B #$02
                      BNE CODE_00D811
                      LDA.B PlayerYSpeed
                      BMI CODE_00D811
                      LDA.W TakeoffTimer
                      BNE +
CODE_00D811:          JMP CODE_00D8CD

                    + STZ.B PlayerIsDucking
                      LDA.B #$0B
                      STA.B PlayerInAir
                      STZ.W MaxStageOfFlight
                      JSR CODE_00D94F
                      LDX.B #$02
                      BRA CODE_00D85B

CODE_00D824:          CPY.B #$02
                      BCC +
                      JSR CODE_00D94F
                    + LDX.W NextFlightPhase
                      CPX.B #$04
                      BEQ CODE_00D856
                      LDX.B #$03
                      LDY.B PlayerYSpeed
                      BMI CODE_00D856
                      LDA.B byetudlrHold
                      AND.B #$03
                      TAY
                      BNE CODE_00D849
                      LDA.W FlightPhase
                      CMP.B #$04
                      BCS CODE_00D856
                      DEX
                      BRA CODE_00D856

CODE_00D849:          LSR A
                      LDY.B PlayerDirection
                      BEQ +
                      EOR.B #$01
                    + TAX
                      CPX.W NextFlightPhase
                      BNE CODE_00D85B
CODE_00D856:          LDA.W CapePumpTimer
                      BNE CODE_00D87E
CODE_00D85B:          BIT.B byetudlrHold
                      BVS +
                      LDX.B #$04
                    + LDA.W FlightPhase
                      CMP.W DATA_00D7D4,X
                      BEQ CODE_00D87E
                      CLC
                      ADC.W CapeSpeed,X
                      STA.W FlightPhase
                      LDA.B #$08
                      LDY.W MaxStageOfFlight
                      CPY.B #$C8
                      BNE +
                      LDA.B #$02
                    + STA.W CapePumpTimer
CODE_00D87E:          STX.W NextFlightPhase
                      LDY.W FlightPhase
                      BEQ CODE_00D8CD
                   if ver_is_ntsc(!_VER)                        ;\=================== J, U, & SS ================
                      LDA.B PlayerYSpeed                        ;!
                      BPL CODE_00D892                           ;!
                      CMP.B #$C8                                ;!
                      BCS +                                     ;!
                      LDA.B #$C8                                ;!
                      BRA +                                     ;!
                                                                ;!
CODE_00D892:          CMP.W DATA_00D7C8,Y                       ;!
                      BCC +                                     ;!
                      LDA.W DATA_00D7C8,Y                       ;!
                    + PHA                                       ;!
                      CPY.B #$01                                ;!
                      BNE CODE_00D8C6                           ;!
                      LDX.W MaxStageOfFlight                    ;!
                      BEQ CODE_00D8C4                           ;!
                      LDA.B PlayerYSpeed                        ;!
                      BMI CODE_00D8AF                           ;!
                      LDA.B #!SFX_CAPE                          ;! \ Play sound effect
                      STA.W SPCIO0                              ;! /
                      BRA +                                     ;!
                                                                ;!
CODE_00D8AF:          CMP.W MaxStageOfFlight                    ;!
                      BCS +                                     ;!
                      STX.B PlayerYSpeed                        ;!
                      STZ.W MaxStageOfFlight                    ;!
                    + LDX.B PlayerDirection                     ;!
                      LDA.B PlayerXSpeed                        ;!
                      BEQ CODE_00D8C4                           ;!
                      EOR.W DATA_00D535,X                       ;!
                      BPL CODE_00D8C6                           ;!
CODE_00D8C4:          LDY.B #$02                                ;!
CODE_00D8C6:          PLA                                       ;!
                      INY                                       ;!
                      INY                                       ;!
                      INY                                       ;!
                   else                                         ;<===================== E0 & E1 =================
                      PHY                                       ;!
                      TYA                                       ;!
                      ASL A                                     ;!
                      TAY                                       ;!
                      REP #$20                                  ;! A->16
                      LDA.B PlayerYPosSpx                       ;!
                      BPL CODE_00D892                           ;!
                      CMP.W #$00C8                              ;!
                      BCS +                                     ;!
                      LDA.W #$00C8                              ;!
                      BRA +                                     ;!
                                                                ;!
CODE_00D892:          CMP.W DATA_00D7C8-1,Y                     ;!
                      BCC +                                     ;!
                      LDA.W DATA_00D7C8-1,Y                     ;!
                    + PLY                                       ;!
                      PHA                                       ;!
                      SEP #$20                                  ;! A->8
                      CPY.B #$01                                ;!
                      BNE CODE_00D8C6                           ;!
                      LDX.W MaxStageOfFlight                    ;!
                      BEQ CODE_00D8C4                           ;!
                      LDA.B PlayerYSpeed                        ;!
                      BMI CODE_00D8AF                           ;!
                      LDA.B #!SFX_CAPE                          ;!
                      STA.W SPCIO0                              ;!
                      BRA +                                     ;!
                                                                ;!
CODE_00D8AF:          CMP.W MaxStageOfFlight                    ;!
                      BCS +                                     ;!
                      STX.B PlayerYSpeed                        ;!
                      STZ.W MaxStageOfFlight                    ;!
                    + LDX.B PlayerDirection                     ;!
                      LDA.B PlayerXSpeed                        ;!
                      BEQ CODE_00D8C4                           ;!
                      EOR.W DATA_00D535,X                       ;!
                      BPL CODE_00D8C6                           ;!
CODE_00D8C4:          LDY.B #$02                                ;!
CODE_00D8C6:          INY                                       ;!
                      INY                                       ;!
                      INY                                       ;!
                      TYA                                       ;!
                      ASL A                                     ;!
                      TAY                                       ;!
                      REP #$20                                  ;! A->16
                      PLA                                       ;!
                   endif                                        ;/===============================================
                      JMP CODE_00D948

CODE_00D8CD:          LDA.B PlayerInAir                         ; \ Branch if not flying
                      BEQ CODE_00D928                           ; /
                      LDX.B #$00                                ; X = #$00
                      LDA.W PlayerRidingYoshi                   ; \ Branch if not on Yoshi
                      BEQ CODE_00D8E7                           ; /
                      LDA.W YoshiHasWingsEvt                    ; \ Branch if not winged Yoshi
                      LSR A                                     ; |
                      BEQ CODE_00D8E7                           ; /
                      LDY.B #$02                                ; \ Branch if not Caped Mario
                      CPY.B Powerup                             ; |
                      BEQ +                                     ; /
                      INX                                       ; X= #$01
                    + BRA CODE_00D8FF

CODE_00D8E7:          LDA.B Powerup                             ; \ Branch if not Caped Mario
                      CMP.B #$02                                ; |
                      BNE CODE_00D928                           ; /
                      LDA.B PlayerInAir                         ; \ Branch if $72 != 0C
                      CMP.B #$0C                                ; |
                      BNE CODE_00D8FD                           ; /
                      LDY.B #$01
                      CPY.W TakeoffTimer
                      BCC CODE_00D8FF
                      INC.W TakeoffTimer
CODE_00D8FD:          LDY.B #$00
CODE_00D8FF:          LDA.W CapeFloatTimer
                      BNE CODE_00D90D
                      LDA.B byetudlrHold,X
                      BPL CODE_00D924
                      LDA.B #$10
                      STA.W CapeFloatTimer
CODE_00D90D:          LDA.B PlayerYSpeed
                      BPL CODE_00D91B
                      LDX.W DATA_00D7B9,Y
                      BPL CODE_00D924
                      CMP.W DATA_00D7B9,Y
                      BCC CODE_00D924
CODE_00D91B:          LDA.W DATA_00D7B9,Y
                      CMP.B PlayerYSpeed
                      BEQ CODE_00D94C
                      BMI CODE_00D94C
CODE_00D924:          CPY.B #$02
                      BEQ +
CODE_00D928:          LDY.B #$01
                      LDA.B byetudlrHold
                      BMI +
CODE_00D92E:          LDY.B #$00
                   if ver_is_ntsc(!_VER)                        ;\================== J, U, & SS =================
                    + LDA.B PlayerYSpeed                        ;! \ If Mario's Y speed is negative (up),
                      BMI CODE_00D948                           ;! / branch to $D948
                      CMP.W DATA_00D7AF,Y                       ;!
                      BCC +                                     ;!
                      LDA.W DATA_00D7AF,Y                       ;!
                    + LDX.B PlayerInAir                         ;!
                      BEQ CODE_00D948                           ;!
                      CPX.B #$0B                                ;!
                      BNE CODE_00D948                           ;!
                      LDX.B #$24                                ;!
                      STX.B PlayerInAir                         ;!
CODE_00D948:          CLC                                       ;!
                      ADC.W DATA_00D7A5,Y                       ;!
                   else                                         ;<==================== E0 & E1 ==================
                    + TYA                                       ;!
                      ASL A                                     ;!
                      TAY                                       ;!
                      REP #$20                                  ;! A->16
                      LDA.B PlayerYPosSpx                       ;!
                      BMI CODE_00D948                           ;!
                      CMP.W DATA_00D7AF,Y                       ;!
                      BCC +                                     ;!
                      LDA.W DATA_00D7AF,Y                       ;!
                    + LDX.B PlayerInAir                         ;!
                      BEQ CODE_00D948                           ;!
                      CPX.B #$0B                                ;!
                      BNE CODE_00D948                           ;!
                      LDX.B #$24                                ;!
                      STX.B PlayerInAir                         ;!
CODE_00D948:          CLC                                       ;!
                      ADC.W DATA_00D7A5,Y                       ;!
                      SEP #$20                                  ;! A->8
                      STA.B PlayerYPosSpx                       ;!
                      XBA                                       ;!
                   endif                                        ;/=============================================== 
CODE_00D94C:          STA.B PlayerYSpeed
                      RTS

CODE_00D94F:          STZ.W Empty_140A
                      LDA.B PlayerYSpeed
                      BPL +
                      LDA.B #$00
                    + LSR A
                      LSR A
                      LSR A
                      TAY
                      LDA.W DATA_00D7D9,Y
                      CMP.W MaxStageOfFlight
                      BPL +
                      STA.W MaxStageOfFlight
                    + RTS

CODE_00D968:          LDY.B #$00
CODE_00D96A:          LDA.W PlayerPMeter
                      CLC
                      ADC.W DATA_00D5EB,Y
                      BPL +
                      LDA.B #$00
                    + CMP.B #con($70,$70,$70,$40,$68)
                      BCC +
                      INY
                      LDA.B #con($70,$70,$70,$40,$68)
                    + STA.W PlayerPMeter
                      RTS


DATA_00D980:          db $16,$1A,$1A,$18

DATA_00D984:          db $E8,$F8,$D0,$D0

CODE_00D988:          STZ.W PlayerSlopePose
                      STZ.B PlayerIsDucking
                      STZ.W FlightPhase
                      STZ.W SpinJumpFlag
                      LDY.B PlayerYSpeed
                      LDA.W IsCarryingItem
                      BEQ CODE_00D9EB
                      LDA.B PlayerInAir
                      BNE CODE_00D9AF
                      LDA.B byetudlrFrame
                      ORA.B axlr0000Frame
                      BPL CODE_00D9AF
                      LDA.B #$0B
                      STA.B PlayerInAir
                      STZ.W PlayerSlopePose
                      LDY.B #$F0
                      BRA CODE_00D9B5

CODE_00D9AF:          LDA.B byetudlrHold
                      AND.B #$04
                      BEQ +
CODE_00D9B5:          JSR CODE_00DAA9
                      TYA
                      CLC
                      ADC.B #$08
                      TAY
                    + INY
                      LDA.W PlayerCanJumpWater
                      BNE +
                      DEY
                      LDA.B EffFrame
                      AND.B #$03
                      BNE +
                      DEY
                      DEY
                    + TYA
                      BMI CODE_00D9D7
                      CMP.B #$10
                      BCC +
                      LDA.B #$10
                      BRA +

CODE_00D9D7:          CMP.B #$F0
                      BCS +
                      LDA.B #$F0
                    + STA.B PlayerYSpeed
                      LDY.B #$80
                      LDA.B byetudlrHold
                      AND.B #$03
                      BNE CODE_00DA48
                      LDA.B PlayerDirection
                      BRA CODE_00DA46

CODE_00D9EB:          LDA.B byetudlrFrame
                      ORA.B axlr0000Frame
                      BPL CODE_00DA0B
                      LDA.W PlayerCanJumpWater
                      BNE CODE_00DA0B
                      JSR CODE_00DAA9
                      LDA.B PlayerInAir
                      BNE +
                      LDA.B #$0B
                      STA.B PlayerInAir
                      STZ.W PlayerSlopePose
                      LDY.B #$F0
                    + TYA
                      SEC
                      SBC.B #$20
                      TAY
CODE_00DA0B:          LDA.B EffFrame
                      AND.B #$03
                      BNE +
                      INY
                      INY
                    + LDA.B byetudlrHold
                      AND.B #$0C
                      LSR A
                      LSR A
                      TAX
                      TYA
                      BMI CODE_00DA25
                      CMP.B #$40
                      BCC +
                      LDA.B #$40
                      BRA +

CODE_00DA25:          CMP.W DATA_00D984,X
                      BCS +
                      LDA.W DATA_00D984,X
                    + STA.B PlayerYSpeed
                      LDA.B PlayerInAir
                      BNE CODE_00DA40
                      LDA.B byetudlrHold
                      AND.B #$04
                      BEQ CODE_00DA40
                      STZ.W CapeInteracts
                      INC.B PlayerIsDucking
                      BRA CODE_00DA69

CODE_00DA40:          LDA.B byetudlrHold
                      AND.B #$03
                      BEQ CODE_00DA69
CODE_00DA46:          LDY.B #$78
CODE_00DA48:          STY.B _0
                      AND.B #$01
                      STA.B PlayerDirection
                      PHA
                      ASL A
                      ASL A
                      TAX
                      PLA
                      ORA.B _0
                      LDY.W Layer3TideSetting
                      BEQ +
                      CLC
                      ADC.B #$04
                    + TAY
                      LDA.B PlayerInAir
                      BEQ +
                      INY
                      INY
                    + JSR CODE_00D742
                      BRA CODE_00DA7C

CODE_00DA69:          LDY.B #$00
                      TYX
                      LDA.W Layer3TideSetting
                      BEQ +
                      LDX.B #$1E
                      LDA.B PlayerInAir
                      BNE +
                      INX
                      INX
                    + JSR CODE_00D772
CODE_00DA7C:          JSR CODE_00D062
                      JSL CODE_00CEB1
                      LDA.W CapeSpinTimer
                      BNE Return00DA8C
                      LDA.B PlayerInAir
                      BNE +
Return00DA8C:         RTS

                    + LDA.B #$18
                      LDY.W ShootFireTimer
                      BNE +
                      LDA.W PlayerAniTimer
                      LSR A
                      LSR A
                      AND.B #$03
                      TAY
                      LDA.W DATA_00D980,Y
                    + LDY.W IsCarryingItem
                      BEQ +
                      INC A
                    + STA.W PlayerPose
                      RTS

CODE_00DAA9:          LDA.B #!SFX_SWIM                          ; \ Play sound effect
                      STA.W SPCIO0                              ; /
                      LDA.W PlayerAniTimer
                      ORA.B #$10
                      STA.W PlayerAniTimer
                      RTS


DATA_00DAB7:          db $10,$08,$F0,$F8

DATA_00DABB:          db $B0,$F0

DATA_00DABD:          db $00,$01,$00,$01,$01,$01,$01,$01
                      db $01,$01,$01,$01,$01,$01,$01,$01
DATA_00DACD:          db $22,$15,$22,$15,$21,$1F,$20,$20
                      db $20,$20,$1F,$21,$1F,$21

ClimbingImgs:         db $15,$22

ClimbPunchingImgs:    db $1E,$23

DATA_00DADF:          db $10,$0F,$0E,$0D,$0C,$0B,$0A,$09
                      db $08,$07,$06,$05,$05,$05,$05,$05
                      db $05,$05

DATA_00DAF1:          db $20,$01,$40,$01,$2A,$01,$2A,$01
                      db $30,$01,$33,$01,$32,$01,$34,$01
                      db $36,$01,$38,$01,$3A,$01,$3B,$01
                      db $45,$01,$45,$01,$45,$01,$45,$01
                      db $45,$01,$45,$01,$08,$F8

CODE_00DB17:          STZ.B PlayerInAir
                      STZ.B PlayerYSpeed
                      STZ.W PlayerCapePose
                      STZ.W SpinJumpFlag
                      LDY.W NetDoorTimer
                      BEQ CODE_00DB7D
                      LDA.W NetDoorPlayerXOffset
                      BPL +
                      EOR.B #$FF
                      INC A
                    + TAX
                      CPY.B #$1E
                      BCC CODE_00DB45
                      LDA.W DATA_00DADF,X
                      BIT.W NetDoorPlayerXOffset
                      BPL +
                      EOR.B #$FF
                      INC A
                    + STA.B PlayerXSpeed
                      STZ.B PlayerXPosSpx
                      STZ.W PlayerXSpeedFPSpx
CODE_00DB45:          TXA
                      ASL A
                      TAX
                      LDA.W NetDoorPlayerXOffset
                      CPY.B #$08
                      BCS +
                      EOR.B #$80
                    + ASL A
                      REP #$20                                  ; A->16
                      LDA.W DATA_00DAF1,X
                      BCS +
                      EOR.W #$FFFF
                      INC A
                    + CLC
                      ADC.B PlayerXPosSpx
                      STA.B PlayerXPosSpx
                      SEP #$20                                  ; A->8
                      TYA
                      LSR A
                      AND.B #$0E
                      ORA.W NetDoorDirIndex
                      TAY
                      LDA.W DATA_00DABD,Y
                      BIT.W NetDoorPlayerXOffset
                      BMI +
                      EOR.B #$01
                    + STA.B PlayerDirection
                      LDA.W DATA_00DACD,Y
                      BRA CODE_00DB92

CODE_00DB7D:          STZ.B PlayerXSpeed
                      STZ.B PlayerXPosSpx
                      LDX.W PlayerBehindNet
                      LDA.W PunchNetTimer
                      BEQ +
                      TXA
                      INC A
                      INC A
                      JSR CODE_00D044
                      LDA.W ClimbPunchingImgs,X
CODE_00DB92:          STA.W PlayerPose
                      RTS

                    + LDY.B PlayerInWater                       ; Mario is in Water flag
                      BIT.B byetudlrFrame
                      BPL CODE_00DBAC
                      LDA.B #$0B
                      STA.B PlayerInAir
                      LDA.W DATA_00DABB,Y
                      STA.B PlayerYSpeed
                      LDA.B #!SFX_JUMP                          ; \ Play sound effect
                      STA.W SPCIO1                              ; /
                      BRA CODE_00DC00

CODE_00DBAC:          BVC +
                      LDA.B PlayerIsClimbing
                      BPL +
                      LDA.B #!SFX_BONK                          ; \ Play sound effect
                      STA.W SPCIO0                              ; /
                      STX.W NetDoorDirIndex
                      LDA.B PlayerXPosNext                      ; Mario X
                      AND.B #$08
                      LSR A
                      LSR A
                      LSR A
                      EOR.B #$01
                      STA.B PlayerDirection                     ; Mario's Direction
                      LDA.B #$08
                      STA.W PunchNetTimer
                    + LDA.W ClimbingImgs,X
                      STA.W PlayerPose                          ; Store A in Mario image
                      LDA.B byetudlrHold
                      AND.B #$03
                      BEQ CODE_00DBF2
                      LSR A
                      TAX
                      LDA.B GraphicsCompPtr+1
                      AND.B #$18
                      CMP.B #$18
                      BEQ CODE_00DBE8
                      LDA.B PlayerIsClimbing
                      BPL CODE_00DC00
                      CPX.B GraphicsCompPtr+2
                      BEQ CODE_00DBF2
CODE_00DBE8:          TXA
                      ASL A
                      ORA.B PlayerInWater
                      TAX
                      LDA.W DATA_00DAB7,X
                      STA.B PlayerXSpeed
CODE_00DBF2:          LDA.B byetudlrHold                        ; \
                      AND.B #$0C                                ; |If up or down isn't pressed, branch to $DC16
                      BEQ CODE_00DC16                           ; /
                      AND.B #$08                                ; \ If up is pressed, branch to $DC03
                      BNE CODE_00DC03                           ; /
                      LSR.B GraphicsCompPtr+1
                      BCS CODE_00DC0B
CODE_00DC00:          STZ.B PlayerIsClimbing                    ; Mario isn't climbing
                      RTS

CODE_00DC03:          INY
                      INY
                      LDA.B GraphicsCompPtr+1
                      AND.B #$02
                      BEQ CODE_00DC16
CODE_00DC0B:          LDA.B PlayerIsClimbing
                      BMI +
                      STZ.B PlayerXSpeed
                    + LDA.W DATA_00DAB7,Y
                      STA.B PlayerYSpeed
CODE_00DC16:          ORA.B PlayerXSpeed
                      BEQ +
                      LDA.W PlayerAniTimer
                      ORA.B #$08
                      STA.W PlayerAniTimer
                      AND.B #$07
                      BNE +
                      LDA.B PlayerDirection
                      EOR.B #$01
                      STA.B PlayerDirection
                    + RTS

CODE_00DC2D:          LDA.B PlayerYSpeed                        ; \ Store Mario's Y speed in $8A
                      STA.B GraphicsCompPtr                     ; /
                      LDA.W WallrunningType
                      BEQ CODE_00DC40
                      LSR A
                      LDA.B PlayerXSpeed
                      BCC +
                      EOR.B #$FF
                      INC A
                    + STA.B PlayerYSpeed
CODE_00DC40:          LDX.B #$00
                      JSR CODE_00DC4F
                      LDX.B #$02
                      JSR CODE_00DC4F
                      LDA.B GraphicsCompPtr
                      STA.B PlayerYSpeed
                      RTS

                   if ver_is_ntsc(!_VER)                        ;\=================== J, U, & SS ================
CODE_00DC4F:          LDA.B PlayerXSpeed,X                      ;!
                      ASL A                                     ;!
                      ASL A                                     ;!
                      ASL A                                     ;!
                      ASL A                                     ;!
                      CLC                                       ;!
                      ADC.W PlayerXSpeedFPSpx,X                 ;!
                      STA.W PlayerXSpeedFPSpx,X                 ;!
                      REP #$20                                  ;! A->16
                      PHP                                       ;!
                      LDA.B PlayerXSpeed,X                      ;!
                      LSR A                                     ;!
                      LSR A                                     ;!
                      LSR A                                     ;!
                      LSR A                                     ;!
                      AND.W #$000F                              ;!
                      CMP.W #$0008                              ;!
                      BCC +                                     ;!
                      ORA.W #$FFF0                              ;!
                    + PLP                                       ;!
                      ADC.B PlayerXPosNext,X                    ;!
                      STA.B PlayerXPosNext,X                    ;!
                      SEP #$20                                  ;! A->8
                      RTS                                       ;!
                   else                                         ;<====================== E0 & E1 ================
CODE_00DC4F:          LDA.B PlayerXSpeed,X                      ;!
                      BPL +                                     ;!
                      EOR.B #$FF                                ;!
                      INC A                                     ;!
                    + STA.B _1                                  ;!
                      STZ.B _0                                  ;!
                      STA.W HW_WRMPYA                           ;!
                      TXA                                       ;!
                      BEQ +                                     ;!
                      LDA.B #$28                                ;!
                    + STA.W HW_WRMPYB                           ;!
                      NOP                                       ;!
                      REP #$20                                  ;! A->16
                      LDA.B _0                                  ;!
                      CLC                                       ;!
                      ADC.W HW_RDMPY                            ;!
                      LSR A                                     ;!
                      LSR A                                     ;!
                      LSR A                                     ;!
                      LSR A                                     ;!
                      STZ.B _2                                  ;!
                      BIT.B PlayerXPosSpx,X                     ;!
                      BPL +                                     ;!
                      DEC.B _2                                  ;!
                      EOR.W #$FFFF                              ;!
                      INC A                                     ;!
                    + STA.B _0                                  ;!
                      SEP #$20                                  ;! A->8
                      CLC                                       ;!
                      ADC.W PlayerXSpeedFPSpx,X                 ;!
                      STA.W PlayerXSpeedFPSpx,X                 ;!
                      REP #$20                                  ;! A->16
                      LDA.B _1                                  ;!
                      ADC.B PlayerXPosNext,X                    ;!
                      STA.B PlayerXPosNext,X                    ;!
                      SEP #$20                                  ;! A->8
                      RTS                                       ;!
                   endif                                        ;/===============================================


NumWalkingFrames:     db $01,$02,$02,$02

                   if ver_is_ntsc(!_VER)                        ;\=================== J, U, & SS ================
DATA_00DC7C:          db $0A,$08,$06,$04,$03,$02,$01,$01        ;!
                      db $0A,$08,$06,$04,$03,$02,$01,$01        ;!
                      db $0A,$08,$06,$04,$03,$02,$01,$01        ;!
                      db $08,$06,$04,$03,$02,$01,$01,$01        ;!
                      db $08,$06,$04,$03,$02,$01,$01,$01        ;!
                      db $05,$04,$03,$02,$01,$01,$01,$01        ;!
                      db $05,$04,$03,$02,$01,$01,$01,$01        ;!
                      db $05,$04,$03,$02,$01,$01,$01,$01        ;!
                      db $05,$04,$03,$02,$01,$01,$01,$01        ;!
                      db $05,$04,$03,$02,$01,$01,$01,$01        ;!
                      db $05,$04,$03,$02,$01,$01,$01,$01        ;!
                      db $04,$03,$02,$01,$01,$01,$01,$01        ;!
                      db $04,$03,$02,$01,$01,$01,$01,$01        ;!
                      db $02,$02,$02,$02,$02,$02,$02,$02        ;!
                   elseif ver_is_hires(!_VER)                   ;<======================= E1 ====================
DATA_00DC7C:          db $09,$08,$06,$05,$04,$03,$03,$02        ;!
                      db $09,$08,$06,$05,$04,$03,$03,$02        ;!
                      db $09,$08,$06,$05,$04,$03,$03,$02        ;!
                      db $07,$06,$05,$04,$03,$03,$02,$01        ;!
                      db $07,$06,$05,$04,$03,$03,$02,$01        ;!
                      db $05,$04,$04,$03,$03,$02,$01,$01        ;!
                      db $05,$04,$03,$03,$02,$02,$01,$01        ;!
                      db $05,$04,$03,$03,$02,$02,$01,$01        ;!
                      db $05,$04,$03,$03,$02,$02,$01,$01        ;!
                      db $05,$04,$03,$03,$02,$02,$01,$01        ;!
                      db $05,$04,$03,$03,$02,$02,$01,$01        ;!
                      db $04,$03,$03,$02,$02,$01,$01,$01        ;!
                      db $04,$03,$03,$02,$02,$01,$01,$01        ;!
                      db $02,$02,$02,$02,$02,$02,$02,$02        ;!
                   else                                         ;<======================= E0 ====================
DATA_00DC7C:          db $0A,$08,$07,$06,$05,$04,$03,$02        ;!
                      db $0A,$08,$07,$06,$05,$04,$03,$02        ;!
                      db $0A,$08,$07,$06,$05,$04,$03,$02        ;!
                      db $08,$07,$06,$05,$04,$03,$02,$01        ;!
                      db $08,$07,$06,$05,$04,$03,$02,$01        ;!
                      db $05,$04,$04,$03,$03,$02,$01,$01        ;!
                      db $05,$04,$03,$03,$02,$02,$01,$01        ;!
                      db $05,$04,$03,$03,$02,$02,$01,$01        ;!
                      db $05,$04,$03,$03,$02,$02,$01,$01        ;!
                      db $05,$04,$03,$03,$02,$02,$01,$01        ;!
                      db $05,$04,$03,$03,$02,$02,$01,$01        ;!
                      db $04,$03,$03,$02,$02,$01,$01,$01        ;!
                      db $04,$03,$03,$02,$02,$01,$01,$01        ;!
                      db $02,$02,$02,$02,$02,$02,$02,$02        ;!
                   endif                                        ;/===============================================

DATA_00DCEC:          db $00,$00,$00,$00,$00,$00,$00,$00
                      db $00,$00,$00,$00,$00,$00,$00,$00
                      db $02,$04,$04,$04,$0E,$08,$00,$00
                      db $00,$00,$00,$00,$00,$00,$08,$08
                      db $08,$08,$08,$08,$00,$00,$00,$00
                      db $0C,$10,$12,$14,$16,$18,$1A,$00
                      db $00,$00,$00,$00,$00,$00,$00,$00
                      db $00,$00,$00,$00,$00,$06,$00,$00
                      db $00,$00,$00,$0A,$00,$00

DATA_00DD32:          db $00,$08,$10,$14,$18,$1E,$24,$24
                      db $28,$30,$38,$3E,$44,$4A,$50,$54
                      db $58,$58,$5C,$60,$64,$68,$6C,$70
                      db $74,$78,$7C,$80

DATA_00DD4E:          db $00,$00,$00,$00,$10,$00,$10,$00
                      db $00,$00,$00,$00,$F8,$FF,$F8,$FF
                      db $0E,$00,$06,$00,$F2,$FF,$FA,$FF
                      db $17,$00,$07,$00,$0F,$00,$EA,$FF
                      db $FA,$FF,$FA,$FF,$00,$00,$00,$00
                      db $00,$00,$00,$00,$10,$00,$10,$00
                      db $00,$00,$00,$00,$F8,$FF,$F8,$FF
                      db $00,$00,$F8,$FF,$08,$00,$00,$00
                      db $08,$00,$F8,$FF,$00,$00,$00,$00
                      db $F8,$FF,$00,$00,$00,$00,$10,$00
                      db $02,$00,$00,$00,$FE,$FF,$00,$00
                      db $00,$00,$00,$00,$FC,$FF,$05,$00
                      db $04,$00,$FB,$FF,$FB,$FF,$06,$00
                      db $05,$00,$FA,$FF,$F9,$FF,$09,$00
                      db $07,$00,$F7,$FF,$FD,$FF,$FD,$FF
                      db $03,$00,$03,$00,$FF,$FF,$07,$00
                      db $01,$00,$F9,$FF,$0A,$00,$F6,$FF
                      db $08,$00,$F8,$FF,$08,$00,$F8,$FF
                      db $00,$00,$04,$00,$FC,$FF,$FE,$FF
                      db $02,$00,$0B,$00,$F5,$FF,$14,$00
                      db $EC,$FF,$0E,$00,$F3,$FF,$08,$00
                      db $F8,$FF,$0C,$00,$14,$00,$FD,$FF
                      db $F4,$FF,$F4,$FF,$0B,$00,$0B,$00
                      db $03,$00,$13,$00,$F5,$FF,$05,$00
                      db $F5,$FF,$09,$00,$01,$00,$01,$00
                      db $F7,$FF,$07,$00,$07,$00,$05,$00
                      db $0D,$00,$0D,$00,$FB,$FF,$FB,$FF
                      db $FB,$FF,$FF,$FF,$0F,$00,$01,$00
                      db $F9,$FF,$00,$00

DATA_00DE32:          db $01,$00,$11,$00,$11,$00,$19,$00
                      db $01,$00,$11,$00,$11,$00,$19,$00
                      db $0C,$00,$14,$00,$0C,$00,$14,$00
                      db $18,$00,$18,$00,$28,$00,$18,$00
                      db $18,$00,$28,$00,$06,$00,$16,$00
                      db $01,$00,$11,$00,$09,$00,$11,$00
                      db $01,$00,$11,$00,$09,$00,$11,$00
                      db $01,$00,$11,$00,$11,$00,$01,$00
                      db $11,$00,$11,$00,$01,$00,$11,$00
                      db $11,$00,$01,$00,$11,$00,$11,$00
                      db $01,$00,$11,$00,$01,$00,$11,$00
                      db $11,$00,$05,$00,$04,$00,$14,$00
                      db $04,$00,$14,$00,$0C,$00,$14,$00
                      db $0C,$00,$14,$00,$10,$00,$10,$00
                      db $10,$00,$10,$00,$10,$00,$00,$00
                      db $10,$00,$00,$00,$10,$00,$00,$00
                      db $10,$00,$00,$00,$0B,$00,$0B,$00
                      db $11,$00,$11,$00,$FF,$FF,$FF,$FF
                      db $10,$00,$10,$00,$10,$00,$10,$00
                      db $10,$00,$10,$00,$10,$00,$15,$00
                      db $15,$00,$25,$00,$25,$00,$04,$00
                      db $04,$00,$04,$00,$14,$00,$14,$00
                      db $04,$00,$14,$00,$14,$00,$04,$00
                      db $04,$00,$14,$00,$04,$00,$04,$00
                      db $14,$00,$00,$00,$08,$00,$00,$00
                      db $00,$00,$08,$00,$00,$00,$00,$00
                      db $10,$00,$18,$00,$00,$00,$10,$00
                      db $18,$00,$00,$00,$10,$00,$00,$00
                      db $10,$00,$F8,$FF

TilesetIndex:         db $00,$46,$83,$46

TileExpansion_:       db $00,$00,$00,$00,$00,$00,$00,$00
                      db $00,$00,$00,$00,$00,$00,$00,$00
                      db $00,$00,$00,$00,$00,$00,$00,$00
                      db $00,$00,$00,$00,$00,$00,$00,$00
                      db $00,$00,$00,$00,$00,$00,$00,$00
                      db $00,$00,$00,$00,$00,$00,$00,$00
                      db $00,$00,$00,$00,$00,$00,$00,$00
                      db $00,$00,$00,$00,$00,$00,$00,$00
                      db $00,$00,$00,$28,$00,$00,$00,$00
                      db $00,$00,$04,$04,$04,$00,$00,$00
                      db $00,$00,$08,$00,$00,$00,$00,$0C
                      db $0C,$0C,$00,$00,$10,$10,$14,$14
                      db $18,$18,$00,$00,$1C,$00,$00,$00
                      db $00,$20,$00,$00,$00,$00,$24,$00
                      db $00,$00,$00,$00,$00,$00,$00,$00
                      db $00,$00,$00,$00,$00,$00,$00,$00
                      db $00,$00,$00,$00,$00,$00,$00,$04
                      db $04,$04,$00,$00,$00,$00,$00,$08
                      db $00,$00,$00,$00,$0C,$0C,$0C,$00
                      db $00,$10,$10,$14,$14,$18,$18,$00
                      db $00,$1C,$00,$00,$00,$00,$20,$00
                      db $00,$00,$00,$24,$00,$00,$00,$00
                      db $00,$00,$00,$00,$00,$00,$00,$00
                      db $00,$00,$00,$00,$00,$00,$00,$00
Mario8x8Tiles:        db $00,$02,$80,$80,$00,$02,$0C,$80
                      db $00,$02,$1A,$1B,$00,$02,$0D,$80
                      db $00,$02,$22,$23,$00,$02,$32,$33
                      db $00,$02,$0A,$0B,$00,$02,$30,$31
                      db $00,$02,$20,$21,$00,$02,$7E,$80
                      db $00,$02,$02,$80,$04,$7F,$4A,$5B
                      db $4B,$5A

DATA_00E00C:          db $50,$50,$50,$09,$50,$50,$50,$50
                      db $50,$50,$09,$2B,$50,$2D,$50,$D5
                      db $2E,$C4,$C4,$C4,$D6,$B6,$50,$50
                      db $50,$50,$50,$50,$50,$C5,$D7,$2A
                      db $E0,$50,$D5,$29,$2C,$B6,$D6,$28
                      db $E0,$E0,$C5,$C5,$C5,$C5,$C5,$C5
                      db $5C,$5C,$50,$5A,$B6,$50,$28,$28
                      db $C5,$D7,$28,$70,$C5,$70,$1C,$93
                      db $C5,$C5,$0B,$85,$90,$84,$70,$70
                      db $70,$A0,$70,$70,$70,$70,$70,$70
                      db $A0,$74,$70,$80,$70,$84,$17,$A4
                      db $A4,$A4,$B3,$B0,$70,$70,$70,$70
                      db $70,$70,$70,$E2,$72,$0F,$61,$70
                      db $63,$82,$C7,$90,$B3,$D4,$A5,$C0
                      db $08,$54,$0C,$0E,$1B,$51,$49,$4A
                      db $48,$4B,$4C,$5D,$5E,$5F,$E3,$90
                      db $5F,$5F,$C5,$70,$70,$70,$A0,$70
                      db $70,$70,$70,$70,$70,$A0,$74,$70
                      db $80,$70,$84,$17,$A4,$A4,$A4,$B3
                      db $B0,$70,$70,$70,$70,$70,$70,$70
                      db $E2,$72,$0F,$61,$70,$63,$82,$C7
                      db $90,$B3,$D4,$A5,$C0,$08,$64,$0C
                      db $0E,$1B,$51,$49,$4A,$48,$4B,$4C
                      db $5D,$5E,$5F,$E3,$90,$5F,$5F,$C5
DATA_00E0CC:          db $71,$60,$60,$19,$94,$96,$96,$A2
                      db $97,$97,$18,$3B,$B4,$3D,$A7,$E5
                      db $2F,$D3,$C3,$C3,$F6,$D0,$B1,$81
                      db $B2,$86,$B4,$87,$A6,$D1,$F7,$3A
                      db $F0,$F4,$F5,$39,$3C,$C6,$E6,$38
                      db $F1,$F0,$C5,$C5,$C5,$C5,$C5,$C5
                      db $6C,$4D,$71,$6A,$6B,$60,$38,$F1
                      db $5B,$69,$F1,$F1,$4E,$E1,$1D,$A3
                      db $C5,$C5,$1A,$95,$10,$07,$02,$01
                      db $00,$02,$14,$13,$12,$30,$27,$26
                      db $30,$03,$15,$04,$31,$07,$E7,$25
                      db $24,$23,$62,$36,$33,$91,$34,$92
                      db $35,$A1,$32,$F2,$73,$1F,$C0,$C1
                      db $C2,$83,$D2,$10,$B7,$E4,$B5,$61
                      db $0A,$55,$0D,$75,$77,$1E,$59,$59
                      db $58,$02,$02,$6D,$6E,$6F,$F3,$68
                      db $6F,$6F,$06,$02,$01,$00,$02,$14
                      db $13,$12,$30,$27,$26,$30,$03,$15
                      db $04,$31,$07,$E7,$25,$24,$23,$62
                      db $36,$33,$91,$34,$92,$35,$A1,$32
                      db $F2,$73,$1F,$C0,$C1,$C2,$83,$D2
                      db $10,$B7,$E4,$B5,$61,$0A,$55,$0D
                      db $75,$77,$1E,$59,$59,$58,$02,$02
                      db $6D,$6E,$6F,$F3,$68,$6F,$6F,$06
MarioPalIndex:        db $00,$40

DATA_00E18E:          db $00,$00,$00,$00,$00,$00,$00,$00
                      db $00,$00,$00,$00,$00,$0D,$00,$10
                      db $13,$22,$25,$28,$00,$16,$00,$00
                      db $00,$00,$00,$00,$00,$08,$19,$1C
                      db $04,$1F,$10,$10,$00,$16,$10,$06
                      db $04,$08,$2B,$30,$35,$3A,$3F,$43
                      db $00,$00,$00,$00,$00,$00,$00,$00
                      db $16,$16,$00,$00,$08,$00,$00,$00
                      db $00,$00,$00,$10,$04,$00

DATA_00E1D4:          db $06

DATA_00E1D5:          db $00

DATA_00E1D6:          db $06

DATA_00E1D7:          db $00

DATA_00E1D8:          db $86,$02,$06,$03,$06,$01,$06,$CE
                      db $06,$06,$40,$00,$06,$2C,$06,$06
                      db $44,$0E,$86,$2C,$06,$86,$2C,$0A
                      db $86,$84,$08,$06,$0A,$02,$06,$AC
                      db $10,$06,$CC,$10,$06,$AE,$10,$00
                      db $8C,$14,$80,$2E,$00,$CA,$16,$91
                      db $2F,$00,$8E,$18,$81,$30,$00,$EB
                      db $1A,$90,$31,$04,$ED,$1C,$82,$06
                      db $92,$1E

DATA_00E21A:          db $84,$86,$88,$8A,$8C,$8E,$90,$90
                      db $92,$94,$96,$98,$9A,$9C,$9E,$A0
                      db $A2,$A4,$A6,$A8,$AA,$B0,$B6,$BC
                      db $C2,$C8,$CE,$D4,$DA,$DE,$E2,$E2
DATA_00E23A:          db $0A,$0A,$84,$0A,$88,$88,$88,$88
                      db $8A,$8A,$8A,$8A,$44,$44,$44,$44
                      db $42,$42,$42,$42,$40,$40,$40,$40
                      db $22,$22,$22,$22,$A4,$A4,$A4,$A4
                      db $A6,$A6,$A6,$A6,$86,$86,$86,$86
                      db $6E,$6E,$6E,$6E

DATA_00E266:          db $02,$02,$02,$0C,$00,$00,$00,$00
                      db $00,$00,$00,$00,$00,$00,$00,$00
                      db $00,$00,$00,$00,$00,$00,$00,$00
                      db $00,$00,$00,$00,$04,$12,$04,$04
                      db $04,$12,$04,$04,$04,$12,$04,$04
                      db $04,$12,$04,$04

DATA_00E292:          db $01,$01,$01,$01,$02,$02,$02,$02
                      db $04,$04,$04,$04,$08,$08,$08,$08

DATA_00E2A2:          dw PlayerColors
                      dw PlayerColors+$14
                      dw PlayerColors
                      dw PlayerColors+$14
                      dw PlayerColors
                      dw PlayerColors+$14
                      dw PlayerColors+$28
                      dw PlayerColors+$3C

DATA_00E2B2:          db $10,$D4,$10,$E8

DATA_00E2B6:          db $08,$CC,$08

DATA_00E2B9:          db $E0,$10,$10,$30

CODE_00E2BD:          PHB
                      PHK
                      PLB
                      LDA.B PlayerHiddenTiles
                      CMP.B #$FF
                      BEQ +
                      JSL CODE_01EA70
                    + LDY.W CyclePaletteTimer
                      BNE CODE_00E308
                      LDY.W InvinsibilityTimer                  ; \ Branch if Mario doesn't have star
                      BEQ CODE_00E314                           ; /
                      LDA.B PlayerHiddenTiles
                      CMP.B #$FF
                      BEQ +
                      LDA.B EffFrame
                      AND.B #$03
                      BNE +
                      DEC.W InvinsibilityTimer                  ; Decrease star timer
                    + LDA.B TrueFrame
                      CPY.B #con($1E,$1E,$1E,$18,$18)
                      BCC CODE_00E30A
                      BNE CODE_00E30C
                      LDA.W MusicBackup
                      CMP.B #$FF
                      BEQ CODE_00E308
                      AND.B #$7F
                      STA.W MusicBackup
                      TAX
                      LDA.W BluePSwitchTimer
                      ORA.W SilverPSwitchTimer
                      ORA.W DirectCoinTimer
                      BEQ +
                      LDX.B #!BGM_PSWITCH
                    + STX.W SPCIO2                              ; / Change music
CODE_00E308:          LDA.B TrueFrame
CODE_00E30A:          LSR A
                      LSR A
CODE_00E30C:          AND.B #$03
                      INC A
                      INC A
                      INC A
                      INC A
                      BRA +

CODE_00E314:          LDA.B Powerup
                      ASL A
                      ORA.W PlayerTurnLvl
                    + ASL A
                      TAY
                      REP #$20                                  ; A->16
                      LDA.W DATA_00E2A2,Y
                      STA.W PlayerPalletePtr
                      SEP #$20                                  ; A->8
                      LDX.W PlayerPose
                      LDA.B #$05
                      CMP.W WallrunningType
                      BCS CODE_00E33E
                      LDA.W WallrunningType
                      LDY.B Powerup
                      BEQ CODE_00E33B
                      CPX.B #$13
                      BNE +
CODE_00E33B:          EOR.B #$01
                    + LSR A
CODE_00E33E:          REP #$20                                  ; A->16
                      LDA.B PlayerXPosNext
                      SBC.B Layer1XPos
                      STA.B PlayerXPosScrRel
                      LDA.W ScrShakePlayerYOffset
                      AND.W #$00FF
                      CLC
                      ADC.B PlayerYPosNext
                      LDY.B Powerup
                      CPY.B #$01
                      LDY.B #$01
                      BCS +
                      DEC A
                      DEY
                    + CPX.B #$0A
                      BCS +
                      CPY.W PlayerWalkingPose
                    + SBC.B Layer1YPos
                      CPX.B #$1C
                      BNE +
                      ADC.W #$0001
                    + STA.B PlayerYPosScrRel
                      SEP #$20                                  ; A->8
                      LDA.W IFrameTimer
                      BEQ +
                      LSR A
                      LSR A
                      LSR A
                      TAY
                      LDA.W DATA_00E292,Y
                      AND.W IFrameTimer
                      ORA.B SpriteLock
                      ORA.W PlayerIsFrozen
                      BNE +
                      PLB
                      RTL

                    + LDA.B #$C8
                      CPX.B #$43
                      BNE +
                      LDA.B #$E8
                    + STA.B _4
                      CPX.B #$29
                      BNE +
                      LDA.B Powerup
                      BNE +
                      LDX.B #$20
                    + LDA.W DATA_00DCEC,X
                      ORA.B PlayerDirection
                      TAY
                      LDA.W DATA_00DD32,Y
                      STA.B _5
                      LDY.B Powerup
                      LDA.W PlayerPose
                      CMP.B #$3D
                      BCS +
                      ADC.W TilesetIndex,Y
                    + TAY
                      LDA.W TileExpansion_,Y
                      STA.B _6
                      LDA.W DATA_00E00C,Y
                      STA.B _A
                      LDA.W DATA_00E0CC,Y
                      STA.B _B
                      LDA.B SpriteProperties
                      LDX.W PlayerBehindNet
                      BEQ +
                      LDA.W DATA_00E2B9,X
                    + LDY.W DATA_00E2B2,X
                      LDX.B PlayerDirection
                      ORA.W MarioPalIndex,X
                      STA.W OAMTileAttr+$100,Y
                      STA.W OAMTileAttr+$104,Y
                      STA.W OAMTileAttr+$10C,Y
                      STA.W OAMTileAttr+$110,Y
                      STA.W OAMTileAttr+$F8,Y
                      STA.W OAMTileAttr+$FC,Y
                      LDX.B _4
                      CPX.B #$E8
                      BNE +
                      EOR.B #$40
                    + STA.W OAMTileAttr+$108,Y
                      JSR CODE_00E45D
                      JSR CODE_00E45D
                      JSR CODE_00E45D
                      JSR CODE_00E45D
                      LDA.B Powerup
                      CMP.B #$02
                      BNE CODE_00E458
                      PHY
                      LDA.B #$2C
                      STA.B _6
                      LDX.W PlayerPose
                      LDA.W DATA_00E18E,X
                      TAX
                      LDA.W DATA_00E1D7,X
                      STA.B _D
                      LDA.W DATA_00E1D8,X
                      STA.B _E
                      LDA.W DATA_00E1D5,X
                      STA.B _C
                      CMP.B #$04
                      BCS CODE_00E432
                      LDA.W PlayerCapePose
                      ASL A
                      ASL A
                      ORA.B _C
                      TAY
                      LDA.W DATA_00E23A,Y
                      STA.B _C
                      LDA.W DATA_00E266,Y
                      BRA +

CODE_00E432:          LDA.W DATA_00E1D6,X
                    + ORA.B PlayerDirection
                      TAY
                      LDA.W DATA_00E21A,Y
                      STA.B _5
                      PLY
                      LDA.W DATA_00E1D4,X
                      TSB.B PlayerHiddenTiles
                      BMI +
                      JSR CODE_00E45D
                    + LDX.W PlayerBehindNet
                      LDY.W DATA_00E2B6,X
                      JSR CODE_00E45D
                      LDA.B _E
                      STA.B _6
                      JSR CODE_00E45D
CODE_00E458:          JSR CODE_00F636
                      PLB
                      RTL

CODE_00E45D:          LSR.B PlayerHiddenTiles
                      BCS +
                      LDX.B _6
                      LDA.W Mario8x8Tiles,X
                      BMI +
                      STA.W OAMTileNo+$100,Y
                      LDX.B _5
                      REP #$20                                  ; A->16
                      LDA.B PlayerYPosScrRel
                      CLC
                      ADC.W DATA_00DE32,X
                      PHA
                      CLC
                      ADC.W #$0010
                      CMP.W #$0100
                      PLA
                      SEP #$20                                  ; A->8
                      BCS +
                      STA.W OAMTileYPos+$100,Y
                      REP #$20                                  ; A->16
                      LDA.B PlayerXPosScrRel
                      CLC
                      ADC.W DATA_00DD4E,X
                      PHA
                      CLC
                      ADC.W #$0080
                      CMP.W #$0200
                      PLA
                      SEP #$20                                  ; A->8
                      BCS +
                      STA.W OAMTileXPos+$100,Y
                      XBA
                      LSR A
                    + PHP
                      TYA
                      LSR A
                      LSR A
                      TAX
                      ASL.B _4
                      ROL A
                      PLP
                      ROL A
                      AND.B #$03
                      STA.W OAMTileSize+$40,X
                      INY
                      INY
                      INY
                      INY
                      INC.B _5
                      INC.B _5
                      INC.B _6
                      RTS


DATA_00E4B9:          db $08,$08,$08,$08,$10,$10,$10,$10
                      db $18,$18,$20,$20,$28,$30,$08,$10
                      db $00,$00,$28,$00,$00,$00,$00,$00
                      db $38,$50,$48,$40,$58,$58,$60,$60
                      db $00

DATA_00E4DA:          db $10,$10,$10,$10,$10,$10,$10,$10
                      db $20,$20,$20,$20,$30,$30,$40,$30
                      db $30,$30,$30,$00,$00,$00,$00,$00
                      db $30,$30,$30,$30,$40,$40,$40,$40
                      db $00

DATA_00E4FB:          db $00,$00,$00,$00,$00,$00,$00,$00
                      db $EC,$EC,$EE,$EE,$DA,$DA,$00,$00
                      db $00,$00,$00,$00,$00,$00,$00,$00
                      db $DA,$DA,$DA,$DA,$00,$00,$00,$00
                      db $00

DATA_00E51C:          db $08,$08,$08,$08,$08,$08,$08,$08
                      db $09,$09,$09,$09,$0B,$0B,$0B,$0B
                      db $0B,$0B,$0B,$00,$00,$00,$00,$00
                      db $0B,$0B,$0B,$0B,$14,$14,$14,$14
                      db $06

DATA_00E53D:          db $FF,$FF,$FF,$FF,$01,$01,$01,$01
                      db $FE,$FE,$02,$02,$FD,$03,$FD,$03
                      db $FD,$03,$FD,$00,$00,$00,$00,$00
                      db $08,$08,$F8,$F8,$FC,$FC,$04,$04
                      db $00

DATA_00E55E:          db $00,$00,$00,$00,$00,$01,$01
                      db $01,$01,$01,$02,$02,$02,$02,$02
                      db $03,$03,$03,$03,$03,$04,$04,$04
                      db $04,$04,$05,$05,$05,$05,$05,$06
                      db $06,$06,$06,$06,$07,$07,$07,$07
                      db $07,$08,$08,$08,$08,$08,$09,$09
                      db $09,$09,$09,$0A,$0A,$0A,$0A,$0A
                      db $0B,$0B,$0B,$0B,$0B,$0C,$0C,$0C
                      db $0C,$0C,$0D,$0D,$0D,$0D,$0D,$0E
                      db $0F,$10,$11,$03,$03,$04,$04,$09
                      db $09,$0A,$0A,$0C,$0C,$0D,$0D,$12
                      db $13,$14,$15,$16,$17,$1C,$1D,$1E
                      db $1F,$18,$19,$1A,$1B,$08,$09,$0A
                      db $0B,$0C,$0D

DATA_00E5C8:          db $00,$00,$00,$00,$00
                      db $01,$01,$01,$01,$01,$02,$02,$02
                      db $02,$02,$03,$03,$03,$03,$03,$04
                      db $04,$04,$04,$04,$05,$05,$05,$05
                      db $05,$06,$06,$06,$06,$06,$07,$07
                      db $07,$07,$07,$08,$08,$08,$08,$08
                      db $09,$09,$09,$09,$09,$0A,$0A,$0A
                      db $0A,$0A,$0B,$0B,$0B,$0B,$0B,$0C
                      db $0C,$0C,$0C,$0C,$0D,$0D,$0D,$0D
                      db $0D,$0E,$0F,$10,$11,$03,$03,$04
                      db $04,$09,$09,$0A,$0A,$0C,$0C,$0D
                      db $0D,$0C,$0D,$0D,$0C,$16,$17,$1C
                      db $1D,$1E,$1F,$18,$19,$1A,$1B,$08
                      db $09,$0A,$0B,$0C,$0D

DATA_00E632:          db $0F,$0F,$0F,$0F,$0E,$0E,$0E,$0E
                      db $0D,$0D,$0D,$0D,$0C,$0C,$0C,$0C
                      db $0B,$0B,$0B,$0B,$0A,$0A,$0A,$0A
                      db $09,$09,$09,$09,$08,$08,$08,$08
                      db $07,$07,$07,$07,$06,$06,$06,$06
                      db $05,$05,$05,$05,$04,$04,$04,$04
                      db $03,$03,$03,$03,$02,$02,$02,$02
                      db $01,$01,$01,$01,$00,$00,$00,$00
                      db $00,$00,$00,$00,$01,$01,$01,$01
                      db $02,$02,$02,$02,$03,$03,$03,$03
                      db $04,$04,$04,$04,$05,$05,$05,$05
                      db $06,$06,$06,$06,$07,$07,$07,$07
                      db $08,$08,$08,$08,$09,$09,$09,$09
                      db $0A,$0A,$0A,$0A,$0B,$0B,$0B,$0B
                      db $0C,$0C,$0C,$0C,$0D,$0D,$0D,$0D
                      db $0E,$0E,$0E,$0E,$0F,$0F,$0F,$0F
                      db $0F,$0F,$0E,$0E,$0D,$0D,$0C,$0C
                      db $0B,$0B,$0A,$0A,$09,$09,$08,$08
                      db $07,$07,$06,$06,$05,$05,$04,$04
                      db $03,$03,$02,$02,$01,$01,$00,$00
                      db $00,$00,$01,$01,$02,$02,$03,$03
                      db $04,$04,$05,$05,$06,$06,$07,$07
                      db $08,$08,$09,$09,$0A,$0A,$0B,$0B
                      db $0C,$0C,$0D,$0D,$0E,$0E,$0F,$0F
                      db $0F,$0E,$0D,$0C,$0B,$0A,$09,$08
                      db $07,$06,$05,$04,$03,$02,$01,$00
                      db $00,$01,$02,$03,$04,$05,$06,$07
                      db $08,$09,$0A,$0B,$0C,$0D,$0E,$0F
                      db $0F,$0E,$0D,$0C,$0B,$0A,$09,$08
                      db $07,$06,$05,$04,$03,$02,$01,$00
                      db $00,$01,$02,$03,$04,$05,$06,$07
                      db $08,$09,$0A,$0B,$0C,$0D,$0E,$0F
                      db $08,$06,$04,$03,$02,$02,$01,$01
                      db $00,$00,$00,$00,$00,$00,$00,$00
                      db $00,$00,$00,$00,$00,$00,$00,$00
                      db $01,$01,$02,$02,$03,$04,$06,$08
                      db $FF,$FE,$FD,$FC,$FB,$FA,$F9,$F8
                      db $F7,$F6,$F5,$F4,$F3,$F2,$F1,$F0
                      db $F0,$F1,$F2,$F3,$F4,$F5,$F6,$F7
                      db $F8,$F9,$FA,$FB,$FC,$FD,$FE,$FF
                      db $FF,$FF,$FE,$FE,$FD,$FD,$FC,$FC
                      db $FB,$FB,$FA,$FA,$F9,$F9,$F8,$F8
                      db $F7,$F7,$F6,$F6,$F5,$F5,$F4,$F4
                      db $F3,$F3,$F2,$F2,$F1,$F1,$F0,$F0
                      db $F0,$F0,$F1,$F1,$F2,$F2,$F3,$F3
                      db $F4,$F4,$F5,$F5,$F6,$F6,$F7,$F7
                      db $F8,$F8,$F9,$F9,$FA,$FA,$FB,$FB
                      db $FC,$FC,$FD,$FD,$FE,$FE,$FF,$FF
                      db $0F,$0E,$0D,$0C,$0B,$0A,$09,$08
                      db $07,$06,$05,$04,$03,$02,$01,$00
                      db $00,$01,$02,$03,$04,$05,$06,$07
                      db $08,$09,$0A,$0B,$0C,$0D,$0E,$0F
                      db $00,$01,$02,$03,$04,$05,$06,$07
                      db $08,$09,$0A,$0B,$0C,$0D,$0E,$0F
                      db $0F,$0E,$0D,$0C,$0B,$0A,$09,$08
                      db $07,$06,$05,$04,$03,$02,$01,$00
                      db $10,$10,$10,$10,$10,$10,$10,$10
                      db $0E,$0C,$0A,$08,$06,$04,$02,$00
                      db $0E,$0C,$0A,$08,$06,$04,$02,$00
                      db $FE,$FC,$FA,$F8,$F6,$F4,$F2,$F0
                      db $00,$02,$04,$06,$08,$0A,$0C,$0E
                      db $10,$10,$10,$10,$10,$10,$10,$10
                      db $F0,$F2,$F4,$F6,$F8,$FA,$FC,$FE
                      db $00,$02,$04,$06,$08,$0A

DATA_00E830:          db $0C,$0E,$08,$00,$0E,$00,$0E,$00
                      db $08,$00,$05,$00,$0B,$00,$08,$00
                      db $02,$00,$02,$00,$08,$00,$0B,$00
                      db $05,$00,$08,$00,$0E,$00,$0E,$00
                      db $08,$00,$05,$00,$0B,$00,$08,$00
                      db $02,$00,$02,$00,$08,$00,$0B,$00
                      db $05,$00,$08,$00,$0E,$00,$0E,$00
                      db $08,$00,$05,$00,$0B,$00,$08,$00
                      db $02,$00,$02,$00,$08,$00,$0B,$00
                      db $05,$00,$08,$00,$0E,$00,$0E,$00
                      db $08,$00,$05,$00,$0B,$00,$08,$00
                      db $02,$00,$02,$00,$08,$00,$0B,$00
                      db $05,$00,$10,$00,$20,$00,$07,$00
                      db $00,$00,$F0,$FF

DATA_00E89C:          db $08,$00,$18,$00,$1A,$00,$16,$00
DATA_00E8A4:          db $10,$00,$20,$00,$20,$00,$18,$00
                      db $1A,$00,$16,$00,$10,$00,$20,$00
                      db $20,$00,$12,$00,$1A,$00,$0F,$00
                      db $08,$00,$20,$00,$20,$00,$12,$00
                      db $1A,$00,$0F,$00,$08,$00,$20,$00
                      db $20,$00,$1D,$00,$28,$00,$19,$00
                      db $13,$00,$30,$00,$30,$00,$1D,$00
                      db $28,$00,$19,$00,$13,$00,$30,$00
                      db $30,$00,$1A,$00,$28,$00,$16,$00
                      db $10,$00,$30,$00,$30,$00,$1A,$00
                      db $28,$00,$16,$00,$10,$00,$30,$00
                      db $30,$00,$18,$00,$18,$00,$18,$00
                      db $18,$00,$18,$00,$18,$00

DATA_00E90A:          db $01,$02,$11

DATA_00E90D:          db $FF

DATA_00E90E:          db $FF,$01,$00

DATA_00E911:          db $02,$0D

DATA_00E913:          db $01,$00,$FF,$FF,$01,$00,$01,$00
                      db $FF,$FF,$FF,$FF

DATA_00E91F:          db $00,$00,$00,$00,$FF,$FF,$01,$00
                      db $FF,$FF,$01,$00

CODE_00E92B:          JSR CODE_00EAA6
                      LDA.W PlayerDisableObjInt
                      BEQ CODE_00E938
                      JSR CODE_00EE1D
                      BRA CODE_00E98C

CODE_00E938:          LDA.W PlayerIsOnGround
                      STA.B GraphicsUncompPtr
                      STZ.W PlayerIsOnGround
                      LDA.B PlayerInAir
                      STA.B GraphicsUncompPtr+2
                      LDA.B ScreenMode
                      BPL +
                      AND.B #$82
                      STA.B GraphicsUncompPtr+1
                      LDA.B #$01
                      STA.W LayerProcessing
                      REP #$20                                  ; A->16
                      LDA.B PlayerXPosNext
                      CLC
                      ADC.B Layer23XRelPos
                      STA.B PlayerXPosNext
                      LDA.B PlayerYPosNext
                      CLC
                      ADC.B Layer23YRelPos
                      STA.B PlayerYPosNext
                      SEP #$20                                  ; A->8
                      JSR CODE_00EADB
                      REP #$20                                  ; A->16
                      LDA.B PlayerXPosNext
                      SEC
                      SBC.B Layer23XRelPos
                      STA.B PlayerXPosNext
                      LDA.B PlayerYPosNext
                      SEC
                      SBC.B Layer23YRelPos
                      STA.B PlayerYPosNext
                      SEP #$20                                  ; A->8
                    + ASL.W PlayerIsOnGround
                      LDA.B ScreenMode
                      AND.B #$41
                      STA.B GraphicsUncompPtr+1
                      ASL A
                      BMI CODE_00E98C
                      STZ.W LayerProcessing
                      ASL.B GraphicsUncompPtr
                      JSR CODE_00EADB
CODE_00E98C:          LDA.W SideExitEnabled
                      BEQ CODE_00E9A1
                      REP #$20                                  ; A->16
                      LDA.B PlayerXPosScrRel
                      CMP.W #$00FA
                      SEP #$20                                  ; A->8
                      BCC CODE_00E9FB
                      JSL SubSideExit
                      RTS

CODE_00E9A1:          LDA.B PlayerXPosScrRel
                      CMP.B #$F0
                      BCS CODE_00EA08
                      LDA.B PlayerBlockedDir
                      AND.B #$03
                      BNE CODE_00E9FB
                      REP #$20                                  ; A->16
                      LDY.B #$00
                      LDA.W NextLayer1XPos
                      CLC
                      ADC.W #$00E8
                      CMP.B PlayerXPosNext
                      BEQ CODE_00E9C8
                      BMI CODE_00E9C8
                      INY
                      LDA.B PlayerXPosNext
                      SEC
                      SBC.W #$0008
                      CMP.W NextLayer1XPos
CODE_00E9C8:          SEP #$20                                  ; A->8
                      BEQ CODE_00E9FB
                      BPL CODE_00E9FB
                      LDA.W HorizLayer1Setting
                      BNE +
                      LDA.B #$80
                      TSB.B PlayerBlockedDir
                      REP #$20                                  ; A->16
                      LDA.W Layer1ScrollXSpeed
                      LSR A
                      LSR A
                      LSR A
                      LSR A
                      SEP #$20                                  ; A->8
                      STA.B _0
                      SEC
                      SBC.B PlayerXSpeed
                      EOR.W DATA_00E90E,Y
                      BMI +
                      LDA.B _0
                      STA.B PlayerXSpeed
                      LDA.W Layer1ScrollXPosUpd
                      STA.W PlayerXSpeedFPSpx
                    + LDA.W DATA_00E90A,Y
                      TSB.B PlayerBlockedDir
CODE_00E9FB:          LDA.B PlayerBlockedDir
                      AND.B #$1C
                      CMP.B #$1C
                      BNE CODE_00EA0D
                      LDA.W StandOnSolidSprite
                      BNE CODE_00EA0D
CODE_00EA08:          JSR CODE_00F629
                      BRA CODE_00EA32

CODE_00EA0D:          LDA.B PlayerBlockedDir
                      AND.B #$03
                      BEQ +
                      AND.B #$02
                      TAY
                      REP #$20                                  ; A->16
                      LDA.B PlayerXPosNext
                      CLC
                      ADC.W DATA_00E90D,Y
                      STA.B PlayerXPosNext
                      SEP #$20                                  ; A->8
                      LDA.B PlayerBlockedDir
                      BMI +
                      LDA.B #$03
                      STA.W PlayerPoseLenTimer
                      LDA.B PlayerXSpeed
                      EOR.W DATA_00E90D,Y
                      BPL +
CODE_00EA32:          STZ.B PlayerXSpeed
                    + LDA.W PlayerBehindNet
                      CMP.B #$01
                      BNE +
                      LDA.B GraphicsCompPtr+1
                      BNE +
                      STZ.W PlayerBehindNet
                    + STZ.W PlayerCanJumpWater
                      LDA.B LevelIsWater
                      BNE CODE_00EA5E
                      LSR.B GraphicsCompPtr
                      BCC CODE_00EAA3
                      LDA.B PlayerInWater
                      BNE CODE_00EA65
                      LDA.B PlayerYSpeed
                      BMI CODE_00EA65
                      LSR.B GraphicsCompPtr
                      BCC Return00EAA5
                      JSR CODE_00FDA5
                      STZ.B PlayerYSpeed
CODE_00EA5E:          LDA.B #$01
                      STA.B PlayerInWater
CODE_00EA62:          JMP CODE_00FD08

CODE_00EA65:          LSR.B GraphicsCompPtr
                      BCS CODE_00EA5E
                      LDA.B PlayerInWater
                      BEQ Return00EAA5
                      LDA.B #$FC
                      CMP.B PlayerYSpeed
                      BMI +
                      STA.B PlayerYSpeed
                    + INC.W PlayerCanJumpWater
                      LDA.B byetudlrHold
                      AND.B #$88
                      CMP.B #$88
                      BNE CODE_00EA62
                      LDA.B axlr0000Hold
                      BPL +
                      LDA.W IsCarryingItem
                      BNE +
                      INC A
                      STA.W SpinJumpFlag
                      LDA.B #!SFX_SPIN                          ; \ Play sound effect
                      STA.W SPCIO3                              ; /
                    + LDA.B PlayerBlockedDir
                      AND.B #$08
                      BNE CODE_00EA62
                      JSR CODE_00FDA5
                      LDA.B #$0B
                      STA.B PlayerInAir
                      LDA.B #$AA
                      STA.B PlayerYSpeed
CODE_00EAA3:          STZ.B PlayerInWater
Return00EAA5:         RTS

CODE_00EAA6:          STZ.W PlayerPoseLenTimer
                      STZ.B PlayerBlockedDir
                      STZ.W SlopeType
                      STZ.W CurrentSlope
                      STZ.B GraphicsCompPtr
                      STZ.B GraphicsCompPtr+1
                      STZ.W Layer2Touched
                      RTS


                   if ver_is_ntsc(!_VER)                        ;\=================== J, U, & SS ================
DATA_00EAB9:          db $DE,$23                                ;!
                   else                                         ;<==================== E0 & E1 ==================
DATA_00EAB9:          db $D6,$2B                                ;!
                   endif                                        ;/===============================================

DATA_00EABB:          db $20,$E0

DATA_00EABD:          db $08,$00,$F8,$FF

DATA_00EAC1:          db $71,$72,$76,$77,$7B,$7C,$81,$86
                      db $8A,$8B,$8F,$90,$94,$95,$99,$9A
                      db $9E,$9F,$A3,$A4,$A8,$A9,$AD,$AE
                      db $B2,$B3

CODE_00EADB:          LDA.B PlayerYPosNext
                      AND.B #$0F
                      STA.B PlayerYPosInBlock
                      LDA.W WallrunningType
                      BNE +
                      JMP CODE_00EB77

                    + AND.B #$01
                      TAY
                      LDA.B PlayerXSpeed
                      SEC
                      SBC.W DATA_00EAB9,Y
                      EOR.W DATA_00EAB9,Y
                      BMI CODE_00EB48
                      LDA.B PlayerInAir
                      ORA.W IsCarryingItem
                      ORA.B PlayerIsDucking
                      ORA.W PlayerRidingYoshi
                      BNE CODE_00EB48
                      LDA.W WallrunningType
                      CMP.B #$06
                      BCS CODE_00EB22
                      LDX.B PlayerYPosInBlock
                      CPX.B #$08
                      BCC Return00EB76
                      CMP.B #$04
                      BCS CODE_00EB73
                      ORA.B #$04
                      STA.W WallrunningType
CODE_00EB19:          LDA.B PlayerXPosNext
                      AND.B #$F0
                      ORA.B #$08
                      STA.B PlayerXPosNext
                      RTS

CODE_00EB22:          LDX.B #$60
                      TYA
                      BEQ +
                      LDX.B #$66
                    + JSR CODE_00EFE8
                      LDA.B Powerup
                      BNE CODE_00EB34
                      INX
                      INX
                      BRA +

CODE_00EB34:          JSR CODE_00EFE8
                    + JSR CODE_00F44D
                      BNE CODE_00EB19
                      LDA.B #$02
                      TRB.W WallrunningType
                      RTS

ADDR_00EB42:          LDA.W WallrunningType
                      AND.B #$01
                      TAY
CODE_00EB48:          LDA.W DATA_00EABB,Y
                      STA.B PlayerXSpeed
                      TYA
                      ASL A
                      TAY
                      REP #$20                                  ; A->16
                      LDA.B PlayerXPosNext
                      CLC
                      ADC.W DATA_00EABD,Y
                      STA.B PlayerXPosNext
                      LDA.W #$0008
                      LDY.B Powerup
                      BEQ +
                      LDA.W #$0010
                    + CLC
                      ADC.B PlayerYPosNext
                      STA.B PlayerYPosNext
                      SEP #$20                                  ; A->8
                      LDA.B #$24
                      STA.B PlayerInAir
                      LDA.B #$E0
                      STA.B PlayerYSpeed
CODE_00EB73:          STZ.W WallrunningType
Return00EB76:         RTS

CODE_00EB77:          LDX.B #$00
                      LDA.B Powerup
                      BEQ +
                      LDA.B PlayerIsDucking
                      BNE +
                      LDX.B #$18
                    + LDA.W PlayerRidingYoshi
                      BEQ +
                      TXA
                      CLC
                      ADC.B #$30
                      TAX
                    + LDA.B PlayerXPosNext
                      AND.B #$0F
                      TAY
                      CLC
                      ADC.B #$08
                      AND.B #$0F
                      STA.B PlayerXPosInBlock
                      STZ.B PlayerBlockXSide
                      CPY.B #$08
                      BCC +
                      TXA
                      ADC.B #$0B
                      TAX
                      INC.B PlayerBlockXSide
                    + LDA.B PlayerYPosInBlock
                      CLC
                      ADC.W DATA_00E8A4,X
                      AND.B #$0F
                      STA.B PlayerBlockMoveY
                      JSR CODE_00F44D
                      BEQ CODE_00EBDD
                      CPY.B #$11
                      BCC CODE_00EC24
                      CPY.B #$6E
                      BCC CODE_00EBC9
                      TYA
                      JSL CODE_00F04D
                      BCC CODE_00EC24
                      LDA.B #$01
                      TSB.B GraphicsCompPtr
                      BRA CODE_00EC24

CODE_00EBC9:          INX
                      INX
                      INX
                      INX
                      TYA
                      LDY.B #$00
                      CMP.B #$1E
                      BEQ +
                      CMP.B #$52
                      BEQ +
                      LDY.B #$02
                    + JMP CODE_00EC6F

CODE_00EBDD:          CPY.B #$9C
                      BNE CODE_00EBE8
                      LDA.W ObjectTileset
                      CMP.B #$01
                      BEQ CODE_00EC06
CODE_00EBE8:          CPY.B #$20
                      BEQ CODE_00EC01
                      CPY.B #$1F
                      BEQ CODE_00EBFD
                      LDA.W BluePSwitchTimer
                      BEQ CODE_00EC21
                      CPY.B #$28
                      BEQ CODE_00EC01
                      CPY.B #$27
                      BNE CODE_00EC21
CODE_00EBFD:          LDA.B Powerup
                      BNE CODE_00EC24
CODE_00EC01:          JSR CODE_00F443
                      BCS CODE_00EC24
CODE_00EC06:          LDA.B GraphicsUncompPtr+2
                      BNE CODE_00EC24
                      LDA.B byetudlrFrame
                      AND.B #$08
                      BEQ CODE_00EC24
                      LDA.B #!BGM_KEYHOLE                       ; \ Play sound effect
                      STA.W SPCIO3                              ; /
                      JSR CODE_00D273
                      LDA.B #$0D
                      STA.B PlayerAnimation
                      JSR NoButtons
                      BRA CODE_00EC24

CODE_00EC21:          JSR CODE_00F28C
CODE_00EC24:          JSR CODE_00F44D
                      BEQ CODE_00EC35
                      CPY.B #$11
                      BCC CODE_00EC3A
                      CPY.B #$6E
                      BCS CODE_00EC3A
                      INX
                      INX
                      BRA CODE_00EC4E

CODE_00EC35:          LDA.B #$10
                      JSR CODE_00F2C9
CODE_00EC3A:          JSR CODE_00F44D
                      BNE CODE_00EC46
                      LDA.B #$08
                      JSR CODE_00F2C9
                      BRA CODE_00EC8A

CODE_00EC46:          CPY.B #$11
                      BCC CODE_00EC8A
                      CPY.B #$6E
                      BCS CODE_00EC8A
CODE_00EC4E:          LDA.B PlayerDirection
                      CMP.B PlayerBlockXSide
                      BEQ +
                      JSR CODE_00F3C4
                      PHX
                      JSR CODE_00F267
                      LDY.W Map16TileNumber                     ; Current MAP16 tile number
                      PLX
                    + LDA.B #$03
                      STA.W PlayerPoseLenTimer
                      LDY.B PlayerBlockXSide
                      LDA.B PlayerXPosNext
                      AND.B #$0F
                      CMP.W DATA_00E911,Y
                      BEQ CODE_00EC8A
CODE_00EC6F:          LDA.W NoteBlockActive
                      BEQ CODE_00EC7B
                      LDA.W Map16TileNumber
                      CMP.B #$52
                      BEQ CODE_00EC8A
CODE_00EC7B:          LDA.W DATA_00E90A,Y
                      TSB.B PlayerBlockedDir
                      AND.B #$03
                      TAY
                      LDA.W Map16TileNumber                     ; Current MAP16 tile number
                      JSL CODE_00F127
CODE_00EC8A:          JSR CODE_00F44D
                      BNE CODE_00ECB1
                      LDA.B #$02
                      JSR CODE_00F2C2
                      LDY.B PlayerYSpeed
                      BPL CODE_00ECA3
                      LDA.W Map16TileNumber                     ; Current MAP16 tile number
                      CMP.B #$21
                      BCC CODE_00ECA3
                      CMP.B #$25
                      BCC +
CODE_00ECA3:          JMP CODE_00ED4A

                    + SEC
                      SBC.B #$04
                      LDY.B #$00
                      JSL CODE_00F17F
                      BRA CODE_00ED0D

CODE_00ECB1:          CPY.B #$11
                      BCC CODE_00ECA3
                      CPY.B #$6E
                      BCC CODE_00ECFA
                      CPY.B #$D8
                      BCC CODE_00ECDA
                      REP #$20                                  ; A->16
                      LDA.B TouchBlockYPos
                      CLC
                      ADC.W #$0010
                      STA.B TouchBlockYPos
                      JSR CODE_00F461
                      BEQ CODE_00ECF8
                      CPY.B #$6E
                      BCC CODE_00ED4A
                      CPY.B #$D8
                      BCS CODE_00ED4A
                      LDA.B PlayerBlockMoveY
                      SBC.B #$0F
                      STA.B PlayerBlockMoveY
CODE_00ECDA:          TYA
                      SEC
                      SBC.B #$6E
                      TAY
                      REP #$20                                  ; A->16
                      LDA.B [SlopesPtr],Y
                      AND.W #$00FF
                      ASL A
                      ASL A
                      ASL A
                      ASL A
                      SEP #$20                                  ; A->8
                      ORA.B PlayerXPosInBlock
                      REP #$10                                  ; XY->16
                      TAY
                      LDA.W DATA_00E632,Y
                      SEP #$10                                  ; XY->8
                      BMI CODE_00ED0F
CODE_00ECF8:          BRA CODE_00ED4A

CODE_00ECFA:          LDA.B #$02
                      JSR CODE_00F3E9
                      TYA
                      LDY.B #$00
                      JSL CODE_00F127
                      LDA.W Map16TileNumber                     ; Current MAP16 tile number
                      CMP.B #$1E                                ; \ If block is turn block, branch to $ED3B
                      BEQ CODE_00ED3B                           ; /
CODE_00ED0D:          LDA.B #$F0
CODE_00ED0F:          CLC
                      ADC.B PlayerBlockMoveY
                      BPL CODE_00ED4A
                      CMP.B #$F9
                      BCS CODE_00ED28
                      LDY.B PlayerInAir
                      BNE CODE_00ED28
                      LDA.B PlayerBlockedDir
                      AND.B #$FC
                      ORA.B #$09
                      STA.B PlayerBlockedDir
                      STZ.B PlayerXSpeed
                      BRA CODE_00ED3B

CODE_00ED28:          LDY.B PlayerInAir
                      BEQ +
                      EOR.B #$FF
                      CLC
                      ADC.B PlayerYPosNext
                      STA.B PlayerYPosNext
                      BCC +
                      INC.B PlayerYPosNext+1
                    + LDA.B #$08
                      TSB.B PlayerBlockedDir
CODE_00ED3B:          LDA.B PlayerYSpeed
                      BPL CODE_00ED4A
                      STZ.B PlayerYSpeed
                      LDA.W SPCIO0                              ; / Play sound effect
                      BNE CODE_00ED4A
                      INC A                                     ; play bonk only if no other sound was queued
                      STA.W SPCIO0                              ; / Play sound effect
CODE_00ED4A:          JSR CODE_00F44D
                      BNE +
                      JMP CODE_00EDDB

                    + CPY.B #$6E
                      BCS +
                      LDA.B #$03
                      JSR CODE_00F3E9
                      JMP CODE_00EDF7

                    + CPY.B #$D8
                      BCC CODE_00ED86
                      CPY.B #$FB
                      BCC +
                      JMP CODE_00F629

                    + REP #$20                                  ; A->16
                      LDA.B TouchBlockYPos
                      SEC
                      SBC.W #$0010
                      STA.B TouchBlockYPos
                      JSR CODE_00F461
                      BEQ CODE_00EDE9
                      CPY.B #$6E
                      BCC CODE_00EDE9
                      CPY.B #$D8
                      BCS CODE_00EDE9
                      LDA.B PlayerYPosInBlock
                      ADC.B #$10
                      STA.B PlayerYPosInBlock
CODE_00ED86:          LDA.W ObjectTileset
                      CMP.B #$03
                      BEQ CODE_00ED91
                      CMP.B #$0E
                      BNE CODE_00ED95
CODE_00ED91:          CPY.B #$D2
                      BCS CODE_00EDE9
CODE_00ED95:          TYA
                      SEC
                      SBC.B #$6E
                      TAY
                      LDA.B [SlopesPtr],Y
                      PHA
                      REP #$20                                  ; A->16
                      AND.W #$00FF
                      ASL A
                      ASL A
                      ASL A
                      ASL A
                      SEP #$20                                  ; A->8
                      ORA.B PlayerXPosInBlock
                      PHX
                      REP #$10                                  ; XY->16
                      TAX
                      LDA.B PlayerYPosInBlock
                      SEC
                      SBC.W DATA_00E632,X
                      BPL +
                      INC.W PlayerIsOnGround
                    + SEP #$10                                  ; XY->8
                      PLX
                      PLY
                      CMP.W DATA_00E51C,Y
                      BCS CODE_00EDE9
                      STA.B PlayerBlockMoveY
                      STZ.B PlayerYPosInBlock
                      JSR CODE_00F005
                      CPY.B #$1C
                      BCC +
                      LDA.B #$08
                      STA.W SkidTurnTimer
                      JMP CODE_00EED1

                    + JSR CODE_00EFBC
                      JMP CODE_00EE85

CODE_00EDDB:          CPY.B #$05
                      BNE CODE_00EDE4
                      JSR CODE_00F629
                      BRA CODE_00EDE9

CODE_00EDE4:          LDA.B #$04
                      JSR CODE_00F2C2
CODE_00EDE9:          JSR CODE_00F44D
                      BNE CODE_00EDF3
                      JSR CODE_00F309
                      BRA CODE_00EE1D

CODE_00EDF3:          CPY.B #$6E
                      BCS CODE_00EE1D
CODE_00EDF7:          LDA.B PlayerYSpeed
                      BMI Return00EE39
                      LDA.W ObjectTileset
                      CMP.B #$03
                      BEQ CODE_00EE06
                      CMP.B #$0E
                      BNE CODE_00EE11
CODE_00EE06:          LDY.W Map16TileNumber                     ; $ED3B
                      CPY.B #$59
                      BCC CODE_00EE11
                      CPY.B #$5C
                      BCC CODE_00EE1D
CODE_00EE11:          LDA.B PlayerYPosInBlock
                      AND.B #$0F
                      STZ.B PlayerYPosInBlock
                      CMP.B #$08
                      STA.B PlayerBlockMoveY
                      BCC CODE_00EE3A
CODE_00EE1D:          LDA.W StandOnSolidSprite                  ; \ If Mario isn't on a sprite platform,
                      BEQ +                                     ; / branch to $EE2D
                      LDA.B PlayerYSpeed                        ; \ If Mario is moving up,
                      BMI +                                     ; / branch to $EE2D
                      STZ.B GraphicsUncompPtr+1
                      LDY.B #$20
                      JMP CODE_00EEE1

                    + LDA.B PlayerBlockedDir                    ; \
                      AND.B #$04                                ; |If Mario is on an edge or in air,
                      ORA.B PlayerInAir                         ; |branch to $EE39
                      BNE Return00EE39                          ; /
CODE_00EE35:          LDA.B #$24                                ; \ Set "In air" to x24 (falling)
                      STA.B PlayerInAir                         ; /
Return00EE39:         RTS

CODE_00EE3A:          LDY.W Map16TileNumber                     ; Current MAP16 tile number
                      LDA.W ObjectTileset                       ; Tileset
                      CMP.B #$02                                ; \ If tileset is "Rope 1",
                      BEQ CODE_00EE48                           ; / branch to $EE48
                      CMP.B #$08                                ; \ If tileset isn't "Rope 3",
                      BNE CODE_00EE57                           ; / branch to $EE57
CODE_00EE48:          TYA                                       ; \
                      SEC                                       ; |If the current tile isn't Rope 3's "Conveyor rope",
                      SBC.B #$0C                                ; |branch to $EE57
                      CMP.B #$02                                ; |
                      BCS CODE_00EE57                           ; /
                      ASL A
                      TAX
                      JSR CODE_00EFCD
                      BRA CODE_00EE83

CODE_00EE57:          JSR CODE_00F267
                      LDY.B #$03
                      LDA.W Map16TileNumber                     ; Current MAP16 tile number
                      CMP.B #$1E                                ; \ If block isn't "Turn block",
                      BNE CODE_00EE78                           ; / branch to $EE78
                      LDX.B GraphicsUncompPtr+2
                      BEQ CODE_00EE83
                      LDX.B Powerup
                      BEQ CODE_00EE83
                      LDX.W SpinJumpFlag
                      BEQ CODE_00EE83
                      LDA.B #$21
                      JSL CODE_00F17F
                      BRA CODE_00EE1D

CODE_00EE78:          CMP.B #$32                                ; \ If block isn't "Brown block",
                      BNE +                                     ; / branch to $EE7F
                      STZ.W BlockSnakeActive
                    + JSL CODE_00F120
CODE_00EE83:          LDY.B #$20
CODE_00EE85:          LDA.B PlayerYSpeed                        ; \ If Mario isn't moving up,
                      BPL CODE_00EE8F                           ; / branch to $EE8F
                      LDA.B GraphicsUncompPtr
                      CMP.B #$02
                      BCC Return00EE39
CODE_00EE8F:          LDX.W SwitchPalacePressed
                      BEQ CODE_00EED1
                      DEX
                      TXA
                      AND.B #$03
                      BEQ CODE_00EEAA
                      CMP.B #$02
                      BCS CODE_00EED1
                      REP #$20                                  ; A->16
                      LDA.B TouchBlockXPos
                      SEC
                      SBC.W #$0010
                      STA.B TouchBlockXPos
                      SEP #$20                                  ; A->8
CODE_00EEAA:          TXA
                      LSR A
                      LSR A
                      TAX
                      LDA.W SwitchBlockFlags,X                  ; \ If switch block is already active,
                      BNE CODE_00EED1                           ; / branch to $EED1
                      INC A                                     ; \ Activate switch block
                      STA.W SwitchBlockFlags,X                  ; /
                      STA.W SwitchPalaceColor
                      PHY
                      STX.W BigSwitchPressTimer
                      JSR FlatPalaceSwitch
                      PLY
                      LDA.B #!BGM_LEVELCLEAR
                      STA.W SPCIO2                              ; / Change music
                      LDA.B #$FF                                ; \
                      STA.W MusicBackup                         ; / Set music to xFF
                      LDA.B #$08
                      STA.W EndLevelTimer
CODE_00EED1:          INC.W PlayerIsOnGround
                      LDA.B PlayerYPosNext
                      SEC
                      SBC.B PlayerBlockMoveY
                      STA.B PlayerYPosNext
                      LDA.B PlayerYPosNext+1
                      SBC.B PlayerYPosInBlock
                      STA.B PlayerYPosNext+1
CODE_00EEE1:          LDA.W DATA_00E53D,Y
                      BNE CODE_00EEEF
                      LDX.W PlayerSlopePose
                      BEQ CODE_00EF05
                      LDX.B PlayerXSpeed
                      BEQ CODE_00EF02
CODE_00EEEF:          STA.W CurrentSlope
                      LDA.B byetudlrHold
                      AND.B #$04
                      BEQ CODE_00EF05
                      LDA.W IsCarryingItem
                      ORA.W PlayerSlopePose
                      BNE CODE_00EF05
                      LDX.B #$1C
CODE_00EF02:          STX.W PlayerSlopePose
CODE_00EF05:          LDX.W DATA_00E4B9,Y
                      STX.W SlopeType
                      CPY.B #$1C
                      BCS CODE_00EF38
                      LDA.B PlayerXSpeed
                      BEQ CODE_00EF31
                      LDA.W DATA_00E53D,Y
                      BEQ CODE_00EF31
                      EOR.B PlayerXSpeed
                      BPL CODE_00EF31
                      STX.W PlayerPoseLenTimer
                      LDA.B PlayerXSpeed
                      BPL +
                      EOR.B #$FF
                      INC A
                    + CMP.B #con($28,$28,$28,$34,$34)
                      BCC CODE_00EF2F
                      LDA.W DATA_00E4FB,Y
                      BRA CODE_00EF60

CODE_00EF2F:          LDY.B #$20
CODE_00EF31:          LDA.B PlayerYSpeed
                      CMP.W DATA_00E4DA,Y
                      BCC +
CODE_00EF38:          LDA.W DATA_00E4DA,Y
                    + LDX.B GraphicsUncompPtr+1
                      BPL CODE_00EF60
                      INC.W Layer2Touched
                      PHA
                      REP #$20                                  ; A->16
                      LDA.W Layer2DYPos
                      AND.W #$FF00
                      BPL +
                      ORA.W #$00FF
                    + XBA
                      EOR.W #$FFFF
                      INC A
                      CLC
                      ADC.B PlayerXPosNext
                      STA.B PlayerXPosNext
                      SEP #$20                                  ; A->8
                      PLA
                      CLC
                      ADC.B #$28
CODE_00EF60:          STA.B PlayerYSpeed
                      TAX
                      BPL +
                      INC.W PlayerIsOnGround
                    + STZ.W StandingOnCage
                      STZ.B PlayerInAir
                      STZ.B PlayerIsClimbing
                      STZ.W BouncingOnBoard
                      STZ.W SpinJumpFlag
                      LDA.B #$04
                      TSB.B PlayerBlockedDir
                      LDY.W FlightPhase
                      BNE CODE_00EF99
                      LDA.W PlayerRidingYoshi
                      BEQ +
                      LDA.B GraphicsUncompPtr+2
                      BEQ +
                      LDA.W YoshiCanStomp                       ; \ If Yoshi has stomp ability,
                      BEQ +                                     ; |
                      JSL YoshiStompRoutine                     ; | Run routine
                      LDA.B #!SFX_YOSHISTOMP                    ; | Play sound effect
                      STA.W SPCIO3                              ; /
                    + STZ.W SpriteStompCounter
                      RTS

CODE_00EF99:          STZ.W SpriteStompCounter
                      STZ.W FlightPhase
                      CPY.B #$05
                      BCS CallGroundPound
                      LDA.B Powerup
                      CMP.B #$02
                      BNE +
                      SEC
                      ROR.W PlayerSlopePose
                    + RTS

CallGroundPound:      LDA.B GraphicsUncompPtr+2
                      BEQ +
                      JSL GroundPound
                      LDA.B #!SFX_KAPOW                         ; \ Play sound effect
                      STA.W SPCIO3                              ; /
                    + RTS

CODE_00EFBC:          LDX.W Map16TileNumber
                      CPX.B #$CE
                      BCC +
                      CPX.B #$D2
                      BCS +
                      TXA
                      SEC
                      SBC.B #$CC
                      ASL A
                      TAX
CODE_00EFCD:          LDA.B TrueFrame
                      AND.B #$03
                      BNE +
                      REP #$20                                  ; A->16
                      LDA.B PlayerXPosNext
                      CLC
                      ADC.W DATA_00E913,X
                      STA.B PlayerXPosNext
                      LDA.B PlayerYPosNext
                      CLC
                      ADC.W DATA_00E91F,X
                      STA.B PlayerYPosNext
                      SEP #$20                                  ; A->8
                    + RTS

CODE_00EFE8:          JSR CODE_00F44D
                      BNE +
                      JMP CODE_00F309

                    + CPY.B #$11
                      BCC +
                      CPY.B #$6E
                      BCS +
                      TYA
                      LDY.B #$00
                      JSL CODE_00F160
                      PLA
                      PLA
                      JMP ADDR_00EB42

                    + RTS

CODE_00F005:          TYA
                      SEC
                      SBC.B #$0E
                      CMP.B #$02
                      BCS Return00F04C
                      EOR.B #$01
                      CMP.B PlayerDirection
                      BNE Return00F04C
                      TAX
                      LSR A
                      LDA.B PlayerXPosInBlock
                      BCC +
                      EOR.B #$0F
                    + CMP.B #con($08,$08,$08,$09,$09)
                      BCS Return00F04C
                      LDA.W PlayerRidingYoshi
                      BEQ +
                      LDA.B #!SFX_SPRING
                      STA.W SPCIO3                              ; / Play sound effect
                      LDA.B #$80
                      STA.B PlayerYSpeed
                      STA.W BouncingOnBoard
                      PLA
                      PLA
                      JMP CODE_00EE35

                    + LDA.B PlayerXSpeed
                      SEC
                      SBC.W DATA_00EAB9,X
                      EOR.W DATA_00EAB9,X
                      BMI Return00F04C
                      LDA.W IsCarryingItem
                      ORA.B PlayerIsDucking
                      BNE Return00F04C
                      INX
                      INX
                      STX.W WallrunningType
Return00F04C:         RTS

CODE_00F04D:          PHX
                      LDX.B #$19
CODE_00F050:          CMP.L DATA_00EAC1,X
                      BEQ CODE_00F05A
                      DEX
                      BPL CODE_00F050
                      CLC
CODE_00F05A:          PLX
                      RTL


DATA_00F05C:          db $01,$05,$01,$02,$01,$01,$00,$00
                      db $00,$00,$00,$00,$00,$06,$02,$02
                      db $02,$02,$02,$02,$02,$02,$02,$02
                      db $02,$03,$03,$04,$02,$02,$02,$01
                      db $01,$07,$11,$10

DATA_00F080:          db $80,$00,$00,$1E,$00,$00,$05,$09
                      db $06,$81,$0E,$0C,$14,$00,$05,$09
                      db $06,$07,$0E,$0C,$16,$18,$1A,$1A
                      db $00,$09,$00,$00,$FF,$0C,$0A,$00
                      db $00,$00,$08,$02

DATA_00F0A4:          db $0C,$08,$0C,$08,$0C,$0F,$08,$08
                      db $08,$08,$08,$08,$08,$08,$08,$08
                      db $08,$08,$08,$08,$08,$08,$08,$08
                      db $08,$03,$03,$08,$08,$08,$08,$08
                      db $08,$04,$08,$08

DATA_00F0C8:          db $0E,$13,$0E,$0D,$0E,$10,$0D,$0D
                      db $0D,$0D,$0A,$0D,$0D,$0C,$0D,$0D
                      db $0D,$0D,$0B,$0D,$0D,$16,$0D,$0D
                      db $0D,$11,$11,$12,$0D,$0D,$0D,$0E
                      db $0F,$0C,$0D,$0D

DATA_00F0EC:          db $08,$01,$02,$04,$ED,$F6,$00,$7D
                      db $BE,$00,$6F,$B7

DATA_00F0F8:          db $40,$50,$00,$70,$80,$00,$A0,$B0
DATA_00F100:          db $05,$09,$06,$05,$09,$06,$05,$09
                      db $06,$05,$09,$06,$05,$09,$06,$05
                      db $07,$0A,$10,$07,$0A,$10,$07,$0A
                      db $10,$07,$0A,$10,$07,$0A,$10,$07

CODE_00F120:          XBA
                      LDA.W PlayerRidingYoshi
                      BNE CODE_00F15F
                      XBA
CODE_00F127:          CMP.B #$2F
                      BEQ CODE_00F154
                      CMP.B #$59
                      BCC CODE_00F144
                      CMP.B #$5C
                      BCS CODE_00F140
                      XBA
                      LDA.W ObjectTileset
                      CMP.B #$05
                      BEQ CODE_00F154
                      CMP.B #$0D
                      BEQ CODE_00F154
                      XBA
CODE_00F140:          CMP.B #$5D
                      BCC CODE_00F14C
CODE_00F144:          CMP.B #$66
                      BCC CODE_00F160
                      CMP.B #$6A
                      BCS CODE_00F160
CODE_00F14C:          XBA
                      LDA.W ObjectTileset
                      CMP.B #$01
                      BNE CODE_00F15F
CODE_00F154:          PHB
                      LDA.B #$01
                      PHA
                      PLB
                      JSL HurtMario
                      PLB
                      RTL

CODE_00F15F:          XBA
CODE_00F160:          SEC
                      SBC.B #$11
                      CMP.B #$1D
                      BCC CODE_00F17F
                      XBA
                      PHX
                      LDX.W ObjectTileset
                      LDA.L DATA_00A625,X
                      PLX
                      AND.B #$03
                      BEQ +
                      RTL

                    + XBA
                      SBC.B #$59
                      CMP.B #$02
                      BCS Return00F1F8
                      ADC.B #$22
CODE_00F17F:          PHX
                      PHA
                      TYX
                      LDA.L DATA_00F0EC,X
                      PLX
                      AND.L DATA_00F0A4,X
                      BEQ CODE_00F1F6
                      STY.B _6
                      LDA.L DATA_00F0C8,X
                      STA.B _7
                      LDA.L DATA_00F05C,X
                      STA.B _4
                      LDA.L DATA_00F080,X
                      BPL CODE_00F1BA
                      CMP.B #$FF
                      BNE CODE_00F1AE
                      LDA.B #$05
                      LDY.W GreenStarBlockCoins
                      BEQ CODE_00F1D0
                      BRA CODE_00F1CE

CODE_00F1AE:          LSR A
                      LDA.B TouchBlockXPos
                      ROR A
                      LSR A
                      LSR A
                      LSR A
                      TAX
                      LDA.L DATA_00F100,X
CODE_00F1BA:          LSR A
                      BCC CODE_00F1D0
                      CMP.B #$03
                      BEQ CODE_00F1C9
                      LDY.B Powerup
                      BNE CODE_00F1D0
                      LDA.B #$01
                      BRA CODE_00F1D0

CODE_00F1C9:          LDY.W InvinsibilityTimer                  ; \ Branch if Mario has star
                      BNE CODE_00F1D0                           ; /
CODE_00F1CE:          LDA.B #$06
CODE_00F1D0:          STA.B _5
                      CMP.B #$05
                      BNE +
                      LDA.B #$16
                      STA.B _7
                    + TAY
                      LDA.B #$0F
                      TRB.B TouchBlockXPos
                      TRB.B TouchBlockYPos
                      CPY.B #$06
                      BNE CODE_00F1EC
                      LDY.W ObjectTileset
                      CPY.B #$04
                      BEQ +
CODE_00F1EC:          PHB
                      LDA.B #$02
                      PHA
                      PLB
                      JSL CODE_028752
                      PLB
CODE_00F1F6:          PLX
                      CLC
Return00F1F8:         RTL

                    + LDA.B TouchBlockYPos+1
                      LSR A
                      LDA.B TouchBlockYPos
                      AND.B #$C0
                      ROL A
                      ROL A
                      ROL A
                      TAY
                      LDA.B TouchBlockXPos
                      LSR A
                      LSR A
                      LSR A
                      LSR A
                      TAX
                      LDA.W PBalloonInflating,Y
                      ORA.L DATA_00F0EC,X
                      LDX.W PBalloonInflating,Y
                      STA.W PBalloonInflating,Y
                      CMP.B #$FF
                      BNE CODE_00F226
                      LDA.B #$05
                      STA.B _5
CODE_00F220:          LDA.B #$17
                      STA.B _7
                      BRA CODE_00F1EC

CODE_00F226:          LDA.W DidPlayBonusGame
                      BNE CODE_00F236
                      TXA
                      BEQ +
                      LDA.B #$02
                    + EOR.B #$03
                      AND.B TrueFrame
                      BNE CODE_00F220
CODE_00F236:          LDA.B #!SFX_WRONG
                      STA.W SPCIO3                              ; / Play sound effect
                      PHY
                      STZ.B _5
                      PHB
                      LDA.B #$02                                ; \ Set data bank = $02
                      PHA                                       ; |
                      PLB
                      JSL CODE_028752
                      PLB
                      PLY
                      LDX.B #$07
                      LDA.W PBalloonInflating,Y
CODE_00F24E:          LSR A
                      BCS +
                      PHA
                      LDA.B #$0D                                ; \ Block to generate = Used block
                      STA.B Map16TileGenerate                   ; /
                      LDA.L DATA_00F0F8,X
                      STA.B TouchBlockXPos
                      JSL GenerateTile
                      PLA
                    + DEX
                      BPL CODE_00F24E
                      JMP CODE_00F1F6

CODE_00F267:          CPY.B #$2E
                      BNE Return00F28B
                      BIT.B byetudlrFrame
                      BVC Return00F28B
                      LDA.W IsCarryingItem
                      ORA.W PlayerRidingYoshi
                      BNE Return00F28B
                      LDA.B #$02
                      PHA
                      PLB
                      JSL CODE_02862F
                      BMI +
                      LDA.B #$02                                ; \ Block to generate = #$02
                      STA.B Map16TileGenerate                   ; /
                      JSL GenerateTile
                    + PHK
                      PLB
Return00F28B:         RTS

CODE_00F28C:          TYA
                      SEC
                      SBC.B #$6F
                      CMP.B #$04
                      BCS CODE_00F2C0
                      CMP.W OneUpCheckpoints
                      BEQ CODE_00F2A8
                      INC A
                      CMP.W OneUpCheckpoints
                      BEQ +
                      LDA.W OneUpCheckpoints
                      CMP.B #$04
                      BCS +
                      LDA.B #$FF
CODE_00F2A8:          INC A
                      STA.W OneUpCheckpoints
                      CMP.B #$04
                      BNE +
                      PHX
                      JSL TriggerInivis1Up
                      JSR CODE_00F3B2
                      ORA.W Checkpoint1upCollected,Y
                      STA.W Checkpoint1upCollected,Y
                      PLX
                    + RTS

CODE_00F2C0:          LDA.B #$01
CODE_00F2C2:          CPY.B #$06
                      BCS CODE_00F2C9
                      TSB.B GraphicsCompPtr
                      RTS

CODE_00F2C9:          CPY.B #$38
                      BNE CODE_00F2EE
                      LDA.B #$02                                ; \ Block to generate = #$02
                      STA.B Map16TileGenerate                   ; /
                      JSL GenerateTile
                      JSR CODE_00FD5A
                      LDA.W DisableMidway
                      BEQ +
                      JSR CODE_00CA2B
                    + LDA.B Powerup
                      BNE +
                      LDA.B #$01
                      STA.B Powerup
                    + LDA.B #!SFX_MIDWAY
                      STA.W SPCIO0                              ; / Play sound effect
                      RTS

CODE_00F2EE:          CPY.B #$06
                      BEQ CODE_00F2FC
                      CPY.B #$07
                      BCC CODE_00F309
                      CPY.B #$1D
                      BCS CODE_00F309
                      ORA.B #$80
CODE_00F2FC:          CMP.B #$01
                      BNE +
                      ORA.B #$18
                    + TSB.B GraphicsCompPtr+1
                      LDA.B PlayerBlockXSide
                      STA.B GraphicsCompPtr+2
                      RTS

CODE_00F309:          CPY.B #$2F
                      BCS CODE_00F311
                      CPY.B #$2A
                      BCS CODE_00F32B
CODE_00F311:          CPY.B #$6E
                      BNE Return00F376
                      LDA.B #$0F
                      JSL CODE_00F38A
                      INC.W MoonCounter
                      PHX
                      JSR CODE_00F3B2
                      ORA.W MoonCollected,Y
                      STA.W MoonCollected,Y
                      PLX
                      BRA CODE_00F36B

CODE_00F32B:          BNE CODE_00F332                           ;YOSHI COIN HANDLER
                      LDA.W BluePSwitchTimer
                      BEQ Return00F376
CODE_00F332:          CPY.B #$2D
                      BEQ CODE_00F33F
                      BCC CODE_00F367
                      LDA.B TouchBlockYPos
                      SEC
                      SBC.B #$10
                      STA.B TouchBlockYPos
CODE_00F33F:          JSL CODE_00F377
                      INC.W DragonCoinsShown
                      LDA.W DragonCoinsShown
                      CMP.B #$05
                      BCC +
                      PHX
                      JSR CODE_00F3B2
                      ORA.W AllDragonCoinsCollected,Y
                      STA.W AllDragonCoinsCollected,Y
                      PLX
                    + LDA.B #!SFX_DRAGONCOIN
                      STA.W SPCIO0                              ; / Play sound effect
                      LDA.B #$01
                      JSL CODE_05B330
                      LDY.B #$18
                      BRA +

CODE_00F367:          JSL CODE_05B34A
CODE_00F36B:          LDY.B #$01                                ; \ Block to generate = #$01
                    + STY.B Map16TileGenerate                   ; /
                      JSL GenerateTile
                      JSR CODE_00FD5A
Return00F376:         RTS

CODE_00F377:          LDA.W DragonCoinsCollected
                      INC.W DragonCoinsCollected
                      CLC
                      ADC.B #$09
                      CMP.B #$0D
                      BCC +
                      LDA.B #$0D
                    + BRA CODE_00F38A

CODE_00F388:          LDA.B #$0D
CODE_00F38A:          PHA
                      JSL CODE_02AD34
                      PLA
                      STA.W ScoreSpriteNumber,Y
                      LDA.B PlayerXPosNext
                      STA.W ScoreSpriteXPosLow,Y
                      LDA.B PlayerXPosNext+1
                      STA.W ScoreSpriteXPosHigh,Y
                      LDA.B PlayerYPosNext
                      STA.W ScoreSpriteYPosLow,Y
                      LDA.B PlayerYPosNext+1
                      STA.W ScoreSpriteYPosHigh,Y
                      LDA.B #$30
                      STA.W ScoreSpriteTimer,Y
                      LDA.B #$00
                      STA.W ScoreSpriteLayer,Y
                      RTL

CODE_00F3B2:          LDA.W TranslevelNo
                      LSR A
                      LSR A
                      LSR A
                      TAY
                      LDA.W TranslevelNo
                      AND.B #$07
                      TAX
                      LDA.L DATA_05B35B,X
                      RTS

CODE_00F3C4:          CPY.B #$3F
                      BNE Return00F376
                      LDY.B GraphicsUncompPtr+2
                      BEQ +
                      JMP CODE_00F43F

                    + PHX
                      TAX
                      LDA.B PlayerXPosNext
                      TXY
                      BEQ +
                      EOR.B #$FF
                      INC A
                    + AND.B #$0F
                      ASL A
                      CLC
                      ADC.B #$20
                      LDY.B #$05
                      BRA CODE_00F40A


DATA_00F3E3:          db $0A,$FF

DATA_00F3E5:          db $02,$01,$08,$04

CODE_00F3E9:          XBA
                      TYA
                      SEC
                      SBC.B #$37
                      CMP.B #$02
                      BCS Return00F442
                      TAY
                      LDA.B PlayerXPosInBlock
                      SBC.W DATA_00F3E3,Y
                      CMP.B #$05
                      BCS CODE_00F43F
                      PHX
                      XBA
                      TAX
                      LDA.B #$20
                      LDY.W PlayerRidingYoshi
                      BEQ +
                      LDA.B #$30
                    + LDY.B #$06
CODE_00F40A:          STA.B PipeTimer
                      LDA.B byetudlrHold
                      AND.W DATA_00F3E5,X
                      BEQ CODE_00F43E
                      STA.B SpriteLock
                      AND.B #$01
                      STA.B PlayerDirection
                      STX.B PlayerPipeAction
                      TXA
                      LSR A
                      TAX
                      BNE +
                      LDA.W IsCarryingItem
                      BEQ +
                      LDA.B PlayerDirection
                      EOR.B #$01
                      STA.B PlayerDirection
                      LDA.B #$08
                      STA.W FaceScreenTimer
                    + INX
                      STX.W YoshiInPipeSetting
                      STY.B PlayerAnimation
                      JSR NoButtons
                      LDA.B #!SFX_PIPE
                      STA.W SPCIO0                              ; / Play sound effect
CODE_00F43E:          PLX
CODE_00F43F:          LDY.W Map16TileNumber
Return00F442:         RTS

CODE_00F443:          LDA.B PlayerXPosNext
                      CLC
                      ADC.B #$04
                      AND.B #$0F
                      CMP.B #$08
                      RTS

CODE_00F44D:          INX
                      INX
                      REP #$20                                  ; A->16
                      LDA.B PlayerXPosNext
                      CLC
                      ADC.W DATA_00E830,X
                      STA.B TouchBlockXPos
                      LDA.B PlayerYPosNext
                      CLC
                      ADC.W DATA_00E89C,X
                      STA.B TouchBlockYPos
CODE_00F461:          JSR CODE_00F465
                      RTS

CODE_00F465:          SEP #$20                                  ; A->8
                      STZ.W SwitchPalacePressed
                      PHX
                      LDA.B GraphicsUncompPtr+1
                      BPL +
                      JMP CODE_00F4EC

                    + BNE CODE_00F4A6
                      REP #$20                                  ; A->16
                      LDA.B TouchBlockYPos
                      CMP.W #$01B0
                      SEP #$20                                  ; A->8
                      BCS CODE_00F4A0
                      AND.B #$F0
                      STA.B _0
                      LDX.B TouchBlockXPos+1
                      CPX.B LevelScrLength
                      BCS CODE_00F4A0
                      LDA.B TouchBlockXPos
                      LSR A
                      LSR A
                      LSR A
                      LSR A
                      ORA.B _0
                      CLC
                      ADC.L DATA_00BA60,X
                      STA.B _0
                      LDA.B TouchBlockYPos+1
                      ADC.L DATA_00BA9C,X
                      BRA CODE_00F4CD

CODE_00F4A0:          PLX
                      LDY.B #$25
CODE_00F4A3:          LDA.B #$00
                      RTS

CODE_00F4A6:          LDA.B TouchBlockXPos+1
                      CMP.B #$02
                      BCS CODE_00F4E7
                      LDX.B TouchBlockYPos+1
                      CPX.B LevelScrLength
                      BCS CODE_00F4E7
                      LDA.B TouchBlockYPos
                      AND.B #$F0
                      STA.B _0
                      LDA.B TouchBlockXPos
                      LSR A
                      LSR A
                      LSR A
                      LSR A
                      ORA.B _0
                      CLC
                      ADC.L DATA_00BA80,X
                      STA.B _0
                      LDA.B TouchBlockXPos+1
                      ADC.L DATA_00BABC,X
CODE_00F4CD:          STA.B _1
                      LDA.B #$7E
                      STA.B _2
                      LDA.B [_0]
                      STA.W Map16TileNumber
                      INC.B _2
                      PLX
                      LDA.B [_0]
                      JSL CODE_00F545
                      LDY.W Map16TileNumber
                      CMP.B #$00
                      RTS

CODE_00F4E7:          PLX
                      LDY.B #$25
                      BRA CODE_00F4A3

CODE_00F4EC:          ASL A
                      BNE CODE_00F51B
                      REP #$20                                  ; A->16
                      LDA.B TouchBlockYPos
                      CMP.W #$01B0
                      SEP #$20                                  ; A->8
                      BCS CODE_00F4E7
                      AND.B #$F0
                      STA.B _0
                      LDX.B TouchBlockXPos+1
                      CPX.B #$10
                      BCS CODE_00F4E7
                      LDA.B TouchBlockXPos
                      LSR A
                      LSR A
                      LSR A
                      LSR A
                      ORA.B _0
                      CLC
                      ADC.L DATA_00BA70,X
                      STA.B _0
                      LDA.B TouchBlockYPos+1
                      ADC.L DATA_00BAAC,X
                      BRA CODE_00F4CD

CODE_00F51B:          LDA.B TouchBlockXPos+1
                      CMP.B #$02
                      BCS CODE_00F4E7
                      LDX.B TouchBlockYPos+1
                      CPX.B #$0E
                      BCS CODE_00F4E7
                      LDA.B TouchBlockYPos
                      AND.B #$F0
                      STA.B _0
                      LDA.B TouchBlockXPos
                      LSR A
                      LSR A
                      LSR A
                      LSR A
                      ORA.B _0
                      CLC
                      ADC.L DATA_00BA8E,X
                      STA.B _0
                      LDA.B TouchBlockXPos+1
                      ADC.L DATA_00BACA,X
                      JMP CODE_00F4CD

CODE_00F545:          TAY
                      BNE CODE_00F577
                      LDY.W Map16TileNumber                     ; Load MAP16 tile number
                      CPY.B #$29                                ; \ If block isn't "Invisible POW ? block",
                      BNE PSwitchNotInvQBlk                     ; / branch to PSwitchNotInvQBlk
                      LDY.W BluePSwitchTimer
                      BEQ Return00F594
                      LDA.B #$24
                      STA.W Map16TileNumber
                      RTL

PSwitchNotInvQBlk:    CPY.B #$2B                                ; \ If block is "Coin",
                      BEQ PSwitchCoinBrown                      ; / branch to PSwitchCoinBrown
                      TYA
                      SEC
                      SBC.B #$EC
                      CMP.B #$10
                      BCS CODE_00F592
                      INC A
                      STA.W SwitchPalacePressed
                      BRA CODE_00F571

PSwitchCoinBrown:     LDY.W BluePSwitchTimer
                      BEQ Return00F594
CODE_00F571:          LDA.B #$32
                      STA.W Map16TileNumber
                      RTL

CODE_00F577:          LDY.W Map16TileNumber
                      CPY.B #$32
                      BNE CODE_00F584
                      LDY.W BluePSwitchTimer
                      BNE CODE_00F58D
                      RTL

CODE_00F584:          CPY.B #$2F
                      BNE Return00F594
                      LDY.W SilverPSwitchTimer
                      BEQ Return00F594
CODE_00F58D:          LDY.B #$2B
                      STY.W Map16TileNumber
CODE_00F592:          LDA.B #$00
Return00F594:         RTL

CODE_00F595:          REP #$20                                  ; A->16
                      LDA.W #$FF80
                      CLC
                      ADC.B Layer1YPos
                      CMP.B PlayerYPosNext
                      BMI +
                      STA.B PlayerYPosNext
                    + SEP #$20                                  ; A->8
                      LDA.B PlayerYPosScrRel+1
                      DEC A
                      BMI Return00F5B6
                      LDA.W YoshiHeavenFlag
                      BEQ +
                      JMP CODE_00C95B

                    + JSL CODE_00F60A
Return00F5B6:         RTS

HurtMario:            LDA.B PlayerAnimation                     ; \ Return if animation sequence activated
                      BNE Return00F628                          ; /
                      LDA.W IFrameTimer                         ; \ If flashing...
                      ORA.W InvinsibilityTimer                  ; | ...or have star...
                      ORA.W EndLevelTimer                       ; | ...or level ending...
                      BNE Return00F628                          ; / ...return
                      STZ.W GameCloudCoinCount
                      LDA.W WallrunningType
                      BEQ +
                      PHB
                      PHK
                      PLB
                      JSR ADDR_00EB42
                      PLB
                    + LDA.B Powerup                             ; \ If Mario is small, kill him
                      BEQ KillMario                             ; /
                      CMP.B #$02                                ; \ Branch if not Caped Mario
                      BNE PowerDown                             ; /
                      LDA.W FlightPhase                         ; \ Branch if not soaring
                      BEQ PowerDown                             ; /
                      LDY.B #!SFX_FLYHIT                        ; \ Break Mario out of soaring
                      STY.W SPCIO0                              ; | (Play sound effect)
                      LDA.B #$01                                ; | (Set spin jump flag)
                      STA.W SpinJumpFlag                        ; |
                      LDA.B #$30                                ; | (Set flashing timer)
                      STA.W IFrameTimer                         ; /
                      BRA CODE_00F622

PowerDown:            LDY.B #!SFX_PIPE                          ; \ Play sound effect
                      STY.W SPCIO0                              ; /
                      JSL CODE_028008
                      LDA.B #$01                                ; \ Set power down animation
                      STA.B PlayerAnimation                     ; /
                      STZ.B Powerup                             ; Mario status = Small
                      LDA.B #$2F
                      BRA +

KillMario:            LDA.B #$90                                ; \ Mario Y speed = #$90
                      STA.B PlayerYSpeed                        ; /
CODE_00F60A:          LDA.B #!BGM_DEATH                         ; \
                      STA.W SPCIO2                              ; / Change music
                      LDA.B #$FF
                      STA.W MusicBackup
                      LDA.B #$09                                ; \ Animation sequence = Kill Mario
                      STA.B PlayerAnimation                     ; /
                      STZ.W SpinJumpFlag                        ; Spin jump flag = 0
                      LDA.B #$30
                    + STA.W PlayerAniTimer                      ; Set hurt frame timer
                      STA.B SpriteLock                          ; set lock sprite timer
CODE_00F622:          STZ.W FlightPhase                         ; Cape status = 0
                      STZ.W Empty188A
Return00F628:         RTL

CODE_00F629:          JSL KillMario
NoButtons:            STZ.B byetudlrHold                        ; Zero RAM mirrors for controller Input
                      STZ.B byetudlrFrame
                      STZ.B axlr0000Hold
                      STZ.B axlr0000Frame
                      RTS

CODE_00F636:          REP #$20                                  ; A->16
                      LDX.B #$00
                      LDA.B _9
                      ORA.W #$0800
                      CMP.B _9
                      BEQ +
                      CLC
                    + AND.W #$F700
                      ROR A
                      LSR A
                      ADC.W #$2000
                      STA.W DynGfxTilePtr
                      CLC
                      ADC.W #$0200
                      STA.W DynGfxTilePtr+$0A
                      LDX.B #$00
                      LDA.B _A
                      ORA.W #$0800
                      CMP.B _A
                      BEQ +
                      CLC
                    + AND.W #$F700
                      ROR A
                      LSR A
                      ADC.W #$2000
                      STA.W DynGfxTilePtr+2
                      CLC
                      ADC.W #$0200
                      STA.W DynGfxTilePtr+$0C
                      LDA.B _B
                      AND.W #$FF00
                      LSR A
                      LSR A
                      LSR A
                      ADC.W #$2000
                      STA.W DynGfxTilePtr+4
                      CLC
                      ADC.W #$0200
                      STA.W DynGfxTilePtr+$0E
                      LDA.B _C
                      AND.W #$FF00
                      LSR A
                      LSR A
                      LSR A
                      ADC.W #$2000
                      STA.W DynGfxTile7FPtr
                      SEP #$20                                  ; A->8
                      LDA.B #$0A
                      STA.W PlayerGfxTileCount
                      RTS


DATA_00F69F:          db $64,$00,$7C,$00

DATA_00F6A3:          db $00,$00,$FF,$FF

DATA_00F6A7:          db $FD,$FF,$05,$00,$FA,$FF

DATA_00F6AD:          db $00,$00,$00,$00,$C0,$00

DATA_00F6B3:          db $90,$00,$60,$00,$00,$00,$00,$00
                      db $00,$00,$00,$00

DATA_00F6BF:          db $00,$00,$FE,$FF,$02,$00,$00,$00
                      db $FE,$FF,$02,$00

DATA_00F6CB:          db $00,$00,$20,$00

DATA_00F6CF:          db $D0,$00,$00,$00,$20,$00,$D0,$00
                      db $01,$00,$FF,$FF

CODE_00F6DB:          PHB
                      PHK
                      PLB
                      REP #$20                                  ; A->16
                      LDA.W CameraMoveTrigger
                      SEC
                      SBC.W #$000C
                      STA.W CameraLeftBuffer
                      CLC
                      ADC.W #$0018
                      STA.W CameraRightBuffer
                      LDA.W NextLayer1XPos
                      STA.B Layer1XPos
                      LDA.W NextLayer1YPos
                      STA.B Layer1YPos
                      LDA.W NextLayer2XPos
                      STA.B Layer2XPos
                      LDA.W NextLayer2YPos
                      STA.B Layer2YPos
                      LDA.B ScreenMode
                      LSR A
                      BCC +
                      JMP CODE_00F75C

                    + LDA.W #$00C0
                      JSR CODE_00F7F4
                      LDY.W HorizLayer1Setting
                      BEQ CODE_00F75A
                      LDY.B #$02
                      LDA.B PlayerXPosNext
                      SEC
                      SBC.B Layer1XPos
                      STA.B _0
                      CMP.W CameraMoveTrigger
                      BPL +
                      LDY.B #$00
                    + STY.B Layer1ScrollDir
                      STY.B Layer2ScrollDir
                      SEC
                      SBC.W CameraLeftBuffer,Y
                      BEQ CODE_00F75A
                      STA.B _2
                      EOR.W DATA_00F6A3,Y
                      BPL CODE_00F75A
                      JSR CODE_00F8AB
                      LDA.B _2
                      CLC
                      ADC.B Layer1XPos
                      BPL +
                      LDA.W #$0000
                    + STA.B Layer1XPos
                      LDA.B LastScreenHoriz
                      DEC A
                      XBA
                      AND.W #$FF00
                      BPL +
                      LDA.W #$0080
                    + CMP.B Layer1XPos
                      BPL CODE_00F75A
                      STA.B Layer1XPos
CODE_00F75A:          BRA CODE_00F79D

CODE_00F75C:          LDA.B LastScreenVert
                      DEC A
                      XBA
                      AND.W #$FF00
                      JSR CODE_00F7F4
                      LDY.W HorizLayer1Setting
                      BEQ CODE_00F79D
                      LDY.B #$00
                      LDA.B PlayerXPosNext
                      SEC
                      SBC.B Layer1XPos
                      STA.B _0
                      CMP.W CameraMoveTrigger
                      BMI +
                      LDY.B #$02
                    + SEC
                      SBC.W CameraLeftBuffer,Y
                      STA.B _2
                      EOR.W DATA_00F6A3,Y
                      BPL CODE_00F79D
                      JSR CODE_00F8AB
                      LDA.B _2
                      CLC
                      ADC.B Layer1XPos
                      BPL +
                      LDA.W #$0000
                    + CMP.W #$0101
                      BMI +
                      LDA.W #$0100
                    + STA.B Layer1XPos
CODE_00F79D:          LDY.W HorizLayer2Setting
                      BEQ CODE_00F7AA
                      LDA.B Layer1XPos
                      DEY
                      BEQ +
                      LSR A
                    + STA.B Layer2XPos
CODE_00F7AA:          LDY.W VertLayer2Setting
                      BEQ CODE_00F7C2
                      LDA.B Layer1YPos
                      DEY
                      BEQ +
                      LSR A
                      DEY
                      BEQ +
                      LSR A
                      LSR A
                      LSR A
                      LSR A
                    + CLC
                      ADC.W BackgroundVertOffset
                      STA.B Layer2YPos
CODE_00F7C2:          SEP #$20                                  ; A->8
                      LDA.B Layer1XPos
                      SEC
                      SBC.W NextLayer1XPos
                      STA.W Layer1DXPos
                      LDA.B Layer1YPos
                      SEC
                      SBC.W NextLayer1YPos
                      STA.W Layer1DYPos
                      LDA.B Layer2XPos
                      SEC
                      SBC.W NextLayer2XPos
                      STA.W Layer2DXPos
                      LDA.B Layer2YPos
                      SEC
                      SBC.W NextLayer2YPos
                      STA.W Layer2DYPos
                      LDX.B #$07
                    - LDA.B Layer1XPos,X
                      STA.W NextLayer1XPos,X
                      DEX
                      BPL -
                      PLB
                      RTL

CODE_00F7F4:          LDX.W VertLayer1Setting
                      BNE +
                      RTS

                    + STA.B _4
                      LDY.B #$00
                      LDA.B PlayerYPosNext
                      SEC
                      SBC.B Layer1YPos
                      STA.B _0
                      CMP.W #$0070
                      BMI +
                      LDY.B #$02
                    + STY.B Layer1ScrollDir
                      STY.B Layer2ScrollDir
                      SEC
                      SBC.W DATA_00F69F,Y
                      STA.B _2
                      EOR.W DATA_00F6A3,Y
                      BMI +
                      LDY.B #$02
                      STZ.B _2
                    + LDA.B _2
                      BMI CODE_00F82A
                      LDX.B #$00
                      STX.W ScreenScrollAtWill
                      BRA CODE_00F883

CODE_00F82A:          SEP #$20                                  ; A->8
                      LDA.W WallrunningType
                      CMP.B #$06
                      BCS +
                      LDA.W YoshiHasWingsGfx                    ; \ If winged Yoshi...
                      LSR A                                     ; |
                      ORA.W TakeoffTimer
                      ORA.B PlayerIsClimbing                    ; | ...or climbing
                      ORA.W PBalloonInflating
                      ORA.W PlayerInCloud
                      ORA.W BouncingOnBoard
                    + TAX
                      REP #$20                                  ; A->16
                      BNE CODE_00F869
                      LDX.W PlayerRidingYoshi
                      BEQ CODE_00F856
                      LDX.W YoshiHasWingsEvt                    ; \ Branch if 141E >= #$02
                      CPX.B #$02                                ; |
                      BCS CODE_00F869                           ; /
CODE_00F856:          LDX.B PlayerInWater
                      BEQ CODE_00F85E
                      LDX.B PlayerInAir
                      BNE CODE_00F869
CODE_00F85E:          LDX.W VertLayer1Setting
                      DEX
                      BEQ CODE_00F875
                      LDX.W VerticalScrollEnabled
                      BNE CODE_00F875
CODE_00F869:          STX.W VerticalScrollEnabled
                      LDX.W VerticalScrollEnabled
                      BNE CODE_00F881
                      LDY.B #$04
                      BRA CODE_00F881

CODE_00F875:          LDX.W ScreenScrollAtWill
                      BNE CODE_00F881
                      LDX.B PlayerInAir
                      BNE Return00F8AA
                      INC.W ScreenScrollAtWill
CODE_00F881:          LDA.B _2
CODE_00F883:          SEC
                      SBC.W DATA_00F6A7,Y
                      EOR.W DATA_00F6A7,Y
                      ASL A
                      LDA.B _2
                      BCS +
                      LDA.W DATA_00F6A7,Y
                    + CLC
                      ADC.B Layer1YPos
                      CMP.W DATA_00F6AD,Y
                      BPL +
                      LDA.W DATA_00F6AD,Y
                    + STA.B Layer1YPos
                      LDA.B _4
                      CMP.B Layer1YPos
                      BPL Return00F8AA
                      STA.B Layer1YPos
                      STZ.W VerticalScrollEnabled
Return00F8AA:         RTS

CODE_00F8AB:          LDY.W CameraIsScrolling
                      BNE Return00F8DE
                      SEP #$20                                  ; A->8
                      LDX.W CameraScrollPlayerDir
                      REP #$20                                  ; A->16
                      LDY.B #$08
                      LDA.W CameraMoveTrigger
                      CMP.W DATA_00F6B3,X
                      BPL +
                      LDY.B #$0A
                    + LDA.W DATA_00F6BF,Y
                      EOR.B _2
                      BPL Return00F8DE
                      LDA.W DATA_00F6BF,X
                      EOR.B _2
                      BPL Return00F8DE
                      LDA.B _2
                      CLC
                      ADC.W DATA_00F6CF,Y
                      BEQ Return00F8DE
                      STA.B _2
                      STY.W CameraProperMove
Return00F8DE:         RTS


DATA_00F8DF:          db $0C,$0C,$08,$00,$20,$04,$0A,$0D
                      db $0D

DATA_00F8E8:          db $2A,$00,$2A,$00,$12,$00,$00,$00
                      db $ED,$FF

CODE_00F8F2:          JSR CODE_00EAA6
                      BIT.W IRQNMICommand
                      BVC CODE_00F94E
                      JSR CODE_00E92B
                      LDA.W ActiveBoss
                      ASL A
                      TAX
                      PHX
                      LDY.B PlayerYSpeed
                      BPL +
                      REP #$20                                  ; A->16
                      LDA.B PlayerYPosNext
                      CMP.W DATA_00F8E8,X
                      BPL +
                      LDA.W DATA_00F8E8,X
                      STA.B PlayerYPosNext
                      SEP #$20                                  ; A->8
                      STZ.B PlayerYSpeed
                      LDA.B #!SFX_BONK
                      STA.W SPCIO0                              ; / Play sound effect
                    + SEP #$20                                  ; A->8
                      PLX
                      LDA.W DATA_00F8E8,X
                      CMP.B #$2A
                      BNE Return00F94D
                      REP #$20                                  ; A->16
                      LDY.B #$00
                      LDA.W SpriteMisc160E+9
                      AND.W #$00FF
                      INC A
                      CMP.B PlayerXPosNext
                      BEQ +
                      BMI +
                      LDA.W SpriteMisc1534+9
                      AND.W #$00FF
                      STA.B _0
                      INY
                      LDA.B PlayerXPosNext
                      CLC
                      ADC.W #$000F
                      CMP.B _0
                    + JMP CODE_00E9C8

Return00F94D:         RTS

CODE_00F94E:          LDY.B #$00
                      LDA.B PlayerYSpeed
                      BPL +
                      JMP CODE_00F997

                    + JSR CODE_00F9A8
                      BCS +
                      JSR CODE_00EE1D
                      JMP CODE_00F997

                    + LDA.B PlayerInAir
                      BEQ +
                      REP #$20                                  ; A->16
                      LDA.W BrSwingPlatXPos
                      AND.W #$00FF
                      STA.W BrSwingXDist
                      STA.W KeyholeXPos
                      LDA.W BrSwingPlatYPos
                      AND.W #$00F0
                      STA.W BrSwingYDist
                      STA.W KeyholeYPos
                      JSR CODE_00F9C9
                    + LDA.B Mode7Angle
                      CLC
                      ADC.B #$48
                      LSR A
                      LSR A
                      LSR A
                      LSR A
                      TAX
                      LDY.W DATA_00F8DF,X
                      LDA.B #$80
                      STA.B GraphicsUncompPtr+1
                      JSR CODE_00EEE1
CODE_00F997:          REP #$20                                  ; A->16
                      LDA.B PlayerYPosScrRel
                      CMP.W #$00AE
                      SEP #$20                                  ; A->8
                      BMI +
                      JSR CODE_00F629
                    + JMP CODE_00E98C

CODE_00F9A8:          REP #$20                                  ; A->16
                      LDA.B PlayerXPosNext
                      CLC
                      ADC.W #$0008
                      STA.W BrSwingXDist
                      LDA.B PlayerYPosNext
                      CLC
                      ADC.W #$0020
                      STA.W BrSwingYDist
CODE_00F9BC:          SEP #$20                                  ; A->8
                      PHB
                      LDA.B #$01
                      PHA
                      PLB
                      JSL CODE_01CC9D
                      PLB
                      RTS

CODE_00F9C9:          LDA.B Mode7Angle
                      PHA
                      EOR.W #$FFFF
                      INC A
                      STA.B Mode7Angle
                      JSR CODE_00F9BC
                      REP #$20                                  ; A->16
                      PLA
                      STA.B Mode7Angle
                      LDA.W BrSwingPlatXPos
                      AND.W #$00FF
                      SEC
                      SBC.W #$0008
                      STA.B PlayerXPosNext
                      LDA.W BrSwingPlatYPos
                      AND.W #$00FF
                      SEC
                      SBC.W #$0020
                      STA.B PlayerYPosNext
                      SEP #$20                                  ; A->8
                      RTS

                      %insert_empty($1B,$1B,$1B,$4D,$4D)

                      LDX.B #$0B                                ; \ Unreachable
                    - STZ.W SpriteStatus,X                      ; | Clear out sprite status table
                      DEX                                       ; |
                      BPL -                                     ; |
                      RTL                                       ; /

CODE_00FA19:          LDY.B #DATA_00E632
                      STY.B _5
                      LDY.B #DATA_00E632>>8
                      STY.B _6
                      LDY.B #DATA_00E632>>16
                      STY.B _7
                      SEC
                      SBC.B #$6E
                      TAY
                      LDA.B [SlopesPtr],Y
                      STA.B _8
                      ASL A
                      ASL A
                      ASL A
                      ASL A
                      STA.B _1
                      BCC +
                      INC.B _6
                    + LDA.B _C
                      AND.B #$0F
                      STA.B _0
                      LDA.B _A
                      AND.B #$0F
                      ORA.B _1
                      TAY
                      RTL

FlatPalaceSwitch:     LDA.B #$20                                ; \ Set "Time to shake ground" to x20
                      STA.W ScreenShakeTimer                    ; /
                      LDY.B #$02                                ; \
                      LDA.B #$60                                ; |Set sprite x02 to x60 (Flat palace switch)
                      STA.W SpriteNumber,Y                      ; /
                      LDA.B #$08                                ; \ Set sprite's status to x08
                      STA.W SpriteStatus,Y                      ; /
                      LDA.B TouchBlockXPos                      ; \
                      AND.B #$F0                                ; |Set sprite X (low) to $9A & 0xF0
                      STA.W SpriteXPosLow,Y                     ; /
                      LDA.B TouchBlockXPos+1                    ; \ Set sprite X (high) to $9B
                      STA.W SpriteYPosHigh,Y                    ; /
                      LDA.B TouchBlockYPos                      ; \
                      AND.B #$F0                                ; |
                      CLC                                       ; |Set sprite Y (low) to ($98 & 0xF0) + 0x10
                      ADC.B #$10                                ; |
                      STA.W SpriteYPosLow,Y                     ; /
                      LDA.B TouchBlockYPos+1                    ; \
                      ADC.B #$00                                ; |Set sprite Y (high) to $99 + carry
                      STA.W SpriteXPosHigh,Y                    ; / (Carry carried over from previous addition)
                      PHX
                      TYX
                      JSL InitSpriteTables
                      PLX
                      LDA.B #$5F                                ; \ Set sprite's "Spin Jump Death Frame Counter" to x5F
                      STA.W SpriteMisc1540,Y                    ; /
                      RTS

TriggerGoalTape:      STZ.W PBalloonInflating
                      STZ.W PBalloonTimer
                      STZ.W SpriteRespawnTimer                  ; Don't respawn sprites
                   if ver_is_english(!_VER)                     ;\================ U, SS, E0, & E1 ==============
                      STZ.W CurrentGenerator                    ;!
                   endif                                        ;/===============================================
                      STZ.W SilverCoinsCollected
                      LDY.B #$0B                                ; Loop over sprites:
LvlEndSprLoopStrt:    LDA.W SpriteStatus,Y                      ; \ If sprite status < 8,
                      CMP.B #$08                                ; | skip the current sprite
                      BCC LvlEndNextSprite                      ; /
                      CMP.B #$0B                                ; \ If Mario carries a sprite past the goal,
                      BNE CODE_00FAA3                           ; |
                      PHX                                       ; |
                      JSR LvlEndPowerUp                         ; | he gets a powerup
                      PLX                                       ; |
                      BRA LvlEndNextSprite                      ; /

CODE_00FAA3:          LDA.W SpriteNumber,Y                      ; \ Branch if goal tape
                      CMP.B #$7B                                ; |
                      BEQ CODE_00FAB2                           ; /
                      LDA.W SpriteOffscreenX,Y                  ; \ If sprite on screen...
                      ORA.W SpriteOffscreenVert,Y               ; |
                      BNE CODE_00FAC5                           ; |
CODE_00FAB2:          LDA.W SpriteTweakerE,Y                    ; | ...and "don't turn into coin" not set,
                      AND.B #$20                                ; |
                      BNE CODE_00FAC5                           ; |
                      LDA.B #$10                                ; | Set coin animation timer = #$10
                      STA.W SpriteMisc1540,Y                    ; |
                      LDA.B #$06                                ; | Sprite status = Level end, turn to coins
                      STA.W SpriteStatus,Y                      ; |
                      BRA LvlEndNextSprite                      ; /

CODE_00FAC5:          LDA.W SpriteTweakerF,Y                    ; \ If "don't erase" not set,
                      AND.B #$02                                ; |
                      BNE LvlEndNextSprite                      ; |
                      LDA.B #$00                                ; | Erase sprite
                      STA.W SpriteStatus,Y                      ; /
LvlEndNextSprite:     DEY                                       ; \ Goto next sprite
                      BPL LvlEndSprLoopStrt                     ; /
                      LDY.B #$07                                ; \
                      LDA.B #$00                                ; | Clear out all extended sprites
                    - STA.W ExtSpriteNumber,Y                   ; |
                      DEY                                       ; |
                      BPL -                                     ; /
                      RTL


DATA_00FADF:          db $74,$74,$77,$75,$76,$E0,$F0,$74
                      db $74,$77,$75,$76,$E0,$F1,$F0,$F0
                      db $F0,$F0,$F1,$E0,$F2,$E0,$E0,$E0
                      db $E0,$F1,$E0,$E4

DATA_00FAFB:          db $FF,$74,$75,$76,$77

LvlEndPowerUp:        LDX.B Powerup                             ; X = Mario's power up status
                      LDA.W InvinsibilityTimer                  ; \ If Mario has star, X = #$04.  However this never happens as $1490 is cleared earlier
                      BEQ +                                     ; | Otherwise Mario could get a star from carrying a sprite past the goal.
                      LDX.B #$04                                ; / Unreachable instruction
                    + LDA.W PlayerRidingYoshi                   ; \ If Mario on Yoshi, X = #$05
                      BEQ +                                     ; |
                      LDX.B #$05                                ; /
                    + LDA.W SpriteNumber,Y                      ; \ If Spring Board, X += #$07
                      CMP.B #$2F                                ; |
                      BEQ CODE_00FB2D                           ; /
                      CMP.B #$3E                                ; \ If P Switch, X += #$07
                      BEQ CODE_00FB2D                           ; /
                      CMP.B #$80                                ; \ If Key, X += #$0E
                      BEQ ADDR_00FB28                           ; /
                      CMP.B #$2D                                ; \ If Baby Yoshi, X += #$15
                      BNE +                                     ; /
                      TXA
                      CLC
                      ADC.B #$07
                      TAX
ADDR_00FB28:          TXA
                      CLC
                      ADC.B #$07
                      TAX
CODE_00FB2D:          TXA
                      CLC
                      ADC.B #$07
                      TAX
                    + LDA.L DATA_00FADF,X
                      LDX.W PlayerItembox
                      CMP.L DATA_00FAFB,X
                      BNE +
                      LDA.B #$78
                    + STZ.B _F
                      CMP.B #$E0
                      BCC +
                      PHA
                      AND.B #$0F
                      STA.B _F
                      PLA
                      CMP.B #$F0
                      LDA.B #$78
                      BCS +
                      LDA.B #$78
                    + STA.W SpriteNumber,Y
                      CMP.B #$76
                      BNE +
                      INC.W UnusedStarCounter
                    + TYX
                      JSL InitSpriteTables
                      LDA.B _F
                      STA.W SpriteMisc1594,Y
                      LDA.B #$0C                                ; \ Sprite status = Goal tape power up
                      STA.W SpriteStatus,Y                      ; /
                      LDA.B #$D0
                      STA.W SpriteYSpeed,Y
                      LDA.B #$05
                      STA.W SpriteXSpeed,Y
                      LDA.B #$20
                      STA.W SpriteMisc154C,Y
                      LDA.B #!SFX_ITEMGOAL
                      STA.W SPCIO0                              ; / Play sound effect
                      LDX.B #$03
CODE_00FB84:          LDA.W SmokeSpriteNumber,X
                      BEQ CODE_00FB8D
                      DEX
                      BPL CODE_00FB84
                      RTS

CODE_00FB8D:          LDA.B #$01
                      STA.W SmokeSpriteNumber,X
                      LDA.W SpriteYPosLow,Y
                      STA.W SmokeSpriteYPos,X
                      LDA.W SpriteXPosLow,Y
                      STA.W SmokeSpriteXPos,X
                      LDA.B #$1B
                      STA.W SmokeSpriteTimer,X
                      RTS


LvlEndSmokeTiles:     db $66,$64,$62,$60,$E8,$EA,$EC,$EA

LvlEndSprCoins:       PHB
                      PHK
                      PLB
                      JSR LvlEndSprCoinsRt
                      PLB
                      RTL

LvlEndSprCoinsRt:     LDY.B #$00
                      LDA.W Layer1DXPos
                      BPL +
                      DEY
                    + CLC
                      ADC.B SpriteXPosLow,X
                      STA.B SpriteXPosLow,X
                      TYA
                      ADC.W SpriteYPosHigh,X
                      STA.W SpriteYPosHigh,X
                      LDA.W SpriteMisc1540,X
                      BEQ CODE_00FBF0
                      CMP.B #$01
                      BNE +
                      LDA.B #$D0
                      STA.B SpriteYSpeed,X
                    + PHX
                      LDA.B #$04                                ; \ Use Palette A
                      STA.W SpriteOBJAttribute,X                ; /
                      JSL GenericSprGfxRt2
                      LDA.W SpriteMisc1540,X
                      LSR A
                      LSR A
                      LDY.W SpriteOAMIndex,X                    ; Y = Index into sprite OAM
                      TAX
                      LDA.W LvlEndSmokeTiles,X
                      STA.W OAMTileNo+$100,Y
                      PLX
                      RTS

CODE_00FBF0:          INC.W SpriteMisc1570,X
                      JSL UpdateYPosNoGvtyW
                      INC.B SpriteYSpeed,X
                      INC.B SpriteYSpeed,X
                      LDA.B SpriteYSpeed,X
                      CMP.B #$20
                      BMI CODE_00FC1E
                      JSL CODE_05B34A
                      LDA.W SilverCoinsCollected
                      CMP.B #$0D
                      BCC +
                      LDA.B #$0D
                    + JSL GivePoints
                      LDA.W SilverCoinsCollected
                      CLC
                      ADC.B #$02
                      STA.W SilverCoinsCollected
                      STZ.W SpriteStatus,X
CODE_00FC1E:          JSL CoinSprGfx
                      RTS

                      LDY.B #$0B                                ; \ Unreachable instructions
ADDR_00FC25:          LDA.W SpriteStatus,Y                      ; / Status = Carried
                      CMP.B #$08
                      BNE ADDR_00FC73
                      LDA.W SpriteNumber,Y
                      CMP.B #$35
                      BNE ADDR_00FC73
                      LDA.B #$01
                      STA.W CarryYoshiThruLvls
                      STZ.W YoshiHasWingsEvt                    ; No Yoshi wings
                      LDA.W SpriteOBJAttribute,Y
                      AND.B #$F1
                      ORA.B #$0A
                      STA.W SpriteOBJAttribute,Y
                      LDA.W PlayerRidingYoshi
                      BNE +
                      LDA.B Layer1XPos
                      SEC
                      SBC.B #$10
                      STA.W SpriteXPosLow,Y
                      LDA.B Layer1XPos+1
                      SBC.B #$00
                      STA.W SpriteYPosHigh,Y
                      LDA.B PlayerYPosNext
                      STA.W SpriteYPosLow,Y
                      LDA.B PlayerYPosNext+1
                      STA.W SpriteXPosHigh,Y
                      LDA.B #$03
                      STA.W SpriteTableC2,Y
                      LDA.B #$00
                      STA.W SpriteMisc157C,Y
                      LDA.B #$10
                      STA.W SpriteXSpeed,Y
                    + RTL

ADDR_00FC73:          DEY
                      BPL ADDR_00FC25
                      STZ.W CarryYoshiThruLvls
                      RTL

CODE_00FC7A:          LDA.B #!SFX_YOSHIDRUMON
                      STA.W SPCIO1                              ; / Play sound effect
                      LDX.B #$00
                      LDA.W DisableBonusSprite
                      BNE +
                      LDX.B #$05
                      LDA.W SpriteMemorySetting
                      CMP.B #$0A
                      BEQ +
                      JSL FindFreeSprSlot                       ; \ X = First free sprite slot, #$03 if none free
                      TYX                                       ; |
                      BPL +                                     ; |
                      LDX.B #$03                                ; /
                    + LDA.B #$08                                ; \ Status = Normal
                      STA.W SpriteStatus,X                      ; /
                      LDA.B #$35                                ; \ Sprite = Yoshi
                      STA.B SpriteNumber,X                      ; /
                      LDA.B PlayerXPosNext                      ; \ Yoshi X position = Mario X position
                      STA.B SpriteXPosLow,X                     ; |
                      LDA.B PlayerXPosNext+1                    ; |
                      STA.W SpriteYPosHigh,X                    ; /
                      LDA.B PlayerYPosNext                      ; \ Yoshi's Y position = Mario Y position - #$10
                      SEC                                       ; | Mario Y position = Mario Y position - #$10
                      SBC.B #$10                                ; |
                      STA.B PlayerYPosNext                      ; |
                      STA.B SpriteYPosLow,X                     ; |
                      LDA.B PlayerYPosNext+1                    ; |
                      SBC.B #$00                                ; |
                      STA.B PlayerYPosNext+1                    ; |
                      STA.W SpriteXPosHigh,X                    ; /
                      JSL InitSpriteTables                      ; Reset sprite tables
                      LDA.B #$04
                      STA.W SpriteMisc1FE2,X
                      LDA.W YoshiColor                          ; \ Set Yoshi palette
                      STA.W SpriteOBJAttribute,X                ; /
                      LDA.W YoshiHeavenFlag
                      BEQ +
                      LDA.B #$06
                      STA.W SpriteOBJAttribute,X
                    + INC.W PlayerRidingYoshi
                      INC.B SpriteTableC2,X
                      LDA.B PlayerDirection
                      EOR.B #$01
                      STA.W SpriteMisc157C,X
                      DEC.W SpriteMisc160E,X
                      INX
                      STX.W CurrentYoshiSlot
                      STX.W YoshiIsLoose
                      RTL

CODE_00FCEC:          LDX.B #$0B
                    - STZ.W SpriteStatus,X
                      DEX
                      BPL -
                      RTS

CODE_00FCF5:          LDA.B #$A0
                      STA.B SpriteXPosLow,X
                      LDA.B #$00
                      STA.W SpriteYPosHigh,X
                      LDA.B #$00
                      STA.B SpriteYPosLow,X
                      LDA.B #$00
                      STA.W SpriteXPosHigh,X
                      RTL

CODE_00FD08:          LDY.B #$3F
                      LDA.B byetudlrHold
                      AND.B #$83
                      BNE +
                      LDY.B #$7F
                    + TYA
                      AND.B EffFrame
                      ORA.B SpriteLock
                      BNE Return00FD23
                      LDX.B #$07                                ; \ Find a free extended sprite slot
CODE_00FD1B:          LDA.W ExtSpriteNumber,X                   ; |
                      BEQ CODE_00FD26                           ; |
                      DEX                                       ; |
                      BPL CODE_00FD1B                           ; |
Return00FD23:         RTS                                       ; / Return if no free slots


DATA_00FD24:          db $02,$0A

CODE_00FD26:          LDA.B #$12                                ; \ Extended sprite = Water buble
                      STA.W ExtSpriteNumber,X                   ; /
                      LDY.B PlayerDirection
                      LDA.B PlayerXPosNext
                      CLC
                      ADC.W DATA_00FD24,Y
                      STA.W ExtSpriteXPosLow,X
                      LDA.B PlayerXPosNext+1
                      ADC.B #$00
                      STA.W ExtSpriteXPosHigh,X
                      LDA.B Powerup
                      BEQ CODE_00FD47
                      LDA.B #$04
                      LDY.B PlayerIsDucking
                      BEQ +
CODE_00FD47:          LDA.B #$0C
                    + CLC
                      ADC.B PlayerYPosNext
                      STA.W ExtSpriteYPosLow,X
                      LDA.B PlayerYPosNext+1
                      ADC.B #$00
                      STA.W ExtSpriteYPosHigh,X
                      STZ.W ExtSpriteMisc176F,X
                      RTS

CODE_00FD5A:          LDA.B PlayerXPosScrRel+1
                      ORA.B PlayerYPosScrRel+1
                      BNE Return00FD6A
                      LDY.B #$03
CODE_00FD62:          LDA.W SmokeSpriteNumber,Y
                      BEQ CODE_00FD6B
                      DEY
                      BPL CODE_00FD62
Return00FD6A:         RTS

CODE_00FD6B:          LDA.B #$05
                      STA.W SmokeSpriteNumber,Y
                      LDA.B TouchBlockXPos
                      AND.B #$F0
                      STA.W SmokeSpriteXPos,Y
                      LDA.B TouchBlockYPos
                      AND.B #$F0
                      STA.W SmokeSpriteYPos,Y
                      LDA.W LayerProcessing
                      BEQ +
                      LDA.B TouchBlockXPos
                      SEC
                      SBC.B Layer23XRelPos
                      AND.B #$F0
                      STA.W SmokeSpriteXPos,Y
                      LDA.B TouchBlockYPos
                      SEC
                      SBC.B Layer23YRelPos
                      AND.B #$F0
                      STA.W SmokeSpriteYPos,Y
                    + LDA.B #$10
                      STA.W SmokeSpriteTimer,Y
                      RTS


DATA_00FD9D:          db $08,$FC,$10,$04

DATA_00FDA1:          db $00,$FF,$00,$00

CODE_00FDA5:          LDA.B PlayerInAir
                      BEQ CODE_00FDB3
                      LDY.B #$0B
CODE_00FDAB:          LDA.W MinExtSpriteNumber,Y
                      BEQ CODE_00FDB4
                      DEY
                      BPL CODE_00FDAB
CODE_00FDB3:          INY
CODE_00FDB4:          PHX
                      LDX.B #$00
                      LDA.B Powerup
                      BEQ +
                      INX
                    + LDA.W PlayerRidingYoshi
                      BEQ +
                      INX
                      INX
                    + LDA.B PlayerYPosNext
                      CLC
                      ADC.W DATA_00FD9D,X
                      PHP
                      AND.B #$F0
                      CLC
                      ADC.B #$03
                      STA.W MinExtSpriteYPosLow,Y
                      LDA.B PlayerYPosNext+1
                      ADC.B #$00
                      PLP
                      ADC.W DATA_00FDA1,X
                      STA.W MinExtSpriteYPosHigh,Y
                      PLX
                      LDA.B PlayerXPosNext
                      STA.W MinExtSpriteXPosLow,Y
                      LDA.B PlayerXPosNext+1
                      STA.W MinExtSpriteXPosHigh,Y
                      LDA.B #$07
                      STA.W MinExtSpriteNumber,Y
                      LDA.B #$00
                      STA.W MinExtSpriteTimer,Y
                      LDA.B PlayerYSpeed
                      BMI Return00FE0D
                      STZ.B PlayerYSpeed
                      LDY.B PlayerInAir
                      BEQ +
                      STZ.B PlayerXSpeed
                    + LDY.B #$03
                      LDA.B Powerup
                      BNE CODE_00FE05
                      DEY
CODE_00FE05:          LDA.W ExtSpriteNumber,Y
                      BEQ CODE_00FE16
CODE_00FE0A:          DEY
                      BPL CODE_00FE05
Return00FE0D:         RTS


DATA_00FE0E:          db $10,$16,$13,$1C

DATA_00FE12:          db $00,$04,$0A,$07

CODE_00FE16:          LDA.B #$12                                ; \ Extended sprite = Water bubble
                      STA.W ExtSpriteNumber,Y                   ; /
                      TYA
                      ASL A
                      ASL A
                      ASL A
                      ADC.B #$F7
                      STA.W ExtSpriteMisc1765,Y
                      LDA.B PlayerYPosNext
                      ADC.W DATA_00FE0E,Y
                      STA.W ExtSpriteYPosLow,Y
                      LDA.B PlayerYPosNext+1
                      ADC.B #$00
                      STA.W ExtSpriteYPosHigh,Y
                      LDA.B PlayerXPosNext
                      ADC.W DATA_00FE12,Y
                      STA.W ExtSpriteXPosLow,Y
                      LDA.B PlayerXPosNext+1
                      ADC.B #$00
                      STA.W ExtSpriteXPosHigh,Y
                      LDA.B #$00
                      STA.W ExtSpriteMisc176F,Y
                      JMP CODE_00FE0A

CODE_00FE4A:          LDA.B TrueFrame
                      AND.B #$03
                      ORA.B PlayerInAir
                      ORA.B PlayerXPosScrRel+1
                      ORA.B PlayerYPosScrRel+1
                      ORA.B SpriteLock
                      BNE Return00FE71
                      LDA.B byetudlrHold
                      AND.B #$04
                      BEQ CODE_00FE67
                      LDA.B PlayerXSpeed
                      CLC
                      ADC.B #$08
                      CMP.B #$10
                      BCC Return00FE71
CODE_00FE67:          LDY.B #$03
CODE_00FE69:          LDA.W SmokeSpriteNumber,Y
                      BEQ CODE_00FE72
                      DEY
                      BNE CODE_00FE69
Return00FE71:         RTS

CODE_00FE72:          LDA.B #$03
                      STA.W SmokeSpriteNumber,Y
                      LDA.B PlayerXPosNext
                      ADC.B #$04
                      STA.W SmokeSpriteXPos,Y
                      LDA.B PlayerYPosNext
                      ADC.B #$1A
                      PHX
                      LDX.W PlayerRidingYoshi
                      BEQ +
                      ADC.B #$10
                    + STA.W SmokeSpriteYPos,Y
                      PLX
                      LDA.B #$13
                      STA.W SmokeSpriteTimer,Y
                      RTS


DATA_00FE94:          db $FD,$03

DATA_00FE96:          db $00,$08,$F8,$10,$F8,$10

DATA_00FE9C:          db $00,$00,$FF,$00,$FF,$00

DATA_00FEA2:          db $08,$08,$0C,$0C,$14,$14

ShootFireball:        LDX.B #$09                                ; \ Find a free fireball slot (08-09)
CODE_00FEAA:          LDA.W ExtSpriteNumber,X                   ; |
                      BEQ CODE_00FEB5                           ; |
                      DEX                                       ; |
                      CPX.B #$07                                ; |
                      BNE CODE_00FEAA                           ; |
                      RTS                                       ; / Return if no free slots

CODE_00FEB5:          LDA.B #!SFX_FIREBALL
                      STA.W SPCIO3                              ; / Play sound effect
                      LDA.B #$0A
                      STA.W ShootFireTimer
                      LDA.B #$05                                ; \ Extended sprite = Mario fireball
                      STA.W ExtSpriteNumber,X                   ; /
                      LDA.B #$30
                      STA.W ExtSpriteYSpeed,X
                      LDY.B PlayerDirection
                      LDA.W DATA_00FE94,Y
                      STA.W ExtSpriteXSpeed,X
                      LDA.W PlayerRidingYoshi
                      BEQ +
                      INY
                      INY
                      LDA.W PlayerDuckingOnYoshi
                      BEQ +
                      INY
                      INY
                    + LDA.B PlayerXPosNext
                      CLC
                      ADC.W DATA_00FE96,Y
                      STA.W ExtSpriteXPosLow,X
                      LDA.B PlayerXPosNext+1
                      ADC.W DATA_00FE9C,Y
                      STA.W ExtSpriteXPosHigh,X
                      LDA.B PlayerYPosNext
                      CLC
                      ADC.W DATA_00FEA2,Y
                      STA.W ExtSpriteYPosLow,X
                      LDA.B PlayerYPosNext+1
                      ADC.B #$00
                      STA.W ExtSpriteYPosHigh,X
                      LDA.W PlayerBehindNet
                      STA.W ExtSpritePriority,X
                      RTS

ADDR_00FF07:          REP #$20                                  ; A->16
                      LDA.W Layer1DYPos
                      AND.W #$FF00
                      BPL +
                      ORA.W #$00FF
                    + XBA
                      CLC
                      ADC.B PlayerXPosNext
                      STA.B PlayerXPosNext
                      LDA.W LoadingLevelNumber
                      AND.W #$FF00
                      BPL +
                      ORA.W #$00FF
                    + XBA
                      EOR.W #$FFFF
                      INC A
                      CLC
                      ADC.B PlayerYPosNext
                      STA.B PlayerYPosNext
                      SEP #$20                                  ; A->8
                      RTL

ADDR_00FF32:          LDA.W SpriteYPosHigh,X
                      XBA
                      LDA.B SpriteXPosLow,X
                      REP #$20                                  ; A->16
                      SEC
                      SBC.B Layer1XPos
                      STA.B _0
                      LDA.W #$0030
                      SEC
                      SBC.B _0
                      STA.B Layer3XPos
                      SEP #$20                                  ; A->8
                      LDA.W SpriteXPosHigh,X
                      XBA
                      LDA.B SpriteYPosLow,X
                      REP #$20                                  ; A->16
                      SEC
                      SBC.B Layer1YPos
                      STA.B _0
                      LDA.W #$0100
                      SEC
                      SBC.B _0
                      STA.B Layer3YPos
                      SEP #$20                                  ; A->8
                      RTL

CODE_00FF61:          LDA.W SpriteYPosHigh,X
                      XBA
                      LDA.B SpriteXPosLow,X
                      REP #$20                                  ; A->16
                      CMP.W #$FF00
                      BMI CODE_00FF73
                      CMP.W #$0100
                      BMI +
CODE_00FF73:          LDA.W #$0100
                    + STA.B Layer3XPos
                      SEP #$20                                  ; A->8
                      LDA.W SpriteXPosHigh,X
                      XBA
                      LDA.B SpriteYPosLow,X
                      REP #$20                                  ; A->16
                      STA.B _0
                      LDA.W #$00A0
                      SEC
                      SBC.B _0
                      CLC
                      ADC.W ScreenShakeYOffset
                      STA.B Layer3YPos
                      SEP #$20                                  ; A->8
                      RTL

                      padbyte $FF : pad $00FFC0