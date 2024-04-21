#graphics #palette #function

Bank 0 line 5620

# Background info

* Graphics data specifies the colour of each pixel as a colour index (0-3 or 0-15).
* A palette is a set of 4 or 16 colour definitions, which determines how to map a colour index to an actual RGB value.
* A colour definition is 16 bits. From MSB: 1 bit unused (zero), 5 bits each BGR.
* An OBJ or a BG tile will choose one of eight palettes to use. This enables cheap colour-swaps.
* There may be independent palette definitions for the OBJ and each BG. Or some of the BGs may share palette definitions. Depends on the BG mode.

`MainPalette` at 0x7E0703 is a WRAM shadow copy of the whole of CGRAM (the palette store in VRAM). This holds the palettes for the BGs and OBJs. It's cleared to zero at reset. [[UploadPalettesToCGRAM]] copies this to VRAM.

`BackAreaColor` in WRAM should really be called `BackAreaColorIndex`, which stores the background colour index that we want to use. There are 8 colour definitions at `BackAreaColors`, which this index looks into. The chosen (looked-up) background colour is copied to `BackgroundColor`.

# LoadPalette

This is written as if all palettes hold 16 colours, though this may not be the case (looks like we will use mode 1, where BG3 has 4-colour palettes, which overlap with the 16-colour BG1 and BG2 palettes).

Loads a variety of palettes to the `MainPalette` shadow in WRAM. Some of the colours are fixed, some are controlled by selection variables.

The first word in `MainPalette` was initialised to 00 on reset, and it looks like other parts of the code rely on this (eg TODO link to mystery "upload palette to CGRAM" function).

1. Set colour 1 in all BG palettes to near-white (~8bit RGB EFF7FF).
2. Set colour 1 in all OBJ palettes to white (8bit RGB FFFFFF).
3. Load colours 8-15 in the first two BG palettes. Comments say this is for the status bar.
4. Load colours 2-7 in palettes 4-13 (last 4 BG palettes, first 6 OBJ palettes). Comments say these are "standard colours".
5. Look up the chosen `BackAreaColor`(Index) and store the colour definition in `BackgroundColor`.
6. Use `ForegroundPalette` (an enum/index) to choose 12 colours from `ForegroundPalettes`. Load them into colours 2-7 in palettes 2 and 3 (BG).
7. Use `SpritePalette` (an enum/index) to choose 12 colours from `SpriteColours`. Load them into colours 2-7 in palettes 14 and 15 (OBJ palettes 6 and 7).
8. Use `BackgroundPalette` (an enum/index) to choose 12 colours from `BackgroundPalettes`. Load them into colours 2-7 in palettes 0 and 1 (BG).
9. Load colours 9-15 in palettes 2-4 (BG), and in palettes 9-11 (OBJ palettes 1-3). Comments say these are berry colours: red, pink, green.

## LoadCol8Pal

Load a colour into the same slot in 8 consecutive palettes.
For palettes that comprise 16 colour slots.

Store in `_4`: the 2 byte colour definition to load.
Store in `X`: the byte offset into `MainPalette` corresponding to the slot in the first palette.

1. Load the colour from `_4`
2. Store it at `MainPalette[x]`
3. `x += 32` (skip 16 colours)
4. Repeat so that the colour is stored 8 times

## LoadColors

Load a stream of colours into 1 or more consecutive palettes, optionally skipping some slots in each destination palette.
For palettes that comprise 16 colour slots.

Store in `_0`: the start address of the source colour definitions.
Store in `_4`: the byte offset into `MainPalette` corresponding to a slot in the first palette.
Store in `_6`: the number of colours to load into each palette, minus one.
Store in `_8`: the number of consecutive palettes to load into, minus one.

## Misc notes

`BackAreaColor` 0 corresponds to 8bit RGB FFE6B5, a light peach colour?