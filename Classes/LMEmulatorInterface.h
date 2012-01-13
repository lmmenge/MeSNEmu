//
//  LMEmulatorInterface.h
//  SiOS
//
//  Created by Lucas Menge on 1/2/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#ifndef SiOS_LMEmulatorInterface_h
#define SiOS_LMEmulatorInterface_h

// where the pixels for the screen are stored. front-end defined
//extern unsigned int* screenPixels;

// emulator entry point
extern int iphone_main(char* filename);

// convenience functions implemented to make things clearer
void LMSetScreen(unsigned char* screen);
void LMSetSystemPath(const char* path);
void LMSetSoundOn(int value);
void LMSetAutoFrameskip(int value);
void LMSetFrameskip(int value);

void LMSetEmulationRunning(int value);
void LMSetEmulationPaused(int value);
void LMReset();

void LMSetControllerPushButton(int button);
void LMSetControllerReleaseButton(int button);

enum
{
  SIOS_UP=0x1,
  SIOS_LEFT=0x4,
  SIOS_DOWN=0x10,
  SIOS_RIGHT=0x40,
  SIOS_START=1<<8,
  SIOS_SELECT=1<<9,
  SIOS_L=1<<10,
  SIOS_R=1<<11,
  SIOS_A=1<<12,
  SIOS_B=1<<13,
  SIOS_X=1<<14,
  SIOS_Y=1<<15,
  SIOS_VOL_UP=1<<23,
  SIOS_VOL_DOWN=1<<22,
  SIOS_PUSH=1<<27
};

#endif
