-------------------------
| Daisy Digital Temperature Probe, Single or Multi-Point Firmware
-------------------------
This firmware works with the Daisy Digital Temperature Probe, Single or MultiPoint

http://daisyworks.com/products.html#daisypetals

You must plug this into PORT C of the Daisy

The digital temperature probe uses the Maxim DS18S20 1-Wire Parasite-Power Digital Thermometer.
You can string up to 15 probes onto the same wire, and it will work with the firmware.

Each device is independently addressable.

Commands:

5; => Query how many sensors have been found
  Response:
	1,1;

The first number (1) always indicates a successful ACK.  The example above indicates that it found
one sensor probe.
  Response:
	1,2;
Indicates it found two sensor probes.

6; => Read Sensor Data
  Response:
	1,28:0E:2F:2F:03:00:00:94,28.31;

The first number (1) always indicates a successful ACK.  The second number represents the device's
address on the 1-Wire bus: 28:0E:2F:2F:03:00:00:94, and the third number represents the current
temperature reading in Celsius 28.31 C.

Example:

1,1-wire scan complete. Number of sensors found: 1;
1,Daisy is ready!
6;
1,28:0E:2F:2F:03:00:00:94,28.31;

Datasheet:

http://www.maxim-ic.com/datasheet/index.mvp/id/2815

-------------------------
| Libraries Used
-------------------------
CmdMessenger 	https://github.com/dreamcat4/CmdMessenger
Streaming	http://arduiniana.org/libraries/streaming/
1-Wire		http://www.pjrc.com/teensy/td_libs_OneWire.html

-------------------------
| Build
-------------------------
$ cp Makefile.sample Makefile
$ vi Makefile 
	(edit for your environment)
$ make
$ make upload
$ make serial

Make sure you read ../README.txt to understand the build process.


