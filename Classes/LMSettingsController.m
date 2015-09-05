//
//  LMSettingsController.m
//  MeSNEmu
//
//  Created by Lucas Menge on 1/12/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import "LMSettingsController.h"

#import "../SNES9X/snes9x.h"

#import "LMMultipleChoicePicker.h"
#import "LMTableViewCellDelegate.h"
#import "LMTableViewNumberCell.h"
#import "LMTableViewSwitchCell.h"

NSString* const kLMSettingsChangedNotification = @"SettingsChanged";

NSString* const kLMSettingsBluetoothController = @"BluetoothController";

NSString* const kLMSettingsSmoothScaling = @"SmoothScaling";
NSString* const kLMSettingsFullScreen = @"FullScreen";

NSString* const kLMSettingsSound = @"Sound";
NSString* const kLMSettingsAutoFrameskip = @"AutoFrameskip";
NSString* const kLMSettingsFrameskipValue = @"FrameskipValue";

NSString* const kLMEmulatorPortName = @"MeSNEmu";

typedef enum _LMSettingsSections
{
  LMSettingsSectionScreen,
  LMSettingsSectionEmulation,
  LMSettingsSectionBluetoothController,
  LMSettingsSectionAbout
} LMSettingsSections;

@interface LMSettingsController(Privates) <LMTableViewCellDelegate, LMMultipleChoicePickerDelegate>
@end

@implementation LMSettingsController(Privates)

- (void)LM_done
{
  if(_changed == YES)
    [[NSNotificationCenter defaultCenter] postNotificationName:kLMSettingsChangedNotification object:nil userInfo:nil];
  [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
    [_delegate settingsDidDismiss:self];
  }];
}

- (void)LM_toggleSmoothScaling:(UISwitch*)sender
{
  _changed = YES;
  [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:kLMSettingsSmoothScaling];
}

- (void)LM_toggleFullScreen:(UISwitch*)sender
{
  _changed = YES;
  [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:kLMSettingsFullScreen];
}

- (void)LM_toggleSound:(UISwitch*)sender
{
  _changed = YES;
  [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:kLMSettingsSound];
}

- (void)LM_toggleAutoFrameskip:(UISwitch*)sender
{
  _changed = YES;
  [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:kLMSettingsAutoFrameskip];
}

- (void)LM_cellValueChanged:(UITableViewCell*)cell
{
  _changed = YES;
  if([[self.tableView indexPathForCell:cell] compare:_frameskipValueIndexPath] == NSOrderedSame)
    [[NSUserDefaults standardUserDefaults] setInteger:((LMTableViewNumberCell*)cell).value forKey:kLMSettingsFrameskipValue];
}

- (LMTableViewNumberCell*)LM_numberCell
{
  static NSString* identifier = @"NumberCell";
  LMTableViewNumberCell* cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
  if (cell == nil)
    cell = [[LMTableViewNumberCell alloc] initWithReuseIdentifier:identifier];
  return cell;
}

- (LMTableViewSwitchCell*)LM_switchCell
{
  static NSString* identifier = @"SwitchCell";
  LMTableViewSwitchCell* cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
  if (cell == nil)
    cell = [[LMTableViewSwitchCell alloc] initWithReuseIdentifier:identifier];
  return cell;
}

- (UITableViewCell*)LM_multipleChoiceCell
{
  static NSString* identifier = @"MultipleChoiceCell";
  UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
  if (cell == nil)
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  return cell;
}

#pragma mark LMMultipleChoicePickerDelegate

- (void)multipleChoice:(LMMultipleChoicePicker*)picker changedIndex:(int)index
{
  _changed = YES;
  int value = [[picker.optionValues objectAtIndex:index] intValue];
  [[NSUserDefaults standardUserDefaults] setInteger:value forKey:kLMSettingsBluetoothController];
}

@end

#pragma mark -

@implementation LMSettingsController

@synthesize delegate = _delegate;

- (void)hideSettingsThatRequireReset
{
  _hideSettingsThatRequireReset = YES;
  if(_soundIndexPath != nil)
  {
    _soundIndexPath = nil;
    [self.tableView reloadData];
  }
}

+ (void)setDefaultsIfNotDefined
{
  if([[NSUserDefaults standardUserDefaults] objectForKey:kLMSettingsBluetoothController] == nil)
    [[NSUserDefaults standardUserDefaults] setInteger:LMBTControllerType_iCade8Bitty forKey:kLMSettingsBluetoothController];
  
  if([[NSUserDefaults standardUserDefaults] objectForKey:kLMSettingsFullScreen] == nil)
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kLMSettingsFullScreen];
  
  if([[NSUserDefaults standardUserDefaults] objectForKey:kLMSettingsSmoothScaling] == nil)
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kLMSettingsSmoothScaling];
  
  if([[NSUserDefaults standardUserDefaults] objectForKey:kLMSettingsSound] == nil)
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kLMSettingsSound];
  
  if([[NSUserDefaults standardUserDefaults] objectForKey:kLMSettingsAutoFrameskip] == nil)
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kLMSettingsAutoFrameskip];
  
  if([[NSUserDefaults standardUserDefaults] objectForKey:kLMSettingsFrameskipValue] == nil)
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:kLMSettingsFrameskipValue];
}

