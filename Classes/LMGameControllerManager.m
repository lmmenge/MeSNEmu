//
//  LMGameControllerManager.m
//  SiOS
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
        SISetControllerPushButton(kSIOS_1PB);
      }
      else {
        SISetControllerReleaseButton(kSIOS_1PB);
      }
      if (extendedGamepad.buttonB.pressed) {
        SISetControllerPushButton(kSIOS_1PA);
      }
      else {
        SISetControllerReleaseButton(kSIOS_1PA);
      }
      if (extendedGamepad.buttonX.pressed) {
        SISetControllerPushButton(kSIOS_1PY);
      }
      else {
        SISetControllerReleaseButton(kSIOS_1PY);
      }
      if (extendedGamepad.buttonY.pressed) {
        SISetControllerPushButton(kSIOS_1PX);
      }
      else {
        SISetControllerReleaseButton(kSIOS_1PX);
      }
      
      if (extendedGamepad.leftShoulder.pressed) {
        SISetControllerPushButton(kSIOS_1PL);
      }
      else {
        SISetControllerReleaseButton(kSIOS_1PL);
      }
      
      if (extendedGamepad.rightShoulder.pressed) {
        SISetControllerPushButton(kSIOS_1PR);
      }
      else {
        SISetControllerReleaseButton(kSIOS_1PR);
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
        SISetControllerPushButton(kSIOS_1PUp);
      }
      else {
        SISetControllerReleaseButton(kSIOS_1PUp);
      }
      if (extendedGamepad.dpad.down.pressed || extendedGamepad.leftThumbstick.down.pressed) {
        SISetControllerPushButton(kSIOS_1PDown);
      }
      else {
        SISetControllerReleaseButton(kSIOS_1PDown);
      }
      if (extendedGamepad.dpad.left.pressed || extendedGamepad.leftThumbstick.left.pressed) {
        SISetControllerPushButton(kSIOS_1PLeft);
      }
      else {
        SISetControllerReleaseButton(kSIOS_1PLeft);
      }
      if (extendedGamepad.dpad.right.pressed || extendedGamepad.leftThumbstick.right.pressed) {
        SISetControllerPushButton(kSIOS_1PRight);
      }
      else {
        SISetControllerReleaseButton(kSIOS_1PRight);
      }
    }
    
    if(_gameController.gamepad)
    {
      GCGamepad* gamepad = _gameController.gamepad;
      
      // You should swap A+B / X+Y because it feels awkward on Gamepad
      if (gamepad.buttonA.pressed) {
        SISetControllerPushButton(kSIOS_1PB);
      }
      else {
        SISetControllerReleaseButton(kSIOS_1PB);
      }
      if (gamepad.buttonB.pressed) {
        SISetControllerPushButton(kSIOS_1PA);
      }
      else {
        SISetControllerReleaseButton(kSIOS_1PA);
      }
      if (gamepad.buttonX.pressed) {
        SISetControllerPushButton(kSIOS_1PY);
      }
      else {
        SISetControllerReleaseButton(kSIOS_1PY);
      }
      if (gamepad.buttonY.pressed) {
        SISetControllerPushButton(kSIOS_1PX);
      }
      else {
        SISetControllerReleaseButton(kSIOS_1PX);
      }
      
      // Extended Gamepad gets a thumbstick as well
      if (gamepad.dpad.up.pressed) {
        SISetControllerPushButton(kSIOS_1PUp);
      }
      else {
        SISetControllerReleaseButton(kSIOS_1PUp);
      }
      if (gamepad.dpad.down.pressed) {
        SISetControllerPushButton(kSIOS_1PDown);
      }
      else {
        SISetControllerReleaseButton(kSIOS_1PDown);
      }
      if (gamepad.dpad.left.pressed) {
        SISetControllerPushButton(kSIOS_1PLeft);
      }
      else {
        SISetControllerReleaseButton(kSIOS_1PLeft);
      }
      if (gamepad.dpad.right.pressed) {
        SISetControllerPushButton(kSIOS_1PRight);
      }
      else {
        SISetControllerReleaseButton(kSIOS_1PRight);
      }
    }
  }
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
