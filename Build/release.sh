#!/bin/sh
set -e # abort on any error

rm -rf atrdisk
rm -rf release
rm -f release.7z

mkdir release
mkdir atrdisk

./build.sh
../../atasm/src/atasm -mae -I../Col80 ../Col80/col80.asm -oatrdisk/col80.com
cp ../bin/icet.xex atrdisk/icet.com
cp ../bin/icet_axlon.xex atrdisk/icet4ax.com
cp ../RHandlers/* atrdisk/
cp ../Doc/readme.txt atrdisk/
cp ../Doc/icet.txt atrdisk/
cp ../Doc/vt102.txt atrdisk/
cp mydos/* atrdisk/

cp ../bin/icet.xex release/
cp ../bin/icet_axlon.xex release/
cp ../Doc/quickstart.txt release/
cp ../Doc/icet.txt release/
cp ../Doc/vt102.txt release/

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
