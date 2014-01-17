//
//  LMGameController.h
//  SiOS
//
//  Created by Wayne Hartman on 1/17/14.
//  Copyright (c) 2014 Lucas Menge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMHardwareController.h"

@interface LMGameController : NSObject <LMHardwareController>

- (instancetype)initWithGameController:(GCController *)controller;

@end