@end

#pragma mark -

@implementation LMSettingsController(UITableViewController)

- (id)initWithStyle:(UITableViewStyle)style
{
  self = [super initWithStyle:style];
  if (self)
  {
    // Custom initialization
  }
  return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
  // Return the number of sections.
  return 4;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  // Return the number of rows in the section.
  if(section == LMSettingsSectionBluetoothController)
    return 1;
  else if(section == LMSettingsSectionScreen)
    return 2;
  else if(section == LMSettingsSectionEmulation)
  {
    if(_soundIndexPath == nil)
      return 2;
    else
      return 3;
  }
  else if(section == LMSettingsSectionAbout)
  {
    NSString* bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleNameKey];
    if([bundleName isEqualToString:kLMEmulatorPortName] == YES)
      return 3;
    return 2;
  }
  return 0;
}

- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
  if(section == LMSettingsSectionScreen)
    return NSLocalizedString(@"FULL_SCREEN_EXPLANATION", nil);
  else if(section == LMSettingsSectionEmulation)
    return NSLocalizedString(@"AUTO_FRAMESKIP_EXPLANATION", nil);
  return nil;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{  
  UITableViewCell* cell = nil;
  
  NSInteger section = indexPath.section;
  if(section == LMSettingsSectionBluetoothController)
  {
    if(indexPath.row == 0)
    {
      cell = [self LM_multipleChoiceCell];
      cell.textLabel.text = NSLocalizedString(@"BLUETOOTH_CONTROLLER", nil);
      NSString* controllerName = nil;
      LMBTControllerType bluetoothControllerType = [[NSUserDefaults standardUserDefaults] integerForKey:kLMSettingsBluetoothController];
      
      for(NSArray* controller in [LMBTControllerView supportedControllers])
      {
        if([[controller objectAtIndex:1] intValue] == bluetoothControllerType)
        {
          controllerName = [controller objectAtIndex:0];
          break;
        }
      }
      
      cell.detailTextLabel.text = controllerName;
    }
  }
  if(section == LMSettingsSectionScreen)
  {
    if([indexPath compare:_smoothScalingIndexPath] == NSOrderedSame)
    {
      LMTableViewSwitchCell* c = (LMTableViewSwitchCell*)(cell = [self LM_switchCell]);
      
      c.switchView.on = [[NSUserDefaults standardUserDefaults] boolForKey:kLMSettingsSmoothScaling];
      [c.switchView addTarget:self action:@selector(LM_toggleSmoothScaling:) forControlEvents:UIControlEventValueChanged];
      c.textLabel.text = NSLocalizedString(@"SMOOTH_SCALING", nil);
    }
    else if([indexPath compare:_fullScreenIndexPath] == NSOrderedSame)
    {
      LMTableViewSwitchCell* c = (LMTableViewSwitchCell*)(cell = [self LM_switchCell]);
      
      c.switchView.on = [[NSUserDefaults standardUserDefaults] boolForKey:kLMSettingsFullScreen];
      [c.switchView addTarget:self action:@selector(LM_toggleFullScreen:) forControlEvents:UIControlEventValueChanged];
      c.textLabel.text = NSLocalizedString(@"FULL_SCREEN", nil);
    }
  }
  else if(section == LMSettingsSectionEmulation)
  {
    if([indexPath compare:_soundIndexPath] == NSOrderedSame)
    {
      LMTableViewSwitchCell* c = (LMTableViewSwitchCell*)(cell = [self LM_switchCell]);
      c.textLabel.text = NSLocalizedString(@"SOUND", nil);
      c.switchView.on = [[NSUserDefaults standardUserDefaults] boolForKey:kLMSettingsSound];
      [c.switchView addTarget:self action:@selector(LM_toggleSound:) forControlEvents:UIControlEventValueChanged];
    }
    else if([indexPath compare:_autoFrameskipIndexPath] == NSOrderedSame)
    {
      LMTableViewSwitchCell* c = (LMTableViewSwitchCell*)(cell = [self LM_switchCell]);
      c.textLabel.text = NSLocalizedString(@"AUTO_FRAMESKIP", nil);
      c.switchView.on = [[NSUserDefaults standardUserDefaults] boolForKey:kLMSettingsAutoFrameskip];
      [c.switchView addTarget:self action:@selector(LM_toggleAutoFrameskip:) forControlEvents:UIControlEventValueChanged];
    }
    else if([indexPath compare:_frameskipValueIndexPath] == NSOrderedSame)
    {
      LMTableViewNumberCell* c = (LMTableViewNumberCell*)(cell = [self LM_numberCell]);
      c.textLabel.text = NSLocalizedString(@"SKIP_EVERY", nil);
      c.minimumValue = 0;
      c.maximumValue = 9;
      c.suffix = NSLocalizedString(@"FRAMES", nil);
      c.allowsDefault = NO;
      c.value = [[NSUserDefaults standardUserDefaults] integerForKey:kLMSettingsFrameskipValue];
      c.delegate = self;
    }
  }
  else if(section == LMSettingsSectionAbout)
  {
    static NSString* identifier = @"AboutCell";
    cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil)
      cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
   
    int row = indexPath.row;
    if(row == 0)
    {
      cell.textLabel.text = NSLocalizedString(@"VERSION", nil);
      NSString* versionString = [NSString stringWithFormat:@"(%s)", __DATE__];
      NSString* bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleNameKey];
      if([bundleName isEqualToString:kLMEmulatorPortName] == YES)
      {
        versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
      }
      cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@",
                                   kLMEmulatorPortName,
                                   versionString];
    }
    else if(row == 1)
    {
      cell.textLabel.text = NSLocalizedString(@"PORT_OF", nil);
      cell.detailTextLabel.text = [NSString stringWithFormat:@"SNES9X %@", [NSString stringWithCString:VERSION encoding:NSUTF8StringEncoding]];
    }
    else if(row == 2)
    {
      cell.textLabel.text = NSLocalizedString(@"BY", nil);
      cell.detailTextLabel.text = @"Lucas Mendes Menge";
    }
  }
  
  return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  NSInteger section = indexPath.section;
  if(section == LMSettingsSectionBluetoothController)
  {
    if(indexPath.row == 0)
    {
      LMMultipleChoicePicker* c = [[LMMultipleChoicePicker alloc] initWithStyle:UITableViewStyleGrouped];
      c.title = NSLocalizedString(@"BLUETOOTH_CONTROLLER", nil);
      
      // building the option names and values for the controllers
      NSMutableArray* optionNames = [NSMutableArray array];
      NSMutableArray* optionValues = [NSMutableArray array];
      for(NSArray* controller in [LMBTControllerView supportedControllers])
      {
        [optionNames addObject:[controller firstObject]];
        [optionValues addObject:[controller objectAtIndex:1]];
      }
      c.optionNames = optionNames;
      c.optionValues = optionValues;
      
      LMBTControllerType controllerType = [[NSUserDefaults standardUserDefaults] integerForKey:kLMSettingsBluetoothController];
      for(int i=0; i<[c.optionValues count]; i++)
      {
        if([[c.optionValues objectAtIndex:i] intValue] == controllerType)
        {
          c.pickedIndex = i;
          break;
        }
      }
      c.delegate = self;
      [self.navigationController pushViewController:c animated:YES];
    }
  }
}

