//
//  Snes9xMain.h
//  SiOS
//
//  Created by Lucas Menge on 1/2/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#ifndef SiOS_Snes9xMain_h
#define SiOS_Snes9xMain_h

#include "../SNES9X/port.h"

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

#ifdef __cplusplus
extern "C" {
#endif
  
// Don't call this
void SIFlipFramebuffer(int flip, int sync);

// Tells the emulator to load the SRAM
void SILoadSRAM();
// Tells the emulator to save the SRAM
void SISaveSRAM();

// Updates the emulator structures with the new settings defined by the convenience functions
void SIUpdateSettings();

// Starts the emulator with a ROM image
int SIStartWithROM(char* rom_filename);
  
#ifdef __cplusplus
}
#endif

#endif

