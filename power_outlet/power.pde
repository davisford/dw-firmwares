/*************************************************************
 * Use with Daisy Power Switch to toggle power on/off
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

/*
  Port C: 4, 6 are control lines, A3->4 sense, A1->6 sense
*/
const int socket1_control = 4;
const int socket2_control = 6;
const int socket1_sense   = A1;
const int socket2_sense   = A3;

// __________________ FUNCTION DECLARATIONS _________________________________
void socket_one_on();
void socket_two_on();
void socket_one_off();
void socket_two_off();
void socket_one_status();
void socket_two_status();
void socket_one_dim();

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
  socket_one_on,		// = 004 
  socket_one_off,		// = 005
  socket_two_on,		// = 006
  socket_two_off,		// = 007
  socket_one_status,		// = 008
  socket_two_status,		// = 009
  socket_one_dim,		// = 010
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

void socket_one_on() {
  digitalWrite(socket1_control, HIGH);
  cmdMessenger.sendCmd(kACK, "socket one should be ON");
}

void socket_one_off() {
  digitalWrite(socket1_control, LOW);
  cmdMessenger.sendCmd(kACK, "socket one should be OFF");
}

void socket_two_on() {
  digitalWrite(socket2_control, HIGH);
  cmdMessenger.sendCmd(kACK, "socket two should be ON");
}

void socket_two_off() {
  digitalWrite(socket2_control, LOW);
  cmdMessenger.sendCmd(kACK, "socket two should be OFF");
}

void socket_one_status() {
  char val[4];
  itoa(analogRead(socket1_sense), val, 10);
  cmdMessenger.sendCmd(kACK, val);
}

void socket_two_status() {
  char val[4];
  itoa(analogRead(socket2_sense), val, 10);
  cmdMessenger.sendCmd(kACK, val);
}

void socket_one_dim() {
  int val = 9;

  // experiment with PWM
  for(int i=0; i<1000; i++) {
    digitalWrite(socket1_control, HIGH);
    delay(val);
    digitalWrite(socket1_control, LOW);
    delay(val);
  }
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

  // set pin mode of socket control ports
  pinMode(socket1_control, OUTPUT);
  pinMode(socket2_control, OUTPUT);
}


// ------------------ M A I N ( ) --------------------------------------------

// Timeout handling
long timeoutInterval = 1000; // 2 seconds
long previousMillis = 0;
int counter = 0;

void timeout()
{
  // Process incoming serial data, if any
  cmdMessenger.feedinSerialData();
}  


void loop() 
{
  // handle timeout function, if any
  if (  millis() - previousMillis > timeoutInterval )
  {
    timeout();
    previousMillis = millis();
  }

  // forever...
}

