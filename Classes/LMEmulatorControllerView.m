//
//  LMEmulatorControllerView.m
//  MeSNEmu
//
//  Created by Lucas Menge on 8/28/13.
//  Copyright (c) 2013 Lucas Menge. All rights reserved.
//

#import "LMEmulatorControllerView.h"

#import "../iCade/LMBTControllerView.h"
#import "../SNES9XBridge/Snes9xMain.h"

#import "LMButtonView.h"
#import "LMDPadView.h"
#import "LMPixelView.h"
#import "LMPixelLayer.h"
#import "LMSettingsController.h"

@interface LMEmulatorControllerView(Privates)

@end

#pragma mark -

@implementation LMEmulatorControllerView(Privates)

#pragma mark UI Creation Shortcuts

- (LMButtonView*)LM_smallButtonWithButton:(int)buttonMap
{
  int width = 64;
  int height = 24;
  CGFloat border = 2.0;
  
  LMButtonView* button = [[LMButtonView alloc] initWithFrame:(CGRect){0,0, width,height} border:border radius:10.0];
  button.button = buttonMap;
  button.titleLabel.font = [UIFont boldSystemFontOfSize:10];
  
  switch (buttonMap) {
    case SI_BUTTON_START:
      [button setTitle:NSLocalizedString(@"START", nil) forState:UIControlStateNormal];
      break;
    case SI_BUTTON_SELECT:
      [button setTitle:NSLocalizedString(@"SELECT", nil) forState:UIControlStateNormal];
      break;
  }
  
  return [button autorelease];
}

- (LMButtonView*)LM_buttonWithButton:(int)buttonMap
{
  int side = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 60 : 50;
  CGFloat border = 4.0;
  
  LMButtonView* button = [[LMButtonView alloc] initWithFrame:(CGRect){0,0, side,side} border:border radius:(buttonMap == SI_BUTTON_L || buttonMap == SI_BUTTON_R)?side/4:(side/2)-(border/2)];
  button.button = buttonMap;
  button.titleLabel.font = [UIFont boldSystemFontOfSize:20.0];
  
  switch (buttonMap) {
    case SI_BUTTON_A:
      [button setTitle:NSLocalizedString(@"A", nil) forState:UIControlStateNormal];
      break;
    case SI_BUTTON_B:
      [button setTitle:NSLocalizedString(@"B", nil) forState:UIControlStateNormal];
      break;
    case SI_BUTTON_X:
      [button setTitle:NSLocalizedString(@"X", nil) forState:UIControlStateNormal];
      break;
    case SI_BUTTON_Y:
      [button setTitle:NSLocalizedString(@"Y", nil) forState:UIControlStateNormal];
      break;
    case SI_BUTTON_L:
      [button setTitle:NSLocalizedString(@"L", nil) forState:UIControlStateNormal];
      break;
    case SI_BUTTON_R:
      [button setTitle:NSLocalizedString(@"R", nil) forState:UIControlStateNormal];
      break;
  }
  
  return [button autorelease];
}

@end

#pragma mark -

@implementation LMEmulatorControllerView

@synthesize optionsButton = _optionsButton;
@synthesize iCadeControlView = _iCadeControlView;
@synthesize viewMode = _viewMode;
- (void)setViewMode:(LMEmulatorControllerViewMode)viewMode
{
  if(_viewMode != viewMode)
  {
    _viewMode = viewMode;
    [self setNeedsLayout];
  }
}

- (void)setControlsHidden:(BOOL)value animated:(BOOL)animated
{
  if(_hideUI != value)
  {
    _hideUI = value;
    [self setNeedsLayout];
    if(animated == YES)
      [UIView animateWithDuration:0.3 animations:^{
        [self layoutIfNeeded];
      }];
    else
      [self layoutIfNeeded];
  }
}

- (void)setMinMagFilter:(NSString*)filter
{
  _screenView.layer.minificationFilter = filter;
  _screenView.layer.magnificationFilter = filter;
}

- (void)setPrimaryBuffer
{
  SISetScreen(_imageBuffer);
}

