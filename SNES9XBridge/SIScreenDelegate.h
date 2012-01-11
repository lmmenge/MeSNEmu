//
//  SIScreenDelegate.h
//  SiOS
//
//  Created by Lucas Menge on 1/2/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#pragma mark Delegates

@protocol SIScreenDelegate <NSObject>

- (void)flipFrontbuffer;

@end

#pragma mark - Delegate Management Functions

void SISetScreenDelegate(id<SIScreenDelegate> value);