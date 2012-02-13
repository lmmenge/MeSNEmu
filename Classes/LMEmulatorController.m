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
#import "LMPixelLayer.h"
#import "LMPixelView.h"
#ifdef SI_ENABLE_SAVES
#import "LMSaveManager.h"
#endif
#import "LMSettingsController.h"

#import "../SNES9XBridge/Snes9xMain.h"
#import "../SNES9XBridge/SISaveDelegate.h"

typedef enum _LMEmulatorAlert
{
  LMEmulatorAlertReset,
  LMEmulatorAlertExit
} LMEmulatorAlert;

void convert565ToARGB(uint32_t* dest, uint16_t* source, int width, int height)
{
  // slowest method. direct computation
  //int pixelCount = width*height;
  /*unsigned short source_pixel;
  unsigned char b;
  unsigned char g;
  unsigned char r;
  // convert to ARGB
  for(int i=0; i<pixelCount; i++)
  {
    source_pixel = source[i];  
    b = (source_pixel & 0xf800) >> 11;
    g = (source_pixel & 0x07c0) >> 5;
    r = (source_pixel & 0x003f);
    dest[i] = 0xff000000 |
    (((r << 3) | (r >> 2)) << 16) | 
    (((g << 2) | (g >> 4)) << 8)  | 
    ((b << 3) | (b >> 2));
  }*/
  
  // fast method. pixel color lookup value
  /*static uint32_t* l = nil;
  if(l == nil)
  {
    l = malloc((0xFFFF+1)*sizeof(uint32_t));
    unsigned short source_pixel;
    unsigned char b;
    unsigned char g;
    unsigned char r;
    // convert to ARGB
    for(uint32_t i=0; i<=0xFFFF; i++)
    {
      source_pixel = i;
      b = (source_pixel & 0xf800) >> 11;
      g = (source_pixel & 0x07c0) >> 5;
      r = (source_pixel & 0x003f);
      l[i] = 0xff000000 |
      (((r << 3) | (r >> 2)) << 16) | 
      (((g << 2) | (g >> 4)) << 8)  | 
      ((b << 3) | (b >> 2));
    }
  }

  for(int i=0; i<pixelCount; i++)
    dest[i] = l[source[i]];*/
  
  // even faster using vDSP
  /*for(int i=0; i<pixelCount; i++)
  {
    //source[i] = 0;
    //source[i] = 0x1F; // blue
    //source[i] = 0x7E0; // green
    //source[i] = 0xF800; // red
  }*/
  /*const vImage_Buffer sourceBuffer = (vImage_Buffer){source, height, width, width*2};
  const vImage_Buffer destinationBuffer = (vImage_Buffer){dest, height, width, width*4};
  vImageConvert_RGB565toARGB8888(0xFF, &sourceBuffer, &destinationBuffer, kvImageDoNotTile);
  static uint8_t channels[4] = {1,2,3,0};
  vImagePermuteChannels_ARGB8888(&destinationBuffer, &destinationBuffer, channels, kvImageDoNotTile);
  //vImageConvert_ARGB1555toARGB8888(&sourceBuffer, &destinationBuffer, kvImageDoNotTile);*/
  
  // fastest method but wrong image. memcpy
  memcpy(dest, source, width*height*2);
}

#pragma mark -

@interface LMEmulatorController(Privates) <UIActionSheetDelegate, UIAlertViewDelegate, LMSettingsControllerDelegate, SISaveDelegate>
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

