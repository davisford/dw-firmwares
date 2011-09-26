/************************************************************
 * Daisy Digital Temp Monitor
 * This firmware works with the DS18S20 temperature chip
 * http://www.maxim-ic.com/datasheet/index.mvp/id/2815
 * Range is -55C to +125C
 *
 * You can string them together on the same onewire
 ************************************************************/

// CmdMessenger library (included in local libraries folder)
// Origin: https://github.com/dreamcat4/cmdmessenger
#include "CmdMessenger.h"

// OneWire library (included in local libraries folder)
// Origin: http://www.pjrc.com/teensy/td_libs_OneWire.html
#include "OneWire.h"

// Streaming4 library (included in local libraries folder)
// Origin: http://arduiniana.org/libraries/streaming/
#include "Streaming.h"

// SD library (included in local libraries folder)
// Origin: arduino-022/libraries
#include <SD.h>

#include <avr/pgmspace.h>

// max number of sensors we support on one onewire
#define MAX_DS1820_SENSORS 15

const int onewirePin	= A3; // on pin 9, daisy port C

// onewire library object
OneWire  onewire(A3);  

// holds the addresses of each sensor
byte addr[MAX_DS1820_SENSORS][8];
int numSensors;

// Mustnt conflict / collide with our message payload data. Fine if we use base64 library ^^ above
const char field_separator = ',';
const char command_separator = ';';

// Attach a new CmdMessenger object to the default Serial port
CmdMessenger cmdMessenger = CmdMessenger(Serial, field_separator, command_separator);

// this buffer holds whatever is being read: it must be as large as the largest string
static char STR_BUF[50];

// Timeout handling
long timeoutInterval = 600000; // 10 minutes
//long timeoutInterval = 2000; // 10 minutes
long previousMillis = -1 * timeoutInterval;
int counter = 0;

//SD chip select
const int SD_CS = 10;
char filename[12] = "datalog.txt";
boolean sdAvailable = false;
File dataFile;
boolean suspend = false;

static char READING[35];

// string constants stored in flash
enum {
  SCAN_COMPLETE,
  CRC_INVALID,
  WRONG_DEVICE,
  DAISY_READY,
  UNKNOWN_CMD,
  SD_CARD_INIT,
  SD_CARD_FAILURE
};

prog_char string0[] PROGMEM = "1-wire scan complete. Number of sensors found: "; // size=48
prog_char string1[] PROGMEM = "CRC is not valid";
prog_char string2[] PROGMEM = "Device is not a DS18S20";
prog_char string3[] PROGMEM = "Daisy is ready!";
prog_char string4[] PROGMEM = "Unknown command";
prog_char string5[] PROGMEM = "SD card failed init or not inserted";
prog_char string6[] PROGMEM = "SD card file read/write failed";

PROGMEM const char *string_table[] = {
  string0, 
  string1, 
  string2,
  string3,
  string4,
  string5,
  string6
};

// __________________ FUNCTION DECLARATIONS ____________________________________
char* readString(int index);

void scan_onewire();
void get_num_sensors();
void set_interval();
void readSensors();
void log_data();
void dump_data();
void delete_data();

// __________________ CMD LISTING (TX/RX) ______________________________________
enum {
  kCOMM_ERROR		= 000,	// serial port comm error
  kACK			= 001,	// ack command was received
  kARDUINO_READY	= 002,	// after setup
  kERR			= 003,	// bad command or error

  kSEND_CMDS_END,		// DO NOT DELETE
};

messengerCallbackFunction messengerCallbacks[] = {
  scan_onewire,	// 004
  get_num_sensors,	// 005
  readSensors,		// 006
  set_interval,	// 007
  dump_data,           // 008
  delete_data          // 009
};

// __________________ DEFAULT CALLBACKS ________________________________________

/* command 002 */
void arduino_ready() {
  cmdMessenger.sendCmd(kACK, readString(DAISY_READY));
}

