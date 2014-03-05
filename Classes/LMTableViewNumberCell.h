//
//  LMTableViewNumberCell.h
//  SiOS
//
//  Created by Lucas Menge on 7/8/11.
//  Copyright 2011 Lucas Menge. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LMTableViewCellDelegate.h"


@interface LMTableViewNumberCell : UITableViewCell
{
  double _value;
  double _minimumValue;
  double _maximumValue;
  NSString* _suffix;
  BOOL _usesDefaultValue;
  BOOL _allowsDefault;
  
  UIView* _plusMinusAccessoryView;
  UIButton* _plusButton;
  UIButton* _minusButton;
  UIButton* _defaultButton;
  
  id<LMTableViewCellDelegate> _delegate;
}

@property (readonly) UIView* plusMinusAccessoryView;
@property (nonatomic) double value;
@property double minimumValue;
@property double maximumValue;
@property (nonatomic, copy) NSString* suffix;
@property (nonatomic) BOOL usesDefaultValue;
@property (nonatomic) BOOL allowsDefault;

@property (assign) id<LMTableViewCellDelegate> delegate;

- (id)initWithReuseIdentifier:(NSString*)reuseIdentifier;

@end
