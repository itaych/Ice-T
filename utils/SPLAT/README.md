# SPLAT
Posted June 2, 2014 to [AtariAge](https://forums.atariage.com/topic/217245-ice-t-xe-275-released/page/2/#findComment-3002557).

*This was posted in response to a user reporting serial port issues.*

Actually I have a better idea for you. I'm attaching SPLAT.BAS. This was the very first proof of concept I did in 1992 or so before starting Ice-T - a dead simple Atari BASIC program that opened the serial port in 300 baud and let you communicate with whatever's on the serial port (modem in my case). What you can do with it is play freely with the XIO commands, twiddle the settings and figure out what's wrong with your setup.

Open the PRC manual (it's on Atarimania if you don't have it), read about the XIOs to understand the port opening sequence, and try to figure out what's wrong. I believe I enabled ATASCII/ASCII translation here so I wouldn't need to code the translation in BASIC, so try disabling that and see what happens (you'll have to press ctrl-J or ctrl-M instead of Return to send an end of line, but it should still *work*). In Ice-T this is of course disabled. Also if you change the baud rate to 9600 you will lose data but you should at least see parts of valid text. Let me know what you discover.
