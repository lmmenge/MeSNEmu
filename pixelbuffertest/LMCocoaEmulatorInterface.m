//
//  LMCocoaEmulatorInterface.c
//  pixelbuffertest
//
//  Created by Lucas Menge on 1/5/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import "LMEmulatorController.h"

void refreshScreenSurface()
{
  [[LMEmulatorController sharedInstance] performSelectorOnMainThread:@selector(updateView) withObject:nil waitUntilDone:NO];
}