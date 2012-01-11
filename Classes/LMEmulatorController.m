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
#import "LMEmulatorInterface.h"
#import "LMPixelLayer.h"
#import "LMPixelView.h"

#import "../SNES9XBridge/Snes9xMain.h"

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

@interface LMEmulatorController(Privates) <UIActionSheetDelegate, UIAlertViewDelegate>
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

  LMSetEmulationPaused(0);
  LMSetEmulationRunning(1);
  SIStartWithROM(romFileNameCString);
  LMSetEmulationRunning(0);
  
  free(romFileNameCString);
  
  if(_emulationThread == [NSThread currentThread])
    _emulationThread = nil;
  
  [pool release];
}

#pragma mark UI Interaction Handling

- (void)options:(UIButton*)sender event:(UIEvent*)event;
{
  LMSetEmulationPaused(1);
  
  UIActionSheet* sheet = [[UIActionSheet alloc] initWithTitle:@"Options" delegate:self cancelButtonTitle:@"Back to game" destructiveButtonTitle:@"Exit game" otherButtonTitles:@"Reset", nil];
  [sheet showInView:self.view];
  [sheet release];
}

#pragma mark Delegates

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
  NSLog(@"%i", buttonIndex);
  if(buttonIndex == actionSheet.destructiveButtonIndex)
  {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Exit game?" message:@"Any unsaved progress will be lost." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Exit", nil];
    alert.tag = LMEmulatorAlertExit;
    [alert show];
    [alert release];
  }
  else if(buttonIndex == 1)
  {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Reset game?" message:@"Any unsaved progress will be lost." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Reset", nil];
    alert.tag = LMEmulatorAlertReset;
    [alert show];
    [alert release];
  }
  else
    LMSetEmulationPaused(0);
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  if(alertView.tag == LMEmulatorAlertReset)
  {
    if(buttonIndex == alertView.cancelButtonIndex)
      LMSetEmulationPaused(0);
    else
      LMReset();
  }
  else if(alertView.tag == LMEmulatorAlertExit)
  {
    if(buttonIndex == alertView.cancelButtonIndex)
      LMSetEmulationPaused(0);
    else
    {
      LMSetEmulationRunning(0);
      [self.navigationController popViewControllerAnimated:YES];
    }
  }
}

#pragma mark Notifications

- (void)didBecomeInactive
{
  LMSetEmulationPaused(1);
}

- (void)didBecomeActive
{
  LMSetEmulationPaused(0);
}

#pragma mark UI Creation Shortcuts

- (LMButtonView*)smallButtonWithButton:(int)buttonMap
{
  int width = 44;
  int height = 24;
  
  LMButtonView* button = [[LMButtonView alloc] initWithFrame:(CGRect){0,0, width,height}];
  button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
  button.image = [UIImage imageNamed:@"ButtonWide.png"];
  button.label.textColor = [UIColor colorWithWhite:1 alpha:0.75];
  button.label.shadowColor = [UIColor colorWithWhite:0 alpha:0.35];
  button.label.shadowOffset = CGSizeMake(0, -1);
  button.label.font = [UIFont systemFontOfSize:10];
  button.button = buttonMap;
  if(buttonMap == GP2X_START)
    button.label.text = @"Start";
  else if(buttonMap == GP2X_SELECT)
    button.label.text = @"Select";
  return [button autorelease];
}

- (LMButtonView*)buttonWithButton:(int)buttonMap
{
  int side = 50;
  side = 60;
  LMButtonView* button = [[LMButtonView alloc] initWithFrame:(CGRect){0,0, side,side}];
  button.button = buttonMap;
  button.label.font = [UIFont boldSystemFontOfSize:27.0];
  if(buttonMap == GP2X_A || buttonMap == GP2X_B)
  {
    button.image = [UIImage imageNamed:@"ButtonDarkPurple.png"];
    button.label.textColor = [UIColor colorWithRed:63/255.0 green:32/255.0 blue:127/255.0 alpha:0.75];
    button.label.shadowColor = [UIColor colorWithWhite:1 alpha:0.25];
    button.label.shadowOffset = CGSizeMake(0, 1);
    if(buttonMap == GP2X_A)
      button.label.text = @"A";
    else if(buttonMap == GP2X_B)
      button.label.text = @"B";
  }
  else if(buttonMap == GP2X_X || buttonMap == GP2X_Y)
  {
    button.image = [UIImage imageNamed:@"ButtonLightPurple.png"];
    button.label.textColor = [UIColor colorWithRed:122/255.0 green:101/255.0 blue:208/255.0 alpha:0.75];
    button.label.shadowColor = [UIColor colorWithWhite:1 alpha:0.25];
    button.label.shadowOffset = CGSizeMake(0, 1);
    if(buttonMap == GP2X_X)
      button.label.text = @"X";
    else if(buttonMap == GP2X_Y)
      button.label.text = @"Y";
  }
  button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
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
  
  _emulationThread = [NSThread mainThread];
  [NSThread detachNewThreadSelector:@selector(emulationThreadMethod:) toTarget:self withObject:romFileName];
}