- (void)layoutForThisOrientation
{
  BOOL fullScreen = [[NSUserDefaults standardUserDefaults] boolForKey:kLMSettingsFullScreen];
  int originalWidth = 256;
  int originalHeight = 224;
  int width = originalWidth;
  int height = originalHeight;
  int screenOffsetY = 0;
  CGSize size = self.view.bounds.size;
  if(self.navigationController != nil)
    size = self.navigationController.view.bounds.size;
  int screenBorder = 0;
  int buttonSpacing = 0;
  int smallButtonsOriginX = 0;
  int smallButtonsOriginY = 0;
  int smallButtonsSpacing = 5;
  BOOL smallButtonsVertical = YES;
  float controlsAlpha = 1;
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    screenBorder = 90;

  if(UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
  {
    self.view.backgroundColor = [UIColor colorWithRed:195/255.0 green:198/255.0 blue:205/255.0 alpha:1];
    
    if(fullScreen)
    {
      width = size.width;
      height = (int)(width/(double)originalWidth*originalHeight);
      
      if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
      {
        smallButtonsVertical = NO;
        smallButtonsOriginX = smallButtonsSpacing;
        smallButtonsOriginY = height+smallButtonsSpacing;
      }
      else
      {
        smallButtonsVertical = YES;
        smallButtonsOriginX = (size.width-_startButton.frame.size.width)/2;
        smallButtonsOriginY = size.height-_dPadView.image.size.height;
      }
    }
    else
    {
      if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
      {
        screenOffsetY = (int)((size.width-width)/2);
        smallButtonsVertical = NO;
        smallButtonsOriginX = (size.width-(_startButton.frame.size.width*3+smallButtonsSpacing*2))/2;
        smallButtonsOriginY = screenOffsetY+height+smallButtonsSpacing;
      }
      else
      {
        screenOffsetY = -2;
        smallButtonsVertical = YES;
        smallButtonsOriginX = (size.width-_startButton.frame.size.width)/2;
        smallButtonsOriginY = size.height-_dPadView.image.size.height;
      }
    }
  }
  else
  {
    if(fullScreen)
    {
      self.view.backgroundColor = [UIColor blackColor];
      
      height = size.height;
      width = (int)(height/(double)originalHeight*originalWidth);
      
      smallButtonsVertical = YES;
      smallButtonsOriginX = ((size.width-width)/2-_startButton.frame.size.width)/2;
      smallButtonsOriginY = smallButtonsOriginX;
      
      controlsAlpha = 0.5;
    }
    else
    {
      self.view.backgroundColor = [UIColor colorWithRed:195/255.0 green:198/255.0 blue:205/255.0 alpha:1];
      
      if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
      {
        smallButtonsVertical = YES;
        smallButtonsOriginX = ((size.width-width)/2-_startButton.frame.size.width)/2;
        smallButtonsOriginY = smallButtonsOriginX;
      }
      else
      {
        screenOffsetY = -2;
        smallButtonsVertical = YES;
        smallButtonsOriginX = (size.width-_startButton.frame.size.width)/2;
        smallButtonsOriginY = size.height-_dPadView.image.size.height;
      }
    }
  }
  
  // layout screen
  int screenOffsetX = (size.width-width)/2;
  if(screenOffsetY == -1)
    screenOffsetY = screenOffsetX;
  else if(screenOffsetY == -2)
    screenOffsetY = (size.height-screenBorder-_dPadView.image.size.height-height)/2;
  _screenView.frame = (CGRect){screenOffsetX,screenOffsetY, width,height};
  
  // start, select, menu buttons
  int xOffset = 0;
  int yOffset = 0;
  if(smallButtonsVertical)
    yOffset = _startButton.frame.size.height+smallButtonsSpacing;
  else
    xOffset = _startButton.frame.size.width+smallButtonsSpacing;
  _startButton.frame = (CGRect){smallButtonsOriginX,smallButtonsOriginY, _startButton.frame.size};
  _selectButton.frame = (CGRect){smallButtonsOriginX+xOffset,smallButtonsOriginY+yOffset, _selectButton.frame.size};
  _optionsButton.frame = (CGRect){smallButtonsOriginX+2*xOffset,smallButtonsOriginY+2*yOffset, _selectButton.frame.size};
  
  // layout buttons
  int buttonSize = _aButton.frame.size.width;
  _aButton.frame = (CGRect){size.width-buttonSize-screenBorder, size.height-buttonSize-screenBorder, _aButton.frame.size};
  _aButton.alpha = controlsAlpha;
  _bButton.frame = (CGRect){size.width-buttonSize*2-screenBorder-buttonSpacing, size.height-buttonSize-screenBorder, _bButton.frame.size};
  _bButton.alpha = controlsAlpha;
  _xButton.frame = (CGRect){size.width-buttonSize-screenBorder, size.height-buttonSize*2-screenBorder-buttonSpacing, _xButton.frame.size};
  _xButton.alpha = controlsAlpha;
  _yButton.frame = (CGRect){size.width-buttonSize*2-screenBorder-buttonSpacing, size.height-buttonSize*2-screenBorder-buttonSpacing, _yButton.frame.size};
  _yButton.alpha = controlsAlpha;
  
  _lButton.alpha = controlsAlpha;
  _lButton.frame = (CGRect){size.width-buttonSize*2-screenBorder-buttonSpacing, size.height-buttonSize*3-screenBorder-buttonSpacing, _yButton.frame.size};
  _rButton.alpha = controlsAlpha;
  _rButton.frame = (CGRect){size.width-buttonSize-screenBorder, size.height-buttonSize*3-screenBorder-buttonSpacing, _xButton.frame.size};
  
  // layout d-pad
  _dPadView.frame = (CGRect){screenBorder,size.height-_dPadView.image.size.height-screenBorder, _dPadView.image.size};
  _dPadView.alpha = controlsAlpha;
}

#pragma mark UI Interaction Handling

- (void)options:(UIButton*)sender event:(UIEvent*)event;
{
  SISetEmulationPaused(1);
  
  UIActionSheet* sheet = [[UIActionSheet alloc] initWithTitle:nil
                                                     delegate:self
                                            cancelButtonTitle:NSLocalizedString(@"BACK_TO_GAME", nil)
                                       destructiveButtonTitle:NSLocalizedString(@"EXIT_GAME", nil)
                                            otherButtonTitles:NSLocalizedString(@"RESET", nil), NSLocalizedString(@"SETTINGS", nil), nil];
  _actionSheet = sheet;
  [sheet showInView:self.view];
  [sheet release];
}

#pragma mark Delegates

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
  //NSLog(@"%i", buttonIndex);
  if(buttonIndex == actionSheet.destructiveButtonIndex)
  {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"EXIT_GAME?", nil)
                                                    message:NSLocalizedString(@"EXIT_CONSEQUENCES", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"CANCEL", nil)
                                          otherButtonTitles:NSLocalizedString(@"EXIT", nil), nil];
    alert.tag = LMEmulatorAlertExit;
    [alert show];
    [alert release];
  }
  else if(buttonIndex == 1)
  {
#ifdef SI_ENABLE_SAVES
    // TODO: remove this save test code once we get save states working
    SISetEmulationPaused(1);
    SIWaitForPause();
    [LMSaveManager loadRunningStateForROMNamed:_romFileName];
    SISetEmulationPaused(0);
#else
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"RESET_GAME?", nil)
                                                    message:NSLocalizedString(@"RESET_CONSEQUENCES", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"CANCEL", nil)
                                          otherButtonTitles:NSLocalizedString(@"RESET", nil), nil];
    alert.tag = LMEmulatorAlertReset;
    [alert show];
    [alert release];
