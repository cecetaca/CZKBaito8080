# CZKBaito8080
Just some **Intel 8080 instruction set** magic with **Swift**. Experimenting with **emulation** in order to expand my knowledge in the field of Computer Architecture and Organization.

**Clearly WIP.** Starting with a subset of the instruction set, but I'm aiming at full emulation at some point.
Ideally, having built a full i8080 emulator, I would like to emulate some nice arcade games on top of it. This would be my goal.

If you feel like checking it out right now, I recommend using the original タイトー Space Invaders binary as an input file for best results.
The reason: I'm iterating through the instructions of that particular file and implementing them one by one.

## Structure
The actual "machine", as I called it, consists of:
* **Functions** implementing the instructions.
* **Data structures** holding everything in place (the registers and flags as variables, memory as an array), might change them in the future with a better approach.
* **REPL** that goes through each byte, printing the corresponding instruction and calling its function, and also advancing the program counter as needed.

There is also a primitive **Cocoa "test app"**, which is basically a View Controller with the ability to call the "machine", allowing you to step through the execution. 
It's kind of useful, because you can see the values of the registers and flags as they change and so on.
Running the whole thing is logically not supported yet, as the subset of the instruction set is not yet complete.

## WIP and to-do (Ordered by priority)
1. Finishing the actual i8080 instruction set.
2. Transforming the "test app" into something more useful. (Debugger/trace thing?)
3. Graphics emulation for the Taito arcade machine. (CoreGraphics?)
4. Input emulation for the Taito arcade machine.
5. Sound emulation for the Taito arcade machine.
6. Possible ports. (GNUstep? iOS?)

## References
* **Intel 8080 Microcomputer System User's Manual:** Explains the inner workings of the CPU. Chapter 4 contains the full list of the instructions available, what they do and their corresponding instruction codes.
