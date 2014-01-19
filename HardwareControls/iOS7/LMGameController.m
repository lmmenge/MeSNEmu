//
//  LMGameController.m
//  SiOS
//
//  Created by Wayne Hartman on 1/17/14.
//  Copyright (c) 2014 Lucas Menge. All rights reserved.
//

#import "LMGameController.h"
#import "Snes9xMain.h"

@interface LMGameController ()

@property (nonatomic, strong) GCController *gameController;

@end

@implementation LMGameController
@synthesize pauseHandler = _pauseHandler;

- (instancetype)initWithGameController:(GCController *)controller {
    if ((self = [super init])) {
        _gameController = controller;
        [self setupController];
    }

    return self;
}

- (void)setupController {
    self.gameController.gamepad.buttonX.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
        if (pressed) {
            SISetControllerPushButton(SIOS_Y);
        } else {
            SISetControllerReleaseButton(SIOS_Y);
        }
    };
    
    self.gameController.gamepad.buttonY.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
        if (pressed) {
            SISetControllerPushButton(SIOS_X);
        } else {
            SISetControllerReleaseButton(SIOS_X);
        }
    };
    
    self.gameController.gamepad.buttonA.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
        if (pressed) {
            SISetControllerPushButton(SIOS_B);
        } else {
            SISetControllerReleaseButton(SIOS_B);
        }
    };
    
    self.gameController.gamepad.buttonB.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
        if (pressed) {
            SISetControllerPushButton(SIOS_A);
        } else {
            SISetControllerReleaseButton(SIOS_A);
        }
    };
    
    self.gameController.gamepad.rightShoulder.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
        if (pressed) {
            SISetControllerPushButton(SIOS_R);
        } else {
            SISetControllerReleaseButton(SIOS_R);
        }
    };
    
    self.gameController.gamepad.leftShoulder.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
        if (pressed) {
            SISetControllerPushButton(SIOS_L);
        } else {
            SISetControllerReleaseButton(SIOS_L);
        }
    };
    
    self.gameController.gamepad.dpad.up.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
        if (pressed) {
            SISetControllerPushButton(SIOS_UP);
        } else {
            SISetControllerReleaseButton(SIOS_UP);
        }
    };
    
    self.gameController.gamepad.dpad.down.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
        if (pressed) {
            SISetControllerPushButton(SIOS_DOWN);
        } else {
            SISetControllerReleaseButton(SIOS_DOWN);
        }
    };
    
    self.gameController.gamepad.dpad.left.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
        if (pressed) {
            SISetControllerPushButton(SIOS_LEFT);
        } else {
            SISetControllerReleaseButton(SIOS_LEFT);
        }
    };
    
    self.gameController.gamepad.dpad.right.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
        if (pressed) {
            SISetControllerPushButton(SIOS_RIGHT);
        } else {
            SISetControllerReleaseButton(SIOS_RIGHT);
        }
    };
    
    self.gameController.controllerPausedHandler = ^(GCController *controller) {
        if (self.pauseHandler) {
            self.pauseHandler();
        }
    };
}

@end
