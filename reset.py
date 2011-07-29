#!/usr/bin/env python

import os
import sys
import time

import serial

for arg in sys.argv:

    if arg.startswith("-P/dev/"):
           
        s = serial.Serial(arg[2:])
        print 'flushing...'
        s.flushInput()

        print 'toggle RTS => false'
        s.setRTS(False)

        print 'toggle DTR => false'
        s.setDTR(False)
        time.sleep(0.1)

        print 'toggle RTS => true'
        s.setRTS(True)

        print 'toggle DTR => true'
        time.sleep(0.025)
        s.setDTR(True)
           
        s.close()
         
        break

