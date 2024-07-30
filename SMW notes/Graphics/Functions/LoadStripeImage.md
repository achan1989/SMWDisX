#graphics #function 

Bank 0 line 912

Args:
\_0: 3 bytes pointer to the desired stripe image.
A: the bank byte (same as \_2).

A stripe image holds chain-of-commands type data.
* Byte 0&1: VRAM destination word address, stored big-endian. If bit 7 of byte 0 is one, marks the end of the stripe.
* Byte 2: mode and length
	* bit 7 = stripe direction (0=horz, 1=vert)
	* bit 6 = RLE (0=no, 1=yes)
	* bit 5-0 = high part of length
* Byte 3: low part of length.
	* Note: actual length is given length + 1
* Byte 4+: image data fragment

DMA operation:
src = image data fragment
dst = VRAM
params = depends on mode.
VRAM inc = depends on mode

## Normal mode (no RLE)

DMA params:  2 bytes (VMDATA L, VMDATA H). Increment A bus.
VRAM inc: after VMDATA H; by 1 word if horizontal, or 32 words if vertical.

Just copy n bytes of src to dst, via VMDATAL then VMDATAH.
Skip to next header: idx += 4 (header size) + length + 1

Inc after high byte means we're expecting to copy full words?

## RLE mode

DMA params:  2 bytes (VMDATA L, VMDATA H).  **DO NOT** increment A bus.
VRAM inc: after VMDATA L; by 1 word if horizontal, or 32 words if vertical.

Set n bytes of dst to src\[0], via VMDATAL then VMDATAH.

DMA params:  2 bytes (VMDATA H, M7SEL).  **DO NOT** increment A bus.
VRAM inc: after VMDATA L; by 1 word if horizontal, or 32 words if vertical.

Set n bytes of dst to src\[1], via VMDATAH then M7SEL. 
Skip to next header: idx += 4 (header size) + 2