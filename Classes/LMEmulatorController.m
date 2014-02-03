//
//  LMViewController.m
//  SiOS
//
//  Created by Lucas Menge on 1/2/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import "LMEmulatorController.h"

#import "LMButtonView.h"
#import "LMDPadView.h"
#import "LMEmulatorControllerView.h"
#import "LMPixelLayer.h"
#import "LMPixelView.h"

#ifdef SI_ENABLE_SAVES

#import "LMSaveManager.h"

#endif

#import "LMSettingsController.h"

#import "../SNES9XBridge/Snes9xMain.h"
#import "../SNES9XBridge/SISaveDelegate.h"

#import "../iCade/LMBTControllerView.h"
#import <GameController/GameController.h>

typedef enum _LMEmulatorAlert
{
  LMEmulatorAlertReset,
  LMEmulatorAlertSave,
  LMEmulatorAlertLoad
} LMEmulatorAlert;

#pragma mark -

@interface LMEmulatorController(Privates) <UIActionSheetDelegate, UIAlertViewDelegate, LMSettingsControllerDelegate, SISaveDelegate, iCadeEventDelegate, SIScreenDelegate>
@end

#pragma mark -

@implementation LMEmulatorController(Privates)

- (void)LM_emulationThreadMethod:(NSString*)romFileName;
{
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

  if(_emulationThread == [NSThread mainThread])
    _emulationThread = [NSThread currentThread];

  const char* originalString = [romFileName UTF8String];
  char* romFileNameCString = (char*)calloc(strlen(originalString) + 1, sizeof(char));
  strcpy(romFileNameCString, originalString);
  originalString = nil;

  SISetEmulationPaused(0);
  SISetEmulationRunning(1);
  SIStartWithROM(romFileNameCString);
  SISetEmulationRunning(0);

  free(romFileNameCString);

  if(_emulationThread == [NSThread currentThread])
    _emulationThread = nil;

  [pool release];
}

- (void)LM_dismantleExternalScreen
{
  if(_externalEmulator != nil)
  {
    _customView.viewMode = LMEmulatorControllerViewModeNormal;

    SISetScreenDelegate(self);
    [_customView setPrimaryBuffer];

    [_externalEmulator release];
    _externalEmulator = nil;
  }

  [_externalWindow release];
  _externalWindow = nil;

  [UIView animateWithDuration:0.3 animations:^{
    [_customView layoutIfNeeded];
  }];
}

#pragma mark UI Interaction Handling

- (void)LM_options:(UIButton*)sender
{
  SISetEmulationPaused(1);

  _customView.iCadeControlView.active = NO;
  [self showControls];

  UIActionSheet* sheet = [[UIActionSheet alloc] initWithTitle:nil
                                                     delegate:self
                                            cancelButtonTitle:NSLocalizedString(@"BACK_TO_GAME", nil)
                                       destructiveButtonTitle:NSLocalizedString(@"EXIT_GAME", nil)
                                            otherButtonTitles:
                                                NSLocalizedString(@"RESET", nil),
                                                #ifdef SI_ENABLE_SAVES
                                                NSLocalizedString(@"LOAD_STATE", nil),
                                                NSLocalizedString(@"SAVE_STATE", nil),
                                                #endif
                                                NSLocalizedString(@"SETTINGS", nil),
                                                nil];
  _actionSheet = sheet;
  [sheet showInView:self.view];
  [sheet autorelease];
}

#pragma mark SIScreenDelegate

- (void)flipFrontbuffer
{
  [_customView flipFrontBuffer];
}

#pragma mark SISaveDelegate

- (void)loadROMRunningState
{
#ifdef SI_ENABLE_RUNNING_SAVES
  NSLog(@"Loading running state...");
  if(_initialSaveFileName == nil)
  {
    [LMSaveManager loadRunningStateForROMNamed:_romFileName];
  }
  else
  {
    // kind of hacky to figure out the slot number, but it suffices right now, since saves are always in a known place and I REALLY wanted to pass the path for the save, for some reason
    int slot = [[[_initialSaveFileName stringByDeletingPathExtension] pathExtension] intValue];
    if(slot == 0)
      [LMSaveManager loadRunningStateForROMNamed:_romFileName];
    else
      [LMSaveManager loadStateForROMNamed:_romFileName slot:slot];
  }
  NSLog(@"Loaded!");
#endif
}

