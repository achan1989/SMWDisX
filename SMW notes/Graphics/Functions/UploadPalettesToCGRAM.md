#graphics #palette #function

Used after [[LoadPalette]] has set up the shadow palette `MainPalette` in WRAM.

1. In the shadow palette, set colour 0 in palette 0 to black. This is the "screen clear" colour, if nothing draws to a pixel on a frame.
2. Use DMA channel 2 to copy the entire shadow palette to CGRAM (512 bytes).