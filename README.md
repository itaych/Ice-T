## Ice-T XE - Telecommunications Software for the Atari 8-bit.

### Features
* Highly accurate VT-102, VT-52 and ANSI-BBS emulation, including boldface, blink, and limited color support.
* Takes advantage of extended RAM to provide many features.
* Incredible speed for the platform - supports up to 19,200 baud, typically with no data loss.
* Readable 80-columns, usable even with a color TV.
* Fully menu driven, very easy to use.
* Xmodem-CRC, Xmodem-1K, Ymodem-batch, Ymodem-G, Zmodem download protocols.
* Xmodem upload, ASCII upload, 16K capture buffer.
* 16K scrollback buffer.
* Macro support, with up to 12 macros of 64 characters each.
* Auto-dialer, with a directory of up to 20 entries.
* Built-in text file viewer and an animation file viewer.
* Fine scroll.
* Print screen and screen dump to file.

### Building
    git clone https://github.com/CycoPH/atasm.git
    git clone https://github.com/itaych/Ice-T.git
    cd atasm/src
    make
    cd ../../Ice-T/Build
    ./build.sh
This should generate `icet.xex` and `icet_axlon.xex` in the `Ice-T/bin` directory.

### Usage
In the "Doc" directory please see `icet.txt` for the full user guide, or `quickstart.txt` for a minimal guide on getting Ice-T running in the [Altirra](https://www.virtualdub.org/altirra.html)  Atari 8-bit emulator.
