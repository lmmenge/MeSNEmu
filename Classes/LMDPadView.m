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

- (IBAction)handleTouches:(id)sender forEvent:(UIEvent*)event
{
	UIView *button = (UIView *)sender;
	UITouch *touch = [[event touchesForView:button] anyObject];
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

- (id)init
{
	self = [super init];
	if(self)
	{
		int maxw = 140;
		int minw = 44;
		CGFloat midw = (maxw-minw)/2;
		CGFloat border = 4.0;
		
		self.frame = CGRectMake(0, 0, maxw, maxw);
		
		UIGraphicsBeginImageContextWithOptions(CGSizeMake(maxw, maxw), NO, self.currentImage.scale);
		CGContextRef context = UIGraphicsGetCurrentContext();
		CGContextSetRGBFillColor(context, 255/255.0, 255/255.0, 255/255.0, 0.0);
		CGContextSetRGBStrokeColor(context, 255/255.0, 255/255.0, 255/255.0, 1.0);
		CGContextSetLineWidth(context, border);
		
		CGRect rrect = CGRectMake(0, 0, maxw, maxw);
		CGFloat radius = 10.0;
		CGFloat minx = CGRectGetMinX(rrect)+(border/2), midx = CGRectGetMidX(rrect), maxx = CGRectGetMaxX(rrect)-(border/2);
		CGFloat miny = CGRectGetMinY(rrect)+(border/2), midy = CGRectGetMidY(rrect), maxy = CGRectGetMaxY(rrect)-(border/2);
		
		CGContextMoveToPoint(context, midw, midw);
		CGContextAddArcToPoint(context, midw, miny, midx, miny, radius);
		CGContextAddArcToPoint(context, maxx-midw, miny, maxx-midw, midw, radius);
		CGContextAddLineToPoint(context, maxx-midw, midw);
		CGContextAddArcToPoint(context, maxx, midw, maxx, midy, radius);
		CGContextAddArcToPoint(context, maxx, maxy-midw, maxx-midw, maxy-midw, radius);
		CGContextAddLineToPoint(context, maxx-midw, maxy-midw);
		CGContextAddArcToPoint(context, maxx-midw, maxy, midx, maxy, radius);
		CGContextAddArcToPoint(context, midw, maxy, midw, maxy-midw, radius);
		CGContextAddLineToPoint(context, midw, maxy-midw);
		CGContextAddArcToPoint(context, minx, maxy-midw, minx, midy, radius);
		CGContextAddArcToPoint(context, minx, midw, midw, midw, radius);
		CGContextClosePath(context);
		CGContextDrawPath(context, kCGPathFillStroke);
		
		[self setImage:UIGraphicsGetImageFromCurrentImageContext() forState:UIControlStateNormal];
		
		UIGraphicsEndImageContext();
		
		[self addTarget:self action:@selector(handleTouches:forEvent:) forControlEvents:UIControlEventAllEvents];
	}
	return self;
}

@end