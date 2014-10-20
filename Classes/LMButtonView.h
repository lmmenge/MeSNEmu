//
//  LMButtonView.h
//  MeSNEmu
//
//  Created by Lucas Menge on 1/11/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LMButtonView : UIButton
{
  uint32_t _button;
}

@property uint32_t button;

- (id)initWithFrame:(CGRect)frame border:(CGFloat)border radius:(CGFloat)radius;

@end
