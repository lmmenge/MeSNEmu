//
//  SISaveDelegate.h
//  MeSNEmu
//
//  Created by Lucas Menge on 1/19/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

// Posted when the emulator wants to load the running save state
extern NSString* const SILoadRunningStateNotification;
// Posted when the emulator wants to save the running save state
extern NSString* const SISaveRunningStateNotification;

// Key of the user dictionary in the above notifications that has the ROM filename
extern NSString* const SIROMFileNameKey;

// Delegate for the class that will handle save/load requests by the emulator
@protocol SISaveDelegate <NSObject>

- (void)loadROMRunningState;
- (void)saveROMRunningState;

@end

#pragma mark - Delegate Management Functions

// Sets who is the save/load delegate
void SISetSaveDelegate(id<SISaveDelegate> value);
