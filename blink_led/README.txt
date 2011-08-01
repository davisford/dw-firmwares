-------------------------
| Daisy Blinker Firmware
-------------------------
This is just a simple shell with a command to toggle the LED on/off

-------------------------
| Libraries Used
-------------------------
CmdMessenger 	https://github.com/dreamcat4/CmdMessenger
Streaming	http://arduiniana.org/libraries/streaming/
Base64		https://github.com/adamvr/arduino-base64

-------------------------
| Build
-------------------------

$ cp Makefile.sample Makefile
$ vi Makefile 
	(edit for your environment)
$ make
$ make upload

Make sure you read ../README.txt to understand the build process.


