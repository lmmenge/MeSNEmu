//
//  LMTableViewCellDelegate.h
//  MeSNEmu
//
//  Created by Lucas Menge on 7/8/11.
//  Copyright 2011 Lucas Menge. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LMTableViewCellDelegate <NSObject>

- (void)LM_cellValueChanged:(UITableViewCell*)cell;

@end