- (void)saveROMRunningState
{
#ifdef SI_ENABLE_RUNNING_SAVES
  NSLog(@"Saving running state...");
  [LMSaveManager saveRunningStateForROMNamed:_romFileName];
  NSLog(@"Saved!");
#endif
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet*)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
  NSLog(@"UIActionSheet button index: %i", buttonIndex);
  int resetIndex = 1;
#ifdef SI_ENABLE_SAVES
  int loadIndex = 2;
  int saveIndex = 3;
  int settingsIndex = 4;
#else
  int loadIndex = -1
  int saveIndex = -1;
  int settingsIndex = 2;
#endif
  if(buttonIndex == actionSheet.destructiveButtonIndex)
  {
    [self LM_dismantleExternalScreen];
    SISetEmulationRunning(0);
    SIWaitForEmulationEnd();
    //[self.navigationController popViewControllerAnimated:YES];
    [self dismissModalViewControllerAnimated:YES];
  }
  else if(buttonIndex == resetIndex)
  {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"RESET_GAME?", nil)
                                                    message:NSLocalizedString(@"RESET_CONSEQUENCES", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"CANCEL", nil)
                                          otherButtonTitles:NSLocalizedString(@"RESET", nil), nil];
    alert.tag = LMEmulatorAlertReset;
    [alert show];
    [alert release];
  }
  else if(buttonIndex == loadIndex)
  {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"LOAD_SAVE?", nil)
                                                    message:NSLocalizedString(@"EXIT_CONSEQUENCES", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"CANCEL", nil)
                                          otherButtonTitles:NSLocalizedString(@"LOAD", nil), nil];
    alert.tag = LMEmulatorAlertLoad;
    [alert show];
    [alert release];
  }
  else if(buttonIndex == saveIndex)
  {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"SAVE_SAVE?", nil)
                                                    message:NSLocalizedString(@"SAVE_CONSEQUENCES", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"CANCEL", nil)
                                          otherButtonTitles:NSLocalizedString(@"SAVE", nil), nil];
    alert.tag = LMEmulatorAlertSave;
    [alert show];
    [alert release];
  }
  else if(buttonIndex == settingsIndex)
  {
    LMSettingsController* c = [[LMSettingsController alloc] init];
    [c hideSettingsThatRequireReset];
    c.delegate = self;
    UINavigationController* n = [[UINavigationController alloc] initWithRootViewController:c];
    n.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentModalViewController:n animated:YES];
    [c release];
    [n release];
  }
  else
  {
    _customView.iCadeControlView.active = YES;
    SISetEmulationPaused(0);
  }
  _actionSheet = nil;
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView*)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  if(alertView.tag == LMEmulatorAlertReset)
  {
    if(buttonIndex == alertView.cancelButtonIndex)
      SISetEmulationPaused(0);
    else
      SIReset();
  }
  else if(alertView.tag == LMEmulatorAlertLoad)
  {
    if(buttonIndex == alertView.cancelButtonIndex)
      SISetEmulationPaused(0);
    else
    {
      SISetEmulationPaused(1);
      SIWaitForPause();
      [LMSaveManager loadStateForROMNamed:_romFileName slot:1];
      SISetEmulationPaused(0);
    }
  }
  else if(alertView.tag == LMEmulatorAlertSave)
  {
    if(buttonIndex == alertView.cancelButtonIndex)
      SISetEmulationPaused(0);
    else
    {
      SISetEmulationPaused(1);
      SIWaitForPause();
      [LMSaveManager saveStateForROMNamed:_romFileName slot:1];
      SISetEmulationPaused(0);
    }
  }
}

#pragma mark LMSettingsControllerDelegate

- (void)settingsDidDismiss:(LMSettingsController*)settingsController
{
  [self LM_options:nil];
}

