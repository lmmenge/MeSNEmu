//
//  LMROMBrowserController.m
//  SiOS
//
//  Created by Lucas Menge on 1/3/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import "LMROMBrowserController.h"

#import "../SNES9XBridge/Snes9xMain.h"

#import "LMEmulatorController.h"
#import "LMSettingsController.h"

@implementation LMROMBrowserController(Privates)

- (void)reloadROMList:(BOOL)updateTable
{
  NSFileManager* fm = [NSFileManager defaultManager];
  
  // copy all ROMs from the Inbox to the documents folder
  NSString* inboxPath = [_romPath stringByAppendingPathComponent:@"Inbox"];
  NSArray* filesInInbox = [fm contentsOfDirectoryAtPath:inboxPath error:nil];
  for(NSString* file in filesInInbox)
  {
    NSString* sourcePath = [inboxPath stringByAppendingPathComponent:file];
    NSString* targetPath = [_romPath stringByAppendingPathComponent:file];
    // avoid overwriting existing files
    int i = 1;
    while([fm fileExistsAtPath:targetPath] == YES)
    {
      targetPath = [[[targetPath stringByDeletingPathExtension] stringByAppendingFormat:@" %i", i] stringByAppendingPathExtension:[sourcePath pathExtension]];
      i++;
    }
    // actually move item
    [fm moveItemAtPath:sourcePath toPath:targetPath error:nil];
  }
  [fm removeItemAtPath:inboxPath error:nil];
  
  // list all ROMs in the documents folder
  NSMutableArray* tempRomList = [NSMutableArray array];
  NSMutableArray* tempSectionTitles = [NSMutableArray array];
  NSMutableArray* tempSectionMarkers = [NSMutableArray array];
  NSArray* proposedFileList = [fm contentsOfDirectoryAtPath:_romPath error:nil];
  
  unichar lastChar = '\0';
  for(NSString* file in proposedFileList)
  {
    BOOL isDirectory = NO;
    if([fm fileExistsAtPath:[_romPath stringByAppendingPathComponent:file] isDirectory:&isDirectory])
    {
      if(isDirectory == NO)
      {
        unichar firstLetter = [[file uppercaseString] characterAtIndex:0];
        if(firstLetter >= '0' && firstLetter <= '9')
          firstLetter = '#';
        if(firstLetter != lastChar)
        {
          lastChar = firstLetter;
          [tempSectionTitles addObject:[NSString stringWithCharacters:&lastChar length:1]];
          [tempSectionMarkers addObject:[NSNumber numberWithInt:[tempRomList count]]];
        }
        [tempRomList addObject:file];
      }
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
    [_sectionTitles release];
    _sectionTitles = [tempSectionTitles copy];
    [_sectionMarkers release];
    _sectionMarkers = [tempSectionMarkers copy];
    if(updateTable == YES)
      [self.tableView reloadData];
  }
}
- (void)reloadROMList
{
  [self reloadROMList:YES];
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

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
  return _sectionTitles;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString*)title atIndex:(NSInteger)index
{
  return index;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  // Return the number of sections.
  return [_sectionTitles count];
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  return [_sectionTitles objectAtIndex:section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  // Return the number of rows in the section.
  int sectionStart = [[_sectionMarkers objectAtIndex:section] intValue];
  int sectionEnd = [_romList count];
  if(section < [_sectionMarkers count]-1)
    sectionEnd = [[_sectionMarkers objectAtIndex:(section+1)] intValue];
  return sectionEnd-sectionStart;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"Cell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if(cell == nil)
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
  
  int index = indexPath.row;
  index += [[_sectionMarkers objectAtIndex:indexPath.section] intValue];
  
  cell.textLabel.text = [_romList objectAtIndex:index];
  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  int index = indexPath.row;
  index += [[_sectionMarkers objectAtIndex:indexPath.section] intValue];
  NSString* romName = [_romList objectAtIndex:index];
  
  LMEmulatorController* emulator = [[LMEmulatorController alloc] init];
  emulator.romFileName = romName;
  [self.navigationController pushViewController:emulator animated:YES];
  [emulator release];
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
  int index = indexPath.row;
  index += [[_sectionMarkers objectAtIndex:indexPath.section] intValue];
  if(editingStyle == UITableViewCellEditingStyleDelete)
  {
    // Delete the row from the data source
    [[NSFileManager defaultManager] removeItemAtPath:[_romPath stringByAppendingPathComponent:[_romList objectAtIndex:index]] error:nil];
    [self reloadROMList:NO];
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
  }
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
  
  self.title = NSLocalizedString(@"ROMS", nil);
  
  UIBarButtonItem* settingsButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"SETTINGS", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(settings)];
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
  
  // set it for the ROMs
  SISetSystemPath([documentsPath UTF8String]);
  // and set it+sram for SRAM
  SISetSRAMPath([[documentsPath stringByAppendingPathComponent:@"sram"] UTF8String]);
  
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
  [_sectionTitles release];
  _sectionTitles = nil;
  [_sectionMarkers release];
  _sectionMarkers = nil;
  [_romPath release];
  _romPath = nil;
  
  [_fsTimer invalidate];
  _fsTimer = nil;
  
  [super dealloc];
}

@end
