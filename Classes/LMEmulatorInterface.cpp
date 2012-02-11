//
//  LMEmulatorInterface.cpp
//  SiOS
//
//  Created by Lucas Menge on 1/2/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import "../SNES9X/snes9x.h"
#import "../SNES9X/memmap.h"
#import "../SNES9X/controls.h"
#import "../SNES9X/gfx.h"

#import "../SNES9XBridge/Snes9xMain.h"

int SI_SoundOn = 1;
int SI_AutoFrameskip = 1;
int SI_Frameskip = 0;

volatile int SI_EmulationRun = 0;
volatile int SI_EmulationSaving = 0;
volatile int SI_EmulationPaused = 0;
volatile int SI_EmulationDidPause = 1;

extern struct timeval SI_NextFrameTime;
extern int SI_FrameTimeDebt;
extern int SI_SleptLastFrame;

char SI_DocumentsPath[1024];
char SI_RunningStatesPath[1024];

extern "C" void LMSetScreen(unsigned char* screen)
{
  GFX.Screen = (uint16*)screen;
}

extern "C" void LMSetSystemPath(const char* path)
{
  strcpy(SI_DocumentsPath, path);
}

extern "C" void LMSetRunningStatesPath(const char* path)
{
  strcpy(SI_RunningStatesPath, path);
}

extern "C" void LMSetSoundOn(int value)
{
  if(value < 0)
    value = 0;
  else if(value > 1)
    value = 1;
  SI_SoundOn = value;
}

extern "C" void LMSetAutoFrameskip(int value)
{
  if(value < 0)
    value = 0;
  else if(value > 1)
    value = 1;
  SI_AutoFrameskip = value;
}

extern "C" void LMSetFrameskip(int value)
{
  SI_Frameskip = value;
}

extern "C" void LMSettingsUpdated()
{
  SIUpdateSettings();
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
  if(SI_EmulationPaused != value)
  {
    if(value == 0)
    {
      // we're unpausing. Reset the frameskip metrics
      SI_NextFrameTime = (timeval){0,0};
      SI_FrameTimeDebt = 0;
      SI_SleptLastFrame = 0;
    }
    else
      SI_EmulationDidPause = 0;
    
    SI_EmulationPaused = value;
  }
}

extern "C" void LMWaitForPause()
{
  if(SI_EmulationPaused == 1)
    // wait for the pause to conclude
    while(SI_EmulationDidPause == 0){}
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
