//
//  LMSettingsController.h
//  SiOS
//
//  Created by Lucas Menge on 1/12/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString* const kLMSettingsSmoothScaling;
extern NSString* const kLMSettingsFullScreen;

extern NSString* const kLMSettingsSound;
extern NSString* const kLMSettingsAutoFrameskip;
extern NSString* const kLMSettingsFrameskipValue;

@interface LMSettingsController : UITableViewController {
  NSIndexPath* _smoothScalingIndexPath;
  NSIndexPath* _fullScreenIndexPath;
  
  NSIndexPath* _soundIndexPath;
  NSIndexPath* _autoFrameskipIndexPath;
  NSIndexPath* _frameskipValueIndexPath;
}

+ (void)setDefaultsIfNotDefined;

@end
