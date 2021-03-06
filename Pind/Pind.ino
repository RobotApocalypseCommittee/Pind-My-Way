
#include <ESP8266WiFi.h>
#include <WebSocketsClient.h>

#ifdef __AVR__
#include <avr/power.h>
#endif

#include "BuzzManagement.h"
#include "PixelManagement.h"
#include "config.h"

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
            // Register as left glove
            uint8_t payload[1] = {0x0};
            webSocket.sendBIN(payload, 1);
#else
            beginGlowAnimation(255, 255, 255, true);
            // Register as right glove
            uint8_t payload[1] = {0x1};
            webSocket.sendBIN(payload, 1);
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
            if (length > 0) {
                switch (payload[0]) {
                    case 1:
                        if (length == 3) {
#ifdef LEFT_GLOVE
                            disableAnimations();
                            switch (payload[2]) {
                                case 0:
                                    // Green
                                    setArrow(payload[1], 0, 255, 0);
                                    break;
                                case 1:
                                    // Orange
                                    setArrow(payload[1], 255, 100, 0);
                                    break;
                                case 2:
                                    // Red
                                    setArrow(payload[1], 255, 0, 0);
                                    break;
                                default:
                                    USE_SERIAL.printf("Does not understand status %u\n", payload[2]);
                            }
                            updatePixels();
                            // If left glove, and left arrow -> Buzz
                            if (payload[1] <= 3) {
                                enable_buzzing(100, 1200 / (payload[2] + 1));
                            } else {
                              disable_buzzing();
                            }
#else
                            if (payload[1] > 3) {
                                enable_buzzing(100, 1200 / (payload[2] + 1));
                            } else {
                              disable_buzzing();
                            }
#endif
                        } else {
                            USE_SERIAL.printf("Invalid length %u for command %u\n", length, payload[0]);
                        }
                        break;
                    case 3:
                        if (length == 1) {
#ifdef LEFT_GLOVE
                            disableAnimations();
                            // Nowhere to go = go ahead blue
                            setArrow(3, 0, 0, 255);
                            updatePixels();
#endif
                            disable_buzzing();
                        } else {
                            USE_SERIAL.printf("Invalid length %u for command %u\n", length, payload[0]);
                        }
                        break;
#ifndef LEFT_GLOVE
                    case 2:
                        // Display some data
                        if (length == 9) {
                            disableAnimations();
                            setData(0, payload[1], payload[2], payload[3], payload[4]);
                            setData(1, payload[5], payload[6], payload[7], payload[8]);
                            updatePixels();
                        } else {
                            USE_SERIAL.printf("Invalid length %u for command %u\n", length, payload[0]);
                        }
                        break;
#endif
                    case 4:
#ifdef LEFT_GLOVE
                        beginGlowAnimation(255, 255, 255);
#else
                        beginGlowAnimation(255, 255, 255, true);
#endif
                        break;
                }
            } else {
                USE_SERIAL.printf("Missing Command");
            }
            break;
    }
}

void setup() {
    // put your setup code here, to run once:
    Serial.begin(115200);
    beginPixels();
    init_buzzer();
    WiFi.mode(WIFI_STA);
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
    loop_buzzing();
}