#pragma mark iCadeEventDelegate

- (void)buttonDown:(iCadeState)button
{
  switch(button)
  {
    case iCadeJoystickRight:
      SISetControllerPushButton(SIOS_RIGHT);
      break;
    case iCadeJoystickUp:
      SISetControllerPushButton(SIOS_UP);
      break;
    case iCadeJoystickLeft:
      SISetControllerPushButton(SIOS_LEFT);
      break;
    case iCadeJoystickDown:
      SISetControllerPushButton(SIOS_DOWN);
      break;
    case iCadeButtonA:
      SISetControllerPushButton(SIOS_SELECT);
      break;
    case iCadeButtonB:
      SISetControllerPushButton(SIOS_START);
      break;
    case iCadeButtonC:
      SISetControllerPushButton(SIOS_Y);
      break;
    case iCadeButtonD:
      SISetControllerPushButton(SIOS_B);
      break;
    case iCadeButtonE:
      SISetControllerPushButton(SIOS_X);
      break;
    case iCadeButtonF:
      SISetControllerPushButton(SIOS_A);
      break;
    case iCadeButtonG:
      SISetControllerPushButton(SIOS_L);
      break;
    case iCadeButtonH:
      SISetControllerPushButton(SIOS_R);
      break;
    default:
      break;
  }

  [self hideControls];
}

- (void)buttonUp:(iCadeState)button
{
  switch(button)
  {
    case iCadeJoystickRight:
      SISetControllerReleaseButton(SIOS_RIGHT);
      break;
    case iCadeJoystickUp:
      SISetControllerReleaseButton(SIOS_UP);
      break;
    case iCadeJoystickLeft:
      SISetControllerReleaseButton(SIOS_LEFT);
      break;
    case iCadeJoystickDown:
      SISetControllerReleaseButton(SIOS_DOWN);
      break;
    case iCadeButtonA:
      SISetControllerReleaseButton(SIOS_SELECT);
      break;
    case iCadeButtonB:
      SISetControllerReleaseButton(SIOS_START);
      break;
    case iCadeButtonC:
      SISetControllerReleaseButton(SIOS_Y);
      break;
    case iCadeButtonD:
      SISetControllerReleaseButton(SIOS_B);
      break;
    case iCadeButtonE:
      SISetControllerReleaseButton(SIOS_X);
      break;
    case iCadeButtonF:
      SISetControllerReleaseButton(SIOS_A);
      break;
    case iCadeButtonG:
      SISetControllerReleaseButton(SIOS_L);
      break;
    case iCadeButtonH:
      SISetControllerReleaseButton(SIOS_R);
      break;
    default:
      break;
  }
}

#pragma mark Notifications

- (void)LM_didBecomeInactive
{
  UIBackgroundTaskIdentifier identifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
    [[UIApplication sharedApplication] endBackgroundTask:identifier];
  }];
  SISetEmulationPaused(1);
  SIWaitForPause();
  [[UIApplication sharedApplication] endBackgroundTask:identifier];
}

- (void)LM_didBecomeActive
{
  if(_actionSheet == nil)
    [self LM_options:nil];
  [self LM_screensChanged];
}

- (void)LM_screensChanged
{
#ifdef LM_LOG_SCREENS
  NSLog(@"Screens changed");
  for(UIScreen* screen in [UIScreen screens])
  {
    NSLog(@"Screen: %@", screen);
    for (UIScreenMode* mode in screen.availableModes)
    {
      NSLog(@"Mode: %@", mode);
    }
  }
#endif

  if([[UIScreen screens] count] > 1)
  {
    if(_externalWindow == nil)
    {
      UIScreen* screen = [[UIScreen screens] objectAtIndex:1];
      // TODO: pick the best display mode (lowest resolution preferred)
      UIWindow* window = [[UIWindow alloc] initWithFrame:screen.bounds];
      window.screen = screen;
      window.backgroundColor = [UIColor redColor];

      // create our mirror controller
      _externalEmulator = [[LMEmulatorController alloc] initMirrorOf:self];
      window.rootViewController = _externalEmulator;

      window.hidden = NO;
      _externalWindow = window;

      _customView.viewMode = LMEmulatorControllerViewModeControllerOnly;
      [UIView animateWithDuration:0.3 animations:^{
        [_customView layoutIfNeeded];
      }];
    }
  }
  else
  {
    // switch back to us and dismantle
    [self LM_dismantleExternalScreen];
  }
}

