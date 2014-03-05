//
//  LMROMBrowserController.h
//  SiOS
//
//  Created by Lucas Menge on 1/3/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JPSDK.h"

@class LMFileListItem;

@interface LMROMBrowserController : UITableViewController <JPDeviceDelegate, JPManagerDelegate> {
  LMFileListItem* _detailsItem;
  NSString* _romPath;
  NSString* _sramPath;
  
  NSArray* _romList;
  NSArray* _sectionTitles;
  NSArray* _sectionMarkers;
  
  NSArray* _filteredRomList;
  NSArray* _filteredSectionTitles;
  NSArray* _filteredSectionMarkers;
  
  NSTimer* _fsTimer;
}

@property (retain) LMFileListItem* detailsItem;

@end
