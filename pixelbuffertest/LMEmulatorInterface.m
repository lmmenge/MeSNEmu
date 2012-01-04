//
//  LMEmulatorInterface.c
//  pixelbuffertest
//
//  Created by Lucas Menge on 1/2/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import "LMEmulatorController.h"

unsigned int* screenPixels = 0;

volatile int __emulation_run = 0;
volatile int __emulation_saving = 0;
volatile int __emulation_paused = 0;

char SYSTEM_DIR[255];
int iphone_soundon = 1;
int __autosave = 0;
int __speedhack = 0;
int __transparency = 0;
int __smooth_scaling = 0;
unsigned long __fps_debug = 0;

unsigned long padStatus = 0;

void refreshScreenSurface()
{
  [[LMEmulatorController sharedInstance] performSelectorOnMainThread:@selector(updateView) withObject:nil waitUntilDone:NO];
}

unsigned long padStatusForPadNumber(int which)
{
  if(which == 0)
    return padStatus;
  else
    return 0;
}

void saveScreenshotToFile(char* filepath)
{
  
}

void LMSetSystemPath(const char* path)
{
  strcpy(SYSTEM_DIR, path);
}

void LMSetEmulationRunning(int value)
{
  if(value < 0)
    value = 0;
  else if(value > 1)
    value = 1;
  __emulation_run = value;
  
  padStatus = 0;
}

void LMSetEmulationPaused(int value)
{
  if(value < 0)
    value = 0;
  else if(value > 1)
    value = 1;
  __emulation_paused = value;
}

void LMSetControllerPushButton(unsigned long button)
{
  padStatus |= button;
  //printf("Press %lX -> %lX\n", button, padStatus);
}

void LMSetControllerReleaseButton(unsigned long button)
{
  padStatus &= ~button;
  //printf("Release %lX (%lX) -> %lX\n", button, ~button, padStatus);
}
