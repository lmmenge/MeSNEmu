//
//  LMSaveManager.h
//  SiOS
//
//  Created by Lucas Menge on 1/18/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LMSaveManager : NSObject

+ (void)saveRunningStateForROMNamed:(NSString*)romFileName;
+ (void)loadRunningStateForROMNamed:(NSString*)romFileName;

+ (void)saveStateForROMNamed:(NSString*)romFileName slot:(int)slot;
+ (void)loadStateForROMNamed:(NSString*)romFileName slot:(int)slot;

@end
