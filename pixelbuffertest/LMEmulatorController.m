//
//  LMViewController.m
//  pixelbuffertest
//
//  Created by Lucas Menge on 1/2/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import "LMEmulatorController.h"

#import "LMDPadView.h"
#import "LMEmulatorInterface.h"
#import "LMPixelLayer.h"
#import "LMPixelView.h"

static LMEmulatorController* sharedInstance = nil;

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
  const vImage_Buffer sourceBuffer = (vImage_Buffer){source, height, width, width*2};
  const vImage_Buffer destinationBuffer = (vImage_Buffer){dest, height, width, width*4};
  vImageConvert_RGB565toARGB8888(0xFF, &sourceBuffer, &destinationBuffer, kvImageDoNotTile);
  static uint8_t channels[4] = {1,2,3,0};
  vImagePermuteChannels_ARGB8888(&destinationBuffer, &destinationBuffer, channels, kvImageDoNotTile);
  //vImageConvert_ARGB1555toARGB8888(&sourceBuffer, &destinationBuffer, kvImageDoNotTile);
  
  // fastest method but wrong image. memcpy
  //memcpy(dest, source, pixelCount*2);
}

#pragma mark -

@interface LMEmulatorController(Privates) <UIActionSheetDelegate>
@end

#pragma mark -

@implementation LMEmulatorController(Privates)

- (void)emulationThreadMethod:(NSString*)romFileName;
{
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  
  if(_emulationThread == [NSThread mainThread])
    _emulationThread = [NSThread currentThread];
  
  const char* originalString = [romFileName UTF8String];
  char* romFileNameCString = calloc(strlen(originalString)+1, sizeof(char));
  strcpy(romFileNameCString, originalString);
  originalString = nil;

  LMSetEmulationPaused(0);
  LMSetEmulationRunning(1);
  iphone_main(romFileNameCString);
  LMSetEmulationRunning(0);
  
  free(romFileNameCString);
  
  if(_emulationThread == [NSThread currentThread])
    _emulationThread = nil;
  
  [pool release];
}

- (void)didBecomeInactive
{
  LMSetEmulationPaused(1);
}

- (void)didBecomeActive
{
  LMSetEmulationPaused(0);
}

- (void)buttonDown:(UIButton*)button
{
  // buttons
  if(button == _aButton)
    LMSetControllerPushButton(GP2X_B);
  else if(button == _bButton)
    LMSetControllerPushButton(GP2X_X);
  else if(button == _xButton)
    LMSetControllerPushButton(GP2X_Y);
  else if(button == _yButton)
    LMSetControllerPushButton(GP2X_A);
  else if(button == _lButton)
    LMSetControllerPushButton(GP2X_L);
  else if(button == _rButton)
    LMSetControllerPushButton(GP2X_R);
  // start / select
  else if(button == _startButton)
    LMSetControllerPushButton(GP2X_START);
  else if(button == _selectButton)
    LMSetControllerPushButton(GP2X_SELECT);
}

- (void)buttonUp:(UIButton*)button
{
  // buttons
  if(button == _aButton)
    LMSetControllerReleaseButton(GP2X_B);
  else if(button == _bButton)
    LMSetControllerReleaseButton(GP2X_X);
  else if(button == _xButton)
    LMSetControllerReleaseButton(GP2X_Y);
  else if(button == _yButton)
    LMSetControllerReleaseButton(GP2X_A);
  else if(button == _lButton)
    LMSetControllerReleaseButton(GP2X_L);
  else if(button == _rButton)
    LMSetControllerReleaseButton(GP2X_R);
  // start / select
  else if(button == _startButton)
    LMSetControllerReleaseButton(GP2X_START);
  else if(button == _selectButton)
    LMSetControllerReleaseButton(GP2X_SELECT);
}