@end

#pragma mark -

@implementation LMSettingsController(UIViewController)

- (void)didReceiveMemoryWarning
{
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  
  // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidLoad
{  
  [super viewDidLoad];
  
  self.title = NSLocalizedString(@"SETTINGS", nil);
  
  UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(LM_done)];
  self.navigationItem.rightBarButtonItem = doneButton;
  
  _smoothScalingIndexPath = [NSIndexPath indexPathForRow:0 inSection:LMSettingsSectionScreen];
  _fullScreenIndexPath = [NSIndexPath indexPathForRow:1 inSection:LMSettingsSectionScreen];
  
  if(_hideSettingsThatRequireReset == NO)
  {
    _soundIndexPath = [NSIndexPath indexPathForRow:0 inSection:LMSettingsSectionEmulation];
    _autoFrameskipIndexPath = [NSIndexPath indexPathForRow:1 inSection:LMSettingsSectionEmulation];
    _frameskipValueIndexPath = [NSIndexPath indexPathForRow:2 inSection:LMSettingsSectionEmulation];
  }
  else
  {
    _autoFrameskipIndexPath = [NSIndexPath indexPathForRow:0 inSection:LMSettingsSectionEmulation];
    _frameskipValueIndexPath = [NSIndexPath indexPathForRow:1 inSection:LMSettingsSectionEmulation];
  }
}

- (void)viewDidUnload
{
  [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{  
  [super viewWillAppear:animated];
  
  [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  // Return YES for supported orientations
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
  else
    return YES;
}

- (BOOL)prefersStatusBarHidden
{
  return NO;
}

@end

#pragma mark -

@implementation LMSettingsController(NSObject)

- (id)init
{
  self = [self initWithStyle:UITableViewStyleGrouped];
  if(self)
  {
    [LMSettingsController setDefaultsIfNotDefined];
  }
  return self;
}

- (void)dealloc
{
  _smoothScalingIndexPath = nil;
  _fullScreenIndexPath = nil;
  
  _soundIndexPath = nil;
  _autoFrameskipIndexPath = nil;
  _frameskipValueIndexPath = nil;
  
}

@end
