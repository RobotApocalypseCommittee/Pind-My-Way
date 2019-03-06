#include <Arduino.h>
#include "config.h"

#ifdef LEFT_GLOVE
#define PIXELNO 13
#else
#define PIXELNO 12
#endif

void beginAcInAnimation(byte r, byte g, byte b);
void beginGlowAnimation(byte r, byte g, byte b, boolean circular = false);
void disableAnimations();
void loopAnimation();

void setData(int track, int data, byte r, byte g, byte b);

void beginPixels();

void setArrow(int a, byte r, byte g, byte b);

void pixelClear();
void pixelSet(int i, byte r, byte g, byte b);

void circleSet(int i, byte r, byte g, byte b);
void centreSet(byte r, byte g, byte b);
