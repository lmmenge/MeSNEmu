//
//  SIScreenDelegate.m
//  SiOS
//
//  Created by Lucas Menge on 1/2/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import "SIScreenDelegate.h"

static NSObject<SIScreenDelegate>* delegate = nil;

void SISetScreenDelegate(NSObject<SIScreenDelegate>* value)
{
  delegate = value;
}

#pragma mark - Internal Flip Callback

void SIFlipFramebufferClient()
{
  [delegate performSelectorOnMainThread:@selector(flipFrontbuffer) withObject:nil waitUntilDone:NO];
}