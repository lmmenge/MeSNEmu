//
//  LMViewController.h
//  pixelbuffertest
//
//  Created by Lucas Menge on 1/2/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SiOS/SIScreenDelegate.h"

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
  UIButton* _startButton;
  UIButton* _selectButton;
  // buttons
  UIButton* _aButton;
  UIButton* _bButton;
  UIButton* _xButton;
  UIButton* _yButton;
  UIButton* _lButton;
  UIButton* _rButton;
  // directions
  LMDPadView* _dPadView;
  
  UIButton* _optionsButton;
  
  NSString* _romFileName;
}

@property (copy) NSString* romFileName;

- (void)startWithROM:(NSString*)romFileName;
- (void)flipFrontbuffer;

@end