- (void)flipFrontBufferWidth:(int)width height:(int)height
{
  if(_imageBuffer == nil || _565ImageBuffer == nil)
    return;
  
  // make sure we're showing the proper amount of image
  [_screenView updateBufferCropResWidth:width height:height];
  
  // we use two framebuffers to avoid copy-on-write due to us using UIImage. Little memory overhead, no speed overhead at all compared to that nasty IOSurface and SDK-safe, to boot
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

- (UIImage*)getScreen
{
  UIImage *__image = [UIImage imageWithCGImage:(CGImageRef)_screenView.layer.contents];
  return __image;
}

@end

#pragma mark -

@implementation LMEmulatorControllerView(UIView)

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if(self)
  {
    self.multipleTouchEnabled = YES;
    _viewMode = LMEmulatorControllerViewModeNormal;
    //_viewMode = LMEmulatorControllerViewModeScreenOnly;
    //_viewMode = LMEmulatorControllerViewModeControllerOnly;
    
    // screen
    _screenView = [[LMPixelView alloc] initWithFrame:(CGRect){0,0,10,10}];
    _screenView.userInteractionEnabled = NO;
    [self addSubview:_screenView];
    
    // start / select buttons
    _startButton = [[self LM_smallButtonWithButton:SI_BUTTON_START] retain];
    [self addSubview:_startButton];
    
    _selectButton = [[self LM_smallButtonWithButton:SI_BUTTON_SELECT] retain];
    [self addSubview:_selectButton];
    
    // menu button
    _optionsButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    _optionsButton.frame = _selectButton.frame;
    [_optionsButton setBackgroundImage:_selectButton.currentBackgroundImage forState:UIControlStateNormal];
    [_optionsButton.titleLabel setFont:_selectButton.titleLabel.font];
    [_optionsButton setTitleColor:_selectButton.titleLabel.textColor forState:UIControlStateNormal];
    [_optionsButton setTitle:NSLocalizedString(@"MENU", nil) forState:UIControlStateNormal];
    [self addSubview:_optionsButton];
    
    // ABXY buttons
    _aButton = [[self LM_buttonWithButton:SI_BUTTON_A] retain];
    [self addSubview:_aButton];
    
    _bButton = [[self LM_buttonWithButton:SI_BUTTON_B] retain];
    [self addSubview:_bButton];
    
    _xButton = [[self LM_buttonWithButton:SI_BUTTON_X] retain];
    [self addSubview:_xButton];
    
    _yButton = [[self LM_buttonWithButton:SI_BUTTON_Y] retain];
    [self addSubview:_yButton];
    
    // L/R buttons
    _lButton = [[self LM_buttonWithButton:SI_BUTTON_L] retain];
    [self addSubview:_lButton];
    
    _rButton = [[self LM_buttonWithButton:SI_BUTTON_R] retain];
    [self addSubview:_rButton];
    
    // d-pad
    _dPadView = [[LMDPadView alloc] init];
    [self addSubview:_dPadView];
    
    // iCade support
    _iCadeControlView = [[LMBTControllerView alloc] initWithFrame:CGRectZero];
    [self addSubview:_iCadeControlView];
    _iCadeControlView.active = YES;
    
    // creating our buffers
    _bufferWidth = 512;
    _bufferHeight = 480;
    _bufferHeightExtended = 480;
    
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
      _imageBuffer = (unsigned char*)calloc(_bufferWidth*_bufferHeightExtended, pixelSizeBytes);
    }
    if(_imageBufferAlt == nil)
    {
      _imageBufferAlt = (unsigned char*)calloc(_bufferWidth*_bufferHeightExtended, pixelSizeBytes);
    }
    if(_565ImageBuffer == nil)
      _565ImageBuffer = (unsigned char*)calloc(_bufferWidth*_bufferHeightExtended, 2);
    
    [(LMPixelLayer*)_screenView.layer setImageBuffer:_imageBuffer
                                               width:_bufferWidth
                                              height:_bufferHeight
                                    bitsPerComponent:bufferBitsPerComponent
                                         bytesPerRow:bufferBytesPerRow
                                          bitmapInfo:bufferBitmapInfo];
    [(LMPixelLayer*)_screenView.layer addAltImageBuffer:_imageBufferAlt];
  }
  return self;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  
  BOOL fullScreen = [[NSUserDefaults standardUserDefaults] boolForKey:kLMSettingsFullScreen];
  UIColor* plasticColor = [UIColor colorWithRed:20/255.0 green:20/255.0 blue:20/255.0 alpha:1.0];
  UIColor* blackColor = [UIColor colorWithRed:20/255.0 green:20/255.0 blue:20/255.0 alpha:1.0];
  if(_viewMode == LMEmulatorControllerViewModeScreenOnly)
    plasticColor = blackColor;
  else if(_viewMode == LMEmulatorControllerViewModeControllerOnly)
    blackColor = plasticColor;
  int originalWidth = 256;
  int originalHeight = 224;
  int width = originalWidth;
  int height = originalHeight;
  int screenOffsetY = 0;
  CGSize size = self.bounds.size;
  int screenBorderX = 6;
  int screenBorderY = 30;
  int buttonSpacing = 10;
  int smallButtonsOriginX = 0;
  int smallButtonsOriginY = 0;
  int smallButtonsSpacing = 10;
  BOOL smallButtonsVertical = YES;
  float controlsAlpha = 0.1;
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
  {
    screenBorderX = 90;
    screenBorderY = 90;
  }
  
  if(size.height > size.width)
  {
    // portrait
    self.backgroundColor = plasticColor;
    
    if(_viewMode == LMEmulatorControllerViewModeControllerOnly)
    {
      // portrait - controller mode
      width = height = 0;
      int dpadHeight = _dPadView.frame.size.height;
      screenBorderY = size.height*0.5-dpadHeight*0.5;
      smallButtonsVertical = NO;
      smallButtonsOriginY = size.height-smallButtonsSpacing-_startButton.frame.size.height;
      smallButtonsOriginX = size.width*0.5-_startButton.frame.size.width*1.5-smallButtonsSpacing;
    }
    else
    {
      // portrait - screen or screen+controller mode
      if(fullScreen == YES)
      {
        // portrait - full screen
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
          smallButtonsOriginY = size.height-_dPadView.frame.size.height;
        }
      }
      else
      {
        // portrait - 1:1
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        {
          screenOffsetY = (int)((size.width-width)/4);
          smallButtonsVertical = NO;
          smallButtonsOriginX = (size.width-(_startButton.frame.size.width*3+smallButtonsSpacing*2))/2;
          smallButtonsOriginY = screenOffsetY+height+smallButtonsSpacing;
        }
        else
        {
          screenOffsetY = -2;
          smallButtonsVertical = YES;
          smallButtonsOriginX = (size.width-_startButton.frame.size.width)/2;
          smallButtonsOriginY = size.height-_dPadView.frame.size.height;
        }
      }
    }
  }
  else
  {
    // landscape
    if(_viewMode == LMEmulatorControllerViewModeControllerOnly)
    {
      // landscape - controller mode
      self.backgroundColor = plasticColor;
      width = height = 0;
      int dpadHeight = _dPadView.frame.size.height;
      screenBorderY = size.height*0.5-dpadHeight*0.5;
      smallButtonsVertical = NO;
      smallButtonsOriginY = size.height-smallButtonsSpacing-_startButton.frame.size.height;
      smallButtonsOriginX = size.width*0.5-_startButton.frame.size.width*1.5-smallButtonsSpacing;
      if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        screenBorderX = 30;
    }
    else
    {
      // landscape - screen only or screen+controller mode
      if(fullScreen == YES)
      {
        // landscape - full screen
        self.backgroundColor = blackColor;
        
        height = size.height;
        width = (int)(height/(double)originalHeight*originalWidth);
        
        smallButtonsVertical = YES;
        smallButtonsOriginX = ((size.width-width)/2-_startButton.frame.size.width)/2;
        smallButtonsOriginY = smallButtonsOriginX;
        
        if(_hideUI == NO)
          controlsAlpha = 0.1;
        else
          controlsAlpha = 0;
      }
      else
      {
        // landscape - 1:1
        self.backgroundColor = plasticColor;
        
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
          smallButtonsOriginY = size.height-_dPadView.frame.size.height;
        }
      }
    }
  }
  
  if(_viewMode == LMEmulatorControllerViewModeScreenOnly)
    controlsAlpha = 0;
  else if(_viewMode == LMEmulatorControllerViewModeControllerOnly)
  {
    controlsAlpha = 0.1;
    
    
  }
  
  // layout screen
  int screenOffsetX = (size.width-width)/2;
  if(screenOffsetY == -1)
    screenOffsetY = screenOffsetX;
  else if(screenOffsetY == -2)
    screenOffsetY = (size.height-screenBorderY-_dPadView.frame.size.height-height)/2;
  if(_viewMode == LMEmulatorControllerViewModeScreenOnly)
    // we're showing only the screen. center it
    _screenView.frame = (CGRect){(int)((size.width-width)*0.5), (int)((size.height-height)*0.5), width,height};
  else
    // we're showing the controls + screen
    _screenView.frame = (CGRect){screenOffsetX,screenOffsetY, width,height};
  
  if(_viewMode == LMEmulatorControllerViewModeControllerOnly)
    _screenView.alpha = 0;
  else
    _screenView.alpha = 1;
  
  // start, select, menu buttons
  int xOffset = 0;
  int yOffset = 0;
  if(smallButtonsVertical == YES)
    yOffset = _startButton.frame.size.height+smallButtonsSpacing;
  else
    xOffset = _startButton.frame.size.width+smallButtonsSpacing;
  _startButton.frame = (CGRect){smallButtonsOriginX,smallButtonsOriginY, _startButton.frame.size};
  _selectButton.frame = (CGRect){smallButtonsOriginX+xOffset,smallButtonsOriginY+yOffset, _selectButton.frame.size};
  _optionsButton.frame = (CGRect){smallButtonsOriginX+2*xOffset,smallButtonsOriginY+2*yOffset, _selectButton.frame.size};
  
  if(_viewMode == LMEmulatorControllerViewModeScreenOnly)
  {
    _startButton.alpha = 0;
    _selectButton.alpha = 0;
    _optionsButton.alpha = 0;
  }
  else
  {
    _startButton.alpha = 0.1;
    _selectButton.alpha = 0.1;
    _optionsButton.alpha = 0.1;
  }
  
  // layout buttons
  int buttonSize = _aButton.frame.size.width;
  _aButton.frame = (CGRect){size.width-buttonSize-screenBorderX-buttonSpacing, size.height-buttonSize-screenBorderY, _aButton.frame.size};
  _aButton.alpha = controlsAlpha;
  _bButton.frame = (CGRect){size.width-buttonSize*2-screenBorderX-buttonSpacing*2, size.height-buttonSize-screenBorderY, _bButton.frame.size};
  _bButton.alpha = controlsAlpha;
  _xButton.frame = (CGRect){size.width-buttonSize-screenBorderX-buttonSpacing, size.height-buttonSize*2-screenBorderY-buttonSpacing, _xButton.frame.size};
  _xButton.alpha = controlsAlpha;
  _yButton.frame = (CGRect){size.width-buttonSize*2-screenBorderX-buttonSpacing*2, size.height-buttonSize*2-screenBorderY-buttonSpacing, _yButton.frame.size};
  _yButton.alpha = controlsAlpha;
  
  _lButton.alpha = controlsAlpha;
  _lButton.frame = (CGRect){size.width-buttonSize*2-screenBorderX-buttonSpacing*2, size.height-buttonSize*3-screenBorderY-buttonSpacing*2, _yButton.frame.size};
  _rButton.alpha = controlsAlpha;
  _rButton.frame = (CGRect){size.width-buttonSize-screenBorderX-buttonSpacing, size.height-buttonSize*3-screenBorderY-buttonSpacing*2, _xButton.frame.size};
  
  // layout d-pad
  _dPadView.frame = (CGRect){screenBorderX+buttonSpacing,size.height-_dPadView.frame.size.height-screenBorderY-buttonSpacing, _dPadView.frame.size};
  _dPadView.alpha = controlsAlpha;
}

@end

#pragma mark -

@implementation LMEmulatorControllerView(NSObject)

- (void)dealloc
{
  if(_imageBuffer != nil)
    free(_imageBuffer);
  _imageBuffer = nil;
  
  if(_imageBufferAlt != nil)
    free(_imageBufferAlt);
  _imageBufferAlt = nil;
  
  if(_565ImageBuffer != nil)
    free(_565ImageBuffer);
  _565ImageBuffer = nil;
  
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
  
  [_iCadeControlView release];
  _iCadeControlView = nil;
  
  [_optionsButton release];
  _optionsButton = nil;
  
  [super dealloc];
}

@end
