-------------------------
| Daisy Ultrasonic Range Finder Firmware
-------------------------
This firmware works with the Daisy Ultrasonic Range Finder.

http://daisyworks.com/products.html#daisypetals

You can poll it for the distance.

The command to read the range is:

4;

The successful command response will be

1, XXXX;

Where XXXX = the distance in inches

The minimum is 6 inches, the maximum is 255 inches

-------------------------
| Libraries Used
-------------------------
CmdMessenger 	https://github.com/dreamcat4/CmdMessenger
Streaming	http://arduiniana.org/libraries/streaming/
NewSoftSerial	http://arduiniana.org/libraries/newsoftserial/

-------------------------
| Build
-------------------------
$ cp Makefile.sample Makefile
$ vi Makefile 
	(edit for your environment)
$ make
$ make upload

Make sure you read ../README.txt to understand the build process.


