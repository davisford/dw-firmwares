-------------------------
| Daisy Rocket Launcher Firmware
-------------------------
This firmware was used for the Maker Faire Rocket Launcher Demo.  It shows how to control some servos with the Daisy.  We attached the Servos to a Rocket Launcpad and then controlled the servos with an Android application.  The phone's accelerometer and magenetometer was used to control the trajectory of the Rocket Launcher wirelessly using Bluetooth.

For more information, check out:

http://daisyworks.wordpress.com/2011/08/01/detroit-maker-faire-wrap-up/

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


