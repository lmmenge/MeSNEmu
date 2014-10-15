//
//  SIScreenDelegate.h
//  MeSNEmu
//
//  Created by Lucas Menge on 1/2/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#pragma mark Delegates

// Delegate for the class that will handle screen update notifications from the emulator
@protocol SIScreenDelegate <NSObject>

- (void)flipFrontbuffer:(NSArray*)dimensions;

@end

#pragma mark - Delegate Management Functions

// Sets the screen update delegate
void SISetScreenDelegate(id<SIScreenDelegate> value);