#function #NMI #graphics 

Part of bank 0 `I_NMI`, label `RegularLevelNMI` after having run the [[Common NMI entry]].

Runs when [[Var IRQNMICommand]] is one of `IRQNMI_Standard`, `IRQNMI_Cutscenes`, `IRQNMI_Overworld`.

1. (Re)apply the requested [[Var ColorSettings]], but ensure that colour math is not enabled for BG 3, even if requested.
2. Choose BG mode 1, with BG3 using high priority.
3. If the [[Var LagFlag]] is set, skip [[#When not lagging]] and go to TBD

# When not lagging

1. Set the [[Var LagFlag]] so the main loop can run after the NMI has ended.

# mystery palette function

`CODE_00A488`

* [[Var PaletteIndexTable]] is "which palette table to use": dynamic, copy, or main.