- (void)LM_settingsChanged
{
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  SISetSoundOn([defaults boolForKey:kLMSettingsSound]);
  if([defaults boolForKey:kLMSettingsSmoothScaling] == YES)
    [_customView setMinMagFilter:kCAFilterLinear];
  else
    [_customView setMinMagFilter:kCAFilterNearest];
  SISetAutoFrameskip([defaults boolForKey:kLMSettingsAutoFrameskip]);
  SISetFrameskip([defaults integerForKey:kLMSettingsFrameskipValue]);

  _customView.iCadeControlView.controllerType = [[NSUserDefaults standardUserDefaults] integerForKey:kLMSettingsBluetoothController];
  // TODO: support custom key layouts

  SIUpdateSettings();

  [_customView setNeedsLayout];
  [UIView animateWithDuration:0.3 animations:^{
    [_customView layoutIfNeeded];
  }];
}

- (void)showControls
{
  [_customView setControlsHidden:NO animated:YES];
}

- (void)hideControls
{
  [_customView setControlsHidden:YES animated:YES];
}

@end

#pragma mark -

@implementation LMEmulatorController

@synthesize romFileName = _romFileName;
@synthesize initialSaveFileName = _initialSaveFileName;

- (void)startWithROM:(NSString*)romFileName
{
  if(_emulationThread != nil)
    return;

  [LMSettingsController setDefaultsIfNotDefined];

  [self LM_settingsChanged];

  _emulationThread = [NSThread mainThread];
  [NSThread detachNewThreadSelector:@selector(LM_emulationThreadMethod:) toTarget:self withObject:romFileName];
}

- (id)initMirrorOf:(LMEmulatorController*)mainController
{
  self = [self init];
  if(self)
  {
    _isMirror = YES;
    [self view];
    _customView.viewMode = LMEmulatorControllerViewModeScreenOnly;
    _customView.iCadeControlView.active = NO;
  }
  return self;
}

- (BOOL)isIOS6OrLower
{
  return floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1;
}

- (void)subscribeToGameControllersConnected
{
  if([self isIOS6OrLower])
    return;

  [[NSNotificationCenter defaultCenter] addObserverForName:GCControllerDidConnectNotification object:nil queue:nil usingBlock:^(NSNotification* notification) {
    [self initializeGameController:notification.object];
  }];
}

- (void)initializeGameController:(GCController*)controller
{
  [self hideControls];
  [self doNotAllowSleep];

  controller.controllerPausedHandler = ^(GCController* controller) {
    [self handlePause];
  };

  controller.gamepad.dpad.valueChangedHandler = ^(GCControllerDirectionPad* dpad, float xValue, float yValue) {
    [self handleDPadWithX:xValue andY:yValue];
  };

  controller.gamepad.valueChangedHandler = ^(GCGamepad* gamepad, GCControllerElement* element) {
    [self handleButton:element onGamepad:gamepad];
  };
}

- (void)handleButton:(GCControllerElement*)element onGamepad:(GCGamepad*)gamepad
{
  if(![element isKindOfClass:[GCControllerButtonInput class]])
    return;

  GCControllerButtonInput* button = (GCControllerButtonInput*)element;
  int siosButton = [self getButtonMap:button forGamepad:gamepad];
  if(siosButton < 0)
    return;

  [self handleButton:siosButton isPressed:button.isPressed];
}

