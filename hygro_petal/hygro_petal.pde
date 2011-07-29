/*************************************************************
 * Daisy v1 Base Shell.  Use this code and expand it for 
 * whatever petal functionality you desire with the Daisy.
 *
 *************************************************************/
// CmdMessenger library (included in local libraries folder)
// Origin: https://github.com/dreamcat4/cmdmessenger
#include "CmdMessenger.h"

// Streaming4 library (included in local libraries folder)
// Origin: http://arduiniana.org/libraries/streaming/
#include "Streaming.h"

// Mustnt conflict / collide with our message payload data. Fine if we use base64 library ^^ above
char field_separator = ',';
char command_separator = ';';

// Attach a new CmdMessenger object to the default Serial port
CmdMessenger cmdMessenger = CmdMessenger(Serial, field_separator, command_separator);

// __________________ FUNCTION DECLARATIONS _________________________________
void led_on();
void led_off();
void readDataOnce();
char * readSensors();

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
  led_on,	       // 004
  led_off,             // 005
  readDataOnce,	       // 006
  NULL
};

// __________________ PROGRAM CONSTANTS _____________________________________
const int power    = A2;
const int moisture = A5;
const int light    = A4;
const int temp     = A6;

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

// command 4
void led_on()
{
   digitalWrite(5, HIGH);
   cmdMessenger.sendCmd(kACK, "LED should be on");
}

// command 5
void led_off()
{
   digitalWrite(5, LOW);
   cmdMessenger.sendCmd(kACK, "LED should be off");
}

// command 6
void readDataOnce() {
   cmdMessenger.sendCmd(kACK, readSensors());
}

char *readSensors() {
   digitalWrite(power, LOW);  // on
   delay(500);

   static char data[15];
   char val[4];

   // read light
   itoa(analogRead(light), data, 10);

   // read moisture
   itoa(analogRead(moisture), val, 10);
   strcat(data, ",");
   strcat(data, val);

   // read temp
   itoa(analogRead(temp), val, 10);
   strcat(data, ",");
   strcat(data, val);

   // turn off power to save power; avoid heating, corrosion
   digitalWrite(power, HIGH);  // off

   return data;
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

  // cmdMessenger.discard_LF_CR(); // Useful if your terminal appends CR/LF, and you wish to remove them
  cmdMessenger.print_LF_CR();   // Make output more readable whilst debugging in Arduino Serial Monitor
  
  // Attach default / generic callback methods
  cmdMessenger.attach(kARDUINO_READY, arduino_ready);
  cmdMessenger.attach(unknownCmd);

  // Attach my application's user-defined callback methods
  attach_callbacks(messengerCallbacks);

  arduino_ready();

  // blink
  pinMode(5, OUTPUT);

  digitalWrite(power, HIGH); //OFF
  pinMode(power, OUTPUT);

  // turn LED on to give a visual indicator that we're running
  led_on();
}


// ------------------ M A I N ( ) --------------------------------------------

// Timeout handling
long timeoutInterval = 2000; // 2 seconds
long previousMillis = 0;
int counter = 0;

void timeout()
{
  // add code in here you want to 
  // execute every timeoutInterval seconds
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