#endif
  }
  else if(buttonIndex == 2)
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

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  if(alertView.tag == LMEmulatorAlertReset)
  {
    if(buttonIndex == alertView.cancelButtonIndex)
      SISetEmulationPaused(0);
    else
      SIReset();
  }
  else if(alertView.tag == LMEmulatorAlertExit)
  {
    if(buttonIndex == alertView.cancelButtonIndex)
      SISetEmulationPaused(0);
    else
    {
      SISetEmulationRunning(0);
      while(_emulationThread != nil) {sleep(0);}
      [self.navigationController popViewControllerAnimated:YES];
    }
  }
}

- (void)settingsDidDismiss:(LMSettingsController*)settingsController
{
  [self options:nil event:nil];
}

#pragma mark Notifications

- (void)didBecomeInactive
{
  if(_actionSheet == nil)
    [self options:nil event:nil];
}

- (void)didBecomeActive
{
}

- (void)settingsChanged
{
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  SISetSoundOn([defaults boolForKey:kLMSettingsSound]);
  if([defaults boolForKey:kLMSettingsSmoothScaling] == YES)
  {
    _screenView.layer.minificationFilter = kCAFilterLinear;
    _screenView.layer.magnificationFilter = kCAFilterLinear;
  }
  else
  {
    _screenView.layer.minificationFilter = kCAFilterNearest;
    _screenView.layer.magnificationFilter = kCAFilterNearest;
  }
  SISetAutoFrameskip([defaults boolForKey:kLMSettingsAutoFrameskip]);
  SISetFrameskip([defaults integerForKey:kLMSettingsFrameskipValue]);
  
  SIUpdateSettings();
  
  [UIView animateWithDuration:0.3 animations:^{
    [self layoutForThisOrientation];
  }];
}

