		Building the Pico/Elf STG Video EPROM Image
		-------------------------------------------

PREREQUISITES

The Pico/Elf Spare Time Gizmos Video EPROM is made by combining the 
original components, minus Forth, with the video.hex file output from
this code.  Please see the original STG readme.txt file for more details.

These original Hex files are available in the stg/hex directory:

	boots	 - Pico/ELf v2 diagnostics, debugger and bootstrap
	sedit	 - Disk sector editor
	edtasm   - Interactive editor and assembler
	basic	 - BASIC interpreter
	visual02 - Visual02 monitor
	xmodem   - communications
	bios	 - BIOS for Elf/OS

New files:
	video.hex - Elf/OS video functions (from this repository)
	help.new  - Updated help text (without Forth menu item)

The assembled video.hex file is available in the bin/video directory 
and the help.new file is available in the stg directory.

Tool files compiled for Windows 10:
	romtext.exe  - STG tool to create hex file with help text
	rommerge.exe - STG tool to merge hex files 
	romcksum.exe - STG tool to update hex file with checksum

Description:
	
The video.hex file is produced by the Make_Rom.bat file from the 
video code in the src/video directory.  The code is assembled at the
A000H address and overlaps the original location of the Forth code.
One can also use the already assembled version of this file from the 
bin/video directory.

The updated help text is created from the help.new file available in
the stg directory.

The original STG ROM tool source files were updated to compile under the
Microsoft Visual Studio 2019 Community Edition C compiler for Windows 10.
These files had only minor changes mainly related to obsolete Windows 
pointer definitions.  The updated source files and executable files are
available in the stg/win10 directory.

Instructions:

After assembling the video.hex file from this code.  Place video.hex along
with the seven other hex files listed above, the three stg tool executable   
programs, the updated help text in help.new and the Make_Stg batch file into
a directory.  Run the Make_Stg batch file to create the StgVideo.hex file.
Load this file into an EPROM burner and create an EPROM with the code.

Credit:
The source for boots, the boots.hex file, the original help text and the tools
used to generate the EPROM image (e.g. romtext, rommerge and romcksum) are 
copyright (C) 2004-2021 by Spare Time Gizmos.  

In general, but not in every cases, these files are distributed under
the terms of the GNU General Public License, a copy of which is included with
this distribution in the file LICENSE.TXT.  Refer to the individual program
or source file for specific licensing terms.

The other EPROM components, including sedit, edtasm, basic, visual02, xmodem and
the bios are Copyright (C) 2004-2021 by Michael H Riley. Mike has kindly granted
permission to use these components.  This permission does not extend to third parties,
and if you want to use Mike's code, either separately or as part of another
EPROM, in your own commercial application you will need to obtain his permission.

Mike's software and contact information may be obtained from his web page,
http://www.elf-emulation.com.  The source for Mike's software, including his
rcasm assembler, are available on GitHub as the repositories for user riley65
available at the https://github.com/rileym65 url. 

The source for Elf/OS video routines used to create the video.hex file is
Copyright (c) 2021 by Gaston Williams and is available on GitHub at the 
https://github.com/fourstix/Elfos-video url.

Many thanks to the original authors for making their code available and for 
their patience in answering questions to create the video ROM.
