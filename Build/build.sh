#!/bin/sh
set -e # abort on any error

# build program
../../atasm/src/atasm -mae -I../src -I../fonts -o../bin/icet.xex ../src/icet.asm -l../bin/icet.lab -g../bin/icet.lst

# also build Axlon memory compatible version
../../atasm/src/atasm -mae -I../src -I../fonts -o../bin/icet_axlon.xex ../src/icet.asm -DAXLON_SUPPORT > /dev/null 2>&1

# run Altirra
if [ "$1" = "-a" ]; then
  /mnt/c/Users/Itay/Emulators/Atari/Altirra/Altirra64.exe ../bin/icet.xex
else
  echo
  echo "Note: you can run Altirra with -a."
fi
