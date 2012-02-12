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
    SISetControllerReleaseButton(SIOS_UP);
    SISetControllerReleaseButton(SIOS_LEFT);
    SISetControllerReleaseButton(SIOS_RIGHT);
    SISetControllerReleaseButton(SIOS_DOWN);
    return;
  }
  SISetControllerReleaseButton(SIOS_UP);
  SISetControllerReleaseButton(SIOS_LEFT);
  SISetControllerReleaseButton(SIOS_RIGHT);
  SISetControllerReleaseButton(SIOS_DOWN);
  CGPoint location = [touch locationInView:self];
  if(location.x < 50)
  {
    if(location.y < 50)
    {
      SISetControllerPushButton(SIOS_UP);
      SISetControllerPushButton(SIOS_LEFT);
    }
    else if(location.y < 100)
      SISetControllerPushButton(SIOS_LEFT);
    else
    {
      SISetControllerPushButton(SIOS_DOWN);
      SISetControllerPushButton(SIOS_LEFT);
    }
  }
  else if(location.x < 100)
  {
    if(location.y < 50)
      SISetControllerPushButton(SIOS_UP);
    else if(location.y > 100)
      SISetControllerPushButton(SIOS_DOWN);
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
            SISetControllerPushButton(SIOS_RIGHT);
          else
            SISetControllerPushButton(SIOS_DOWN);
        }
        else
        {
          // right or up
          if(x > -y)
            SISetControllerPushButton(SIOS_RIGHT);
          else
            SISetControllerPushButton(SIOS_UP);
        }
      }
      else
      {
        // left or up or down
        if(y > 0)
        {
          // left or down
          if(-x > y)
            SISetControllerPushButton(SIOS_LEFT);
          else
            SISetControllerPushButton(SIOS_DOWN);
        }
        else
        {
          // left or up
          if(-x > -y)
            SISetControllerPushButton(SIOS_LEFT);
          else
            SISetControllerPushButton(SIOS_UP);
        }
      }
    }
  }
  else
  {
    if(location.y < 50)
    {
      SISetControllerPushButton(SIOS_UP);
      SISetControllerPushButton(SIOS_RIGHT);
    }
    else if(location.y < 100)
      SISetControllerPushButton(SIOS_RIGHT);
    else
    {
      SISetControllerPushButton(SIOS_DOWN);
      SISetControllerPushButton(SIOS_RIGHT);
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