- (void)options:(UIButton*)sender event:(UIEvent*)event;
{
  LMSetEmulationPaused(1);
  
  UIActionSheet* sheet = [[UIActionSheet alloc] initWithTitle:@"Options" delegate:self cancelButtonTitle:@"Back to game" destructiveButtonTitle:@"Exit game" otherButtonTitles:nil];
  [sheet showInView:self.view];
  [sheet release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  if(buttonIndex == actionSheet.destructiveButtonIndex)
  {
    LMSetEmulationRunning(0);
    [self.navigationController popViewControllerAnimated:YES];
  }
  else
    LMSetEmulationPaused(0);
}

- (UIButton*)smallButtonNamed:(NSString*)name
{
  int width = 40;
  int height = 20;
  UIButton* button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  [button setTitle:name forState:UIControlStateNormal];
  button.titleLabel.font = [UIFont systemFontOfSize:10];
  button.frame = (CGRect){0,0, width, height};
  button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
  [button addTarget:self action:@selector(buttonDown:) forControlEvents:UIControlEventTouchDown|UIControlEventTouchDragEnter];
  [button addTarget:self action:@selector(buttonUp:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchDragExit];
  return button;
}

- (UIButton*)buttonNamed:(NSString*)name
{
  int side = 50;
  UIButton* button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  [button setTitle:name forState:UIControlStateNormal];
  //button.titleLabel.font = [UIFont systemFontOfSize:10];
  button.frame = (CGRect){0,0, side, side};
  button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
  [button addTarget:self action:@selector(buttonDown:) forControlEvents:UIControlEventTouchDown|UIControlEventTouchDragEnter];
  [button addTarget:self action:@selector(buttonUp:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchDragExit];
  return button;
}

- (UIButton*)dButtonNamed:(NSString*)name
{
  int side = 50;
  UIButton* button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  [button setTitle:name forState:UIControlStateNormal];
  //button.titleLabel.font = [UIFont systemFontOfSize:10];
  button.frame = (CGRect){0,0, side, side};
  button.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
  [button addTarget:self action:@selector(buttonDown:) forControlEvents:UIControlEventTouchDown|UIControlEventTouchDragEnter];
  [button addTarget:self action:@selector(buttonUp:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchDragExit];
  return button;
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

- (void)updateView
{
  if(_imageBuffer == nil || _565ImageBuffer == nil)
    return;
  
  if(((LMPixelLayer*)_screenView.layer).displayMainBuffer == YES)
  {
    convert565ToARGB((unsigned int*)_imageBuffer, (unsigned short*)_565ImageBuffer, _bufferWidth, _bufferHeight);
  
    [_screenView setNeedsDisplay];
    
    ((LMPixelLayer*)_screenView.layer).displayMainBuffer = NO;
  }
  else
  {
    convert565ToARGB((unsigned int*)_imageBufferAlt, (unsigned short*)_565ImageBuffer, _bufferWidth, _bufferHeight);
    
    [_screenView setNeedsDisplay];
    
    ((LMPixelLayer*)_screenView.layer).displayMainBuffer = YES;
  }
}

+ (LMEmulatorController*)sharedInstance
{
  return sharedInstance;
}

@end

#pragma mark -

@implementation LMEmulatorController(UIViewController)

- (void)loadView
{
  [super loadView];
  
  self.wantsFullScreenLayout = YES;
  self.view.multipleTouchEnabled = YES;
  
  CGSize size = self.view.bounds.size;
  
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
  _startButton = [[self smallButtonNamed:@"Start"] retain];
  _startButton.frame = (CGRect){(int)((size.width-_startButton.frame.size.width)/2),height+10, _startButton.frame.size};
  [self.view addSubview:_startButton];
  
  _selectButton = [[self smallButtonNamed:@"Select"] retain];
  _selectButton.frame = (CGRect){(int)((size.width-_selectButton.frame.size.width)/2),height+20+_selectButton.frame.size.height, _selectButton.frame.size};
  [self.view addSubview:_selectButton];
  
  _optionsButton = [[self smallButtonNamed:@"Menu"] retain];
  _optionsButton.frame = (CGRect){(int)((size.width-_optionsButton.frame.size.width)/2),height+50+_optionsButton.frame.size.height, _optionsButton.frame.size};
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
  int buttonSize = 0;
  _aButton = [[self buttonNamed:@"A"] retain];
  buttonSize = _aButton.frame.size.width;
  _aButton.frame = (CGRect){size.width-buttonSize-screenBorder, size.height-buttonSize-screenBorder-buttonSize/2, _aButton.frame.size};
  [self.view addSubview:_aButton];
  
  _bButton = [[self buttonNamed:@"B"] retain];
  _bButton.frame = (CGRect){size.width-buttonSize*2-screenBorder-buttonSpacing, size.height-buttonSize-screenBorder, _bButton.frame.size};
  [self.view addSubview:_bButton];
  
  _xButton = [[self buttonNamed:@"X"] retain];
  _xButton.frame = (CGRect){size.width-buttonSize-screenBorder, size.height-buttonSize*2-screenBorder-buttonSpacing-buttonSize/2, _xButton.frame.size};
  [self.view addSubview:_xButton];
  
  _yButton = [[self buttonNamed:@"Y"] retain];
  _yButton.frame = (CGRect){size.width-buttonSize*2-screenBorder-buttonSpacing, size.height-buttonSize*2-screenBorder-buttonSpacing, _yButton.frame.size};
  [self.view addSubview:_yButton];
  
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
  unsigned int pixelSizeBytes = bufferBitsPerComponent/8*defaultComponentCount;
  if(pixelSizeBytes == 0)
    pixelSizeBytes = defaultComponentCount;
  unsigned int bufferBytesPerRow = _bufferWidth*pixelSizeBytes;
  CGBitmapInfo bufferBitmapInfo = kCGImageAlphaNoneSkipLast;
  
  // BGR 555 format (something weird)
  /*defaultComponentCount = 3;
  bufferBitsPerComponent = 5;
  pixelSizeBytes = 2;
  bufferBytesPerRow = _bufferWidth*pixelSizeBytes;
  bufferBitmapInfo = kCGImageAlphaNoneSkipFirst|kCGBitmapByteOrder16Little;*/
  
  if(_imageBuffer == nil)
  {
    _imageBuffer = calloc(_bufferWidth*_bufferHeight, pixelSizeBytes);
    NSLog(@"Got buffer of size %i", _bufferWidth*_bufferHeight*pixelSizeBytes);
    /*for(int i=0; i<_bufferWidth*_bufferHeight; i++)
      ((uint32_t*)_imageBuffer)[i] = 0xFFFFFFFF;*/
  }
  if(_imageBufferAlt == nil)
  {
    _imageBufferAlt = calloc(_bufferWidth*_bufferHeight, pixelSizeBytes);
  }
  if(_565ImageBuffer == nil)
    _565ImageBuffer = calloc(_bufferWidth*_bufferHeight, 2);
  
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
  
  sharedInstance = self;
  screenPixels = (unsigned int*)_565ImageBuffer;
  
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
  
  if(sharedInstance == self)
    sharedInstance = nil;
  
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
