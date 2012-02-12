//
//  LMSaveManager.m
//  SiOS
//
//  Created by Lucas Menge on 1/18/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import "LMSaveManager.h"

#import "../SNES9X/port.h"
#import "../SNES9X/snes9x.h"
#import "../SNES9X/snapshot.h"

#import "../SNES9XBridge/iOSAudio.h"


@implementation LMSaveManager(Privates)

+ (NSString*)pathForRunningStates
{
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
  return [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Saves"];
}

+ (NSString*)pathForSaveStates
{
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  return [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Saves"];
}

+ (NSString*)pathForSaveOfROMName:(NSString*)romFileName slot:(int)slot
{
  NSString* saveFolderPath = nil;
  if(slot <= 0)
    saveFolderPath = [LMSaveManager pathForRunningStates];
  else
    saveFolderPath = [LMSaveManager pathForSaveStates];
  
  if([[NSFileManager defaultManager] fileExistsAtPath:saveFolderPath isDirectory:nil] == NO)
    [[NSFileManager defaultManager] createDirectoryAtPath:saveFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
  
  NSString* romFileNameWithoutExtension = [romFileName stringByDeletingPathExtension];
  return [[saveFolderPath stringByAppendingPathComponent:romFileNameWithoutExtension] stringByAppendingPathExtension:[NSString stringWithFormat:@"%03d", slot]];
}

+ (void)LM_saveStateForROMName:(NSString*)romFileName inSlot:(int)slot
{
  NSString* savePath = [LMSaveManager pathForSaveOfROMName:romFileName slot:slot];
  
  if(S9xFreezeGame([savePath UTF8String]))
    NSLog(@"Saved to %@", savePath);
  else
    NSLog(@"Failed to save to %@", savePath);
  
  //LMSetEmulationPaused(0);
}

+ (void)LM_loadStateForROMName:(NSString*)romFileName inSlot:(int)slot
{
  SIMuteSound();
  NSString* savePath = [LMSaveManager pathForSaveOfROMName:romFileName slot:slot];
  
  if([[NSFileManager defaultManager] fileExistsAtPath:savePath] == NO)
  {
    NSLog(@"Save file doesn't exist at: %@", savePath);
    return;
  }
  
  if(S9xUnfreezeGame([savePath UTF8String]))
    NSLog(@"Loaded from %@", savePath);
  else
    NSLog(@"Failed to load from %@", savePath);
  
  /*int samplecount = Settings.SoundPlaybackRate/(Settings.PAL ? 50 : 60);
  int soundBufferSize = samplecount<<(1+(Settings.Stereo?1:0));
  SIDemuteSound(soundBufferSize);*/
}

@end

@implementation LMSaveManager

+ (void)saveRunningStateForROMNamed:(NSString*)romFileName
{
  [LMSaveManager LM_saveStateForROMName:romFileName inSlot:0];
}
+ (void)loadRunningStateForROMNamed:(NSString*)romFileName
{
  [LMSaveManager LM_loadStateForROMName:romFileName inSlot:0];
}

+ (void)saveStateForROMNamed:(NSString*)romFileName slot:(int)slot
{
  if(slot <= 0)
    return;
  
  [LMSaveManager LM_saveStateForROMName:romFileName inSlot:slot];
}
+ (void)loadStateForROMNamed:(NSString*)romFileName slot:(int)slot
{
  if(slot <= 0)
    return;
  
  [LMSaveManager LM_loadStateForROMName:romFileName inSlot:slot];
}

@end
