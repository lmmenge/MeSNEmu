//
//  LMTableViewNumberCell.h
//  SiOS
//
//  Created by Lucas Menge on 7/8/11.
//  Copyright 2011 Lucas Menge. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LMTableViewCellDelegate.h"

@interface LMTableViewNumberCell : UITableViewCell {
  int value;
  int minimumValue;
  int maximumValue;
  NSString* suffix;
  BOOL usesDefaultValue;
  BOOL allowsDefault;
  
  UIView* _plusMinusAccessoryView;
  UIButton* plusButton;
  UIButton* minusButton;
  UIButton* defaultButton;
  
  id<LMTableViewCellDelegate> delegate;
}

@property (readonly) UIView* plusMinusAccessoryView;
@property (nonatomic) int value;
@property int minimumValue;
@property int maximumValue;
@property (nonatomic, copy) NSString* suffix;
@property (nonatomic) BOOL usesDefaultValue;
@property (nonatomic) BOOL allowsDefault;

@property (assign) id<LMTableViewCellDelegate> delegate;

- (id)initWithReuseIdentifier:(NSString*)reuseIdentifier;

@end
