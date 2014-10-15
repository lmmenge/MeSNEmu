//
//  LMPixelView.m
//  MeSNEmu
//
//  Created by Lucas Menge on 1/2/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import "LMPixelView.h"

#import "LMPixelLayer.h"

@implementation LMPixelView

- (void)updateBufferCropResWidth:(unsigned int)width height:(unsigned int)height
{
  [(LMPixelLayer*)self.layer updateBufferCropWidth:width height:height];
}

@end

#pragma mark -

@implementation LMPixelView(UIView)

- (void)drawRect:(CGRect)rect
{
  // override this to allow the CALayer to be invalidated and thus displaying the actual layer contents
}

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if(self)
  {
    // Initialization code
  }
  return self;
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

+ (Class)layerClass
{
  return [LMPixelLayer class];
}

@end