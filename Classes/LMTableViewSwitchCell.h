//
//  LMTableViewSwitchCell.h
//  MeSNEmu
//
//  Created by Lucas Menge on 1/12/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LMTableViewSwitchCell : UITableViewCell
{
  UISwitch* _switch;
}

@property (readonly) UISwitch* switchView;

- (id)initWithReuseIdentifier:(NSString*)reuseIdentifier;

@end
