//
//  LMDPadView.m
//  SiOS
//
//  Created by Lucas Menge on 1/4/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import "LMDPadView.h"

#import "../SNES9XBridge/Snes9xMain.h"

@implementation LMDPadView(Privates)

- (void)handleTouches:(NSSet*)touches
{
  UITouch* touch = [touches anyObject];
  if(touch.phase == UITouchPhaseCancelled || touch.phase == UITouchPhaseEnded || touch == nil)
  {
    SISetControllerReleaseButton(kSIOS_1PUp);
    SISetControllerReleaseButton(kSIOS_1PLeft);
    SISetControllerReleaseButton(kSIOS_1PRight);
    SISetControllerReleaseButton(kSIOS_1PDown);
    return;
  }
  SISetControllerReleaseButton(kSIOS_1PUp);
  SISetControllerReleaseButton(kSIOS_1PLeft);
  SISetControllerReleaseButton(kSIOS_1PRight);
  SISetControllerReleaseButton(kSIOS_1PDown);
  CGPoint location = [touch locationInView:self];
  if(location.x < 50)
  {
    if(location.y < 50)
    {
      SISetControllerPushButton(kSIOS_1PUp);
      SISetControllerPushButton(kSIOS_1PLeft);
    }
    else if(location.y < 100)
      SISetControllerPushButton(kSIOS_1PLeft);
    else
    {
      SISetControllerPushButton(kSIOS_1PDown);
      SISetControllerPushButton(kSIOS_1PLeft);
    }
  }
  else if(location.x < 100)
  {
    if(location.y < 50)
      SISetControllerPushButton(kSIOS_1PUp);
    else if(location.y > 100)
      SISetControllerPushButton(kSIOS_1PDown);
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
            SISetControllerPushButton(kSIOS_1PRight);
          else
            SISetControllerPushButton(kSIOS_1PDown);
        }
        else
        {
          // right or up
          if(x > -y)
            SISetControllerPushButton(kSIOS_1PRight);
          else
            SISetControllerPushButton(kSIOS_1PUp);
        }
      }
      else
      {
        // left or up or down
        if(y > 0)
        {
          // left or down
          if(-x > y)
            SISetControllerPushButton(kSIOS_1PLeft);
          else
            SISetControllerPushButton(kSIOS_1PDown);
        }
        else
        {
          // left or up
          if(-x > -y)
            SISetControllerPushButton(kSIOS_1PLeft);
          else
            SISetControllerPushButton(kSIOS_1PUp);
        }
      }
    }
  }
  else
  {
    if(location.y < 50)
    {
      SISetControllerPushButton(kSIOS_1PUp);
      SISetControllerPushButton(kSIOS_1PRight);
    }
    else if(location.y < 100)
      SISetControllerPushButton(kSIOS_1PRight);
    else
    {
      SISetControllerPushButton(kSIOS_1PDown);
      SISetControllerPushButton(kSIOS_1PRight);
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
    
    self.image = [UIImage imageNamed:@"ButtonDPad"];
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