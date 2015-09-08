//
//  CKMultipleChoicePicker.h
//  carte
//
//  Created by Lucas Menge on 6/30/11.
//  Copyright 2011 Lucas Menge. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LMMultipleChoicePickerDelegate.h"

@interface LMMultipleChoicePicker : UITableViewController
{
  NSArray* _optionNames;
  NSArray* _optionValues;
  int _pickedIndex;
  
  id<LMMultipleChoicePickerDelegate> __weak _delegate;
}

@property (copy) NSArray* optionNames;
@property (copy) NSArray* optionValues;
@property int pickedIndex;

@property (weak) id<LMMultipleChoicePickerDelegate> delegate;

@end
