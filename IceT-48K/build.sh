#!/bin/sh
set -e # abort on any error

# build program
../../atasm/src/atasm -mae -oicet48.xex vtsend.asm
../../atasm/src/atasm -mae -oicet48_with_r.xex vt.asm
../../atasm/src/atasm -mae -onotice.ar0 notice.asm

# run Altirra
if [ "$1" = "-a" ]; then
  /mnt/c/Users/Itay/Emulators/Atari/Altirra/Altirra64.exe icet48.xex
else
  echo
  echo "Note: you can run Altirra with -a."
fi
