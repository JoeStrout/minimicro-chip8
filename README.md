# minimicro-chip8
A CHIP-8 emulator for Mini Micro

This is a program to simulate the [CHIP-8](https://en.wikipedia.org/wiki/CHIP-8) virtual computer in [Mini Micro](https://miniscript.org/MiniMicro/).

It was developed on Feb 27, 2022 during a live-stream on [Twitch](https://www.twitch.tv/joestrout/schedule), and then further developed the following week (Mar 06).  It runs well but is still missing a handful of features:

- the built-in 16-character font and the Fx29 (sprite_addr) instruction
- the Fx33 (BCD) instruction
- the Fx55 and Fx65 (register save/load) instructions
- the CHIP-8 sound (just an arbitrary tone played for Vx/60 seconds)
- control over emulation speed (though you can switch between run and single-step)

Despite this, it can run many CHIP-8 programs just fine, and shows the state of the machine when paused or single-stepping, including a disassembly of the memory around the program counter.

I've had a lot of fun with this project, and find the CHIP-8 a very pleasant environment to play with assembly code in.  I hope somebody runs with it and develops it into a nice CHIP-8 coding/play environment!
