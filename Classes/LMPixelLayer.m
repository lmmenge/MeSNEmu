//
//  LMPixelLayer.m
//  SiOS
//
//  Created by Lucas Menge on 1/2/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import "LMPixelLayer.h"

@implementation LMPixelLayer

@synthesize imageBuffer = _imageBuffer;
@synthesize bufferWidth = _bufferWidth;
@synthesize bufferHeight = _bufferHeight;
@synthesize bufferBitsPerComponent = _bufferBitsPerComponent;
@synthesize bufferBytesPerRow = _bufferBytesPerRow;
@synthesize bufferBitmapInfo = _bufferBitmapInfo;
@synthesize displayMainBuffer = _displayMainBuffer;

- (void)setImageBuffer:(unsigned char*)imageBuffer width:(unsigned int)width height:(unsigned int)height bitsPerComponent:(unsigned short)bitsPerComponent bytesPerRow:(unsigned int)bytesPerRow bitmapInfo:(CGBitmapInfo)bitmapInfo
{
  // release
  if(_bitmapContext != nil)
    CGContextRelease(_bitmapContext);
  _bitmapContext = nil;
  
  // set new values
  _imageBuffer = imageBuffer;
  _bufferWidth = width;
  _bufferHeight = height;
  _bufferBitsPerComponent = bitsPerComponent;
  _bufferBytesPerRow = bytesPerRow;
  _bufferBitmapInfo = bitmapInfo;
  
  // create our context
  if(_imageBuffer != nil)
  {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    _bitmapContext = CGBitmapContextCreate(
                                           _imageBuffer,
                                           _bufferWidth,
                                           _bufferHeight,
                                           _bufferBitsPerComponent,
                                           _bufferBytesPerRow,
                                           colorSpace,
                                           _bufferBitmapInfo
                                           );
    
    CGColorSpaceRelease(colorSpace);
  }
}

- (void)addAltImageBuffer:(unsigned char*)imageBuffer
{
  if(_bitmapContextAlt != nil)
    CGContextRelease(_bitmapContextAlt);
  _bitmapContextAlt = nil;
  
  // set new values
  _imageBufferAlt = imageBuffer;
  
  // create our context
  if(_imageBufferAlt != nil)
  {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    _bitmapContextAlt = CGBitmapContextCreate(
                                           _imageBufferAlt,
                                           _bufferWidth,
                                           _bufferHeight,
                                           _bufferBitsPerComponent,
                                           _bufferBytesPerRow,
                                           colorSpace,
                                           _bufferBitmapInfo
                                           );
    
    CGColorSpaceRelease(colorSpace);
  }
  
  // set scaling parameters
  self.magnificationFilter = kCAFilterNearest;
  self.minificationFilter = kCAFilterNearest;
}

@end

#pragma mark -

@implementation LMPixelLayer(CALayer)

- (void)display
{
  if(_bitmapContext == nil)
    return;
  
  CGImageRef cgImage = nil;
  if(_displayMainBuffer)
    cgImage = CGBitmapContextCreateImage(_bitmapContext);
  else
    cgImage = CGBitmapContextCreateImage(_bitmapContextAlt);
  self.contents = (id)cgImage;
  CGImageRelease(cgImage);
}

- (void)setNeedsDisplay
{
  [super setNeedsDisplay];
}

@end

#pragma mark -

@implementation LMPixelLayer(NSObject)

- (id)init
{
  self = [super init];
  if(self)
  {
    _displayMainBuffer = YES;
  }
  return self;
}

- (void)dealloc
{
  if(_bitmapContext != nil)
    CGContextRelease(_bitmapContext);
  _bitmapContext = nil;
  
  if(_bitmapContextAlt != nil)
    CGContextRelease(_bitmapContextAlt);
  _bitmapContextAlt = nil;
  
  [super dealloc];
}

@end