/* command 003 */
void unknownCmd() {
  cmdMessenger.sendCmd(kERR, readString(UNKNOWN_CMD));
}

// __________________ USER DEFINED CALLBACKS ___________________________________

/* command 004 
 This scans the wire for devices and populates the internal array with the list
 of addresses it found
 */
void scan_onewire() {
  // reset numSensors
  numSensors = 0;
  // scan for temp probes on the wire
  for (int i=0; i<MAX_DS1820_SENSORS; i++) {
    if (true == onewire.search(addr[i])) {
      numSensors++;
    } 
    else {
      // print out the number of sensors we found
      char val[12];
      char msg[sizeof(string0) + sizeof(val)];    
      ltoa(numSensors, val, 10);
      strcpy(msg, readString(SCAN_COMPLETE));
      strcat(msg, val);

      onewire.reset_search();
      delay(250); // why? i dunno, it was in the sample code
      cmdMessenger.sendCmd(kACK, msg);
      return;
    }
  }
}

/* command 005
 Returns the number of sensors found from the last scan
 */
void get_num_sensors() {
  char buf[12];
  cmdMessenger.sendCmd(kACK, ltoa(numSensors, buf, 10));
}

//int HighByte, LowByte, TReading, SignBit, Tc_100, Whole, Fract;
//char buf[20];

/* command 006
 Scans through all known sensors and reads their data
 */
void readSensors() {
  if (suspend) {
    return;
  }
  byte sensor;
  byte data[12];
  int LoByte, HiByte, Temp, SignBit, TempC, Whole, Fract;

  unsigned long timestamp = millis();

  for (sensor=0; sensor<numSensors; sensor++) {

    if ( OneWire::crc8( addr[sensor], 7) != addr[sensor][7]) {
      // crc error
      cmdMessenger.sendCmd(kERR, readString(CRC_INVALID));
      return;
    }

    if ( addr[sensor][0] != 0x28) {
      // wrong device type
      cmdMessenger.sendCmd(kERR, readString(WRONG_DEVICE));
      return;
    }

    onewire.reset();
    onewire.select(addr[sensor]);
    onewire.write(0x44,1);         // start conversion, with parasite power on at the end

    //delay(1000);     // maybe 750ms is enough, maybe not
    // we might do a onewire.depower() here, but the reset will take care of it.

    // reset 1-wire bus; necessary before communicating with any device
    onewire.reset();
    // select device based on its address
    onewire.select(addr[sensor]);    
    // command to read the scratchpad
    onewire.write(0xBE);         

    for (byte i = 0; i < 9; i++) {
      // we need 9 bytes
      data[i] = onewire.read();
    }

    // convert to celsius 12 45 78 01 34 67, 
    LoByte = data[0];
    HiByte = data[1];
    Temp = (HiByte << 8) + LoByte;

    SignBit = Temp & 0x8000;  // test most sig bit
    if (SignBit) // negative
    {
      Temp = (Temp ^ 0xffff) + 1; // 2's comp
    }
    TempC = (6 * Temp) + Temp / 4;    // multiply by (100 * 0.0625) or 6.25

    Whole = TempC / 100;  // separate off the whole and fractional portions
    Fract = TempC % 100;

    // build up the string
    char TempStr[sizeof(Whole) + sizeof(Fract) + 2] = { 
      '\0'                                     };
    if(SignBit) { 
      strcat(TempStr, "-"); 
    }
    char val[4] = { 
      '\0'                                     };
    strcat(TempStr, itoa(Whole, val, 10));
    strcat(TempStr, ".");
    if(Fract < 10) { 
      strcat(TempStr, "0"); 
    }
    strcat(TempStr, itoa(Fract, val, 10)); 

    if (suspend) {
      return;
    }
    sprintf(READING, "%02X:%02X:%02X:%02X:%02X:%02X:%02X:%02X,%s",
    addr[sensor][0],
    addr[sensor][1],
    addr[sensor][2],
    addr[sensor][3],
    addr[sensor][4],
    addr[sensor][5],
    addr[sensor][6],
    addr[sensor][7],
    TempStr);

    log_data(timestamp);

    cmdMessenger.sendCmd(kACK, READING);
  }
}

