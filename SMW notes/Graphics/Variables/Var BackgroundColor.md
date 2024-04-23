#graphics #palette #variable

A variable in WRAM called `BackgroundColor`. Sounds as if it's supposed to be the "screen clear" colour (colour 0 in palette 0), but it seems not.

I think it's something to do with the fixed colour used in colour math -- see write to `HW_COLDATA` in [[UploadDynamicPalettesAndBackgroundColor]]. Are we using fixed colour math as an additional configurable "background colour", and leaving the "screen clear" colour as black?