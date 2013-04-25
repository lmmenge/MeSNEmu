//
//  LMSettingsController.m
//  SiOS
//
//  Created by Lucas Menge on 1/12/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import "LMSettingsController.h"

#import "../SNES9X/snes9x.h"

#import "LMTableViewCellDelegate.h"
#import "LMTableViewNumberCell.h"
#import "LMTableViewSwitchCell.h"

NSString* const kLMSettingsChangedNotification = @"SettingsChanged";

NSString* const kLMSettingsSmoothScaling = @"SmoothScaling";
NSString* const kLMSettingsFullScreen = @"FullScreen";

NSString* const kLMSettingsSound = @"Sound";
NSString* const kLMSettingsAutoFrameskip = @"AutoFrameskip";
NSString* const kLMSettingsFrameskipValue = @"FrameskipValue";

@interface LMSettingsController(Privates) <LMTableViewCellDelegate>
@end

@implementation LMSettingsController(Privates)

- (void)done
{
  if(_changed)
    [[NSNotificationCenter defaultCenter] postNotificationName:kLMSettingsChangedNotification object:nil userInfo:nil];
  [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
    [_delegate settingsDidDismiss:self];
  }];
}

- (void)toggleSmoothScaling:(UISwitch*)sender
{
  _changed = YES;
  [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:kLMSettingsSmoothScaling];
}

- (void)toggleFullScreen:(UISwitch*)sender
{
  _changed = YES;
  [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:kLMSettingsFullScreen];
}

- (void)toggleSound:(UISwitch*)sender
{
  _changed = YES;
  [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:kLMSettingsSound];
}

- (void)toggleAutoFrameskip:(UISwitch*)sender
{
  _changed = YES;
  [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:kLMSettingsAutoFrameskip];
}

- (void)cellValueChanged:(UITableViewCell*)cell
{
  _changed = YES;
  if([[self.tableView indexPathForCell:cell] compare:_frameskipValueIndexPath] == NSOrderedSame)
    [[NSUserDefaults standardUserDefaults] setInteger:((LMTableViewNumberCell*)cell).value forKey:kLMSettingsFrameskipValue];
}

- (LMTableViewNumberCell*)numberCell
{
  static NSString* identifier = @"NumberCell";
  LMTableViewNumberCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
  if (cell == nil)
    cell = [[[LMTableViewNumberCell alloc] initWithReuseIdentifier:identifier] autorelease];
  return cell;
}

- (LMTableViewSwitchCell*)switchCell
{
  static NSString* identifier = @"SwitchCell";
  LMTableViewSwitchCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
  if (cell == nil)
    cell = [[[LMTableViewSwitchCell alloc] initWithReuseIdentifier:identifier] autorelease];
  return cell;
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
    [_soundIndexPath release];
    _soundIndexPath = nil;
    [self.tableView reloadData];
  }
}

+ (void)setDefaultsIfNotDefined
{
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  // Return the number of sections.
  return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  // Return the number of rows in the section.
  if(section == 0)
    return 2;
  else if(section == 1)
  {
    if(_soundIndexPath == nil)
      return 2;
    else
      return 3;
  }
  else if(section == 2)
    return 3;
  return 0;
}

