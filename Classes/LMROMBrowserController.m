//
//  LMROMBrowserController.m
//  SiOS
//
//  Created by Lucas Menge on 1/3/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import "LMROMBrowserController.h"

#import "LMEmulatorController.h"
#import "LMEmulatorInterface.h"
#import "LMSettingsController.h"

@implementation LMROMBrowserController(Privates)

- (void)reloadROMList
{
  // copy all ROMs from the Inbox to the documents folder
  // TODO: import the ROMs
  [[NSFileManager defaultManager] removeItemAtPath:[_romPath stringByAppendingPathComponent:@"Inbox"] error:nil];
  
  // list all ROMs in the documents folder
  NSMutableArray* tempRomList = [NSMutableArray array];
  NSArray* proposedFileList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_romPath error:nil];
  
  for(NSString* file in proposedFileList)
  {
    BOOL isDirectory = NO;
    if([[NSFileManager defaultManager] fileExistsAtPath:[_romPath stringByAppendingPathComponent:file] isDirectory:&isDirectory])
    {
      if(isDirectory == NO)
        [tempRomList addObject:file];
    }
  }
  
  BOOL different = ([_romList count] != [tempRomList count]);
  if(different == NO)
  {
    for(int i=0; i<[tempRomList count]; i++)
    {
      NSString* romA = [_romList objectAtIndex:i];
      NSString* romB = [tempRomList objectAtIndex:i];
      if([romA isEqualToString:romB] == NO)
      {
        different = YES;
        break;
      }
    }
  }
  if(different)
  {
    [_romList release];
    _romList = [tempRomList copy];
    [self.tableView reloadData];
  }
}

- (void)settings
{
  LMSettingsController* c = [[LMSettingsController alloc] init];
  UINavigationController* n = [[UINavigationController alloc] initWithRootViewController:c];
  n.modalPresentationStyle = UIModalPresentationFormSheet;
  [self presentModalViewController:n animated:YES];
  [c release];
  [n release];
}

@end

#pragma mark -

@implementation LMROMBrowserController



@end

#pragma mark -

@implementation LMROMBrowserController(UITableViewController)

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  // Return the number of sections.
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  // Return the number of rows in the section.
  return [_romList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"Cell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if(cell == nil)
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
  
  int index = indexPath.row;
  
  cell.textLabel.text = [_romList objectAtIndex:index];
  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSString* romName = [_romList objectAtIndex:indexPath.row];
  
  LMEmulatorController* emulator = [[LMEmulatorController alloc] init];
  emulator.romFileName = romName;
  [self.navigationController pushViewController:emulator animated:YES];
  [emulator release];
}

@end

#pragma mark -

@implementation LMROMBrowserController(UIViewController)

- (id)initWithStyle:(UITableViewStyle)style
{
  self = [super initWithStyle:style];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (void)didReceiveMemoryWarning
{
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  
  // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.title = @"ROMs";
  
  UIBarButtonItem* settingsButton = [[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStyleBordered target:self action:@selector(settings)];
  self.navigationItem.rightBarButtonItem = settingsButton;
  [settingsButton release];
  
  if(_romList != nil)
  {
    [_romList release];
    _romList = nil;
  }
  
  // documents folder
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsPath = [paths objectAtIndex:0];
  
  // set it as the system dir
  LMSetSystemPath([documentsPath UTF8String]);
  
  _romPath = [documentsPath copy];
  [self reloadROMList];
}

- (void)viewDidUnload
{
  [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
  [self.navigationController setNavigationBarHidden:NO animated:YES];
  
  [self reloadROMList];
  
  _fsTimer = [[NSTimer timerWithTimeInterval:5 target:self selector:@selector(reloadROMList) userInfo:nil repeats:YES] retain];
  [[NSRunLoop mainRunLoop] addTimer:_fsTimer forMode:NSDefaultRunLoopMode];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadROMList) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  
  [_fsTimer invalidate];
  _fsTimer = nil;
  
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
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

@implementation LMROMBrowserController(NSObject)

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [_romList release];
  _romList = nil;
  [_romPath release];
  _romPath = nil;
  
  [_fsTimer invalidate];
  _fsTimer = nil;
  
  [super dealloc];
}

@end
