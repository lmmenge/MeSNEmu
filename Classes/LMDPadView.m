//
//  LMDPadView.m
//  pixelbuffertest
//
//  Created by Lucas Menge on 1/4/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import "LMDPadView.h"

#import "LMEmulatorInterface.h"

@implementation LMDPadView(Privates)

- (void)handleTouches:(NSSet*)touches
{
  UITouch* touch = [touches anyObject];
  if(touch.phase == UITouchPhaseCancelled || touch.phase == UITouchPhaseEnded || touch == nil)
  {
    LMSetControllerReleaseButton(GP2X_UP);
    LMSetControllerReleaseButton(GP2X_LEFT);
    LMSetControllerReleaseButton(GP2X_RIGHT);
    LMSetControllerReleaseButton(GP2X_DOWN);
    return;
  }
  //LMSetControllerReleaseButton(GP2X_UP|GP2X_LEFT|GP2X_RIGHT|GP2X_DOWN); // TODO: make this atomic
  LMSetControllerReleaseButton(GP2X_UP);
  LMSetControllerReleaseButton(GP2X_LEFT);
  LMSetControllerReleaseButton(GP2X_RIGHT);
  LMSetControllerReleaseButton(GP2X_DOWN);
  CGPoint location = [touch locationInView:self];
  if(location.x < 50)
  {
    if(location.y < 50)
    {
      LMSetControllerPushButton(GP2X_UP);
      LMSetControllerPushButton(GP2X_LEFT);
    }
    else if(location.y < 100)
      LMSetControllerPushButton(GP2X_LEFT);
    else
    {
      LMSetControllerPushButton(GP2X_DOWN);
      LMSetControllerPushButton(GP2X_LEFT);
    }
  }
  else if(location.x < 100)
  {
    if(location.y < 50)
      LMSetControllerPushButton(GP2X_UP);
    else if(location.y > 100)
      LMSetControllerPushButton(GP2X_DOWN);
  }
  else
  {
    if(location.y < 50)
    {
      LMSetControllerPushButton(GP2X_UP);
      LMSetControllerPushButton(GP2X_RIGHT);
    }
    else if(location.y < 100)
      LMSetControllerPushButton(GP2X_RIGHT);
    else
    {
      LMSetControllerPushButton(GP2X_DOWN);
      LMSetControllerPushButton(GP2X_RIGHT);
    }
  }
}

@end

@implementation LMDPadView

@end

#pragma mark -

@implementation LMDPadView(UIView)

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if(self)
  {
    self.userInteractionEnabled = YES;
    
    self.image = [UIImage imageNamed:@"ButtonDPad.png"];
    self.contentMode = UIViewContentModeCenter;
  }
  return self;
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
  [self handleTouches:touches];
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
  [self handleTouches:touches];
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
  [self handleTouches:touches];
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event
{
  [self handleTouches:touches];
}

@end