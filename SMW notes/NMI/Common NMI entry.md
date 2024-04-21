#function #NMI #graphics 

Bank 0, `I_NMI`.

1. Disable interrupts, save registers, clear the NMI interrupt flag register.
2. TBD do things associated with sound/music.
3. Force screen blank.
4. Disable HDMA.
5. Apply window mask settings for BGs/OBJ/colour window, and colour addition settings.
	1. Push [[Var Layer12Window]] and [[Var Layer34Window]] to PPU `HW_W12SEL` and `HW_W34SEL`.
	2. Push [[Var OBJCWWindow]] to PPU `HW_WOBJSEL`.
	3. Push [[Var ColorAddition]] to PPU `HW_CGSWSEL`.

Then switch on [[Var IRQNMICommand]]. If negative, run [[Mode7 NMI]]. Otherwise run [[Normal NMI]].