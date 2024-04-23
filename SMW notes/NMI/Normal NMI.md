#function #NMI #graphics 

Part of bank 0 `I_NMI`, label `RegularLevelNMI` after having run the [[Common NMI entry]].

Runs when [[Var IRQNMICommand]] is one of `IRQNMI_Standard`, `IRQNMI_Cutscenes`, `IRQNMI_Overworld`.

1. (Re)apply the requested [[Var ColorSettings]], but ensure that colour math is not enabled for BG 3, even if requested.
2. Choose BG mode 1, with BG3 using high priority.
3. If the [[Var LagFlag]] is set, skip [[#1. When not lagging]] and go to TBD

# 1. When not lagging

1. Set the [[Var LagFlag]] so the main loop can run after the NMI has ended.
2. Call [[UploadDynamicPalettesAndBackgroundColor]].
3. Check [[Var IRQNMICommand]], branch depending on if it's the overworld or not.

## 1.1 When IRQNMI_Overworld

TBD

## 1.2 When not IRQNMI_Overworld

`IRQNMI_Standard` or `IRQNMI_Cutscenes`.
Too complicated to describe accurately, just look at the code. I'll mention the important things that can happen, but the triggering conditions are complicated.

* [[DrawStatusBar]] if [[Var IRQNMICommand]] == `IRQNMI_Standard`.
* Update tilemap strips if needed -- part of moving through a level?
* If [[Var UploadMarioStart]] is true, upload gfx for black screen messages.
* Restore the gfx clobbered by those messages.
* [[UploadAnimatedTilesAndColourFlash]]
* In the credits cutscene, maybe update the background.
* Call [[MarioGFXDMA]] -- to upload mario/yoshi/podoboo (fire enemy) gfx?
* [[LoadScrnImage]] -- "upload tilemap data", "Routine to upload a stripe image to VRAM (usually layer 3)".
* [[DoSomeSpriteDMA]] -- upload shadow OAM to the PPU.
* [[ControllerUpdate]] to read controller inputs, store mask/hold/various state in variables.

# 2. Common after lag/no-lag paths

Again, these are things that sometimes happen, with complicated conditions.

* If not a special level, upload the BG1 and BG2 layer scroll values.
* Enable vertical IRQ which will draw the status bar.
* Enable NMI, auto joypad reading.
* Enable/disable HDMA.
* Upload brightness.
* Upload BG3 scroll values as 0.

# 3. Common prelude

Restore registers, return from interrupt.