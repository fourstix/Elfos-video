romtext -a38144 help.new help.hex
rommerge -s32k -o32768 merged.hex boots.hex video.hex bios.hex sedit.hex forth.hex edtasm.hex rcbasic.hex visual02.hex xmodem.hex help.hex 
romcksum merged.hex -s32k -o32768 -c32764 StgVideo.hex