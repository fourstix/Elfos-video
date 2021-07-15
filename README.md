# Elfos-video
Video functions for 1861 Pixie Video Display written for the 1802 Pico/Elf v2 microcomputer.

This code provides support for a basic video functions on an 1861 Pixie Video display
driven by an Pico/Elf v2 1802 microcomputer running the Elf/OS operating system.  
It has been tested with the Pico/Elf v2 microcomputer by Mike Riley using the [PicoElfPixieVideoGLCDV2](https://github.com/fourstix/PicoElfPixieVideoGLCDV2) CDP1861 simulator. Information about the Pico/Elf v2 is available at
[Elf-Emulation.com](http://www.elf-emulation.com/).


The code is based on Richard Dienstknecht's original graphics code that was posted in the [Cosmac Elf Group on Groups.io.](https://groups.io/g/cosmacelf) The code is assembled with the [Macro Assembler AS](http://john.ccac.rwth-aachen.de:8000/as/) by Alfred Arnold.
 
Examples
--------

<table class="table table-hover table-striped table-bordered">
  <tr align="center">
   <td><img width=300 src="https://github.com/fourstix/Elfos-video/blob/main/pics/HelloWorld.jpg"></td>
   <td><img width=300 src="https://github.com/fourstix/Elfos-video/blob/main/pics/CharSet.jpg"></td> 
  </tr>
  <tr align="center">
    <td>Hello World demo</td>
    <td>Character Set Demo</td>
  </tr>
  <tr align="center">
   <td><img width=300 src="https://github.com/fourstix/Elfos-video/blob/main/pics/StringTest.jpg"></td>
   <td><img width=300 src="https://github.com/fourstix/Elfos-video/blob/main/pics/SpriteDemo.jpg"></td> 
  </tr>
  <tr align="center">
    <td>String test demo</td>
    <td>Sprite Demo</td>
  </tr>
  <tr align="center">
   <td><img width=300 src="https://github.com/fourstix/Elfos-video/blob/main/pics/HappyCat.jpg"></td>
   <td><img width=300 src="https://github.com/fourstix/Elfos-video/blob/main/pics/HappyDog.jpg"></td> 
  </tr>
  <tr align="center">
    <td>Happy Cat 32x64 bit graphics demo</td>
    <td>Happy Dog 64x64 bit graphics demo</td>
  </tr>
  <tr align="center">
   <td ><img src="https://github.com/fourstix/Elfos-video/blob/main/pics/PixelDemo.jpg"></td>
   <td ><img src="https://github.com/fourstix/Elfos-video/blob/main/pics/BasicStars.jpg"></td>
  </tr>
  <tr align="center">
   <td >Pixel Graphics Demo.</td>
   <td >Basic/02 DrawStars Elfos-video Demo.</td>
  </tr>
  <tr align="center">
   <td ><img src="https://github.com/fourstix/Elfos-video/blob/main/pics/BasicSine.jpg"></td>
   <td ><img src="https://github.com/fourstix/Elfos-video/blob/main/pics/BasicCircle.jpg"></td>
  </tr>
  <tr align="center">
   <td >Basic/02 DrawSine Elfos-video Demo.</td>
   <td >Basic/02 DrawCircle Elfos-video Demo.</td>
  </tr>  
  <tr align="center">
   <td colspan="2"><img src="https://github.com/fourstix/Elfos-video/blob/main/pics/Config.jpg"></td>
  </tr>
  <tr align="center">
   <td colspan="2">Pico/Elf v2 with the STG v1.10 + Video EPROM and an STG RTC/NVR/UART card and a PicoElf Pixie Video GLCD card showing the output from the echo command.</td>
  </tr>
</table>

Elf/OS Video Programs
---------------------
**vstart** - Start Video
* Allocate the video buffers in high memory, if needed, and set the video flag to true.  The display can be updated
until a *vstop* command is issued.
  
**vstop** - Stop Video
* Option: -u
* Set the video flag to false. The display will not be updated until *vstart* command is issued. 
* The command *vstop -u* will stop the video and unload the video buffers returning the high memory to the system, if possible.

**vtest** - Test the Video and show status
* Test the video and print out whether the video buffers are allocated, whether video is on and the location of the video buffers in high memory.

**cls** - Clear the screen
* Clear the screen

**draw *filename***
* Read a 256-byte or 512-byte image from the file *filename* and draw it the display.

**capture *filename***
* Write the image in the video buffer to a 512-byte file named *filename* on the disk.

**echo**
* Turn echo on and off.  When echo is on, text written using the O_MSG, O_TYPE and O_INMSG bios routines will be written to the display and to the serial output.  
* If echo is already on, *echo* will turn the echo function off.  
* The echo command is only available when the video routines are in ROM, since they must be available to the Elf/OS after the *echo* command has run.

**write *text***
* Write the string *text* to the display.

**CharSet**
* Demo program to print charater set to the display.

**HappyCat**
* Demo program to draw a 32x64 bit image of a cat to the display. 

**HappyDog** 
* Demo program to draw a 64x64 bit image of a dog to the display.
  
**HelloWorld**
* Demo program to print the greeting "Hello, World!" to the display.

**SpriteDemo**
* Demo program to draw sprite graphics to the display.

**StringTest**
* Demo program to print various strings to the display.

**PixelDemo**
* Demo program to draw pixel graphics on the display.

Video API
---------
**ValidateVideo** - Validate video buffers are loaded into high memory
* Returns RF.0 equal Zero if valid, non-zero if not valid

**AllocateVideoBuffers** -- Allocate video buffers in high memory. 

**VideoOn** -- Turn video on

**VideoOff** -- Turn video off

**UnloadVideo** -- Unload video buffers and return high memory to system.

**IsVideoReady** -- Test if video buffers are loaded and video is on.
* Returns RF.0 non-zero (true) if ready, zero if not ready
* Safe - This function saves and restores registers used.

**UpdateVideo** -- Update the video display. Briefly turns on Interrupts and DMA to update display.

**ClearScreen** -- Clear the screen, reset the text cursor to home.

**PutChar** -- Write a character to the display at the cursor position.
* RC.0 contains the ASCII code of the character to write.

**Println** -- Write a string to the display at the cursor position followed by a new line character.
* RF contains an pointer to the address of the character buffer with the null-terminated string.

**Print** -- Write a string to the display at the cursor position.
* RF contains an pointer to the address of the character buffer with the null-terminated string.

**IsEchoOn** -- Get the status of the Echo function
* Returns RF.0 non-zero (true) if on, zero if off.
* Safe - This function saves and restores registers used.

**EchoOn** -- Turn echo on. Text written by O_TYPE, O_MSG and O_INMSG will be printed to the display and to the serial output.

**EchoOff** -- Turn echo off. Text written by O_TYPE, O_MSG and O_INMSG will no longer be copied to the display.

**DrawString** -- Write a text string to an explicit X,Y location on the display.
* RA.0 contains the X coordinate of the string
* RA.1 contains the Y coordinate of the string
* RF contains the address pointer to a character buffer with the null-terminated string.

**Draw32x64Image** -- Draw an 32x64 bit image to the display.
* RF contains the address pointer to 256 byte buffer with the image data

**Draw64x64Image** -- Draw an 32x64 bit image to the display.
* RF contains the address pointer to 512 byte buffer with the image data

**DrawSprite** -- Draw a graphical sprite to the display
* RA.0 contains the X coordinate of the sprite
* RA.1 contains the Y coordinate of the sprite
* RD contains the size of the sprite in bytes
* RF contains the address pointer to a buffer with the sprite image data.

**DrawPixel** -- Draw a pixel on the display
* RA.0 contains the X coordinate of the pixel to set
* RA.1 contains the Y coordinate of the pixel to set

**SaveVideoRegs** -- Save all registers affected by video routines into the video buffer
* The R9, RA, RB, RC, RD and RF registers are saved in the video buffer.
* Safe - This function can be used to save video registers before calling video routines.

**RestoreVideoRegs** -- Restore all registers affected by video routines from the video buffer
* Restore the R9, RA, RB, RC, RD and RF registers with values retrieved from the video buffer.
* Safe - This function can be used to restore video registers after calling video routines.

Video API Notes
---------------
* AllocateVideoBuffers should be called first to set up the Video Buffers into HiMem.
  The ValidateVideo function can be used to verify video buffers are allocated.

* VideoOn should be called to initialize the system variables, and the UpdateVideo
  function should be used to display the video buffer after a change.

* VideoOff should be used to turn the video off and clear the system variables.

* The UnloadVideo can be used to return video buffer memory to the system.

* The IsVideoReady and IsEchoOn functions save and restore registers that they use and are 
  safe. The other video functions do not preserve register values.

* The SaveVideoRegs and RestoreVideoRegs functions can be used to make video functions safe
  by saving all registers used by video routines into the video buffer before any calls are made to video routines, and then restoring them afterwards.

Basic/02 Example Programs
-------------------------
The Basic/02 compiler written by Mike Riley supports blocks of 1802 Assembly code 
through the asm statement.  The Basic/02 compiler is available on Github in the 
[rileym65/Basic-02](https://github.com/rileym65/Basic-02) repository.

These examples show how to call the Elfos-video routines from inside a Basic/02 program.
DrawStars is an example of a 16-bit Basic/02 program using the Elfos-video routines to
display a field of random dots.  DrawSine and DrawCircle are 32-bit programs using floating point functions to draw a sine wave and a circle on the video display using the Elfos-video drawpixel function.

**DrawStars** 
* Basic/02 demo program to draw a random set of dots on the display.
  
**DrawSine**
* Basic/02 demo program to draw a sine wave on the display.

**DrawCircle**
* Basic/02 demo program to draw a circle on the display.

Repository Contents
-------------------
* **/src/video/**  -- Assembly code source files for the Elf/OS Video functions.
  * StdDefs.asm - standard definitions and macros used in assembly source files
  * InitPicoElf.asm - initialization functions and includes
  * Graphics1861.asm - graphics routines for drawing on the CDP1861 display
  * Text1861.asm - routines to draw text characters on screen
  * Fonts.asm - font table for text functions
  * Tty1861.asm	- printing routines and other video functions for the CDP1861 display
  * VideoRom.asm	- Assembly file to locate the Elf/OS video functions in ROM.
  * bios.inc - Include file for Elf/OS bios definitions from [rileym65/Elf-BIOS](https://github.com/rileym65/Elf-BIOS)
  * kernel.inc - Include file for Elf/OS kernel definitions from [rileym65/Elf-Elfos-Kernel](https://github.com/rileym65/Elf-Elfos-Kernel)
  These files are used to create the video.hex file used for the ROM images.
* **/src/asm/**  -- Video programs for the Elf/OS
  * **video.inc** - Include file for video ROM definitions.
  * **vstart.asm** - Start video by allocating video buffers in high memory and set flags. Use the vstart.bat batch file to assemble the vstart command
  * **vtest.asm** - Test video and show status. Use the vtest.bat batch file to assemble vtest command.
  * **vstop.asm** - Stop video, the -u option will also unload the video buffers and free up high memory.  Use the vstop.bat batch file to assemble the vstop command.
  * **cls.asm** - Command to clear the display. Use the batch file Make_Cls.bat to assemble cls command.
  * **capture.asm** - Command to capture the display image into a file. Use the batch file Capture.bat to assemble the capture command.
  * **draw.asm** - Command to draw an image on the display. Use the Make_Draw.bat batch file to assemble the draw command.
  * **echo.asm** - Command to echo text from the Elf/OS to the display. Use the Make_Echo.bat batch file to assemble the echo command.
  * **write.asm** - Command to write text to the display. Use the Make_Write.bat batch file to assemble the write command.
  * **HappyCat.asm** - Draw a 32x64 bit image of a cat to the display. Use the HappyCat.bat batch file to assemble the HappyCat demo.
  * **HappyDog.asm** - Draw a 64x64 bit image of a dog to the display. Use the HappyDog.bat batch file to assemble the HappyDog demo.  
  * **HelloWorld.asm** - Write a greeting to the display. Use the HelloWorld.bat batch file to assemble HelloWorld demo.
  * **CharSet.asm** - Write the character set to the display.  Use the CharSet.bat batch file to assemble CharSet demo.
  * **SpriteDemo.asm** - Draw sprites on the display.  Use the SpriteDemo.bat batch file to assemble SpriteDemo.
  * **StringTest.asm** - Write various strings to the display. Use the StringTest.bat batch file to assemble StringTest demo.
  * **PixelDemo.asm** - Draw pixels on the display.  Use the PixelDemo.bat batch file to assemble PixelDemo.
  * **bios.inc** - Include file for Elf/OS bios definitions from [rileym65/Elf-BIOS](https://github.com/rileym65/Elf-BIOS)
  * **kernel.inc** - Include file for Elf/OS kernel definitions from [rileym65/Elf-Elfos-Kernel](https://github.com/rileym65/Elf-Elfos-Kernel)
  * **StdDefs.asm** - standard definitions and macros used in assembly source files.  
  * These files can be compiled to run with the video routines in ROM or in the command memory, except
  for echo which works only with the video routines in ROM.  Setting the VideoCode constant to "ROM"
  in the code will use the addresses in video.inc to locate the routines, setting the VideoCode constant
  to MEM will locate the routines in the Elf/OS user memory.  The echo command relies on the routines
  remaining available while the Elf/OS is running, so it requires the routines to be located in ROM.
  * **/src/bas/** -- Example programs for the Basic/02 compiler using Elf-video API routines located in ROM.
    * **DrawStars.bas** - Basic/02 16-bit program that uses the Elfos-video API in ROM to draw random dots on the display. Use the DrawStars.bat batch file to compile the program.
    * **DrawSine.bas** - Basic/02 32-bit program that uses the Elfos-video API in ROM to draw a sine wave on the display. Use the DrawSine.bat batch file to compile the program.
    * **DrawStars.bas** - Basic/02 32-bit program that uses the Elfos-video API in ROM to draw a circle on the display.  Use the DrawCircle.bat batch file to compile the program.    
* **/bin/video/**  -- Assembled binary code from the source files.
  * video.hex - Hex file assembled for video source.
  * **/bin/video/mem/** -- Binary files assembled from the source files with the video routines located in memory.  These files can be loaded into the Elf/OS file system using the xr or xrb command.
  * **/bin/video/rom/** -- Binary files assembled from the source files with the video routines located in ROM.  These files can be loaded into the Elf/OS file system using the xr or xrb command.
* **/bin/bas/** -- Binary files compiled with the Basic/02 compiler for Elf-video API routines located in ROM.
* **/bin/pev2_rom/**  -- Pico/Elf v2 Runtime ROM with video routines.  
  * runtime+video.hex - Hex file for Pico/Elf v2 Runtime with assembled video routines added at address 9D00H.
* **/bin/stg_rom/**  -- Spare Time Gizmos v1.10 ROM with video routines.  
  * StgVideo.hex - Hex file for Spare Time Gizmos v1.10 and assembled video routines added at address 9D00H.
* **/utils/pev2_rom/**  -- Utility files to create Pico/Elf v2 Runtime ROM with video routines. 
  * runtime.hex - [Hex file for Pico/Elf v2 Runtime](http://www.elf-emulation.com/software/picoelf/runtime.hex) from [Elf-Emulation](http://www.elf-emulation.com/software.html) website.    
* **/utils/stg_rom/**  -- Utility files to create Spare Time Gizmos v1.10 ROM with video routines.  
  * help.new - Updated help text with Pixie Video test enabled.
  * Make_Stg.bat - Batch files to run the STG ROM tools to create the STG v1.10 ROM with video routines.
  * readme.txt - Updated detailed information on how the ROM is created with video routines in place of the RC Forth code.
  * readme_original.txt - Original detailed information on how the STG v1.10 ROM is created.
* **/utils/stg_rom/boots/** -- Updated Boots monitor program to include video routines and pixie video test.  Based on source files from the [Elf2K and PicoElf EPROM v1.10 source files](https://groups.io/g/cosmacelf/files/STG%20Elf2K/Elf2K%20and%20PicoElf%20EPROM%20v107.zip) in the files section of the [CosmacElf group](https://groups.io/g/cosmacelf) on groups.io.  More information is available on the [Spare Time Gizmos](http://www.sparetimegizmos.com/Hardware/Elf2K.htm) website, especially in the [Cosmac ELf 2000 User's Manual](http://www.sparetimegizmos.com/Downloads/Elf2k.pdf).
  * boots.asm - Updated Boots monitor source to include video routines.
  * boots.inc - Included file with definitions for Boots monitor.
  * config.inc - Included configuration definitions for a Pico/Elf v2 with Pixie Video.
  * hardware.inc - Included hardware definitions for a Pico/Elf v2 with Pixie Video.
  * bios.hex - Bios routines assembled from [rileym65/Elf-BIOS](https://github.com/rileym65/Elf-BIOS) 
  * make_boots.bat - Windows batch file to create boots.hex file
* **/utils/stg_rom/hex/**  -- Original program hex files used to create the STG v1.10 rom
  * bios.hex - Bios routines assembled from [rileym65/Elf-BIOS](https://github.com/rileym65/Elf-BIOS)  
  * boots.hex - Bootstrap and monitor program for the Pico/Elf v2 created from source files based on the [Elf2K and PicoElf EPROM v1.10 source files](https://groups.io/g/cosmacelf/files/STG%20Elf2K/Elf2K%20and%20PicoElf%20EPROM%20v107.zip) in the files section of the [CosmacElf group](https://groups.io/g/cosmacelf) on groups.io and modified as listed above.  More information is available on the [Spare Time Gizmos](http://www.sparetimegizmos.com/Hardware/Elf2K.htm) website, especially in the [Cosmac ELf 2000 User's Manual](http://www.sparetimegizmos.com/Downloads/Elf2k.pdf).
  * edtasm.hex - Edit/Asm program assembled from [rileym65/Elf-EDTASM](https://github.com/rileym65/Elf-EDTASM)
  * rcbasic.hex - BASIC program assembled from [rileym65/Elf-RcBasic](https://github.com/rileym65/Elf-RcBasic)
  * forth.hex - Forth program assembled from [rileym65/Elf-RcForth](https://github.com/rileym65/Elf-RcForth)
  * sedit.hex - Sedit program assembled from [rileym65/Elf-Elfos-sedit](https://github.com/rileym65/Elf-Elfos-sedit)
  * visual02.hex - Visual02 program assembled from [rileym65/Elf-Visual02](https://github.com/rileym65/Elf-Visual02)
  * xmodem.hex - XModem communication routines similar to those used in [rileym65/Elf-diskless](https://github.com/rileym65/Elf-diskless)
* **/utils/stg_rom/tools_win10** -- Spare Time Gizmos Rom tools compiled for Windows 10 using the Microsoft Visual Studio for C Community Edition C compiler. Except for a few edits to update some references for Windows 10, the source files are largely unchanged. The source files for the [Elf2K and PicoElf EPROM v1.10](https://groups.io/g/cosmacelf/files/STG%20Elf2K/Elf2K%20and%20PicoElf%20EPROM%20v110%20BIOS%201.0.9.zip) are available in the files section of the [CosmacElf group](https://groups.io/g/cosmacelf) on groups.io.
  * readme_tools.txt - Original information file from Spare Time Gizmos
  * romcksum.c - Tool to generate checksom for the ROM code.
  * romcksum.exe - Executable file for Windows 10
  * rommerge.c - Tool to merge hex files into a single combined ROM hex files
  * rommerge.exe - Executable file for Windows 10.    
  * romtext.c - Tool generate ROM help information from a text file, such as help.new 
  * romtext.exe - Executable file for Windows 10.
* **/utils/bas/**  -- Basic/02 compiler  used to compile the demo programs.  Please check the [rileym65/Basic-02](https://github.com/rileym65/Basic-02) repository for the latest version of Basic/02.
  * sbc.exe - Windows 10 executable version of the Basic/02 compiler.
  * sbc.doc - Basic/02 documentation.
* **/pics/** -- Example pictures for the repository documentation 

STG v1.10 + Video ROM Memory Map
--------------------------------
<table class="table table-hover table-striped table-bordered">
  <tr align="center">
   <th colspan="2">Address Range</th>
   <th>Program</th>
   <th>Size</th> 
  </tr>
  <tr align="center">
   <th>Start</th>
   <th>Stop</th>
   <th>Name</th>
   <th>in Pages</th> 
  </tr>
  <tr align="center">
   <td>8000H</td>
   <td>94FFH</td> 
   <td>Boots Monitor</td>
   <td>18</td> 
  </tr>
  <tr align="center">
   <td>9500H</td>
   <td>9CFFH</td> 
   <td>Help Menu</td>
   <td>8</td> 
  </tr>
  <tr align="center">
   <td>9D00H</td>
   <td>A5FFH</td> 
   <td>Video API</td>
   <td>9</td> 
  </tr>
  <tr align="center">
   <td>A600H</td>
   <td>B4FFH</td> 
   <td>Forth</td>
   <td>15</td> 
  </tr>
  <tr align="center">
   <td>B500H</td>
   <td>C1FFH</td> 
   <td>EDTASM</td>
   <td>13</td> 
  </tr>     
  <tr align="center">
   <td>C200H</td>
   <td>D2FFH</td> 
   <td>Visual/02</td>
   <td>17</td> 
  </tr>  
  <tr align="center">
   <td>D300H</td>
   <td>D5FFH</td> 
   <td>SEDIT</td>
   <td>3</td> 
  </tr>  
  <tr align="center">
   <td>D600H</td>
   <td>EFFFH</td> 
   <td>BASIC</td>
   <td>26</td> 
  </tr> 
  <tr align="center">
   <td>F000H</td>
   <td>F2FFH</td> 
   <td>XModem</td>
   <td>3</td> 
   <tr align="center">
    <td>F300H</td>
    <td>FFFFH</td> 
    <td>BIOS</td>
    <td>14</td> 
  </tr>     
</table>

Elfos-Video API ROM Memory Map
------------------------------
These values are defined in the video.inc include file.
<table class="table table-hover table-striped table-bordered">
  <tr align="center">
    <th>API Name</th>
    <th>Address</th>
    <th colspan="2">Description</th>  
  </tr>
  <tr align="center">
    <td colspan="4">Safe - These Video API Routines save and restore registers used.
    </td>
  </tr>
  <tr align="center">
    <td>IsVideoReady</td>
    <td>A545H</td>
    <td colspan="2">Check that the video driver is loaded and started.</td> 
  </tr>       
  <tr align="center">
    <td>IsEchoOn</td>
    <td>A475H</td>
    <td colspan="2">Get the Echo Flag from the video buffers.</td> 
  </tr>
  <tr align="center">
    <td>SaveVideoRegs</td>
    <td>A218H</td> 
    <td colspan="2">Save all registers affected by video routines into the video buffer.</td>
  </tr>       
  <tr align="center">
    <td>RestoreVideoRegs</td>
    <td>A249H</td>
    <td colspan="2">Restore all registers affected by video routines from the video buffer.</td>
  </tr>
  <tr align="center">       
    <td colspan="2">Unsafe - These Video API Routines do *NOT* save and restore registers used.  The SaveVideoRegs and RestoreVideoRegs routines can be used to call them safely.
    </td>
  </tr>       
  <tr align="center">
    <td>AllocateVideoBuffers</td>
    <td>A1CCH</td>
    <td colspan="2">This routine should be called first to set up the Video Buffers in HiMem.</td> 
  </tr>
  <tr align="center">
    <td>ValidateVideo</td>
    <td>A1B1H</td> 
    <td colspan="2">Verify the Video Buffer is loaded into HiMem.</td>
  </tr>
  <tr align="center">
    <td>VideoOn</td>
    <td>9FF5H</td> 
    <td colspan="2">Initialize the Video Buffer to turn on video.</td>
  </tr>
  <tr align="center">
    <td>VideoOff</td>
    <td>A00BH</td> 
    <td colspan="2">Turn the video off and clear the Video Buffer variables.</td>
  </tr>
  <tr align="center">
    <td>UnloadVideo</td>
    <td>A3BFH</td> 
    <td colspan="2">Return the Video Buffer memory to the system.</td>
  </tr>
  <tr align="center">
    <td>UpdateVideo</td>
    <td>A280H</td> 
    <td colspan="2"Display the Video Buffer after a change.</td>
  </tr>
  <tr align="center">
    <td>ClearScreen</td>
    <td>A0C9H</td> 
    <td colspan="2"Blank the Video Buffer and home the cursor.</td>
  </tr>
  <tr align="center">
    <td>PutChar</td>
    <td>9FC7H</td> 
    <td colspan="2"Write a character to the Video Buffer and advance the cursor.</td>
  </tr>
  <tr align="center">
    <td>Print</td>
    <td>A185H</td> 
    <td colspan="2">Read characters from a string and write them to the Video Buffer, advancing the cursor.</td>
  </tr>
  <tr align="center">
    <td>Println</td>
    <td>A199H</td> 
    <td colspan="2">Read characters from a string and write them to the Video Buffer, advancing the cursor. Then write a new line character and move the cursor to the next line..</td>
  </tr>
  <tr align="center">
    <td>EchoOn</td>
    <td>A4C7H</td> 
    <td colspan="2">Save kernel vectors in Video Buffer and map them to video display functions.</td>
  </tr>    
  <tr align="center">
    <td>EchoOn</td>
    <td>A4C7H</td> 
    <td colspan="2">Save the character output kernel vectors in the Video Buffer and map them to echo display functions.</td>
  </tr>
  <tr align="center">
    <td>EchoOff</td>
    <td>A4EFH</td> 
    <td colspan="2">Restore the character output kernel vectors from the Video Buffer.</td>
  </tr>
  <tr align="center">
    <td>DrawString</td>
    <td>9ECCH</td> 
    <td colspan="2">Write a string into the video buffer at the specified display coordinates.</td>
  </tr>
  <tr align="center">
    <td>Draw32x64Image</td>
    <td>A514H</td> 
    <td colspan="2">Copy a 32x64 bit image (256 bytes) into the video buffer.</td>
  </tr>
  <tr align="center">
    <td>Draw64x64Image</td>
    <td>A3CFH</td> 
    <td colspan="2">Copy a 64x64 bit image (512 bytes) into the video buffer.</td>
  </tr>
  <tr align="center">
    <td>DrawSprite</td>
    <td>9E61H</td> 
    <td colspan="2">Copy an image into the video buffer at the specified display coordinates.</td>
  </tr>
  <tr align="center">
    <td>DrawPixel</td>
    <td>A566H</td> 
    <td colspan="2">Set a single pixel in the video buffer at the specified display coordinates.</td>
  </tr>                     
</table>
License Information
-------------------

This code is public domain under the MIT License, but please buy me a beer
if you use this and we meet someday (Beerware).

References to any products, programs or services do not imply
that they will be available in all countries in which their respective owner operates.

Any company, product, or services names may be trademarks or services marks of others.

All libraries used in this code are copyright their respective authors.

This video code is based on a graphics code library written by Richard Dienstknecht

1861 Graphics Code Library
Copyright (c) 2004-2021 by Richard Dienstknecht

Macro Assembler AS
Copyright (c) 1996-2021 by Alfred Arnold
  
The Pico/Elf v2 1802 microcomputer hardware and software
Copyright (c) 2004-2021 by Mike Riley.

Elf/OS BIOS and Elf/OS Software
Copyright (c) 2004-2021 by Mike Riley.

Spare Time Gizmos Pico Elf EProm v1.10 
Copyright (C) 2004-2021 by Spare Time Gizmos
 
Many thanks to the original authors for making their designs and code available as open source.
Special thanks to Mike Riley and Bob Armstrong for their patience and help.
 
This code, firmware, and software is released under the [MIT License](http://opensource.org/licenses/MIT).

The MIT License (MIT)

Copyright (c) 2021 by Gaston Williams

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

**THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.**
         
