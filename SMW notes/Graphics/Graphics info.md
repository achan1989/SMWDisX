#graphics

# Terminology

Tile = an 8x8 pixel graphic.
Character/CHR = a synonym for a tile's 8x8 graphic data?
Object/OBJ/sprite = an independently movable graphic, like mario.
Background/screen/BG = a layer of tiles in a continuous grid. The whole layer can scroll.
Tilemap/nametable = a grid of 32x32 tile choices for a background.
Name = a tile number.
Name base address = the beginning of (OBJ, usually?) tile storage in VRAM.

# Generic Overview

"240p60", but really 256x224.
VRAM is total 32 K-word, i.e. 64 KB. It's only word-addressable.

Always 128 OBJ OAM entries. Total 544 bytes, **but in a separate memory space** (not VRAM).

One OBJ tile's graphic data is 16 words (4bpp, 8x8 pixels = 32 bytes), total 2048 words (4 KB) for 128 of them.
Tiles for the OBJ need to be stored at the name base address. This is configurable.
The name base address "window size" is 8 K-words (16 KB), which is more than is required to store 128 tiles -- why?

A background tile's graphic data size depends on the bg mode, can be 8/16/32 words (2/4/8 bpp).
Tiles for the backgrounds need to be stored at a CHR base address (see HW_BG12NBA and HW_BG34NBA). These are configurable, one per background. A background can select from up to 1024 tiles (though there probably isn't enough VRAM for that).

One 32x32 tilemap is 1 K-word. For each background we need to store 1 or 2 or 4 at a configurable location (see HW_BG1SC thru HW_BG4SC).

# For SMW

See [[SetUpScreen]]

OAM object/sprite sizes are always 8x8 and 16x16.
The name base address is 0x6000 (VRam_OBJTiles) and is a contiguous 8 K-words (16 KB) until 0x7FFF.
(This is set at reset, bank 0 line 46, HW_OBJSEL).

SetUpScreen, bank 0, line 1262. For title screens etc:
BG1 is a 2x2 tilemap (64x64 tiles) at VRAM 0x2000 (VRam_L1Tilemap)
BG2 is a 2x2 tilemap (64x64 tiles) at VRAM 0x3000 (VRam_L2Tilemap)
BG3 is a 2x2 tilemap (64x64 tiles) at VRAM 0x5000 (VRam_L3Tilemap)
BG1 and BG2 share tiles at VRAM 0x0000 (VRam_L1Tiles, VRam_L2Tiles)
BG3 has tiles at VRAM 0x4000-5000 (VRam_L3Tiles), enough for 4 sets of 32 tiles of 8x8 @4bpp.

## BG Mode

BG mode 1 is used for most of the game, with BG3 using high priority. See [[Normal NMI]].

This means the priority order is as follows, with the highest priority written first:
3H S3 1H 2H S2 1L 2L S1 S0 3L