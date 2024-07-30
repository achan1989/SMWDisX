#graphics #OAM #function

The code is generated at reset time.  Is an unrolled loop that moves all OBJs off screen *in the OAMMirror only*.

The OAMMirror starts at 7E0200 and holds entries for 128 OBJs. Each entry is 4 bytes: low 8 bits of X position, Y position, low 8 bits of tile number, various properties.

1. LDA 0xF0 (when written to OAM Y position, would put the OBJ off screen)
2. STA 0x03FD (the Y position of the last OBJ (idx 127) in the OAMMirror)
3. STA 0x03F9 (the Y position of the last-but-one OBJ in the OAMMirror)
4. ...
5. STA 0x0201 (the Y position of the first OBJ (idx 0) in the OAMMirror)
6. RTL

Note that OAM also has a "final 32 bytes (16 words) \[which\] contain some additional properties, with 4 sprites packed into each byte". But those are mirrored separately.