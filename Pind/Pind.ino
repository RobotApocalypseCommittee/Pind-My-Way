
#include <ESP8266WiFi.h>
#include <WebSocketsClient.h>

#ifdef __AVR__
#include <avr/power.h>
#endif

#include "config.h"
#include "PixelManagement.h"

int delayval = 100;

WebSocketsClient webSocket;
#define USE_SERIAL Serial


void webSocketEvent(WStype_t type, uint8_t* payload, size_t length) {
    switch (type) {
        case WStype_DISCONNECTED:
            USE_SERIAL.printf("[WSc] Disconnected!\n");
            beginAcInAnimation(255, 0, 0);
            break;
        case WStype_CONNECTED: {
            USE_SERIAL.printf("[WSc] Connected to url: %s\n", payload);
            #ifdef LEFT_GLOVE
            beginGlowAnimation(255, 255, 255);
            #else
            beginGlowAnimation(255, 255, 255, true);
            #endif

        } break;
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

void setup() {
    // put your setup code here, to run once:
    Serial.begin(115200);
    beginPixels();
    WiFi.begin(SSID, PASSWORD);
    beginAcInAnimation(255, 255, 255);
    while (WiFi.status() != WL_CONNECTED) {
        loopAnimation();
    }

    Serial.println("");
    Serial.println("WiFi connected");
    Serial.println("IP address: ");
    Serial.println(WiFi.localIP());
    beginAcInAnimation(255, 0, 0);
    // server address, port and URL
    webSocket.begin(PI_IP, 8080, "/");

    // event handler
    webSocket.onEvent(webSocketEvent);

    // try ever 5000 again if connection has failed
    webSocket.setReconnectInterval(5000);

    Serial.println("Init Completed");
}

void loop() {
    webSocket.loop();
    loopAnimation();
}
