//
//  LMFileListItem.h
//  MeSNEmu
//
//  Created by Jared Egan on 8/6/15.
//  Copyright 2015 Lucas Menge. All rights reserved.
//

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////////////////////////
@interface LMRomInfo : NSObject

@property BOOL hasDetails; // Has saves?
@property (strong) NSString* displayName;
@property (strong) NSString* displayDetails;
@property (strong) NSString* fileName;
@property (strong) NSString* filePath;

+ (BOOL)isROMExtension:(NSString*)extension;
+ (BOOL)isROMFileName:(NSString*)fileName;
+ (BOOL)isFreezeFileName:(NSString*)fileName;
+ (BOOL)isSRMFileName:(NSString*)fileName;

@end
