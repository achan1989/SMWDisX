#graphics #function 

Bank 0, line 5289

1. Set VRAM write address to 0x4000 -- beginning of BG3 tiles (VRam_L3Tiles).
2. Use [[PrepareGraphicsFile]]-->[[GraphicsUncompress]] to decompress GFX28_HUDTiles to WRAM 0x7EAD00. Always decompresses 2 KB? One set of 32 tiles of 8x8 @4bpp.
3. Copy the tile set to VRAM.
4. Repeat for graphics files GFX29_TitleScreen, GFX2A_MessageTiles, GFX2B_CastleCrusher. VRAM space for tile graphics is now full.
5. Set VRAM write address to 0x6000 (VRam_OBJTiles).
6. Call [[UploadGFXFile]] (line 5408) with Y=0. Does [[PrepareGraphicsFile]] to decompress GFX00_Powerups. I think `ObjectTileset` defaults to 0 (ObjTileset_Normal1), so we fall through to the "mundane" (ha) path. This takes the decompressed graphics stored as 3bpp, and converts it into 4bpp in VRAM.