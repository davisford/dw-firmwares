-------------------------
| Daisy Hygro Petal Firmware
-------------------------
This firmware works with the Daisy Hygro Petal.

http://daisyworks.com/products.html#daisypetals

You can poll it for moisture, light and temperature.

The command to read the sensors is:

6;

The successful command response will be

1, XXXX, YYYY, ZZZZ;

Where XXXX = light
      YYYY = moisture
      ZZZZ = temperature

Refer to the data sheet for the Hygro Petal to understand the min/max range
for each value and conversions.

-------------------------
| Libraries Used
-------------------------
CmdMessenger 	https://github.com/dreamcat4/CmdMessenger
Streaming	http://arduiniana.org/libraries/streaming/


$ cp Makefile.sample Makefile
$ vi Makefile 
	(edit for your environment)
$ make
$ make upload

Make sure you read ../README.txt to understand the build process.


