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
	k_HD = 0x80000000,
    
	k_JP = 0x01000000,
	k_MO = 0x02000000,
	k_SS = 0x04000000,
	k_LG = 0x08000000,
    
	k_BT = 0x00100000,
	k_PT = 0x00200000,
	k_PS = 0x00400000,
    
	k_C1 = 0x00000100,
	k_C2 = 0x00000200,
	k_C3 = 0x00000400,
	k_C4 = 0x00000800,
	k_C5 = 0x00001000,
	k_C6 = 0x00002000,
	k_C7 = 0x00004000,
	k_C8 = 0x00008000
};

enum
{
	kSIOS_1PX            = k_HD | k_BT | k_JP | k_C1,
	kSIOS_1PA,
	kSIOS_1PB,
	kSIOS_1PY,
	kSIOS_1PL,
	kSIOS_1PR,
	kSIOS_1PSelect,
	kSIOS_1PStart,
	kSIOS_1PUp,
	kSIOS_1PDown,
	kSIOS_1PLeft,
	kSIOS_1PRight,
    
	kSIOS_2PX            = k_HD | k_BT | k_JP | k_C2,
	kSIOS_2PA,
	kSIOS_2PB,
	kSIOS_2PY,
	kSIOS_2PL,
	kSIOS_2PR,
	kSIOS_2PSelect,
	kSIOS_2PStart,
	kSIOS_2PUp,
	kSIOS_2PDown,
	kSIOS_2PLeft,
	kSIOS_2PRight,
    
	kSIOS_3PX            = k_HD | k_BT | k_JP | k_C3,
	kSIOS_3PA,
	kSIOS_3PB,
	kSIOS_3PY,
	kSIOS_3PL,
	kSIOS_3PR,
	kSIOS_3PSelect,
	kSIOS_3PStart,
	kSIOS_3PUp,
	kSIOS_3PDown,
	kSIOS_3PLeft,
	kSIOS_3PRight,
    
	kSIOS_4PX            = k_HD | k_BT | k_JP | k_C4,
	kSIOS_4PA,
	kSIOS_4PB,
	kSIOS_4PY,
	kSIOS_4PL,
	kSIOS_4PR,
	kSIOS_4PSelect,
	kSIOS_4PStart,
	kSIOS_4PUp,
	kSIOS_4PDown,
	kSIOS_4PLeft,
	kSIOS_4PRight,
    
	kSIOS_5PX            = k_HD | k_BT | k_JP | k_C5,
	kSIOS_5PA,
	kSIOS_5PB,
	kSIOS_5PY,
	kSIOS_5PL,
	kSIOS_5PR,
	kSIOS_5PSelect,
	kSIOS_5PStart,
	kSIOS_5PUp,
	kSIOS_5PDown,
	kSIOS_5PLeft,
	kSIOS_5PRight,
    
	kSIOS_6PX            = k_HD | k_BT | k_JP | k_C6,
	kSIOS_6PA,
	kSIOS_6PB,
	kSIOS_6PY,
	kSIOS_6PL,
	kSIOS_6PR,
	kSIOS_6PSelect,
	kSIOS_6PStart,
	kSIOS_6PUp,
	kSIOS_6PDown,
	kSIOS_6PLeft,
	kSIOS_6PRight,
    
	kSIOS_7PX            = k_HD | k_BT | k_JP | k_C7,
	kSIOS_7PA,
	kSIOS_7PB,
	kSIOS_7PY,
	kSIOS_7PL,
	kSIOS_7PR,
	kSIOS_7PSelect,
	kSIOS_7PStart,
	kSIOS_7PUp,
	kSIOS_7PDown,
	kSIOS_7PLeft,
	kSIOS_7PRight,
    
	kSIOS_8PX            = k_HD | k_BT | k_JP | k_C8,
	kSIOS_8PA,
	kSIOS_8PB,
	kSIOS_8PY,
	kSIOS_8PL,
	kSIOS_8PR,
	kSIOS_8PSelect,
	kSIOS_8PStart,
	kSIOS_8PUp,
	kSIOS_8PDown,
	kSIOS_8PLeft,
	kSIOS_8PRight,
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

