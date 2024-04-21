#game-mode

1. [[ClearOutLayer3]] to make layer 3 blank.
2. [[SetUpScreen]] to set various basic screen settings.
3. [[LoadLayer3Graphics]] to upload tile graphics data, for BG3 HUD and some OBJ.
4. Use OBJ to display the "Nintendo presents" logo.
5. Play the "bing" sound (request to SPC).
6. Set up the [[Var VariousPromptTimer]] to display the logo for 64 frames.
7. Set the shadow screen [[Var Brightness]] to max.
8. Do TBD with [[Var MosaicDirection]].
9. Set [[Var SpritePalette]] to 0 and call [[LoadPalette]] to load palettes to shadow WRAM.
10. Override the [[Var BackgroundColor]] to black and push the palettes to VRAM.
11. Set [[Var BlinkCursorPos]] to 0. (menu pointer posiiton?)
12. Set [[Var IRQNMICommand]] to [[IRQNMI_Cutscenes]].
13. Call [[ScreenSettings]]:
	1. [[HW_CGADSUB]] = [[Var ColorSettings]] = colour math affects the "back" only. TBD is "back" == the "screen clear" "layer"?
	2. Main screen shows OBJ only.
	3. Subscreen shows BG3 only.
	4. Disable windowing on main/sub screens.
14. Set game mode to [[GM01Presents]] (showing the "Nintendo presents" logo).
15. Enable NMI and auto-joypad reading.