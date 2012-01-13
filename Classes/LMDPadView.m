//
//  LMDPadView.m
//  SiOS
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
    LMSetControllerReleaseButton(SIOS_UP);
    LMSetControllerReleaseButton(SIOS_LEFT);
    LMSetControllerReleaseButton(SIOS_RIGHT);
    LMSetControllerReleaseButton(SIOS_DOWN);
    return;
  }
  //LMSetControllerReleaseButton(SIOS_UP|SIOS_LEFT|SIOS_RIGHT|SIOS_DOWN); // TODO: make this atomic
  LMSetControllerReleaseButton(SIOS_UP);
  LMSetControllerReleaseButton(SIOS_LEFT);
  LMSetControllerReleaseButton(SIOS_RIGHT);
  LMSetControllerReleaseButton(SIOS_DOWN);
  CGPoint location = [touch locationInView:self];
  if(location.x < 50)
  {
    if(location.y < 50)
    {
      LMSetControllerPushButton(SIOS_UP);
      LMSetControllerPushButton(SIOS_LEFT);
    }
    else if(location.y < 100)
      LMSetControllerPushButton(SIOS_LEFT);
    else
    {
      LMSetControllerPushButton(SIOS_DOWN);
      LMSetControllerPushButton(SIOS_LEFT);
    }
  }
  else if(location.x < 100)
  {
    if(location.y < 50)
      LMSetControllerPushButton(SIOS_UP);
    else if(location.y > 100)
      LMSetControllerPushButton(SIOS_DOWN);
    else
    {
      // inside the middle square things get "tricky"
      int x = location.x-75;
      int y = location.y-75;
      if(x > 0)
      {
        // right or up or down
        if(y > 0)
        {
          // right or down
          if(x > y)
            LMSetControllerPushButton(SIOS_RIGHT);
          else
            LMSetControllerPushButton(SIOS_DOWN);
        }
        else
        {
          // right or up
          if(x > -y)
            LMSetControllerPushButton(SIOS_RIGHT);
          else
            LMSetControllerPushButton(SIOS_UP);
        }
      }
      else
      {
        // left or up or down
        if(y > 0)
        {
          // left or down
          if(-x > y)
            LMSetControllerPushButton(SIOS_LEFT);
          else
            LMSetControllerPushButton(SIOS_DOWN);
        }
        else
        {
          // left or up
          if(-x > -y)
            LMSetControllerPushButton(SIOS_LEFT);
          else
            LMSetControllerPushButton(SIOS_UP);
        }
      }
    }
  }
  else
  {
    if(location.y < 50)
    {
      LMSetControllerPushButton(SIOS_UP);
      LMSetControllerPushButton(SIOS_RIGHT);
    }
    else if(location.y < 100)
      LMSetControllerPushButton(SIOS_RIGHT);
    else
    {
      LMSetControllerPushButton(SIOS_DOWN);
      LMSetControllerPushButton(SIOS_RIGHT);
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