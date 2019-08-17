#include <Arduino.h>
#include "config.h"

#ifdef LEFT_GLOVE
#define BUZZPIN D6
#else
#define BUZZPIN 1
#endif

void init_buzzer();
void enable_buzzing(int on_delay, int off_delay);
void disable_buzzing();
void loop_buzzing();
void buzz_once(int length);
