#variable #NMI 

Indicates that the non-interrupt game loop is taking too long to execute.

* The flag is set at reset, and at the end of the NMI handler.
* The main loop waits until the flag is set before executing, and clears the flag once it has finished executing.
* So the NMI handler can check the flag on entry. If set, the main loop is taking too long, and the NMI handler can act appropriately.