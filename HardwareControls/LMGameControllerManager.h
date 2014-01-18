//
//  LMGameControllerManager.h
//  SiOS
//
//  Created by Wayne Hartman on 1/17/14.
//  Copyright (c) 2014 Lucas Menge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMHardwareController.h"

typedef void(^LMGameControllerConnectionHandler)(BOOL isConnected);

@interface LMGameControllerManager : NSObject

@property (nonatomic, strong) id<LMHardwareController>hardwareController;
@property (nonatomic, copy) LMGameControllerConnectionHandler connectionHandler;

@end