- (void)loadROMRunningState
{
#ifdef SI_ENABLE_SAVES
  NSLog(@"loading state");
  [LMSaveManager loadRunningStateForROMNamed:_romFileName];
  NSLog(@"loaded state");
#endif
}
- (void)saveROMRunningState
{
#ifdef SI_ENABLE_SAVES
  //[LMSaveManager saveRunningStateForROMNamed:_romFileName];
#endif
}

#pragma mark UI Creation Shortcuts

- (LMButtonView*)smallButtonWithButton:(int)buttonMap
{
  int width = 44;
  int height = 24;
  
  LMButtonView* button = [[LMButtonView alloc] initWithFrame:(CGRect){0,0, width,height}];
  button.image = [UIImage imageNamed:@"ButtonWide.png"];
  button.label.textColor = [UIColor colorWithWhite:1 alpha:0.75];
  button.label.shadowColor = [UIColor colorWithWhite:0 alpha:0.35];
  button.label.shadowOffset = CGSizeMake(0, -1);
  button.label.font = [UIFont systemFontOfSize:10];
  button.button = buttonMap;
  if(buttonMap == SIOS_START)
    button.label.text = @"Start";
  else if(buttonMap == SIOS_SELECT)
    button.label.text = @"Select";
  return [button autorelease];
}

- (LMButtonView*)buttonWithButton:(int)buttonMap
{
  int side = 50;
  side = 60;
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    side = 70;
  LMButtonView* button = [[LMButtonView alloc] initWithFrame:(CGRect){0,0, side,side}];
  button.button = buttonMap;
  button.label.font = [UIFont boldSystemFontOfSize:27.0];
  if(buttonMap == SIOS_A || buttonMap == SIOS_B)
  {
    button.image = [UIImage imageNamed:@"ButtonDarkPurple.png"];
    button.label.textColor = [UIColor colorWithRed:63/255.0 green:32/255.0 blue:127/255.0 alpha:0.75];
    button.label.shadowColor = [UIColor colorWithWhite:1 alpha:0.25];
    button.label.shadowOffset = CGSizeMake(0, 1);
    if(buttonMap == SIOS_A)
      button.label.text = @"A";
    else if(buttonMap == SIOS_B)
      button.label.text = @"B";
  }
  else if(buttonMap == SIOS_X || buttonMap == SIOS_Y)
  {
    button.image = [UIImage imageNamed:@"ButtonLightPurple.png"];
    button.label.textColor = [UIColor colorWithRed:122/255.0 green:101/255.0 blue:208/255.0 alpha:0.75];
    button.label.shadowColor = [UIColor colorWithWhite:1 alpha:0.25];
    button.label.shadowOffset = CGSizeMake(0, 1);
    if(buttonMap == SIOS_X)
      button.label.text = @"X";
    else if(buttonMap == SIOS_Y)
      button.label.text = @"Y";
  }
  else if(buttonMap == SIOS_L || buttonMap == SIOS_R)
  {
    button.image = [UIImage imageNamed:@"ButtonLightPurple.png"];
    button.label.textColor = [UIColor colorWithRed:122/255.0 green:101/255.0 blue:208/255.0 alpha:0.75];
    button.label.shadowColor = [UIColor colorWithWhite:1 alpha:0.25];
    button.label.shadowOffset = CGSizeMake(0, 1);
    if(buttonMap == SIOS_L)
      button.label.text = @"L";
    else if(buttonMap == SIOS_R)
      button.label.text = @"R";
  }
  return [button autorelease];
}
@end

