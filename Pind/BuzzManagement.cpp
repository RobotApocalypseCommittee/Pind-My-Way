#include "BuzzManagement.h"

enum BuzzPattern {
  OFF,
  ONCE,
  FREQUENT
};
enum BuzzPattern currentBuzzPattern = OFF;

unsigned long last_action;

bool currentState;
int m_on_delay;
int m_off_delay;

void buzz_set(bool state) {
    digitalWrite(BUZZPIN, state);
    currentState = state;
}

void loop_once() {
    if ((last_action + m_on_delay) < millis()) {
        buzz_set(false);
        currentBuzzPattern = OFF;
    }
}

void loop_frequent() {
    if (currentState) {
        // It's on
        if ((last_action + m_on_delay) < millis()) {
            // Turn off
            last_action = millis();
            buzz_set(false);
        }
    } else {
        if ((last_action + m_off_delay) < millis()) {
            last_action = millis();
            buzz_set(true);
        } 
    }
}

void init_buzzer() {
    pinMode(BUZZPIN, OUTPUT);
    buzz_set(false);
}

void enable_buzzing(int on_delay, int off_delay) {
    buzz_set(false);
    m_on_delay = on_delay;
    m_off_delay = off_delay;
    last_action = millis();
    currentBuzzPattern = FREQUENT;
}
void disable_buzzing() {
    currentBuzzPattern = OFF;
    buzz_set(false);
}

void buzz_once(int length) {
    currentBuzzPattern = ONCE;
    buzz_set(true);
    last_action = millis();
    m_on_delay = length;
}

void loop_buzzing() {
    switch (currentBuzzPattern) {
        case FREQUENT:
            loop_frequent();
            break;
        case ONCE:
            loop_once();
            break;
    }
}


