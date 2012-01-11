//
//  LMPixelLayer.h
//  SiOS
//
//  Created by Lucas Menge on 1/2/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>


@interface LMPixelLayer : CALayer {
  unsigned char* _imageBuffer;
  unsigned char* _imageBufferAlt;
  unsigned int _bufferWidth;
  unsigned int _bufferHeight;
  unsigned short _bufferBitsPerComponent;
  unsigned int _bufferBytesPerRow;
  CGBitmapInfo _bufferBitmapInfo;
  
  CGContextRef _bitmapContext;
  CGContextRef _bitmapContextAlt;
  BOOL _displayMainBuffer;
}

@property (readonly) unsigned char* imageBuffer;
@property (readonly) unsigned int bufferWidth;
@property (readonly) unsigned int bufferHeight;
@property (readonly) unsigned short bufferBitsPerComponent;
@property (readonly) unsigned int bufferBytesPerRow;
@property (readonly) CGBitmapInfo bufferBitmapInfo;
@property BOOL displayMainBuffer;

- (void)setImageBuffer:(unsigned char*)imageBuffer width:(unsigned int)width height:(unsigned int)height bitsPerComponent:(unsigned short)bitsPerComponent bytesPerRow:(unsigned int)bytesPerRow bitmapInfo:(CGBitmapInfo)bitmapInfo;
- (void)addAltImageBuffer:(unsigned char*)imageBuffer;

@end
