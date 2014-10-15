//
//  LMGameControllerManager.m
//  MeSNEmu
//
//  Created by Adam Bell on 12/22/2013.
//
//

#import "LMGameControllerManager.h"

#import <GameController/GameController.h>

#import "../SNES9XBridge/Snes9xMain.h"

@implementation LMGameControllerManager(Privates)

#pragma mark Game Controller Handling

- (void)LM_setupController
{
  if([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f)
  {
    NSArray* controllers = [GCController controllers];
    // Grab first controller
    // TODO: Add support for multiple controllers
    _gameController = [controllers firstObject];
    
    __weak id weakSelf = self;
    
    _gameController.gamepad.valueChangedHandler = ^(GCGamepad* gamepad, GCControllerElement* element) {
      [weakSelf LM_getCurrentControllerInput];
    };
    _gameController.extendedGamepad.valueChangedHandler = ^(GCExtendedGamepad* gamepad, GCControllerElement* element) {
      [weakSelf LM_getCurrentControllerInput];
    };
  }
}

- (void)LM_controllerConnected:(NSNotification*)notification
{
  [self LM_setupController];
  [self.delegate gameControllerManagerGamepadDidConnect:self];
}

- (void)LM_controllerDisconnected:(NSNotification*)notification
{
  [self LM_setupController];
  [self.delegate gameControllerManagerGamepadDidDisconnect:self];
}

- (void)LM_getCurrentControllerInput
{
  if(_gameController)
  {
    if(_gameController.extendedGamepad)
    {
      GCExtendedGamepad* extendedGamepad = _gameController.extendedGamepad;
      
      // You should swap A+B / X+Y because it feels awkward on Gamepad
      if (extendedGamepad.buttonA.pressed) {
        SISetControllerPushButton(SI_BUTTON_B);
      }
      else {
        SISetControllerReleaseButton(SI_BUTTON_B);
      }
      if (extendedGamepad.buttonB.pressed) {
        SISetControllerPushButton(SI_BUTTON_A);
      }
      else {
        SISetControllerReleaseButton(SI_BUTTON_A);
      }
      if (extendedGamepad.buttonX.pressed) {
        SISetControllerPushButton(SI_BUTTON_Y);
      }
      else {
        SISetControllerReleaseButton(SI_BUTTON_Y);
      }
      if (extendedGamepad.buttonY.pressed) {
        SISetControllerPushButton(SI_BUTTON_X);
      }
      else {
        SISetControllerReleaseButton(SI_BUTTON_X);
      }
      
      if (extendedGamepad.leftShoulder.pressed) {
        SISetControllerPushButton(SI_BUTTON_L);
      }
      else {
        SISetControllerReleaseButton(SI_BUTTON_L);
      }
      
      if (extendedGamepad.rightShoulder.pressed) {
        SISetControllerPushButton(SI_BUTTON_R);
      }
      else {
        SISetControllerReleaseButton(SI_BUTTON_R);
      }

      if (extendedGamepad.leftTrigger.pressed) {
        SISetControllerPushButton(SI_BUTTON_SELECT);
      }
      else {
        SISetControllerReleaseButton(SI_BUTTON_SELECT);
      }

      if (extendedGamepad.rightTrigger.pressed) {
        SISetControllerPushButton(SI_BUTTON_START);
      }
      else {
        SISetControllerReleaseButton(SI_BUTTON_START);
      }
      
      // This feels super awkward
      /*
       if (extendedGamepad.buttonX.pressed) {
       padInput |= NestopiaPadInputStart;
       }
       if (extendedGamepad.buttonY.pressed) {
       padInput |= NestopiaPadInputSelect;
       }
       */
      
      // Extended Gamepad gets a thumbstick as well
      if (extendedGamepad.dpad.up.pressed || extendedGamepad.leftThumbstick.up.pressed) {
        SISetControllerPushButton(SI_BUTTON_UP);
      }
      else {
        SISetControllerReleaseButton(SI_BUTTON_UP);
      }
      if (extendedGamepad.dpad.down.pressed || extendedGamepad.leftThumbstick.down.pressed) {
        SISetControllerPushButton(SI_BUTTON_DOWN);
      }
      else {
        SISetControllerReleaseButton(SI_BUTTON_DOWN);
      }
      if (extendedGamepad.dpad.left.pressed || extendedGamepad.leftThumbstick.left.pressed) {
        SISetControllerPushButton(SI_BUTTON_LEFT);
      }
      else {
        SISetControllerReleaseButton(SI_BUTTON_LEFT);
      }
      if (extendedGamepad.dpad.right.pressed || extendedGamepad.leftThumbstick.right.pressed) {
        SISetControllerPushButton(SI_BUTTON_RIGHT);
      }
      else {
        SISetControllerReleaseButton(SI_BUTTON_RIGHT);
      }
      
      extendedGamepad.controller.controllerPausedHandler = ^(GCController *controller) {
        if (extendedGamepad.leftShoulder.pressed) {
            SISetControllerPushButton(SI_BUTTON_SELECT);
            // Release button after a delay otherwise it will get stuck or not register at all
            [self performSelector:@selector(releaseSelect) withObject:nil afterDelay:0.1];
        }
        else {
            SISetControllerPushButton(SI_BUTTON_START);
            // Release button after a delay otherwise it will get stuck or not register at all
            [self performSelector:@selector(releaseStart) withObject:nil afterDelay:0.1];
        }
      };
    } else if(_gameController.gamepad)
    {
      GCGamepad* gamepad = _gameController.gamepad;
      
      // You should swap A+B / X+Y because it feels awkward on Gamepad
      if (gamepad.buttonA.pressed) {
        SISetControllerPushButton(SI_BUTTON_B);
      }
      else {
        SISetControllerReleaseButton(SI_BUTTON_B);
      }
      if (gamepad.buttonB.pressed) {
        SISetControllerPushButton(SI_BUTTON_A);
      }
      else {
        SISetControllerReleaseButton(SI_BUTTON_A);
      }
      if (gamepad.buttonX.pressed) {
        SISetControllerPushButton(SI_BUTTON_Y);
      }
      else {
        SISetControllerReleaseButton(SI_BUTTON_Y);
      }
      if (gamepad.buttonY.pressed) {
        SISetControllerPushButton(SI_BUTTON_X);
      }
      else {
        SISetControllerReleaseButton(SI_BUTTON_X);
      }
      
      if (gamepad.leftShoulder.pressed) {
        SISetControllerPushButton(SI_BUTTON_L);
      }
      else {
        SISetControllerReleaseButton(SI_BUTTON_L);
      }
    
      if (gamepad.rightShoulder.pressed) {
        SISetControllerPushButton(SI_BUTTON_R);
      }
      else {
        SISetControllerReleaseButton(SI_BUTTON_R);
      }
        
      // Extended Gamepad gets a thumbstick as well
      if (gamepad.dpad.up.pressed) {
        SISetControllerPushButton(SI_BUTTON_UP);
      }
      else {
        SISetControllerReleaseButton(SI_BUTTON_UP);
      }
      if (gamepad.dpad.down.pressed) {
        SISetControllerPushButton(SI_BUTTON_DOWN);
      }
      else {
        SISetControllerReleaseButton(SI_BUTTON_DOWN);
      }
      if (gamepad.dpad.left.pressed) {
        SISetControllerPushButton(SI_BUTTON_LEFT);
      }
      else {
        SISetControllerReleaseButton(SI_BUTTON_LEFT);
      }
      if (gamepad.dpad.right.pressed) {
        SISetControllerPushButton(SI_BUTTON_RIGHT);
      }
      else {
        SISetControllerReleaseButton(SI_BUTTON_RIGHT);
      }
      
      gamepad.controller.controllerPausedHandler = ^(GCController *controller) {
          if (gamepad.leftShoulder.pressed) {
              SISetControllerPushButton(SI_BUTTON_SELECT);
              // Release button after a delay otherwise it will get stuck or not register at all
              [self performSelector:@selector(releaseSelect) withObject:nil afterDelay:0.1];
          }
          else {
              SISetControllerPushButton(SI_BUTTON_START);
              // Release button after a delay otherwise it will get stuck or not register at all
              [self performSelector:@selector(releaseStart) withObject:nil afterDelay:0.1];
          }
      };
    }
  }
}

- (void)releaseSelect {
    SISetControllerReleaseButton(SI_BUTTON_SELECT);
}

- (void)releaseStart {
    SISetControllerReleaseButton(SI_BUTTON_START);
}

@end

#pragma mark -

@implementation LMGameControllerManager

- (BOOL)gameControllerConnected
{
  return (_gameController != nil);
}

+ (instancetype)sharedInstance
{
  static dispatch_once_t p = 0;
  
  __strong static id _sharedInstance = nil;
  
  dispatch_once(&p, ^{
    _sharedInstance = [[self alloc] init];
  });
  
  return _sharedInstance;
}

+ (BOOL)gameControllersMightBeAvailable
{
  if([GCController class] != nil)
    return YES;
  return NO;
}

@end

#pragma mark -

@implementation LMGameControllerManager(NSObject)

- (instancetype)init
{
  self = [super init];
  if(self != nil)
  {
    [self LM_setupController];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(LM_controllerConnected:)
                                                 name:GCControllerDidConnectNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(LM_controllerDisconnected:)
                                                 name:GCControllerDidDisconnectNotification
                                               object:nil];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:GCControllerDidConnectNotification
                                                object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:GCControllerDidDisconnectNotification
                                                object:nil];
}

@end
