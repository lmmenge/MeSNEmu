//
//  LMEmulatorInterface.h
//  pixelbuffertest
//
//  Created by Lucas Menge on 1/2/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#ifndef pixelbuffertest_LMEmulatorInterface_h
#define pixelbuffertest_LMEmulatorInterface_h

// where the pixels for the screen are stored. front-end defined
extern unsigned int* screenPixels;

// emulator entry point
extern int iphone_main(char* filename);

// implemented by the frontend to be notified of screen updates
void refreshScreenSurface();
// implemented by the frontend to be polled for joypad status
unsigned long padStatusForPadNumber(int which);

// convenience functions implemented to make things clearer
void LMSetSystemPath(const char* path);
void LMSetEmulationRunning(int value);
void LMSetEmulationPaused(int value);

void LMSetControllerPushButton(int button);
void LMSetControllerReleaseButton(int button);

enum
{
  GP2X_UP=0x1,
  GP2X_LEFT=0x4,
  GP2X_DOWN=0x10,
  GP2X_RIGHT=0x40,
  GP2X_START=1<<8,
  GP2X_SELECT=1<<9,
  GP2X_L=1<<10,
  GP2X_R=1<<11,
  GP2X_A=1<<12,
  GP2X_B=1<<13,
  GP2X_X=1<<14,
  GP2X_Y=1<<15,
  GP2X_VOL_UP=1<<23,
  GP2X_VOL_DOWN=1<<22,
  GP2X_PUSH=1<<27
};

#endif