#pragma mark -

@implementation LMEmulatorController

@synthesize romFileName = _romFileName;

- (void)startWithROM:(NSString*)romFileName
{
  if(_emulationThread != nil)
    return;
  
  [LMSettingsController setDefaultsIfNotDefined];
  
  [self settingsChanged];
  
  _emulationThread = [NSThread mainThread];
  [NSThread detachNewThreadSelector:@selector(emulationThreadMethod:) toTarget:self withObject:romFileName];
}

- (void)flipFrontbuffer
{
  if(_imageBuffer == nil || _565ImageBuffer == nil)
    return;
  
  if(((LMPixelLayer*)_screenView.layer).displayMainBuffer == YES)
  {
    SISetScreen(_imageBufferAlt);
  
    [_screenView setNeedsDisplay];
    
    ((LMPixelLayer*)_screenView.layer).displayMainBuffer = NO;
  }
  else
  {
    SISetScreen(_imageBuffer);
    
    [_screenView setNeedsDisplay];
    
    ((LMPixelLayer*)_screenView.layer).displayMainBuffer = YES;
  }
}

@end

#pragma mark -

@implementation LMEmulatorController(UIViewController)

- (void)loadView
{
  [super loadView];
  
  self.wantsFullScreenLayout = YES;
  self.view.multipleTouchEnabled = YES;
  
  // screen
  _screenView = [[LMPixelView alloc] initWithFrame:(CGRect){0,0,10,10}];
  _screenView.userInteractionEnabled = NO;
  [self.view addSubview:_screenView];
  
  // start / select buttons
  _startButton = [[self smallButtonWithButton:SIOS_START] retain];
  [self.view addSubview:_startButton];
  
  _selectButton = [[self smallButtonWithButton:SIOS_SELECT] retain];
  [self.view addSubview:_selectButton];
  
  // menu button
  _optionsButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
  [_optionsButton setBackgroundImage:[UIImage imageNamed:@"ButtonWide.png"] forState:UIControlStateNormal];
  [_optionsButton setTitle:NSLocalizedString(@"MENU", nil) forState:UIControlStateNormal];
  [_optionsButton setTitleColor:[UIColor colorWithWhite:1 alpha:0.75] forState:UIControlStateNormal];
  [_optionsButton setTitleShadowColor:[UIColor colorWithWhite:0 alpha:0.35] forState:UIControlStateNormal];
  _optionsButton.titleLabel.shadowOffset = CGSizeMake(0, -1);
  _optionsButton.titleLabel.font = [UIFont systemFontOfSize:10];
  [_optionsButton removeTarget:self action:nil forControlEvents:UIControlEventAllEvents];
  [_optionsButton addTarget:self action:@selector(options:event:) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:_optionsButton];
  
  // ABXY buttons
  _aButton = [[self buttonWithButton:SIOS_A] retain];
  [self.view addSubview:_aButton];
  
  _bButton = [[self buttonWithButton:SIOS_B] retain];
  [self.view addSubview:_bButton];
  
  _xButton = [[self buttonWithButton:SIOS_X] retain];
  [self.view addSubview:_xButton];
  
  _yButton = [[self buttonWithButton:SIOS_Y] retain];
  [self.view addSubview:_yButton];
  
  // L/R buttons
  _lButton = [[self buttonWithButton:SIOS_L] retain];
  [self.view addSubview:_lButton];
  
  _rButton = [[self buttonWithButton:SIOS_R] retain];
  [self.view addSubview:_rButton];
  
  // d-pad
  _dPadView = [[LMDPadView alloc] initWithFrame:(CGRect){0,0,10,10}];
  [self.view addSubview:_dPadView];
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  _bufferWidth = 256;
  _bufferHeight = 224;
  
  // RGBA888 format
  unsigned short defaultComponentCount = 4;
  unsigned short bufferBitsPerComponent = 8;
  unsigned int pixelSizeBytes = (_bufferWidth*bufferBitsPerComponent*defaultComponentCount)/8/_bufferWidth;
  if(pixelSizeBytes == 0)
    pixelSizeBytes = defaultComponentCount;
  unsigned int bufferBytesPerRow = _bufferWidth*pixelSizeBytes;
  CGBitmapInfo bufferBitmapInfo = kCGImageAlphaNoneSkipLast;
  
  // BGR 555 format (something weird)
  defaultComponentCount = 3;
  bufferBitsPerComponent = 5;
  pixelSizeBytes = 2;
  bufferBytesPerRow = _bufferWidth*pixelSizeBytes;
  bufferBitmapInfo = kCGImageAlphaNoneSkipFirst|kCGBitmapByteOrder16Little;
  
  if(_imageBuffer == nil)
  {
    _imageBuffer = (unsigned char*)calloc(_bufferWidth*_bufferHeight, pixelSizeBytes);
  }
  if(_imageBufferAlt == nil)
  {
    _imageBufferAlt = (unsigned char*)calloc(_bufferWidth*_bufferHeight, pixelSizeBytes);
  }
  if(_565ImageBuffer == nil)
    _565ImageBuffer = (unsigned char*)calloc(_bufferWidth*_bufferHeight, 2);
  
  [(LMPixelLayer*)_screenView.layer setImageBuffer:_imageBuffer
                                           width:_bufferWidth
                                          height:_bufferHeight
                                bitsPerComponent:bufferBitsPerComponent
                                     bytesPerRow:bufferBytesPerRow
                                      bitmapInfo:bufferBitmapInfo];
  [(LMPixelLayer*)_screenView.layer addAltImageBuffer:_imageBufferAlt];
}

