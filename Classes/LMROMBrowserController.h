//
//  LMROMBrowserController.h
//  SiOS
//
//  Created by Lucas Menge on 1/3/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LMROMBrowserController : UITableViewController {
  NSString* _romPath;
  NSArray* _romList;
  NSArray* _sectionTitles;
  NSArray* _sectionMarkers;
  NSTimer* _fsTimer;
}

@end
