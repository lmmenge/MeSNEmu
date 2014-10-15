//
//  SISaveDelegate.m
//  MeSNEmu
//
//  Created by Lucas Menge on 1/19/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import "SISaveDelegate.h"

NSString* const SILoadRunningStateNotification = @"SILoadRunningStateNotification";
NSString* const SISaveRunningStateNotification = @"SISaveRunningStateNotification";
NSString* const SIROMFileNameKey = @"SIRomFileNameKey";

static NSObject<SISaveDelegate>* delegate = nil;

void SISetSaveDelegate(id<SISaveDelegate> value)
{
  delegate = value;
}

#pragma mark - Start and End Notifications

void SILoadRunningStateForGameNamed(const char* romFileName)
{
  @autoreleasepool {
  /*[[NSNotificationCenter defaultCenter] postNotificationName:SILoadRunningStateNotification
                                                      object:nil
                                                    userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithCString:romFileName encoding:NSUTF8StringEncoding] forKey:SIROMFileNameKey]];*/
  [delegate loadROMRunningState];
  }
}
   
void SISaveRunningStateForGameNamed(const char* romFileName)
{
  @autoreleasepool {
  /*[[NSNotificationCenter defaultCenter] postNotificationName:SISaveRunningStateNotification
                                                      object:nil
                                                    userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithCString:romFileName encoding:NSUTF8StringEncoding] forKey:SIROMFileNameKey]];*/
  [delegate saveROMRunningState];
  }
}
