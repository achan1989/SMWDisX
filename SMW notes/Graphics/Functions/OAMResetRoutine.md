#graphics #OAM #function

The code is generated at reset time.  Is an unrolled loop that moves all OBJs off screen *in the OAMMirror only*.

1. LDA 0xF0 (when written to OAM Y position, would put the OBJ off screen)
2. STA 0x03FD (the Y position of the last OBJ in the OAMMirror)
3. STA 0x03F9 (the Y position of the last-but-one OBJ in the OAMMirror)
4. ...
5. STA 0x0201 (the Y position of the first OBJ in the OAMMirror)
6. RTL