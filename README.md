# Elfos-video
Video functions for 1861 Pixie Video Display written for the 1802 Pico/Elf v2 microcomputer.

This code provides support for a basic video functions on an 1861 Pixie Video display
driven by an Pico/Elf v2 1802 microcomputer running the Elf/OS operating system.  
It has been tested with the Pico/Elf v2 microcomputer by Mike Riley using the [PicoElfPixieVideoGLCDV2](https://github.com/fourstix/PicoElfPixieVideoGLCDV2) CDP1861 simulator.

The code is based on Richard Dienstknecht's original graphics code that was posted in the [Cosmac Elf Group on Groups.io.](https://groups.io/g/cosmacelf) The code is assembled with the [Macro Assembler AS](http://john.ccac.rwth-aachen.de:8000/as/) by Alfred Arnold,

Repository Contents
-------------------
* **/src/video/**  -- Assembly code source files for the Elf/OS Video functions.
  * StdDefs.asm - standard definitions and macros used in assembly source files
  * InitPicoElf.asm - initialization functions and includes
  * Graphics1861.asm - graphics routines for drawing on the CDP1861 display
  * Text1861.asm - routines to draw text characters on screen
  * Fonts.asm - font table for text functions
  * Tty1861.asm	- printing routines and other video functions for the CDP1861 display
  * VideoRom.asm	- Assemble Elf/OS video functions located in ROM.
  * bios.inc - Include file for Elf/OS bios definitions.
  * kernel.inc - Include file for Elf/OS kernel definitions.
  *
* **/src/**  -- Video programs for the Elf/OS
  * video.inc - Include file for video ROM definitions.
  * vstart.asm - Start video by allocating video buffers in high memory and set flags.
  * vtest.asm - Test video and show status
  * vstop.asm - Stop video, the -u option will also unload the video buffers and free up high memory.
  * HelloWorld.asm - Write a greeting to the display.
  * HelloWorld.bat - Batch file to assemble HelloWorld demo.
  * CharSet.asm - Write the character set to the display.
  * CharSet.bat - Batch file to assemble CharSet demo.
  * StringTest.asm - Write various strings to the display.
  