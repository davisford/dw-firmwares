--------------------------------
DaisyWorks firmware repository
--------------------------------
This is the repo for various firmwares for the Daisy.  The Daisy is an Arduino-derivative board that includes:

a) Class 1 Bluetooth Modem
b) SD Card
c) IrDA
d) 3 RJ25, and 1 RJ45 jacks that allow you to easily swap out various sensors and controls (e.g. light, moisture, temp, etc.)
e) Servo control ports

The Daisy uses the Atmel ATMEGA328 microcontroller.  It is compatible with the Arduino, which means you can use Arduino libraries
to build firmware for the Daisy (in fact, we do).  It als has the Arduino stk500 bootloader, and we've built software that 
allows you to do Firmware-Over-The-Air (FOTA) to reprogram the Daisy using Bluetooth from your Android phone or Desktop Computer
(Mac / Windows / Linux).

We've also built an App Store that allows you to quickly browse applications that are custom made for the various sensors / controls
we sell for the Daisy.  To find out more information, check our website 

http://daisyworks.com

This repository has all the source code we are using in our sample applications we have built.  Instructions are on the website
and simple instructions are provided below on how to get started.  

-------------------------
| License
_________________________

All the code in this repository is public domain which means you are free to modify it to your heart's content.   If we use libraries created by others, we credit them in the README and provide a link to the original source.  If we use code that has an open source license attached to it, we'll include a copy of the license and credit.

-------------------------
| Pre-requisites
------------------------- 
** !!!! IF YOU'RE TRYING TO BUILD ON A PLATFORM OTHER THAN LINUX YOU ARE ON YOUR OWN !!!! **  
We build the firmware on Linux.  I'm sure these Makefiles could be ported to Win/Mac, but we haven't bothered to try yet.

You need all the stuff below before you try to begin:

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
Step into a subdir for a firmware image, and:

$ cp Makefile.sample Makefile

Now, edit Makefile to your environment...at the very least you will need to point the Makefile to where the Arduino distribution lives

$ make
$ make clean

-------------------------
| Libraries
-------------------------
There are two types of library includes.  You can include any of the base libraries that ship with the Arduino SDK.
You'll find these under $ARDUINO_HOME/libraries.  So, for example, to include the SD library in your .pde file, you'd
do this:

#include <SD.h>

Outside libraries that you might grab from the net somewhere can be placed in the firmware directories local ./libraries/ folder.
You need to name the folder the same as the header file...just like the Arduino libraries.

Any libraries will be included underneath the directory ./libraries

For example:
	libraries/CmdMessenger/
	libraries/Streaming/
	libraries/Base64/

If you drop a new folder in there with lib source code it will be included in the build.

To include these libraries in your code, you do it like this:

#include "Streaming.h"

--------------------------
| Upload
--------------------------

$ make upload

This calls out to avrdude directly.  Before doing so, it calls the python reset.py script to toggle DTR/RTS.

--------------------------
| Serial Port
--------------------------
If you have gtkterm installed (which you should), then you may run:

$ make serial

And it will launch gtkterm and connect to the device so you can interact with it via the terminal




