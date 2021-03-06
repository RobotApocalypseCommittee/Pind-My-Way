#include "PixelManagement.h"
#include <Adafruit_NeoPixel.h>

int arrows[8] = {0b001110000100, 0b011100001000, 0b111001000000, 0b100001000011, 0b000001001110, 0b001000011100, 0b010000111000, 0b000011100001};
#ifdef LEFT_GLOVE
Adafruit_NeoPixel circle = Adafruit_NeoPixel(12, 15, NEO_GRB + NEO_KHZ800);
Adafruit_NeoPixel center = Adafruit_NeoPixel(1, 13, NEO_GRB + NEO_KHZ800);
#else
Adafruit_NeoPixel circle = Adafruit_NeoPixel(12, 13, NEO_GRB + NEO_KHZ800);
#endif

enum Animation {
  AcIn,
  Glowing,
  GlowingCircle,
  None
};
enum Animation currentAnimation = None;

byte activityIndicator[12][3];
int activityCounter;
void beginAcInAnimation(byte r, byte g, byte b) {
  pixelClear();
  currentAnimation = AcIn;
  activityCounter = 0;
  for (int i = 0; i < 12; i++) {
    activityIndicator[i][0] = i == 0 ? r : activityIndicator[i - 1][0] / 2;
    activityIndicator[i][1] = i == 0 ? g : activityIndicator[i - 1][1] / 2;
    activityIndicator[i][2] = i == 0 ? b : activityIndicator[i - 1][2] / 2;
  }
}
void loopAcInAnimation() {
  delay(100);
  if (activityCounter == 12) {
    activityCounter = 0;
  }

  for (int i = 1; i <= circle.numPixels(); i++) {
    int colorIndex = activityCounter - i;
    if (colorIndex < 0) {
      colorIndex += 12;
    }
    pixelSet(i, activityIndicator[colorIndex][0], activityIndicator[colorIndex][1], activityIndicator[colorIndex][2]);
  }
  activityCounter++;
}
byte gr;
byte gg;
byte gb;
boolean dir;
void beginGlowAnimation(byte r, byte g, byte b, boolean circular) {
  pixelClear();
  currentAnimation = circular ? GlowingCircle : Glowing;
  activityCounter = 0;
  dir = false;
  gr = r;
  gg = g;
  gb = b;
}

void loopGlowAnimation(boolean circular) {
  delay(20);
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
  if (circular) {
    byte r = gr * (activityCounter / 256.0);
    byte g = gg * (activityCounter / 256.0);
    byte b = gb * (activityCounter / 256.0);
    for (int i = 0; i < circle.numPixels(); i++) {
      circleSet(i, r, g, b);
    }
  } else {
    pixelSet(0, gr * (activityCounter / 256.0), gg * (activityCounter / 256.0), gb * (activityCounter / 256.0));
  }
}

void disableAnimations() {
  pixelClear();
  currentAnimation = None;
}

void loopAnimation() {
  switch (currentAnimation) {
    case AcIn:
      loopAcInAnimation();
      break;
    case Glowing:
      loopGlowAnimation(false);
      break;
    case GlowingCircle:
      loopGlowAnimation(true);
      break;
  }
  updatePixels();
}

void beginPixels() {
  circle.begin();  // This initializes the NeoPixel library.
#ifdef LEFT_GLOVE
  center.begin();
  center.show();
#endif
  // Delay cos dodgyness
  delay(50);
  circle.setBrightness(128);
  circle.setPixelColor(0, 0, 0, 0);
  circle.show();
}

void setData(int track, int data, byte r, byte g, byte b) {
  if (track < 2) {
    // Display data on certain track
    // There are 5 possible LEDs
    for (int i = 0; i < 5; i++) {
      if (i < data) {
        circleSet(track ? 5 - i : i + 7, r, g, b);
      } else {
        circleSet(track ? 5 - i : i + 7, 0, 0, 0);
      }
    }
  }
}


void setArrow(int a, byte r, byte g, byte b) {
  // Arrow can be 0 to 7
  // Array indexes 0 to 7
  int arrow = arrows[a];
  for (int i = 0; i < 12; i++) {
    if ((arrow >> i) & 1) {
      circleSet(i, r, g, b);
    } else {
      circleSet(i, 0, 0, 0);
    }
  }
  centreSet(r, g, b);
}

void pixelClear() {
  for (int i = 0; i < PIXELNO; i++) {
    pixelSet(i, 0, 0, 0);
  }
}

void pixelSet(int i, byte r, byte g, byte b) {
#ifdef LEFT_GLOVE
  if (i == 0) {
    centreSet(r, g, b);
  } else {
    circleSet(i - 1, r, g, b);
  }
#else
  circleSet(i, r, g, b);
#endif
}

void centreSet(byte r, byte g, byte b) {
#ifdef LEFT_GLOVE
  center.setPixelColor(0, r, g, b);
#endif
}

void circleSet(int i, byte r, byte g, byte b) {
  if (i > 11) {
    i = i % 12;
  }
#ifdef LEFT_GLOVE
  circle.setPixelColor((i + 15) % 12, r, g, b);
#else
  circle.setPixelColor((i + 8) % 12, r, g, b);
#endif
}

void updatePixels() {
#ifdef LEFT_GLOVE
  center.show();
#endif
  circle.show();
}

