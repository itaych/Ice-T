# Ice-T v1.1 48K
This is an old version of Ice-T, dated July 9, 1995, that was intended for 48K machines. It was abandoned when I got my 130XE and started developing for machines with extended memory, but it's included here for completeness.
To explain the history of this directory:
- Commit ab5fabe contained the original source files in ATASCII format, a snapshot of my last known development directory.
- In that snapshot the executable did not match the sources exactly. For commit 53fde20 I converted these original sources to ATasm readable format but slightly modified them to match the executable (which was apparently a previous revision).
- In commit 64395e4 I restored the sources to match the originals.
- While there are no plans to actively maintain this version, in commit 5990d21 I fixed a couple of critical bugs that caused the version to not work at all in some common cases.
- For later commits see the git log, they should be self-explanatory.
## Important Files
- `icet.txt` - the user guide.
- `notice.asm` - building this file will generate notice.ar0, a file that ran at boot time (before the MyDOS menu) and presented a friendly welcome message to the user.
- `vt.asm` - building this will generate icet48_with_r.xex. This version includes a prepended R: handler (Atari 850 interface boot loader) and was for my personal use.
- `vtsend.asm` - building this will generate icet48.xex, which does not include a prepended R: handler. This is the version for general release, hence the name (i.e. the version that I will *send* out to users).
- `build.sh` - this build script will perform the builds detailed above. You may need to edit it if ATasm is not located in the expected path.
