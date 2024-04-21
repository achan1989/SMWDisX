#graphics #function

Unless noted, all changes are written to the PPU immediately.

1. Set vertical resolution to 224 lines.
2. No mosaic.
3. BG1 is a 2x2 tilemap (64x64 tiles) at VRAM 0x2000 (VRam_L1Tilemap).
4. BG2 is a 2x2 tilemap (64x64 tiles) at VRAM 0x3000 (VRam_L2Tilemap).
5. BG3 is a 2x2 tilemap (64x64 tiles) at VRAM 0x5000 (VRam_L3Tilemap).
6. BG1 and BG2 share tile graphics data at VRAM 0x0000 (VRam_L1Tiles, VRam_L2Tiles).
7. BG3 has tile graphics data at VRAM 0x4000-5000 (VRam_L3Tiles).
8. In shadow variables: disable windows for all BGs, the OBJ layer, and the colour window. [[Var Layer12Window]], [[Var Layer34Window]], [[Var OBJCWWindow]].
9. Window mask logic for BGs, OBJ, colour window is set to `OR`.
10. Don't apply BG and OBJ windows to main screen or subscreen.
11. In shadow variable [[Var ColorAddition]]: will add the subscreen to the main screen (not a fixed colour). Won't force any of the main/sub screen to be black/transparent.
12. Mode 7 will be transparent outside of the tilemap boundaries.