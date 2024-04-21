Starts with console reset to bank 0, I_RESET.

1. Disable IRQ, NMI, DMA, HDMA.  Force v-blank.
2. Clear APU IO ports.
3. Put CPU in native mode, no decimal. The Direct register is 0. Stack starts at 0x7E01FF.
4. Generate the code for the OAMResetRoutine function.
5. Upload the audio engine to the SPC chip.
6. GameMode = 0, OverworldOverride = 0.
7. Call ClearMemory to zero out a lot of the Direct-accessed variables. Affects $0000-$1FFF (except the stack) and $7F837B/D.
8. Upload samples to the SPC.
9. Call WindowDMASetup to set up window HDMA settings for channel 7.
	1. Mode: CPU->PPU, indirect addressing, copy 2 bytes, increment address.
	2. Dst: HW_WH0 then HW_WH1 -- left and right edges of window 1.
	3. Src: WindowDMASizes is a table that specifies what to write.
		1. On each scanline number i, copy the word at WindowTable\[i\].
	4. HDMA data bank: 0 -- is this for the WindowDMASizes, the WindowTable, or both?
	5. Fall through to disable HDMA and set the WindowTable contents to left=FF right=00. Window fully "open" (not occluding) on each scanline?
10. OBJ tiles will be at VRAM 0x6000 (VRam_OBJTiles). OAM character sizes are 8x8 and 16x16.
11. Set [[Var LagFlag]] = 1.

Then enter the main GameLoop.