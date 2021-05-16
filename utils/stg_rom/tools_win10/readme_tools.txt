Elf 2000 EPROM Tools
--------------------

  This archive contains the source for the custom tools used to build the Elf
2000 EPROM image.  These includes

     romtext  - convert an ASCII file (e.g. the help text) to an EPROM image
     rommerge - merge multiple HEX files into a single EPROM image
     romcksum - compute Data IO/EEtools compatible checksum and store in EPROM


  This archive contains only the source for these three tools.  You can find 
executable images for DOS/Windows in the v88-source file, along with a Makefile
that uses them to rebuild the Elf 2K EPROM.  

  NOTE that there are two versions of the romcksum program included in this
archive.  The original version is romcksum-old.c and is the one that was used
back in 2006 to build the Elf 2K EPROMs.  Somewhat later I used the same program
for a different project and discovered a few problems with it.  I rewrote it to
fix some of the issues, and the result is romcksum.c.  This new version should
be completely backward compatible with the old one and the new one should work
perfectly well for building Elf 2K images, but since I haven't tested that and
that's not how it was originally done, I've included the original version as
well.

 All programs in this archive are copyright (C) 1998-2017 by Spare Time Gizmos.
These files are distributed under the terms of the GNU General Public License,
version 2, a copy of which is included with this distribution in the file
LICENSE.TXT.  Please refer to the individual program or source file for specific
licensing terms.

