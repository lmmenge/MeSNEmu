//
//  LMEmulatorInterface.h
//  SiOS
//
//  Created by Lucas Menge on 1/2/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#ifndef SiOS_LMEmulatorInterface_h
#define SiOS_LMEmulatorInterface_h

#ifdef __cplusplus
extern "C" {
#endif

// convenience functions implemented to make things clearer
void LMSetScreen(unsigned char* screen);
void LMSetSystemPath(const char* path);
void LMSetRunningStatesPath(const char* path);
void LMSetSoundOn(int value);
void LMSetAutoFrameskip(int value);
void LMSetFrameskip(int value);

void LMSettingsUpdated();

void LMSetEmulationRunning(int value);
void LMSetEmulationPaused(int value);
void LMWaitForPause();
void LMReset();

void LMSetControllerPushButton(int button);
void LMSetControllerReleaseButton(int button);

#ifdef __cplusplus
}
#endif
  
#endif
