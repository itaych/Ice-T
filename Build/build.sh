#!/bin/sh
set -e # abort on any error

# build program
../../atasm/src/atasm -mae -I../src -I../fonts -o../bin/icet.xex ../src/icet.asm -l../bin/icet.lab -g../bin/icet.lst

# display some equates so we see how much memory we have left
echo
echo "Diagnostics"
echo "-----------"
grep -i "bytes_free_below_banked_memory\|bytes_free_bank_1\|bytes_free_bank_2" ../bin/icet.lab

# run Altirra
/mnt/c/Users/Itay/Emulators/Atari/Altirra/Altirra64.exe ../bin/icet.xex
