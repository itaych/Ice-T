# Ice-T v1.1 48K
This is an old version of Ice-T, dated July 9, 1995, that was intended for 48K machines. It was abandoned when I got my 130XE and started developing for machines with extended memory, but it's included here for completeness.

The sources here are taken from commit ab5fabe and converted to ATasm readable format. Note that for whatever historical reasons, the snapshot contained code and an executable that don't match exactly, and therefore the binary generated here is not the same as the original. See the previous commit, 53fde20, for a version that does generate an identical binary.

## Important Files
- `notice.asm` - building this file will generate notice.ar0, a file that ran at boot time (before the MyDOS menu) and presented a friendly welcome message to the user.
- `vt.asm` - building this will generate icet48_with_r.xex. This version includes a prepended R: handler (Atari 850 interface boot loader) and was for my personal use.
- `vtsend.asm` - building this will generate icet48.xex, which does not include a prepended R: handler. This is the version for general release, hence the name (i.e. the version that I will *send* out to users).
- `build.sh` - this build script will perform the builds detailed above. You may need to edit it if ATasm is not located in the expected path.