- (void)flipFrontbuffer
{
  if(_imageBuffer == nil || _565ImageBuffer == nil)
    return;
  
  if(((LMPixelLayer*)_screenView.layer).displayMainBuffer == YES)
  {
    //convert565ToARGB((unsigned int*)_imageBuffer, (unsigned short*)_565ImageBuffer, _bufferWidth, _bufferHeight);
    LMSetScreen(_imageBufferAlt);
  
    [_screenView setNeedsDisplay];
    
    ((LMPixelLayer*)_screenView.layer).displayMainBuffer = NO;
  }
  else
  {
    //convert565ToARGB((unsigned int*)_imageBufferAlt, (unsigned short*)_565ImageBuffer, _bufferWidth, _bufferHeight);
    LMSetScreen(_imageBuffer);
    
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
  //self.view.backgroundColor = [UIColor blackColor];
  self.view.backgroundColor = [UIColor colorWithRed:195/255.0 green:198/255.0 blue:205/255.0 alpha:1];
  
  self.wantsFullScreenLayout = YES;
  self.view.multipleTouchEnabled = YES;
  
  CGSize size = self.view.bounds.size;
  
  // screen
  int width = 256;
  int height = 224;
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
  {
    width *= 3;
    height *= 3;
  }
  _screenView = [[LMPixelView alloc] initWithFrame:(CGRect){(int)((size.width-width)/2),0,width,height}];
  _screenView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
  _screenView.userInteractionEnabled = NO;
  [self.view addSubview:_screenView];
  
  // start / select buttons
  _startButton = [[self smallButtonWithButton:GP2X_START] retain];
  _startButton.frame = (CGRect){(int)((size.width-_startButton.frame.size.width)/2),height+10, _startButton.frame.size};
  [self.view addSubview:_startButton];
  
  _selectButton = [[self smallButtonWithButton:GP2X_SELECT] retain];
  _selectButton.frame = (CGRect){(int)((size.width-_selectButton.frame.size.width)/2),height+15+_selectButton.frame.size.height, _selectButton.frame.size};
  [self.view addSubview:_selectButton];
  
  // menu button
  int smallButtonWidth = 44;
  int smallButtonHeight = 24;
  _optionsButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
  [_optionsButton setBackgroundImage:[UIImage imageNamed:@"ButtonWide.png"] forState:UIControlStateNormal];
  [_optionsButton setTitle:@"Menu" forState:UIControlStateNormal];
  [_optionsButton setTitleColor:[UIColor colorWithWhite:1 alpha:0.75] forState:UIControlStateNormal];
  [_optionsButton setTitleShadowColor:[UIColor colorWithWhite:0 alpha:0.35] forState:UIControlStateNormal];
  _optionsButton.titleLabel.shadowOffset = CGSizeMake(0, -1);
  _optionsButton.titleLabel.font = [UIFont systemFontOfSize:10];
  _optionsButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
  _optionsButton.frame = (CGRect){(int)((size.width-smallButtonWidth)/2),height+45+smallButtonHeight, smallButtonWidth, smallButtonHeight};
  [_optionsButton removeTarget:self action:nil forControlEvents:UIControlEventAllEvents];
  [_optionsButton addTarget:self action:@selector(options:event:) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:_optionsButton];
  
  // ABXY buttons
  int screenBorder = 2;
  int buttonSpacing = 10;
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
  {
    screenBorder = 40;
    buttonSpacing = 15;
  }
  screenBorder = 0;
  buttonSpacing = 0;
  int buttonSize = 0;
  _aButton = [[self buttonWithButton:GP2X_A] retain];
  buttonSize = _aButton.frame.size.width;
  _aButton.frame = (CGRect){size.width-buttonSize-screenBorder, size.height-buttonSize-screenBorder, _aButton.frame.size};
  [self.view addSubview:_aButton];
  
  _bButton = [[self buttonWithButton:GP2X_B] retain];
  _bButton.frame = (CGRect){size.width-buttonSize*2-screenBorder-buttonSpacing, size.height-buttonSize-screenBorder, _bButton.frame.size};
  [self.view addSubview:_bButton];
  
  _xButton = [[self buttonWithButton:GP2X_X] retain];
  _xButton.frame = (CGRect){size.width-buttonSize-screenBorder, size.height-buttonSize*2-screenBorder-buttonSpacing, _xButton.frame.size};
  [self.view addSubview:_xButton];
  
  _yButton = [[self buttonWithButton:GP2X_Y] retain];
  _yButton.frame = (CGRect){size.width-buttonSize*2-screenBorder-buttonSpacing, size.height-buttonSize*2-screenBorder-buttonSpacing, _yButton.frame.size};
  [self.view addSubview:_yButton];
  
  // TODO: L/R buttons
  
  // d-pad
  _dPadView = [[LMDPadView alloc] initWithFrame:(CGRect){screenBorder,size.height-150-screenBorder, 150,150}];
  _dPadView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleRightMargin;
  [self.view addSubview:_dPadView];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  // size of _imageBuffer in Bytes MUST BE at least 256*224*2
  NSLog(@"Want buffer of size %i", 256*224*2);

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
    NSLog(@"Got buffer of size %i", _bufferWidth*_bufferHeight*pixelSizeBytes);
    /*for(int i=0; i<_bufferWidth*_bufferHeight; i++)
      ((uint32_t*)_imageBuffer)[i] = 0xFFFFFFFF;*/
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
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeInactive) name:UIApplicationWillResignActiveNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
  
  SISetScreenDelegate(self);
  
  //screenPixels = (unsigned int*)_565ImageBuffer;
  LMSetScreen(_imageBuffer);
  
  [self startWithROM:_romFileName];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
  
  LMSetEmulationRunning(0);
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

@end

#pragma mark -

@implementation LMEmulatorController(NSObject)

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  LMSetEmulationRunning(0);
  
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
