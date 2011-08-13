-------------------------
| Daisy Power Outlet Firmware
-------------------------
This firmware works with the Daisy Power Outlet Petal 

* --- (currently not for sale) --- *

You must plug this into PORT C of the Daisy

You can toggle switches on/off with this or use PWM for dimming

Commands:

4; => socket one ON
5; => socket one OFF
6; => socket two ON
7; => socket two OFF

8; => sense socket two ON/OFF
9; => sense socket one ON/OFF
10; => PWM dimmer (not working)

The successful command response will be

1, XXXX;

Where XXXX = a hi/lo analog value indicating the on/off state (lo value = on, hi value = off)

Example:

tx> 4;					<- turn the socket on
rx> 1,socket one should be ON;
tx> 9;					<- read the state of the socket
rx> 1,51;
tx> 5;					<- turn the socket off
rx> 1,socket one should be OFF;
tx> 9;					<- read the state of the socket
rx> 1,1023;

-------------------------
| Libraries Used
-------------------------
CmdMessenger 	https://github.com/dreamcat4/CmdMessenger
Streaming	http://arduiniana.org/libraries/streaming/

-------------------------
| Build
-------------------------
$ cp Makefile.sample Makefile
$ vi Makefile 
	(edit for your environment)
$ make
$ make upload

Make sure you read ../README.txt to understand the build process.