- (void)viewDidUnload
{
  [super viewDidUnload];
  
  [_screenView release];
  _screenView = nil;
  
  [_startButton release];
  _startButton = nil;
  [_selectButton release];
  _selectButton = nil;
  [_aButton release];
  _aButton = nil;
  [_bButton release];
  _bButton = nil;
  [_yButton release];
  _yButton = nil;
  [_xButton release];
  _xButton = nil;
  [_lButton release];
  _lButton = nil;
  [_rButton release];
  _rButton = nil;
  [_dPadView release];
  _dPadView = nil;
  
  [_optionsButton release];
  _optionsButton = nil;
}

- (void)viewWillAppear:(BOOL)animated
{  
  [super viewWillAppear:animated];
  
  [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
  [self.navigationController setNavigationBarHidden:YES animated:YES];
  
  [self layoutForThisOrientation];
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
  
  SISetScreen(_imageBuffer);
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
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
  } else {
    return YES;
  }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
  [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
  
  [self layoutForThisOrientation];
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
  
  [_screenView release];
  _screenView = nil;
  
  [_startButton release];
  _startButton = nil;
  [_selectButton release];
  _selectButton = nil;
  [_aButton release];
  _aButton = nil;
  [_bButton release];
  _bButton = nil;
  [_yButton release];
  _yButton = nil;
  [_xButton release];
  _xButton = nil;
  [_lButton release];
  _lButton = nil;
  [_rButton release];
  _rButton = nil;
  [_dPadView release];
  _dPadView = nil;
  
  [_optionsButton release];
  _optionsButton = nil;
  
  SISetScreenDelegate(nil);
  SISetSaveDelegate(nil);
  
  if(_imageBuffer != nil)
    free(_imageBuffer);
  _imageBuffer = nil;
  
  if(_imageBufferAlt != nil)
    free(_imageBufferAlt);
  _imageBufferAlt = nil;
  
  if(_565ImageBuffer != nil)
    free(_565ImageBuffer);
  _565ImageBuffer = nil;
  
  self.romFileName = nil;
  
  [super dealloc];
}

@end
