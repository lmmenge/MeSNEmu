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

typedef enum _LMEmulatorAlert
{
  LMEmulatorAlertReset,
  LMEmulatorAlertSave,
  LMEmulatorAlertLoad
} LMEmulatorAlert;

#pragma mark -

@interface LMEmulatorController(Privates) <UIActionSheetDelegate, UIAlertViewDelegate, LMSettingsControllerDelegate, SISaveDelegate, iCadeEventDelegate>
@end

#pragma mark -

@implementation LMEmulatorController(Privates)

- (void)emulationThreadMethod:(NSString*)romFileName;
{
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  
  if(_emulationThread == [NSThread mainThread])
    _emulationThread = [NSThread currentThread];
  
  const char* originalString = [romFileName UTF8String];
  char* romFileNameCString = (char*)calloc(strlen(originalString)+1, sizeof(char));
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

#pragma mark UI Interaction Handling

- (void)options:(UIButton*)sender event:(UIEvent*)event;
{
  SISetEmulationPaused(1);
  
  [_customView setControlsHidden:NO animated:YES];
  
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

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
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
    SISetEmulationRunning(0);
    SIWaitForEmulationEnd();
    [self.navigationController popViewControllerAnimated:YES];
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
    SISetEmulationPaused(0);
  _actionSheet = nil;
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
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
  [self options:nil event:nil];
}

#pragma mark iCadeEventDelegate

- (void)setState:(BOOL)state forButton:(iCadeState)button
{
  
}

- (void)buttonDown:(iCadeState)button
{
  [self setState:YES forButton:button];
  
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
  
  [_customView setControlsHidden:YES animated:YES];
}

- (void)buttonUp:(iCadeState)button
{
  [self setState:NO forButton:button];
  
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

- (void)didBecomeInactive
{
  UIBackgroundTaskIdentifier identifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
    [[UIApplication sharedApplication] endBackgroundTask:identifier];
  }];
  SISetEmulationPaused(1);
  SIWaitForPause();
  [[UIApplication sharedApplication] endBackgroundTask:identifier];
}

- (void)didBecomeActive
{
  if(_actionSheet == nil)
    [self options:nil event:nil];
}

- (void)settingsChanged
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
  
  [self settingsChanged];
  
  _emulationThread = [NSThread mainThread];
  [NSThread detachNewThreadSelector:@selector(emulationThreadMethod:) toTarget:self withObject:romFileName];
}

#pragma mark SIScreenDelegate

- (void)flipFrontbuffer
{
  [_customView flipFrontBuffer];
}

@end

#pragma mark -

@implementation LMEmulatorController(UIViewController)

- (void)loadView
{
  _customView = [[LMEmulatorControllerView alloc] initWithFrame:(CGRect){0,0,100,200}];
  _customView.iCadeControlView.delegate = self;
  [_customView.optionsButton addTarget:self action:@selector(options:event:) forControlEvents:UIControlEventTouchUpInside];
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
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeInactive) name:UIApplicationWillResignActiveNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveROMRunningState:) name:SISaveRunningStateNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadROMRunningState:) name:SILoadRunningStateNotification object:nil];
  
  SISetScreenDelegate(self);
  SISetSaveDelegate(self);
  
  [_customView setPrimaryBuffer];
  if(_emulationThread == nil)
    [self startWithROM:_romFileName];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:SISaveRunningStateNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:SILoadRunningStateNotification object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  // Return YES for supported orientations
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
  else
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsChanged) name:kLMSettingsChangedNotification object:nil];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  SISetEmulationRunning(0);
  SIWaitForEmulationEnd();
  SISetScreenDelegate(nil);
  SISetSaveDelegate(nil);
  
  // this is released upon showing
  _actionSheet = nil;
  
  [_customView release];
  _customView = nil;
  
  self.romFileName = nil;
  self.initialSaveFileName = nil;
  
  [super dealloc];
}

@end
