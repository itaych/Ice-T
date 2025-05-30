#!/bin/sh
set -e # abort on any error

rm -rf atrdisk
rm -rf release
rm -f release.7z

mkdir release
mkdir atrdisk

./build.sh
# Add files to disk image
cp ../bin/icet.xex atrdisk/icet.com
cp ../bin/icet_axlon.xex atrdisk/icetaxln.com
../../atasm/src/atasm -mae -I../Col80 ../Col80/col80.asm -oatrdisk/col80.com
../../atasm/src/atasm -mae -I../IceT-48K ../IceT-48K/vtsend.asm -oatrdisk/icet48k.com
cp ../RHandlers/* atrdisk/
cp ../Doc/icet.txt atrdisk/
cp ../Doc/vt102.txt atrdisk/
cp ../utils/AnimationDemo/icetdemo.vt atrdisk/
cp mydos/* atrdisk/

# Add files to .7z archive
cp ../bin/icet.xex release/
cp ../bin/icet_axlon.xex release/
cp atrdisk/icet48k.com release/icet_48k.xex
cp ../Doc/readme.txt release/
cp ../Doc/quickstart.txt release/
cp ../Doc/icet.txt release/
cp ../Doc/vt102.txt release/
cp ../Doc/icet_cfg.h release/
cp ../utils/AnimationDemo/icetdemo.vt release/

./dir2atr.exe -d -m -b MyDos4534 1040 icet.atr atrdisk
#/mnt/c/Users/Itay/Emulators/Atari/ATasm/Projects/Ice-T/Build/dir2atr.exe -d -m -b MyDos4534 1040 icet.atr atrdisk
cp icet.atr release/

BUILD_DIR=`pwd`
cd /mnt/c
PROG_FILES=$(wslpath -au "$(cmd.exe /c 'echo %programfiles%' | tr -d '\r\n')")
cd ${BUILD_DIR}/release
"${PROG_FILES}/7-Zip/7z.exe" a ../release.7z *
cd ..
rm -rf atrdisk
rm -rf release

# run Altirra if user specified -a
if [ "$1" = "-a" ]; then
  /mnt/c/Users/Itay/Emulators/Atari/Altirra/Altirra64.exe icet.atr
else
  echo
  echo "Note: you can run Altirra with -a."
fi
