/*************************************************************
 * Daisy v1 Base Shell.  Use this code and expand it for 
 * whatever petal functionality you desire with the Daisy.
 *
 *************************************************************/
// CmdMessenger library (included in local libraries folder)
// Origin: https://github.com/dreamcat4/cmdmessenger
#include "CmdMessenger.h"

// Base64 library (included in local libraries folder)
// Origin: https://github.com/adamvr/arduino-base64
#include "Base64.h"

// Streaming4 library (included in local libraries folder)
// Origin: http://arduiniana.org/libraries/streaming/
#include "Streaming.h"

#include <Servo.h>

#define SERVO1_PIN A2
#define SERVO2_PIN A5

#define SENSE_PIN  A6
#define FIRE_PIN   A4

// Mustn't conflict / collide with our message payload data. Fine if we use base64 library ^^ above
char field_separator = ',';
char command_separator = ';';


Servo servo1;
Servo servo2;
Servo servo3;

Servo servos[3];

int servoTarget[3];
int servoCurrent[3];

// Attach a new CmdMessenger object to the default Serial port
CmdMessenger cmdMessenger = CmdMessenger(Serial, field_separator, command_separator);

void set_servo_pos();
void launch();
void is_engine_ready();

// ------------------ S E R I A L  M O N I T O R -----------------------------
// 

// ------------------ C M D  L I S T I N G ( T X / R X ) ---------------------

// We can define up to a default of 50 cmds total, including both directions (send + recieve)
// and including also the first 4 default command codes for the generic error handling.
// If you run out of message slots, then just increase the value of MAXCALLBACKS in CmdMessenger.h

// Commands we send from the Arduino to be received on the PC
enum
{
  kCOMM_ERROR    = 000, // Lets Arduino report serial port comm error back to the PC (only works for some comm errors)
  kACK           = 001, // Arduino acknowledges cmd was received
  kARDUINO_READY = 002, // After opening the comm port, send this cmd 02 from PC to check arduino is ready
  kERR           = 003, // Arduino reports badly formatted cmd, or cmd not recognised

  // Now we can define many more 'send' commands, coming from the arduino -> the PC, eg
  // kICE_CREAM_READY,
  // kICE_CREAM_PRICE,
  // For the above commands, we just call cmdMessenger.sendCmd() anywhere we want in our Arduino program.

  kSEND_CMDS_END, // Mustnt delete this line
};

// Commands we send from the PC and want to recieve on the Arduino.
// We must define a callback function in our Arduino program for each entry in the list below vv.
// They start at the address kSEND_CMDS_END defined ^^ above as 004
messengerCallbackFunction messengerCallbacks[] = 
{
  set_servo_pos,       // 004
  is_engine_ready,     // 005
  launch,              // 006
  NULL
};

// ------------------ C A L L B A C K  M E T H O D S -------------------------

void set_servo_pos()
{
  if (!cmdMessenger.available()) {
    cmdMessenger.sendCmd(kERR, "Servo number not specified. Valid servo numbers: 1,2");
    return;
  }
  
  int servo = cmdMessenger.readInt();
  
  if (servo < 1 || servo > 2) {
    cmdMessenger.sendCmd(kERR, "Invalid servo number. Valid servo numbers: 1,2");
    return;
  }
    
  if (!cmdMessenger.available()) {
    cmdMessenger.sendCmd(kERR, "Servo position not specified. Valid servo positions are between 10 and 160");
    return;
  }

  int pos = cmdMessenger.readInt();

  if (pos < 10 || pos > 160) {
    cmdMessenger.sendCmd(kERR, "Invalid servo position. Valid servo positions are between 10 and 160");
    return;
  }

  servoTarget[servo - 1] = pos;
}

void is_engine_ready()
{
  int value = digitalRead(SENSE_PIN);
  if (value == HIGH)
  {
    cmdMessenger.sendCmd(kACK, "Rocket Ready");
  }
  else
  {
    cmdMessenger.sendCmd(kACK, "Rocket Not Ready");
  }
}

void launch()
{
  digitalWrite(FIRE_PIN, HIGH);
  delay(3000);
  digitalWrite(FIRE_PIN, LOW);
}

// ------------------ D E F A U L T  C A L L B A C K S -----------------------

void arduino_ready()
{
  // In response to ping. We just send a throw-away Acknowledgement to say "im alive"
  cmdMessenger.sendCmd(kACK,"Arduino ready");
}

void unknownCmd()
{
  // Default response for unknown commands and corrupt messages
  cmdMessenger.sendCmd(kERR,"Unknown command");
}

// ------------------ E N D  C A L L B A C K  M E T H O D S ------------------



// ------------------ S E T U P ----------------------------------------------

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

  pinMode(5, OUTPUT);
     
  servo1.attach(SERVO1_PIN);
  servo2.attach(SERVO2_PIN);
  
  servos[0] = servo1;
  servos[1] = servo2;
  
  servoTarget[0] = 85;
  servoTarget[1] = 85;  

  servoCurrent[0] = servos[0].read();
  servoCurrent[1] = servos[1].read();
  
  pinMode(FIRE_PIN, OUTPUT);
  pinMode(SENSE_PIN, INPUT);
}

// ------------------ M A I N ( ) --------------------------------------------

// Timeout handling
long timeoutInterval = 20; // milliseconds
long previousMillis = 0;

void timeout(long current_time)
{
  for (int i = 0; i < 2; i++)
  {
    int current = servoCurrent[i];
    int target = servoTarget[i];
    
    if ( current == target)
    {
      continue;
    }
    
    current += (current < target ? 1 : -1);
    servos[i].write(current);
    servoCurrent[i] = current;
  }
}

void loop() 
{  
  // Process incoming serial data, if any
  cmdMessenger.feedinSerialData();
  
  // handle timeout function, if any
  long current_time = millis();
  if (  current_time - previousMillis > timeoutInterval )
  {
    timeout(current_time);
    previousMillis = millis();
  }
  
  // forever...
}
