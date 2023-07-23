SET TASMTABS=[Your Path]\TASM\
[Your Path]\TASM\tasm64.exe boots.asm -t1802 -la -g0 -i -DTASM -DPicoElf -DSTGROM -DPICOELF
COPY boots.obj boots.hex
DEL boots.obj


