-------------------------
| Daisy Shell
-------------------------

-------------------------
| Pre-requisites
------------------------- 

  # avr tools (compiler/linker/libs for Atmel AVR targets)

  Debian Install:
	sudo apt-get install avr-gcc avr-g++ avr-libc

  # Arduino SDK
	
Download the package here: http://www.arduino.cc/en/Main/Software and unzip it somewhere.  You'll need to modify the Makefile to point here.

  # Gnu Make (already installed)

  # avrdude AVRDUDE is an open source utility to download/upload/manipulate the ROM and EEPROM contents of AVR microcontrollers using the in-system programming technique (ISP).

  Debian Install:
	sudo apt-get install avrdude

  # Python with pySerial package - needed to toggle DTR/RTS when uploading

  Debian Install:
	sudo apt-get install python-serial

-------------------------
| Build
-------------------------
Edit Makefile for your own environment.  You shouldn't need to modify anything in Include.mk.

$ make
$ make clean

-------------------------
| Libraries
-------------------------
Any libraries will be included underneath the directory ./libraries

For example:
	libraries/CmdMessenger/
	libraries/Streaming/
	libraries/Base64/

If you drop a new folder in there with lib source code it will be included in the build.

--------------------------
| Upload
--------------------------

$ make upload

You may need to toggle DTR programmatically depending on your device.  If you get timeout messages, this is probably why.  You can also reset the board immediately after starting the upload which should fix it.


