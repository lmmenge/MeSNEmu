//
//  LMViewController.h
//  pixelbuffertest
//
//  Created by Lucas Menge on 1/2/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "../SNES9XBridge/SIScreenDelegate.h"

@class LMButtonView;
@class LMDPadView;
@class LMPixelView;

@interface LMEmulatorController : UIViewController <SIScreenDelegate> {
  LMPixelView* _screenView;
  
  unsigned int _bufferWidth;
  unsigned int _bufferHeight;
  unsigned char* _imageBuffer;
  unsigned char* _imageBufferAlt;
  unsigned char* _565ImageBuffer;
  
  NSThread* _emulationThread;
  
  // start / select
  LMButtonView* _startButton;
  LMButtonView* _selectButton;
  // buttons
  LMButtonView* _aButton;
  LMButtonView* _bButton;
  LMButtonView* _xButton;
  LMButtonView* _yButton;
  LMButtonView* _lButton;
  LMButtonView* _rButton;
  // directions
  LMDPadView* _dPadView;
  
  UIButton* _optionsButton;
  
  NSString* _romFileName;
}

@property (copy) NSString* romFileName;

- (void)startWithROM:(NSString*)romFileName;
- (void)flipFrontbuffer;

@end