/* command 007
 Sets the timeout interval between 2 sec and 24 hours.
 */
void set_interval() {
  while (cmdMessenger.available()) {
    char buf[10] = {
      '\0'                                };
    cmdMessenger.copyString(buf, 10);
    int val = atoi(buf);
    // sanity check this value
    if(val < 2000) { 
      timeoutInterval = 2000; 
    }
    else if(val > 86400000) { 
      timeoutInterval = 86400000; 
    }
    else { 
      timeoutInterval = val; 
    }
  }
}

/*
 Logs data to SD card if SD card is available
 */
void log_data(unsigned long timestamp) {
  if (!sdAvailable) {
    return;
  }

  if (!dataFile) {
    dataFile = SD.open(filename, FILE_WRITE);
  }

  if (!dataFile) {
    cmdMessenger.sendCmd(kERR,readString(SD_CARD_FAILURE));
    return;
  }

  dataFile.print(timestamp);
  dataFile.print(",");
  dataFile.println(READING);
  dataFile.close();
}

/* command 008
 Suspends logging and dumps the data to the serial port
 */
void dump_data() {
  if (!sdAvailable) {
    return;
  }

  suspend=true; //suspend logging
  if (dataFile) {
    dataFile.close();
  }

  dataFile = SD.open(filename, FILE_READ);

  if (!dataFile) {
    cmdMessenger.sendCmd(kERR,readString(SD_CARD_FAILURE));
    suspend=false;
    return;
  }

  Serial.println("");
  while (dataFile.available()) {
    Serial.write(dataFile.read());
  }
  dataFile.close();
  Serial.println("");
  suspend=false; //resume logging
}

/* command 009
 Deletes the log file
 */
void delete_data() {
  if (!sdAvailable) {
    return;
  }

  suspend=true; //suspend logging

  if (dataFile) {
    dataFile.close();
  }

  SD.remove(filename);
  suspend=false; //resume logging
}

/* copies a string from flash into the static STR_BUF SRAM var, returns the pointer */
char* readString(int idx) {
  strcpy_P(STR_BUF, (char*) pgm_read_word( &(string_table[idx]) ) );
  return STR_BUF;
}

// __________________ S E T U P ________________________________________________

void attach_callbacks(messengerCallbackFunction* callbacks) {
  int i=0;
  int offset = kSEND_CMDS_END;
  while(callbacks[i]) {
    cmdMessenger.attach(offset+i, callbacks[i]);
    i++;
  }
}

void setup(void) {
  // listen on serial for messages from pc/phone
  Serial.begin(57600);

  cmdMessenger.print_LF_CR();

  // attach default/generic callbacks
  cmdMessenger.attach(kARDUINO_READY, arduino_ready);
  cmdMessenger.attach(unknownCmd);

  // attach user-defined callbacks
  attach_callbacks(messengerCallbacks);

  // scan the wire
  scan_onewire();

  // ready
  arduino_ready();

  //SD chip select setup
  pinMode(SD_CS, OUTPUT);
  if (SD.begin(SD_CS)) {
    sdAvailable = true;
  } 
  else {
    cmdMessenger.sendCmd(kERR,readString(SD_CARD_INIT));
  }    
}

// ___________________ M A I N ( ) _____________________________________________

void timeout()
{
  readSensors();
}


void loop() 
{
  // Process incoming serial data, if any
  cmdMessenger.feedinSerialData();

  // handle timeout function, if any
  if (  millis() - previousMillis > timeoutInterval )
  {
    timeout();
    previousMillis = millis();
  }

  // forever...
}
