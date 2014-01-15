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
        SISetControllerPushButton(SIOS_B);
      }
      else {
        SISetControllerReleaseButton(SIOS_B);
      }
      if (extendedGamepad.buttonB.pressed) {
        SISetControllerPushButton(SIOS_A);
      }
      else {
        SISetControllerReleaseButton(SIOS_A);
      }
      if (extendedGamepad.buttonX.pressed) {
        SISetControllerPushButton(SIOS_Y);
      }
      else {
        SISetControllerReleaseButton(SIOS_Y);
      }
      if (extendedGamepad.buttonY.pressed) {
        SISetControllerPushButton(SIOS_X);
      }
      else {
        SISetControllerReleaseButton(SIOS_X);
      }
      
      if (extendedGamepad.leftShoulder.pressed) {
        SISetControllerPushButton(SIOS_L);
      }
      else {
        SISetControllerReleaseButton(SIOS_L);
      }
      
      if (extendedGamepad.rightShoulder.pressed) {
        SISetControllerPushButton(SIOS_R);
      }
      else {
        SISetControllerReleaseButton(SIOS_R);
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
        SISetControllerPushButton(SIOS_UP);
      }
      else {
        SISetControllerReleaseButton(SIOS_UP);
      }
      if (extendedGamepad.dpad.down.pressed || extendedGamepad.leftThumbstick.down.pressed) {
        SISetControllerPushButton(SIOS_DOWN);
      }
      else {
        SISetControllerReleaseButton(SIOS_DOWN);
      }
      if (extendedGamepad.dpad.left.pressed || extendedGamepad.leftThumbstick.left.pressed) {
        SISetControllerPushButton(SIOS_LEFT);
      }
      else {
        SISetControllerReleaseButton(SIOS_LEFT);
      }
      if (extendedGamepad.dpad.right.pressed || extendedGamepad.leftThumbstick.right.pressed) {
        SISetControllerPushButton(SIOS_RIGHT);
      }
      else {
        SISetControllerReleaseButton(SIOS_RIGHT);
      }
    }
    
    if(_gameController.gamepad)
    {
      GCGamepad* gamepad = _gameController.gamepad;
      
      // You should swap A+B / X+Y because it feels awkward on Gamepad
      if (gamepad.buttonA.pressed) {
        SISetControllerPushButton(SIOS_B);
      }
      else {
        SISetControllerReleaseButton(SIOS_B);
      }
      if (gamepad.buttonB.pressed) {
        SISetControllerPushButton(SIOS_A);
      }
      else {
        SISetControllerReleaseButton(SIOS_A);
      }
      if (gamepad.buttonX.pressed) {
        SISetControllerPushButton(SIOS_Y);
      }
      else {
        SISetControllerReleaseButton(SIOS_Y);
      }
      if (gamepad.buttonY.pressed) {
        SISetControllerPushButton(SIOS_X);
      }
      else {
        SISetControllerReleaseButton(SIOS_X);
      }
      
      // Extended Gamepad gets a thumbstick as well
      if (gamepad.dpad.up.pressed) {
        SISetControllerPushButton(SIOS_UP);
      }
      else {
        SISetControllerReleaseButton(SIOS_UP);
      }
      if (gamepad.dpad.down.pressed) {
        SISetControllerPushButton(SIOS_DOWN);
      }
      else {
        SISetControllerReleaseButton(SIOS_DOWN);
      }
      if (gamepad.dpad.left.pressed) {
        SISetControllerPushButton(SIOS_LEFT);
      }
      else {
        SISetControllerReleaseButton(SIOS_LEFT);
      }
      if (gamepad.dpad.right.pressed) {
        SISetControllerPushButton(SIOS_RIGHT);
      }
      else {
        SISetControllerReleaseButton(SIOS_RIGHT);
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
