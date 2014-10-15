//
//  LMDPadView.m
//  MeSNEmu
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
    SISetControllerReleaseButton(SI_BUTTON_UP);
    SISetControllerReleaseButton(SI_BUTTON_LEFT);
    SISetControllerReleaseButton(SI_BUTTON_RIGHT);
    SISetControllerReleaseButton(SI_BUTTON_DOWN);
    return;
  }
  SISetControllerReleaseButton(SI_BUTTON_UP);
  SISetControllerReleaseButton(SI_BUTTON_LEFT);
  SISetControllerReleaseButton(SI_BUTTON_RIGHT);
  SISetControllerReleaseButton(SI_BUTTON_DOWN);
  CGPoint location = [touch locationInView:self];
  if(location.x < 50)
  {
    if(location.y < 50)
    {
      SISetControllerPushButton(SI_BUTTON_UP);
      SISetControllerPushButton(SI_BUTTON_LEFT);
    }
    else if(location.y < 100)
      SISetControllerPushButton(SI_BUTTON_LEFT);
    else
    {
      SISetControllerPushButton(SI_BUTTON_DOWN);
      SISetControllerPushButton(SI_BUTTON_LEFT);
    }
  }
  else if(location.x < 100)
  {
    if(location.y < 50)
      SISetControllerPushButton(SI_BUTTON_UP);
    else if(location.y > 100)
      SISetControllerPushButton(SI_BUTTON_DOWN);
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
            SISetControllerPushButton(SI_BUTTON_RIGHT);
          else
            SISetControllerPushButton(SI_BUTTON_DOWN);
        }
        else
        {
          // right or up
          if(x > -y)
            SISetControllerPushButton(SI_BUTTON_RIGHT);
          else
            SISetControllerPushButton(SI_BUTTON_UP);
        }
      }
      else
      {
        // left or up or down
        if(y > 0)
        {
          // left or down
          if(-x > y)
            SISetControllerPushButton(SI_BUTTON_LEFT);
          else
            SISetControllerPushButton(SI_BUTTON_DOWN);
        }
        else
        {
          // left or up
          if(-x > -y)
            SISetControllerPushButton(SI_BUTTON_LEFT);
          else
            SISetControllerPushButton(SI_BUTTON_UP);
        }
      }
    }
  }
  else
  {
    if(location.y < 50)
    {
      SISetControllerPushButton(SI_BUTTON_UP);
      SISetControllerPushButton(SI_BUTTON_RIGHT);
    }
    else if(location.y < 100)
      SISetControllerPushButton(SI_BUTTON_RIGHT);
    else
    {
      SISetControllerPushButton(SI_BUTTON_DOWN);
      SISetControllerPushButton(SI_BUTTON_RIGHT);
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