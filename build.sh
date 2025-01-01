
ASM6809="/Users/thibaut/.wine/drive_c/users/thibaut/AppData/Roaming/UGBASIC-IDE/asm6809.exe"

wine "$ASM6809" -v raycaster_v1.asm -o raycaster_v1.bin -l raycaster_v1.asm.listing
wine "$ASM6809" -v raycaster_v2.asm -o raycaster_v2.bin -l raycaster_v2.asm.listing