- (NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
  if(section == 0)
    return NSLocalizedString(@"FULL_SCREEN_EXPLANATION", nil);
  else if(section == 1)
    return NSLocalizedString(@"AUTO_FRAMESKIP_EXPLANATION", nil);
  return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{  
  UITableViewCell* cell = nil;
  
  if([indexPath compare:_smoothScalingIndexPath] == NSOrderedSame)
  {
    LMTableViewSwitchCell* c = (LMTableViewSwitchCell*)(cell = [self switchCell]);
    
    c.switchView.on = [[NSUserDefaults standardUserDefaults] boolForKey:kLMSettingsSmoothScaling];
    [c.switchView addTarget:self action:@selector(toggleSmoothScaling:) forControlEvents:UIControlEventValueChanged];
    c.textLabel.text = NSLocalizedString(@"SMOOTH_SCALING", nil);
  }
  else if([indexPath compare:_fullScreenIndexPath] == NSOrderedSame)
  {
    LMTableViewSwitchCell* c = (LMTableViewSwitchCell*)(cell = [self switchCell]);
    
    c.switchView.on = [[NSUserDefaults standardUserDefaults] boolForKey:kLMSettingsFullScreen];
    [c.switchView addTarget:self action:@selector(toggleFullScreen:) forControlEvents:UIControlEventValueChanged];
    c.textLabel.text = NSLocalizedString(@"FULL_SCREEN", nil);
  }
  else if([indexPath compare:_soundIndexPath] == NSOrderedSame)
  {
    LMTableViewSwitchCell* c = (LMTableViewSwitchCell*)(cell = [self switchCell]);
    c.textLabel.text = NSLocalizedString(@"SOUND", nil);
    c.switchView.on = [[NSUserDefaults standardUserDefaults] boolForKey:kLMSettingsSound];
    [c.switchView addTarget:self action:@selector(toggleSound:) forControlEvents:UIControlEventValueChanged];
  }
  else if([indexPath compare:_autoFrameskipIndexPath] == NSOrderedSame)
  {
    LMTableViewSwitchCell* c = (LMTableViewSwitchCell*)(cell = [self switchCell]);
    c.textLabel.text = NSLocalizedString(@"AUTO_FRAMESKIP", nil);
    c.switchView.on = [[NSUserDefaults standardUserDefaults] boolForKey:kLMSettingsAutoFrameskip];
    [c.switchView addTarget:self action:@selector(toggleAutoFrameskip:) forControlEvents:UIControlEventValueChanged];
  }
  else if([indexPath compare:_frameskipValueIndexPath] == NSOrderedSame)
  {
    LMTableViewNumberCell* c = (LMTableViewNumberCell*)(cell = [self numberCell]);
    c.textLabel.text = NSLocalizedString(@"SKIP_EVERY", nil);
    c.minimumValue = 0;
    c.maximumValue = 10;
    c.suffix = NSLocalizedString(@"FRAMES", nil);
    c.allowsDefault = NO;
    c.value = [[NSUserDefaults standardUserDefaults] integerForKey:kLMSettingsFrameskipValue];
    c.delegate = self;
  }
  else
  {
    static NSString* identifier = @"AboutCell";
    cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil)
      cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier] autorelease];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
   
    int row = indexPath.row;
    if(row == 0)
    {
      cell.textLabel.text = NSLocalizedString(@"VERSION", nil);
      cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@",
                                   [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleNameKey],
                                   [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey]];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
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
  
  UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
  self.navigationItem.rightBarButtonItem = doneButton;
  [doneButton release];
  
  _smoothScalingIndexPath = [[NSIndexPath indexPathForRow:0 inSection:0] retain];
  _fullScreenIndexPath = [[NSIndexPath indexPathForRow:1 inSection:0] retain];
  
  if(_hideSettingsThatRequireReset == NO)
  {
    _soundIndexPath = [[NSIndexPath indexPathForRow:0 inSection:1] retain];
    _autoFrameskipIndexPath = [[NSIndexPath indexPathForRow:1 inSection:1] retain];
    _frameskipValueIndexPath = [[NSIndexPath indexPathForRow:2 inSection:1] retain];
  }
  else
  {
    _autoFrameskipIndexPath = [[NSIndexPath indexPathForRow:0 inSection:1] retain];
    _frameskipValueIndexPath = [[NSIndexPath indexPathForRow:1 inSection:1] retain];
  }
}

- (void)viewDidUnload
{
  [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{  
  [super viewWillAppear:animated];
  
  //if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    //[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
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
  if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
  else
    return YES;
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
  [_smoothScalingIndexPath release];
  _smoothScalingIndexPath = nil;
  [_fullScreenIndexPath release];
  _fullScreenIndexPath = nil;
  
  [_soundIndexPath release];
  _soundIndexPath = nil;
  [_autoFrameskipIndexPath release];
  _autoFrameskipIndexPath = nil;
  [_frameskipValueIndexPath release];
  _frameskipValueIndexPath = nil;
  
  [super dealloc];
}

@end