- (void)handleDPadWithX:(float)xValue andY:(float)yValue
{
  [self handleButton:SIOS_DOWN isPressed:NO];
  [self handleButton:SIOS_UP isPressed:NO];
  [self handleButton:SIOS_LEFT isPressed:NO];
  [self handleButton:SIOS_RIGHT isPressed:NO];

  if(xValue > 0)
    [self handleButton:SIOS_RIGHT isPressed:YES];
  else if(xValue < 0)
    [self handleButton:SIOS_LEFT isPressed:YES];
  if(yValue > 0)
    [self handleButton:SIOS_UP isPressed:YES];
  else if(yValue < 0)
    [self handleButton:SIOS_DOWN isPressed:YES];
}

- (void)handlePause
{
  [self handleButton:SIOS_START isPressed:YES];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    [self handleButton:SIOS_START isPressed:NO];
  });
}

- (void)doNotAllowSleep
{
  [UIApplication sharedApplication].idleTimerDisabled = YES;
}

- (void)initializeGameControllers
{
  if([self isIOS6OrLower])
    return;

  NSArray* controllers = [GCController controllers];
  for(GCController* controller in controllers)
    [self initializeGameController:controller];
}

- (void)handleButton:(int)button isPressed:(BOOL)isPressed
{
  if(isPressed)
    SISetControllerPushButton(button);
  else
    SISetControllerReleaseButton(button);

  [self hideControls];
}

- (int)getButtonMap:(GCControllerButtonInput*)button forGamepad:(GCGamepad*)gamepad
{
  if(button == gamepad.buttonA)
    return SIOS_B;
  if(button == gamepad.buttonB)
    return SIOS_A;
  if(button == gamepad.buttonX)
    return SIOS_Y;
  if(button == gamepad.buttonY)
    return SIOS_X;
  if(button == gamepad.leftShoulder)
    return SIOS_L;
  if(button == gamepad.rightShoulder)
    return SIOS_R;

  return -1;
}

@end

#pragma mark -

@implementation LMEmulatorController(UIViewController)

- (void)loadView
{
  _customView = [[LMEmulatorControllerView alloc] initWithFrame:(CGRect){0, 0, 100, 200}];
  _customView.iCadeControlView.delegate = self;
  [_customView.optionsButton addTarget:self action:@selector(LM_options:) forControlEvents:UIControlEventTouchUpInside];
  self.view = _customView;

  self.wantsFullScreenLayout = YES;
}

- (void)viewDidUnload
{
  [super viewDidUnload];

  [_customView release];
  _customView = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
  [self.navigationController setNavigationBarHidden:YES animated:YES];

  if(_isMirror == NO)
    [self LM_screensChanged];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];

  if(_isMirror == NO)
  {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(LM_didBecomeInactive) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(LM_didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(LM_screensChanged) name:UIScreenDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(LM_screensChanged) name:UIScreenDidDisconnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveROMRunningState:) name:SISaveRunningStateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadROMRunningState:) name:SILoadRunningStateNotification object:nil];
  }

  if(_externalEmulator == nil)
  {
    SISetScreenDelegate(self);
    [_customView setPrimaryBuffer];
  }

  if(_isMirror == NO)
  {
    SISetSaveDelegate(self);
    if(_emulationThread == nil)
      [self startWithROM:_romFileName];
  }
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];

  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIScreenDidConnectNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIScreenDidDisconnectNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:SISaveRunningStateNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:SILoadRunningStateNotification object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  // Return YES for supported orientations
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
  else
    return YES;
}

- (BOOL)prefersStatusBarHidden
{
  return YES;
}

@end

#pragma mark -

@implementation LMEmulatorController(NSObject)

- (id)init
{
  self = [super init];
  if(self)
  {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(LM_settingsChanged) name:kLMSettingsChangedNotification object:nil];
    [self initializeGameControllers];
    [self subscribeToGameControllersConnected];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  if(_isMirror == NO)
  {
    SISetEmulationRunning(0);
    SIWaitForEmulationEnd();
    SISetScreenDelegate(nil);
    SISetSaveDelegate(nil);
  }

  // this is released upon showing
  _actionSheet = nil;

  [self LM_dismantleExternalScreen];

  [_customView release];
  _customView = nil;

  self.romFileName = nil;
  self.initialSaveFileName = nil;

  [super dealloc];
}

@end
