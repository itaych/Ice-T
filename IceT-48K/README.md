# Ice-T v1.1 48K
This is an old version of Ice-T, dated July 9, 1995, that was intended for 48K machines. It was abandoned when I got my 130XE and started developing for machines with extended memory, but it's included here for completeness.

The sources here are taken from commit ab5fabe, converted to ATasm readable format, and slightly changed to generate a binary-identical result to the executable from the same snapshot. Note that for whatever historical reasons, the snapshot contained code and an executable that don't match exactly, and therefore the source code here is not the same code as in ab5fabe. The next commit will contain matching source code.

## Important Files
- `original_binaries/original_icet48.xex` - this is the original ICET.OBJ file from commit ab5fabe.
- `original_binaries/original_icet48_streamlined.xex` - this is the same file, streamlined to remove redundant binary file headers but containing the same code and data.
- `original_binaries/original_notice.ar0` - this is NOTICE.AR0, a file that ran at boot time (before the MyDOS menu) and presented a friendly welcome message to the user.
- `original_binaries/original_notice_streamlined.ar0` - a streamlined copy of the above.
- `notice.asm` - building this file will generate notice.ar0, identical to original_binaries/original_notice_streamlined.ar0.
- `vt.asm` - building this will generate icet48_with_r.xex, identical to original_binaries/original_icet48_streamlined.xex. This version includes a prepended R: handler (Atari 850 interface boot loader) and was for my personal use.
- `vtsend.asm` - building this will generate icet48.xex, which is the same as icet48_with_r.xex but without the prepended R: handler, hence the name (this is the version that I will *send* out to users).
- `build.sh` - this build script will perform the builds detailed above. You may need to edit it if ATasm is not located in the expected path.
