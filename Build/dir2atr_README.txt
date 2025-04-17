AtariSIO tools V0.30

Copyright (C) 2003-2010 Matthias Reichl <hias@horus.com>

This program is proteced under the terms of the GNU General Public
License, version 2. Please read LICENSE for further details.

Visit http://www.horus.com/~hias/atari/ for new versions.
  
dir2atr
=======

With 'dir2atr' you can create a disk image from a directory on your PC.

Usage: dir2atr [options] [size] file.atr directory

If you don't specify the size (in sectors), dir2atr will automatically
calculate it so that all files in the directory will fit into the
image.

If you set the image size to 720 sectors (either SD or DD) or to 1040
SD sectors (the 1050 "enhanced" density format), the disk image
will be created using standard DOS 2.x format, otherwise dir2atr
creates an image in MyDOS format.

Note: in MyDOS format dir2atr also descends into subdirectories.

Options:

-d  create a double density (256 bytes per sector) image
    (default is single density, 128 byte per sector).

-m  create a MyDOS image (use this option to create a 720 or
    1040 sectors image with subdirectories).

-p  create a 'PICONAME.TXT' (long filenames for MyPicoDos) in
    each (sub-) directory of the image.

-P  like '-p', but the extension of is stripped from the long
    names in PICONAME.TXT. So, for example a file 'Boulder Dash.com'
    on your PC will show up as 'Boulder Dash' in MyPicoDos.

-b <dostype> create a bootable image. 

Bootable Images:

If you use one of the MyPicoDos modes, dir2atr will include the
'PICODOS.SYS' file in the disk image and also write the bootsectors.
This is more or less identical to initializing the disk using the
'myinit.com' program on your Atari.

A few other DOSes are supported in '-b', too, but dir2atr only
writes the bootsectors, you have to provide the DOS.SYS (and
optionally DUP.SYS) by yourself. Be careful to use the correct
DOS.SYS file, otherwise the disk won't work or the DOS might
behave strangely. dir2atr only checks for the presence of DOS.SYS
but not if it's the correct version!

Supported DOSes:
Dos20           DOS 2.0
Dos25           DOS 2.5
MyDos4533       MYDOS 4.53/3
MyDos4534       MYDOS 4.53/4
TurboDos21      Turbo Dos 2.1
TurboDos21HS    Turbo Dos 2.1 HS (ultra-speed support)
XDos243F        XDOS 2.43F ("fast" version / ultra-speed support)
XDos243N        XDOS 2.43N ("normal speed" version)

Supported MyPicoDos variants:
Currently the old 4.03, the last official release 4.04
and the 4.05 beta version of MyPicoDos are supported, in several
different configurations. I recommend using version 4.05 because
it comes with improved highspeed SIO support.

MyPicoDos 4.03 variants:
MyPicoDos403    standard SIO speed only
MyPicoDos403HS  highspeed SIO support

MyPicoDos 4.04 variants:
These versions (except for the barebone version) all include
highspeed SIO (HS) support plus optionally an atariserver remote
console (RC). Since most Atari emulators react allergic to the
highspeed SIO code, and the highspeed SIO also has to be disabled
to use MyPicoDos with (PBI) harddrives, there exist versions that have
highspeed SIO disabled by default (but it can be enabled manually
from within MyPicoDos):

MyPicoDos404    HS default: on   remote console: no
MyPicoDos404N   HS default: off  remote console: no
MyPicoDos404R   HS default: on   remote console: yes
MyPicoDos404RN  HS default: off  remote console: yes
MyPicoDos404B   barebone version: no highspeed SIO and no remote console

MyPicoDos 4.05 variants:
This version introduces an improved highspeed SIO code (up to 126kbit/sec,
Pokey divisor 0) and also speeds up loading of MyPicoDos by activating
the highspeed SIO code during the boot process. In case of an transmission
error the highspeed code is automatically switched off, so compatibility
with emulators is slightly improved. For full compatibility you can
also choose highspeed SIO to be automatically activated after booting
('A' versions) or be in a default 'off' ('N' versions).

4.05 also adds special version for SDrive users: after booting
MyPicoDos sends a special command to the SDrive to switch it
to Pokey divisor 0 (126kbit/sec) or 1 (110kbit/sec).

Then there's also the new 'PicoBoot' boot. This is an extremely
stripped down version that fits into the 3 boot sectors and loads
the first (COM/EXE/XEX) file on the disk. No other features
(menu, highspeed SIO, disabling basic, support for BIN/BAS, ...)
are supported.

Like in 4.04 there are also version which include the atariserver
remote console ('R' versions).

MyPicoDos405    HS enabled while booting   remote console: no
MyPicoDos405A   HS default: on after boot  remote console: no
MyPicoDos405N   HS default: off            remote console: no
MyPicoDos405R   HS enabled while booting   remote console: yes
MyPicoDos405RA  HS default: on after boot  remote console: yes
MyPicoDos405RN  HS default: off            remote console: yes
MyPicoDos405S0  Like 405, set SDrive to Pokey divisor 0
MyPicoDos405S1  Like 405, set SDrive to Pokey divisor 1
MyPicoDos405B   barebone version: no highspeed SIO, no remote console
PicoBoot405     minimal boot-sector only version

Examples:

dir2atr -d -b MyPicoDos405 -P games.atr my_games_dir

This creates a double-density MyDOS image named 'games.atr' from
the directory 'my_games_dir' (including subdirectories) with
MyPicoDos 4.05 (highspeed SIO enabled during booting) and with
MyPicoDos long filenames ('PICONAME.TXT').

