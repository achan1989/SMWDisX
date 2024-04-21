#graphics #function #NMI

There's a lookup `DATA_PaletteTableLookup` which maps [[Var PaletteIndexTable]] to the address of each palette table.

1. Read [[Var PaletteIndexTable]], and set up to read from the relevant table.
2. Read the first byte in the table. If it's 0, we're using `PaletteTableUse_Copy` or `PaletteTableUse_Main`; or `PaletteTableUse_Dynamic` and the dynamic table is empty. Skip to step 4.
3. Each entry in the table specifies a number of bytes to upload, the CGRAM address to load to, and some colour data. For each entry, DMA the colour data into CGRAM.
4. Call [[UploadBackgroundColor]] to upload [[Var BackgroundColor]] as the PPU's fixed colour value (`HW_COLDATA`).
5. Ensure [[Var PaletteIndexTable]] is set to `PaletteTableUse_Dynamic` and the dynamic table is cleared.