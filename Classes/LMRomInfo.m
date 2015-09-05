//
//  LMFileListItem.m
//  MeSNEmu
//
//  Created by Jared Egan on 8/6/15.
//  Copyright 2015 Lucas Menge. All rights reserved.
//

#import "LMRomInfo.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
@interface LMRomInfo()

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation LMRomInfo

+ (BOOL)isROMExtension:(NSString*)extension
{
    extension = [extension lowercaseString];
    if (extension != nil
        && ([extension compare:@"smc"] == NSOrderedSame
            || [extension compare:@"sfc"] == NSOrderedSame
            || [extension compare:@"zip"] == NSOrderedSame)) {
            return YES;
        }
    return NO;
}

+ (BOOL)isROMFileName:(NSString*)fileName {
    return [self isROMExtension:[fileName pathExtension]];
}

+ (BOOL)isFreezeFileName:(NSString*)fileName {
    return [[[fileName pathExtension] lowercaseString] isEqualToString:@"frz"];
}

+ (BOOL)isSRMFileName:(NSString*)fileName {
    return [[[fileName pathExtension] lowercaseString] isEqualToString:@"srm"];
}

@end
