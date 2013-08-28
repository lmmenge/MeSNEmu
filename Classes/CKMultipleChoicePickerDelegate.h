//
//  CKMultipleChoicePickerDelegate.h
//  carte
//
//  Created by Lucas Menge on 10/31/11.
//  Copyright (c) 2011 Lucas Menge. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LMMultipleChoicePicker;

@protocol LMMultipleChoicePickerDelegate <NSObject>

- (void)multipleChoice:(LMMultipleChoicePicker*)picker changedIndex:(int)index;

@end
