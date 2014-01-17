//
//  LMGameControllerManager.h
//  SiOS
//
//  Created by Wayne Hartman on 1/17/14.
//  Copyright (c) 2014 Lucas Menge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMHardwareController.h"

@interface LMGameControllerManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, strong) id<LMHardwareController>hardwareController;

@end
