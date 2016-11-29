//
//  LMButtonView.m
//  MeSNEmu
//
//  Created by Lucas Menge on 1/11/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import "LMButtonView.h"

#import "../SNES9XBridge/Snes9xMain.h"

@implementation LMButtonView(Privates)

- (IBAction)handleTouches:(id)sender forEvent:(UIEvent*)event
{
  UIView *button = (UIView *)sender;
  UITouch *touch = [[event touchesForView:button] anyObject];
  if(touch.phase == UITouchPhaseCancelled || touch.phase == UITouchPhaseEnded || touch == nil)
    SISetControllerReleaseButton(_button);
  else
    SISetControllerPushButton(_button);
}

@end

@implementation LMButtonView

@synthesize button = _button;

- (id)initWithFrame:(CGRect)frame border:(CGFloat)border radius:(CGFloat)radius
{
  self = [super initWithFrame:frame];
  if(self)
  {
    [self setTitleColor:[UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0] forState:UIControlStateNormal];
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(frame.size.width, frame.size.height), NO, self.currentImage.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetRGBFillColor(context, 120/255.0, 120/255.0, 120/255.0, 0.0);
    CGContextSetRGBStrokeColor(context, 255/255.0, 255/255.0, 255/255.0, 1.0);
    CGContextSetLineWidth(context, border);
    
    CGRect rrect = CGRectMake(0, 0, frame.size.width, frame.size.height);
    CGFloat minx = CGRectGetMinX(rrect)+(border/2), midx = CGRectGetMidX(rrect), maxx = CGRectGetMaxX(rrect)-(border/2);
    CGFloat miny = CGRectGetMinY(rrect)+(border/2), midy = CGRectGetMidY(rrect), maxy = CGRectGetMaxY(rrect)-(border/2);
    
    CGContextMoveToPoint(context, minx, midy);
    CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
    CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
    CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
    CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathFillStroke);
    
    [self setBackgroundImage:UIGraphicsGetImageFromCurrentImageContext() forState:UIControlStateNormal];
    
    UIGraphicsEndImageContext();
    
    [self addTarget:self action:@selector(handleTouches:forEvent:) forControlEvents:UIControlEventAllEvents];
  }
  return self;
}

@end
