#graphics #variable 

`PaletteIndexTable` is a choice of which palette table to use. Choice of:
* `PaletteTableUse_Dynamic` -- use [[Var DynPaletteTable]] to set colours in arbitrary palettes.
* `PaletteTableUse_Copy` -- TBD
* `PaletteTableUse_Main` -- TBD

I think it resets to `PaletteTableUse_Dynamic` in each NMI, and the dynamic table gets cleared. See [[UploadPaletteTableToCGRAM]].