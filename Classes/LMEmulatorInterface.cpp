//
//  LMEmulatorInterface.cpp
//  pixelbuffertest
//
//  Created by Lucas Menge on 1/2/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import "../SNES9X/snes9x.h"
#import "../SNES9X/memmap.h"
#import "../SNES9X/controls.h"
#import "../SNES9X/gfx.h"

#import "../SNES9XBridge/Snes9xMain.h"

//unsigned int* screenPixels = 0;

volatile int SI_EmulationRun = 0;
volatile int SI_EmulationSaving = 0;
volatile int SI_EmulationPaused = 0;

char SI_DocumentsPath[255];

extern "C" void LMSetScreen(unsigned char* screen)
{
  GFX.Screen = (uint16*)screen;
}

extern "C" void LMSetSystemPath(const char* path)
{
  strcpy(SI_DocumentsPath, path);
}

extern "C" void LMSetEmulationRunning(int value)
{
  if(value < 0)
    value = 0;
  else if(value > 1)
    value = 1;
  SI_EmulationRun = value;
}

extern "C" void LMSetEmulationPaused(int value)
{
  if(value < 0)
    value = 0;
  else if(value > 1)
    value = 1;
  SI_EmulationPaused = value;
}

extern "C" void LMReset()
{
  SI_EmulationPaused = 1;
  SISaveSRAM();
  S9xReset();
  SILoadSRAM();
  SI_EmulationPaused = 0;
}

extern "C" void LMSetControllerPushButton(unsigned long button)
{
  S9xReportButton((uint32)button, (bool)1);
}

extern "C" void LMSetControllerReleaseButton(unsigned long button)
{
  S9xReportButton((uint32)button, (bool)0);
}
