# TCP2Con
Posted December 4, 2013 to [AtariAge](https://forums.atariage.com/topic/217539-ice-t-xe-276-released/?do=findComment&comment=2879458).

One of the things that's been bothering me is that when communicating with a remote Internet host we are at the mercy of whomever wrote the communications layer between the Atari and the Internet connection. In the case of Altirra there is an excellent Telnet client, thanks to my persistence and Phaeron's responsiveness and willingness to get it right, so we were lucky there. In the case of APE however the Telnet implementation is not perfect, and I doubt I can convince the author to mess with it. And neither of them offer SSH, which is the current standard for remote access while Telnet is losing support due to its security flaws.

In looking for a solution I came across an application named Plink, which is a component of the PuTTY suite. PuTTY is a terminal emulator for modern machines that includes an excellent Telnet/SSH/Rlogin implementation. It is also under constant development, and so is a good foundation to rely on. So, what is Plink? Plink is a subset of PuTTY, which opens the connection and takes care of all negotiations, security and binary transparency but does not do any terminal emulation - it's a simple stdin/out console application, useless on its own but just what we need. However there is a missing link needed to connect the Atari's terminal emulation to Plink's stdin/out.

I have implemented a simple proxy application named tcp2con that runs Plink as a slave process, receives a TCP connection from an Atari (real, through APE or emulated by Altirra) and bridges the two, such that the Atari only needs to emulate the terminal while Plink handles the communications protocol.

I've attached the source code (for Visual Studio 2010) and x86 executable. Here's how to use it. Perform these steps on the same machine on which APE or Altirra is running:

 1. Download Plink.exe and Putty.exe from the Putty download page (google it).
 2. Open putty and change the default Terminal type string to vt100 (or vt102, ansi, vt52). The default setting "xterm" will cause Linux hosts to send control codes Ice-T does not recognize. Connection > Data > Terminal-type, fill in "vt100" then Session, click "Default Settings" and Save. Close PuTTY.
 3. Put tcp2con.exe (from the attached zip) and plink.exe in the same directory.
 4. Open a command window in that directory and type: tcp2con plink.exe *parameters*, where the parameters are whatever you'd give putty if you were using it directly. For example, "-telnet 10.0.0.1" or "-ssh username@10.0.0.2" or the name of a saved configuration in putty. Make sure the saved configuration has the terminal type set properly (see step 2). With a saved configuration you can even connect the Atari to a real modem attached to your PC's serial port.
 5. Load Ice-T (or any other terminal program) on the Atari.
 6. Disable the Telnet protocol on the Atari side. APE: use Server mode and type atb2 . Apparently you have to do this before every time you connect. In Altirra disable "Emulate Telnet protocol".
 7. Connect: APE users type "atd localhost 9001". In Altirra use "atdi" instead of "atd". If all went well you should now see the login prompt of the destination machine specified in the tcp2con command line. Note: If using SSH, Plink prompts you for the password. It seems that when typing the password you need to finish with Ctrl-J rather than `<return>`. I have no simple solution for this.
 8. Enjoy!

That should take care of most use cases. The application also has a few command line options:
 - -v : print version information and exit.
 - -p=port : set listening port number (default 9001).
 - -o : once - exit after one session. (normally it will wait for another connection.)
 - -a : public access. Allows access from addresses other than localhost. This is a security risk and is not recommended.

Finally, note that you can set tcp2con to use any other console application instead of plink.exe. I can't think of a reason why you'd want to but the option is there. Of course this can also pose a security risk so use with care.

Let me know if you find any problems, or have any feature suggestions. Right now there is one known issue: If the slave process (plink) outputs anything to stderr, the message is only shown when the process exits. This causes a few out of place messages to appear when logging out (such as "Using username ..." which should appear in the beginning of the session).
