
#include <ESP8266WiFi.h>
#include <WebSocketsClient.h>

#include <Adafruit_NeoPixel.h>
#ifdef __AVR__
  #include <avr/power.h>
#endif

const char* ssid     = "";
const char* password = "";
const char* PI_IP    = "172.24.1.1";
int delayval = 100; 

WebSocketsClient webSocket;

Adafruit_NeoPixel circle = Adafruit_NeoPixel(12, 13, NEO_GRB + NEO_KHZ800);
Adafruit_NeoPixel center = Adafruit_NeoPixel(1, 15, NEO_GRB + NEO_KHZ800);

void webSocketEvent(uint8_t num, WStype_t type, uint8_t * payload, size_t lenght) {
    Serial.printf("[%u] get Message: %s\r\n", num, payload);
    switch(type) {
        case WStype_DISCONNECTED:      
            center.setPixelColor(0, 10, 0, 10);
            center.show(); 
            delay(200);
            center.setPixelColor(0, 0, 0, 0));
            center.show(); 
            delay(200);    
            center.setPixelColor(0, 10, 0, 10);
            center.show();
            break;
            
        case WStype_CONNECTED: 
            {
              IPAddress ip = webSocket.remoteIP(num);
              Serial.printf("[%u] Connected from %d.%d.%d.%d url: %s\r\n", num, ip[0], ip[1], ip[2], ip[3], payload); 
              for(int i=0;i<circle.numPixels();i++){

                // pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
                circle.setPixelColor(i, circle.Color(10, 0, 10)); 
            
                circle.show(); // This sends the updated pixel color to the hardware.
            
                delay(delayval); // Delay for a period of time (in milliseconds).
            
              }   
            }
            break;
        
        case WStype_TEXT:
            {
              Serial.printf("[WSc] get text: %s\n", payload);
              //Serial.printf("[%u] get Text: %s\r\n", num, payload);
              String _payload = String((char *) &payload[0]);
              Serial.println(_payload);
              for (int i = 0; i <= strlen(_payload) / 10; i++) {
                int idLed = (_payload.substring(0 + 10 * i,2 + 10 * i)).toInt();
                int R =     (_payload.substring(2 + 10 * i,5 + 10 * i)).toInt();
                int G =     (_payload.substring(5 + 10 * i,8 + 10 * i)).toInt();    //dubious
                int B =     (_payload.substring(8 + 10 * i,11 + 10 * i)).toInt();
                int A =     (_payload.substring(11 + 10 * i,14 + 10 * i)).toInt();
                pixelSet(idLed, R, G, B, A);
              }
            }   
            break;     
             
        case WStype_BIN:
            {
              hexdump(payload, lenght);
            }
            // echo data back to browser
            webSocket.sendBIN(num, payload, lenght);
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

  while(WiFi.status() != WL_CONNECTED) {
     Serial.print(".");
     center.setPixelColor(0, center.Color(0, 10, 10));
     center.show(); 
     delay(200);
     center.setPixelColor(0, center.Color(0, 0, 0));
     center.show(); 
     delay(200);     
}
    
  Serial.println("");
  Serial.println("WiFi connected");  
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());

  for(int i=0;i<circle.numPixels();i++){

    // pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    circle.setPixelColor(i, circle.Color(0, 10, 10)); 

    circle.show(); // This sends the updated pixel color to the hardware.

    delay(delayval); // Delay for a period of time (in milliseconds).

  }
   
  // Connect to server
  webSocket.begin(PI_IP, 8080);
  // Set event callback.
  webSocket.onEvent(webSocketEvent);

  Serial.println("Init Completed");
}

void loop() {
  webSocket.loop();
}

