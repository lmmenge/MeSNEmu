//
//  LMHardwareController.h
//  SiOS
//
//  Created by Wayne Hartman on 1/17/14.
//  Copyright (c) 2014 Lucas Menge. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^LMPauseHandler)(void);

@protocol LMHardwareController <NSObject>

@property (nonatomic, copy) LMPauseHandler pauseHandler;

@end
