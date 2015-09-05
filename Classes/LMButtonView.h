//
//  LMButtonView.h
//  MeSNEmu
//
//  Created by Lucas Menge on 1/11/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LMButtonView : UIImageView
{
  uint32_t _button;
  UILabel* __weak _label;
}

@property uint32_t button;
@property (weak, readonly) UILabel* label;

@end
