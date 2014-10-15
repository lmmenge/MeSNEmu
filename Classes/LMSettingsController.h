//
//  LMSettingsController.h
//  MeSNEmu
//
//  Created by Lucas Menge on 1/12/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "../iCade/LMBTControllerView.h"

extern NSString* const kLMSettingsChangedNotification;

extern NSString* const kLMSettingsBluetoothController;

extern NSString* const kLMSettingsSmoothScaling;
extern NSString* const kLMSettingsFullScreen;

extern NSString* const kLMSettingsSound;
extern NSString* const kLMSettingsAutoFrameskip;
extern NSString* const kLMSettingsFrameskipValue;

@class LMSettingsController;

@protocol LMSettingsControllerDelegate <NSObject>

- (void)settingsDidDismiss:(LMSettingsController*)settingsController;

@end

#pragma mark -

@interface LMSettingsController : UITableViewController
{
  BOOL _hideSettingsThatRequireReset;
  BOOL _changed;
  
  NSIndexPath* _smoothScalingIndexPath;
  NSIndexPath* _fullScreenIndexPath;
  
  NSIndexPath* _soundIndexPath;
  NSIndexPath* _autoFrameskipIndexPath;
  NSIndexPath* _frameskipValueIndexPath;
  
  id<LMSettingsControllerDelegate> _delegate;
}

@property (assign) id<LMSettingsControllerDelegate> delegate;

- (void)hideSettingsThatRequireReset;

+ (void)setDefaultsIfNotDefined;

@end
