/*************************************************************
 * Simple RangeFinder firmware for use with Ultrasonic Range Petal
 *
 *************************************************************/
// CmdMessenger library (included in local libraries folder)
// Origin: https://github.com/dreamcat4/cmdmessenger
#include "CmdMessenger.h"

// Streaming4 library (included in local libraries folder)
// Origin: http://arduiniana.org/libraries/streaming/
#include "Streaming.h"

#include "NewSoftSerial.h"

// Mustnt conflict / collide with our message payload data. Fine if we use base64 library ^^ above
char field_separator = ',';
char command_separator = ';';

// Attach a new CmdMessenger object to the default Serial port
CmdMessenger cmdMessenger = CmdMessenger(Serial, field_separator, command_separator);

// soft serial to get range values
NewSoftSerial range(A5, A4, true);

// the last value read from the sensor
String lastValue;
String currentValue;

// __________________ FUNCTION DECLARATIONS _________________________________
void read();

// __________________ C M D  L I S T I N G ( T X / R X ) ____________________

enum
{
  kCOMM_ERROR    = 000, // serial port comm error
  kACK           = 001, // ack command was received
  kARDUINO_READY = 002, // after setup
  kERR           = 003, // bad command or error

  kSEND_CMDS_END, 	// DO NOT DELETE
};

messengerCallbackFunction messengerCallbacks[] = 
{
  read,		// = 004 read the last value
  NULL
};

// __________________ PROGRAM CONSTANTS _____________________________________


// __________________ D E F A U L T  C A L L B A C K S ________________________

// command 2
void arduino_ready()
{
  cmdMessenger.sendCmd(kACK,"Arduino ready");
}

// command error
void unknownCmd()
{
  cmdMessenger.sendCmd(kERR,"Unknown command");
}

// __________________ C A L L B A C K  M E T H O D S __________________________
void read() {
  char buf[4];
  lastValue.toCharArray(buf, 4);
  cmdMessenger.sendCmd(kACK, buf);
}

// __________________ S E T U P ________________________________________________

void attach_callbacks(messengerCallbackFunction* callbacks)
{
  int i = 0;
  int offset = kSEND_CMDS_END;
  while(callbacks[i])
  {
    cmdMessenger.attach(offset+i, callbacks[i]);
    i++;
  }
}

void setup() 
{
  // Listen on serial connection for messages from the pc
  // Daisy v1 must be set to 57600 for Bluetooth comms
  // If you use the serial-USB adapter, you can go to 115200
  Serial.begin(57600); 

  range.begin(9600);

  // cmdMessenger.discard_LF_CR(); // Useful if your terminal appends CR/LF, and you wish to remove them
  cmdMessenger.print_LF_CR();   // Make output more readable whilst debugging in Arduino Serial Monitor
  
  // Attach default / generic callback methods
  cmdMessenger.attach(kARDUINO_READY, arduino_ready);
  cmdMessenger.attach(unknownCmd);

  // Attach my application's user-defined callback methods
  attach_callbacks(messengerCallbacks);

  arduino_ready();

  // turn led on
  pinMode(5, OUTPUT);
}


// ------------------ M A I N ( ) --------------------------------------------

// Timeout handling
long timeoutInterval = 500; // 1/2 seconds
long previousMillis = 0;
int counter = 0;

void timeout()
{
  // Process incoming serial data, if any
  cmdMessenger.feedinSerialData();
}  


void loop() 
{
  // range finder outputs as R###0x0D
  // unit is in inches, so R0150x0D means 15 inches
  if (range.available()) {
    char rx_char = (char) range.read();
    if (rx_char == 'R') {
      // start over, R means start of new data
      currentValue = "";
    } 
      // 0x0D means termination of the range value
    else if (rx_char == (char)0x0D) {
        lastValue = currentValue;
	currentValue = "";
    } 
    else {
      // append
      currentValue += rx_char;
    }
  }

  // handle timeout function, if any
  if (  millis() - previousMillis > timeoutInterval )
  {
    timeout();
    previousMillis = millis();
  }

  // forever...
}

