//
//  Snes9xMain.h
//  MeSNEmu
//
//  Created by Lucas Menge on 1/2/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#ifndef MeSNEmu_Snes9xMain_h
#define MeSNEmu_Snes9xMain_h

#include "../SNES9X/port.h"

enum
{
  SI_BUTTON_UP=0x1,
  SI_BUTTON_LEFT=0x4,
  SI_BUTTON_DOWN=0x10,
  SI_BUTTON_RIGHT=0x40,
  SI_BUTTON_START=1<<8,
  SI_BUTTON_SELECT=1<<9,
  SI_BUTTON_L=1<<10,
  SI_BUTTON_R=1<<11,
  SI_BUTTON_A=1<<12,
  SI_BUTTON_B=1<<13,
  SI_BUTTON_X=1<<14,
  SI_BUTTON_Y=1<<15,
  SI_BUTTON_VOL_UP=1<<23,
  SI_BUTTON_VOL_DOWN=1<<22,
  SI_BUTTON_PUSH=1<<27
};

#ifdef __cplusplus
extern "C" {
#endif

// Path management
// ===============

// sets the path where ROMs are going to be loaded from
void SISetSystemPath(const char* path);
// sets the path where save states are going to be saved to/loaded from (currently unused)
void SISetRunningStatesPath(const char* path);
// sets the path where SRAM will be saved/loaded from
void SISetSRAMPath(const char* path);
  
// Emulated hardware management
// ============================
  
void SISetScreen(unsigned char* screen);
void SISetSoundOn(int value);
void SISetAutoFrameskip(int value);
void SISetFrameskip(int value);

// Run-state management
// ====================
  
void SISetEmulationRunning(int value);
void SISetEmulationPaused(int value);
void SIWaitForPause();
void SIWaitForEmulationEnd();
void SIReset();

// Controller updates
// ==================
  
// called by the client when it wants to notify of a button push
void SISetControllerPushButton(unsigned long button);
// called by the client when it wants to notify of a button release
void SISetControllerReleaseButton(unsigned long button);

// SRAM Management
// ===============
  
// Tells the emulator to load the SRAM
void SILoadSRAM();
// Tells the emulator to save the SRAM
void SISaveSRAM();

// Notifications to the emulator
// =============================
  
// Updates the emulator structures with the new settings defined by the convenience functions
void SIUpdateSettings();

// Main starting point
// ===================
  
// Starts the emulator with a ROM image
int SIStartWithROM(char* rom_filename);
  
#ifdef __cplusplus
}
#endif

#endif

