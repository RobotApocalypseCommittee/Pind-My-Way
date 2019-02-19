
#include <ESP8266WiFi.h>
#include <WebSocketsClient.h>

#include <Adafruit_NeoPixel.h>
#ifdef __AVR__
  #include <avr/power.h>
#endif



const char* ssid     = "PIMW-NET";
const char* password = "12345678";
const char* PI_IP    = "192.168.0.10";

int delayval = 100; 

WebSocketsClient webSocket;
#define USE_SERIAL Serial

Adafruit_NeoPixel circle = Adafruit_NeoPixel(12, 13, NEO_GRB + NEO_KHZ800);
Adafruit_NeoPixel center = Adafruit_NeoPixel(1, 15, NEO_GRB + NEO_KHZ800);

enum Animation {
  AcIn,
  Glowing,
  None
};
enum Animation currentAnimation = None;

int activityIndicator[12][3];
int activityCounter;
void setupAcInAnimation(int r, int g, int b) {
  currentAnimation = AcIn;
  activityCounter = 0;
  for (int i = 0; i < 12; i++) {
    activityIndicator[i][0] = i == 0 ? r : activityIndicator[i-1][0] / 2;
    activityIndicator[i][1] = i == 0 ? g : activityIndicator[i-1][1] / 2;
    activityIndicator[i][2] = i == 0 ? b : activityIndicator[i-1][2] / 2;
  }
}


void loopAcInAnimation() {
  if (activityCounter == 12) {
    activityCounter = 0;
  }

  for (int i = 1; i<=circle.numPixels(); i++) {

    int colorIndex = activityCounter - i;
    if (colorIndex < 0) {
      colorIndex += 12;
    }
    pixelSet(i, activityIndicator[colorIndex][0], activityIndicator[colorIndex][1], activityIndicator[colorIndex][2], 0);
  }
  delay(100);
  activityCounter++;
}
int gr;
int gg;
int gb;
boolean dir;
void setupGlowAnimation(int r, int g, int b) {
  currentAnimation = Glowing;
  activityCounter = 0;
  dir = false;
  gr = r;
  gg = g;
  gb = b;
}

void loopGlowAnimation() {
  if (dir == false) {
    activityCounter++;
    if (activityCounter == 255) {
      dir = true;
    } 
  } else {
    activityCounter--;
    if (activityCounter == 0) {
      dir = false;
    }
  }
  pixelSet(0, gr*(activityCounter/256.0), gg*(activityCounter/256.0), gb*(activityCounter/256.0), 0);
  delay(20);
}

void updateAnimation() {
  switch (currentAnimation) {
    case AcIn:
      loopAcInAnimation();
      break;
    case Glowing:
      loopGlowAnimation();
      break;
  }
}
void webSocketEvent(WStype_t type, uint8_t * payload, size_t length) {

  switch(type) {
    case WStype_DISCONNECTED:
      USE_SERIAL.printf("[WSc] Disconnected!\n");
      setupAcInAnimation(255,0,0);
      break;
    case WStype_CONNECTED: {
      USE_SERIAL.printf("[WSc] Connected to url: %s\n", payload);
      setupGlowAnimation(255, 255, 255);
      
    }
      break;
    case WStype_TEXT:
      USE_SERIAL.printf("[WSc] get text: %s\n", payload);

      // send message to server
      // webSocket.sendTXT("message here");
      break;
    case WStype_BIN:
      USE_SERIAL.printf("[WSc] get binary length: %u\n", length);
      hexdump(payload, length);

      // send data to server
      // webSocket.sendBIN(payload, length);
      break;
  }

}

void pixelSet(int id, int r, int g, int b, int a) {
  if (id == 0) {
    center.setPixelColor(0, r, g, b, a);
    center.show();
  }
  else if (id > 0 && id < 13) {
    circle.setPixelColor(id - 1, r, g, b, a);
    circle.show();
  }
}

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200); 
  circle.begin(); // This initializes the NeoPixel library.
  
  center.begin();
  center.show();
  delay(50);
  circle.setPixelColor(0, center.Color(0, 0, 0));
  circle.show();
  
  WiFi.begin(ssid, password);
  setupAcInAnimation(255,255,255);
  while(WiFi.status() != WL_CONNECTED) {
     /*
     Serial.print(".");
     center.setPixelColor(0, center.Color(0, 10, 10));
     center.show(); 
     delay(200);
     center.setPixelColor(0, center.Color(0, 0, 0));
     center.show(); 
     delay(200);   
     */
    updateAnimation();


}
    
  Serial.println("");
  Serial.println("WiFi connected");  
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());
  setupAcInAnimation(255,0,0);
  // server address, port and URL
  webSocket.begin("192.168.0.10", 8080, "/");

  // event handler
  webSocket.onEvent(webSocketEvent);

  // try ever 5000 again if connection has failed
  webSocket.setReconnectInterval(5000);

  Serial.println("Init Completed");
  
}

void loop() {
  webSocket.loop();
  updateAnimation();
}

