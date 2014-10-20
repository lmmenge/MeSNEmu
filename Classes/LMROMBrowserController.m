//
//  LMROMBrowserController.m
//  MeSNEmu
//
//  Created by Lucas Menge on 1/3/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import "LMROMBrowserController.h"

#import "../SNES9XBridge/Snes9xMain.h"

#import "LMEmulatorController.h"
#import "LMSaveManager.h"
#import "LMSettingsController.h"

static NSString* const LMFileOrganizationVersion = @"LMFileOrganizationVersion";
static int const LMFileOrganizationVersionNumber = 1;

@interface LMFileListItem : NSObject
{
  BOOL _hasDetails;
  NSString* _displayName;
  NSString* _displayDetails;
  NSString* _fileName;
}

@property BOOL hasDetails;
@property (retain) NSString* displayName;
@property (retain) NSString* displayDetails;
@property (retain) NSString* fileName;

+ (BOOL)isROMExtension:(NSString*)lowerCaseExtension;
@end

#pragma mark -

@implementation LMFileListItem

@synthesize hasDetails = _hasDetails;
@synthesize displayName = _displayName;
@synthesize displayDetails = _displayDetails;
@synthesize fileName = _fileName;

+ (BOOL)isROMExtension:(NSString*)lowerCaseExtension
{
  if(lowerCaseExtension != nil
     && ([lowerCaseExtension compare:@"smc"] == NSOrderedSame
         || [lowerCaseExtension compare:@"sfc"] == NSOrderedSame
         || [lowerCaseExtension compare:@"zip"] == NSOrderedSame))
    return YES;
  return NO;
}

- (void)dealloc
{
  self.displayName = nil;
  self.displayDetails = nil;
  self.fileName = nil;
  [super dealloc];
}

@end

#pragma mark -

@interface LMROMBrowserController(Privates) <UISearchDisplayDelegate>

@end

#pragma mark -

@implementation LMROMBrowserController(Privates)

- (void)LM_moveLegacyFilesToDocumentsFolder
{
  NSFileManager* fm = [NSFileManager defaultManager];
  // SRAM
  NSString* sramPath = [_romPath stringByAppendingPathComponent:@"SRAM"];
  if([sramPath compare:_romPath] != NSOrderedSame)
  {
    NSArray* sramList = [fm contentsOfDirectoryAtPath:sramPath error:nil];
    for(NSString* file in sramList)
      [fm moveItemAtPath:[sramPath stringByAppendingPathComponent:file] toPath:[_romPath stringByAppendingPathComponent:file] error:nil];
    [fm removeItemAtPath:sramPath error:nil];
  }
  // Saves
  NSString* savesPath = [LMSaveManager legacy_pathForSaveStates];
  if([savesPath compare:_romPath] != NSOrderedSame)
  {
    NSArray* savesList = [fm contentsOfDirectoryAtPath:savesPath error:nil];
    for(NSString* file in savesList)
      [fm moveItemAtPath:[savesPath stringByAppendingPathComponent:file] toPath:[_romPath stringByAppendingPathComponent:file] error:nil];
    [fm removeItemAtPath:savesPath error:nil];
  }
  
  // Running Saves
  NSString* runningSavesPath = [LMSaveManager legacy_pathForRunningStates];
  if([runningSavesPath compare:_romPath] != NSOrderedSame)
  {
    NSArray* runningSavesList = [fm contentsOfDirectoryAtPath:runningSavesPath error:nil];
    for(NSString* file in runningSavesList)
      [fm moveItemAtPath:[runningSavesPath stringByAppendingPathComponent:file] toPath:[_romPath stringByAppendingPathComponent:file] error:nil];
    [fm removeItemAtPath:runningSavesPath error:nil];
  }
  
  // renaming saves .### to .###.frz
  NSArray* fileList = [fm contentsOfDirectoryAtPath:_romPath error:nil];
  for(NSString* file in fileList)
  {
    NSString* extension = [file pathExtension];
    if([extension length] == 3)
    {
      unichar char0 = [extension characterAtIndex:0];
      unichar char1 = [extension characterAtIndex:1];
      unichar char2 = [extension characterAtIndex:2];
      if(char0 >= '0' && char0 <= '9'
         && char1 >= '0' && char1 <= '9'
         && char2 >= '0' && char2 <= '9')
      {
        [fm moveItemAtPath:[_romPath stringByAppendingPathComponent:file] toPath:[_romPath stringByAppendingPathComponent:[file stringByAppendingPathExtension:@"frz"]] error:nil];
      }
    }
  }
  
  [[NSUserDefaults standardUserDefaults] setInteger:LMFileOrganizationVersionNumber forKey:LMFileOrganizationVersion];
}

- (NSArray*)LM_relatedFilesForROMNamed:(NSString*)romName
{
  NSFileManager* fm = [NSFileManager defaultManager];
  NSArray* filesList = [fm contentsOfDirectoryAtPath:_romPath error:nil];
  NSMutableArray* list = [NSMutableArray array];
  NSString* romNameWithoutExtension = [romName stringByDeletingPathExtension];
  for(NSString* file in filesList)
  {
    if([file rangeOfString:romNameWithoutExtension].location == 0)
    {
      NSString* extension = [[file pathExtension] lowercaseString];
      if([LMFileListItem isROMExtension:extension] == YES)
        [list addObject:file];
      else if([extension compare:@"srm"] == NSOrderedSame)
        [list addObject:file];
      else if([extension compare:@"frz"] == NSOrderedSame)
        [list addObject:file];
    }
  }
  return [[list copy] autorelease];
}

- (void)LM_reloadROMList:(BOOL)updateTable
{
  if([[NSUserDefaults standardUserDefaults] integerForKey:LMFileOrganizationVersion] != LMFileOrganizationVersionNumber)
    [self LM_moveLegacyFilesToDocumentsFolder];
    
  BOOL searching = self.searchDisplayController.isActive;
  NSString* filterString = self.searchDisplayController.searchBar.text;
  
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
  BOOL isROMDetail = (_detailsItem != nil);
  NSArray* tempItemList = nil;
  NSMutableArray* tempSectionTitles = nil;
  NSMutableArray* tempSectionMarkers = nil;
  if(isROMDetail == NO)
  {
    // listing all ROMs
    NSArray* proposedFileList = [fm contentsOfDirectoryAtPath:_romPath error:nil];
    NSMutableArray* onlyROMsItemList = [NSMutableArray array];
    for(NSString* file in proposedFileList)
    {
      NSString* extension = [[file pathExtension] lowercaseString];
      if([LMFileListItem isROMExtension:extension] == YES)
      {
        LMFileListItem* item = [[LMFileListItem alloc] init];
        item.displayName = [file stringByDeletingPathExtension];
        item.fileName = file;
        NSString* sramPath = [_sramPath stringByAppendingPathComponent:[[file stringByDeletingPathExtension] stringByAppendingPathExtension:@"srm"]];
        if([fm fileExistsAtPath:sramPath] == YES)
          item.hasDetails = YES;
        else
        {
          for(int i=0; i<10; i++)
          {
            if([LMSaveManager hasStateForROMNamed:file slot:i] == YES)
            {
              item.hasDetails = YES;
              break;
            }
          }
        }
        [onlyROMsItemList addObject:item];
        [item release];
      }
    }
    proposedFileList = onlyROMsItemList;
    
    // sort symbols first
    NSMutableArray* symbolsList = [NSMutableArray array];
    NSMutableArray* alphabetList = [NSMutableArray array];
    for(LMFileListItem* file in proposedFileList)
    {
      unichar firstLetter = [[file.displayName uppercaseString] characterAtIndex:0];
      if(firstLetter < 'A' || firstLetter > 'Z')
        [symbolsList addObject:file];
      else
        [alphabetList addObject:file];
    }
    [symbolsList addObjectsFromArray:alphabetList];
    proposedFileList = symbolsList;
    
    // build sections and real file names
    NSMutableArray* tempRomList = [NSMutableArray array];
    tempSectionTitles = [NSMutableArray array];
    tempSectionMarkers = [NSMutableArray array];
    unichar lastChar = '\0';
    for(LMFileListItem* file in proposedFileList)
    {
      if(searching == YES && [file.fileName rangeOfString:filterString options:NSCaseInsensitiveSearch].location == NSNotFound)
        continue;
      
      unichar firstLetter = [[file.displayName uppercaseString] characterAtIndex:0];
      if(firstLetter < 'A' || firstLetter > 'Z')
        firstLetter = '#';
      if(firstLetter != lastChar)
      {
        lastChar = firstLetter;
        [tempSectionTitles addObject:[NSString stringWithCharacters:&lastChar length:1]];
        [tempSectionMarkers addObject:[NSNumber numberWithInt:[tempRomList count]]];
      }
      [tempRomList addObject:file];
    }
    tempItemList = tempRomList;
  }
  else
  {
    NSMutableArray* itemsList = [NSMutableArray array];
    tempSectionTitles = [NSMutableArray array];
    tempSectionMarkers = [NSMutableArray array];
    // rom item
    NSString* romPath = [_romPath stringByAppendingPathComponent:_detailsItem.fileName];
    if([fm fileExistsAtPath:romPath] == YES)
    {
      [tempSectionTitles addObject:NSLocalizedString(@"CARTRIDGE_FILES", nil)];
      [tempSectionMarkers addObject:[NSNumber numberWithInt:[itemsList count]]];
      LMFileListItem* romItem = [[LMFileListItem alloc] init];
      romItem.displayName = _detailsItem.displayName;
      //romItem.displayName = NSLocalizedString(@"GAME_FILE", nil);
      //romItem.displayDetails = _detailsItem.displayName;
      romItem.fileName = _detailsItem.fileName;
      [itemsList addObject:romItem];
      [romItem release];
    }
    // sram
    NSString* sramPath = [_sramPath stringByAppendingPathComponent:[[_detailsItem.fileName stringByDeletingPathExtension] stringByAppendingPathExtension:@"srm"]];
    if([fm fileExistsAtPath:sramPath] == YES)
    {
      LMFileListItem* sramItem = [[LMFileListItem alloc] init];
      sramItem.displayName = NSLocalizedString(@"SRAM_FILE", nil);
      sramItem.fileName = [sramPath lastPathComponent];
      sramItem.displayDetails = sramItem.fileName;
      [itemsList addObject:sramItem];
      [sramItem release];
    }
    // saves
    BOOL hasSaves = NO;
    for(int i=0; i<10; i++)
    {
      if([LMSaveManager hasStateForROMNamed:_detailsItem.fileName slot:i] == YES)
      {
        if(hasSaves == NO)
        {
          [tempSectionTitles addObject:NSLocalizedString(@"SAVE_POINTS", nil)];
          [tempSectionMarkers addObject:[NSNumber numberWithInt:[itemsList count]]];
          hasSaves = YES;
        }
        LMFileListItem* saveItem = [[LMFileListItem alloc] init];
        if(i == 0)
          saveItem.displayName = NSLocalizedString(@"LAST_PLAYED_SPOT", nil);
        else
          saveItem.displayName = [NSString stringWithFormat:NSLocalizedString(@"SAVE_FILE_SLOT_%i", nil), i];
        saveItem.fileName = [[LMSaveManager pathForSaveOfROMName:_detailsItem.fileName slot:i] lastPathComponent];
        saveItem.displayDetails = saveItem.fileName;
        [itemsList addObject:saveItem];
        [saveItem release];
      }
      else if(i > 0)
        break;
    }
    
    tempItemList = itemsList;
  }
  
  BOOL different = NO;
  if(searching == YES)
    different = ([_filteredRomList count] != [tempItemList count]);
  else
    different = ([_romList count] != [tempItemList count]);
  
  if(different == NO)
  {
    for(int i=0; i<[tempItemList count]; i++)
    {
      LMFileListItem* romA = nil;
      if(searching == YES)
        romA = [_filteredRomList objectAtIndex:i];
      else
        romA = [_romList objectAtIndex:i];
      LMFileListItem* romB = [tempItemList objectAtIndex:i];
      if([romA.fileName isEqualToString:romB.fileName] == NO)
      {
        different = YES;
        break;
      }
      if(romA.hasDetails != romB.hasDetails)
      {
        different = YES;
        break;
      }
    }
  }
  if(different)
  {
    if(searching == YES)
    {
      [_filteredRomList release];
      _filteredRomList = [tempItemList copy];
      [_filteredSectionTitles release];
      _filteredSectionTitles = [tempSectionTitles copy];
      [_filteredSectionMarkers release];
      _filteredSectionMarkers = [tempSectionMarkers copy];
    }
    else
    {
      [_romList release];
      _romList = [tempItemList copy];
      [_sectionTitles release];
      _sectionTitles = [tempSectionTitles copy];
      [_sectionMarkers release];
      _sectionMarkers = [tempSectionMarkers copy];
      if(updateTable == YES)
        [self.tableView reloadData];
    }
  }
}
- (void)LM_reloadROMList
{
  if(self.searchDisplayController.isActive == NO)
    [self LM_reloadROMList:YES];
}

- (void)LM_settingsTapped
{
  LMSettingsController* c = [[LMSettingsController alloc] init];
  UINavigationController* n = [[UINavigationController alloc] initWithRootViewController:c];
  n.modalPresentationStyle = UIModalPresentationFormSheet;
  [self presentViewController:n animated:YES completion:nil];
  [c release];
  [n release];
}

- (LMFileListItem*)LM_romItemForTableView:(UITableView*)tableView indexPath:(NSIndexPath*)indexPath
{
  int index = indexPath.row;
  if(tableView == self.searchDisplayController.searchResultsTableView)
  {
    index += [[_filteredSectionMarkers objectAtIndex:indexPath.section] intValue];
    return [_filteredRomList objectAtIndex:index];
  }
  else
  {
    index += [[_sectionMarkers objectAtIndex:indexPath.section] intValue];
    return [_romList objectAtIndex:index];
  }
}

#pragma mark UISearchDisplayControllerDelegate

- (BOOL)searchDisplayController:(UISearchDisplayController*)controller shouldReloadTableForSearchString:(NSString*)searchString
{
  [self LM_reloadROMList:NO];
  return YES;
}

@end

#pragma mark -

@implementation LMROMBrowserController

@synthesize detailsItem = _detailsItem;

@end

#pragma mark -

@implementation LMROMBrowserController(UITableViewController)

- (NSArray*)sectionIndexTitlesForTableView:(UITableView*)tableView
{
  if(_detailsItem != nil)
    return nil;
  if(tableView == self.searchDisplayController.searchResultsTableView)
    return _filteredSectionTitles;
  else
    return _sectionTitles;
}

- (NSInteger)tableView:(UITableView*)tableView sectionForSectionIndexTitle:(NSString*)title atIndex:(NSInteger)index
{
  return index;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
  // Return the number of sections.
  if(tableView == self.searchDisplayController.searchResultsTableView)
    return [_filteredSectionTitles count];
  else
    return [_sectionTitles count];
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
  if(tableView == self.searchDisplayController.searchResultsTableView)
    return [_filteredSectionTitles objectAtIndex:section];
  else
    return [_sectionTitles objectAtIndex:section];
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  // Return the number of rows in the section.
  int sectionStart, sectionEnd;
  if(tableView == self.searchDisplayController.searchResultsTableView)
  {
    sectionStart = [[_filteredSectionMarkers objectAtIndex:section] intValue];
    sectionEnd = [_filteredRomList count];
    if(section < [_filteredSectionMarkers count]-1)
      sectionEnd = [[_filteredSectionMarkers objectAtIndex:(section+1)] intValue];
  }
  else
  {
    sectionStart = [[_sectionMarkers objectAtIndex:section] intValue];
    sectionEnd = [_romList count];
    if(section < [_sectionMarkers count]-1)
      sectionEnd = [[_sectionMarkers objectAtIndex:(section+1)] intValue];
  }
  
  return sectionEnd-sectionStart;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  static NSString* CellIdentifier = @"Cell";
  
  UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if(cell == nil)
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
  
  LMFileListItem* item = [self LM_romItemForTableView:tableView indexPath:indexPath];
  cell.textLabel.text = item.displayName;
  cell.detailTextLabel.text = item.displayDetails;
  if(item.hasDetails)
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
  else
    cell.accessoryType = UITableViewCellAccessoryNone;
  
  return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  LMEmulatorController* emulator = [[LMEmulatorController alloc] init];
  LMFileListItem* item = [self LM_romItemForTableView:tableView indexPath:indexPath];
  if(_detailsItem == nil)
    emulator.romFileName = item.fileName;
  else
  {
    emulator.romFileName = _detailsItem.fileName;
    NSString* extension = [[item.fileName pathExtension] lowercaseString];
    if([LMFileListItem isROMExtension:extension] == YES)
    {
      // do nothing here either
    }
    else if([extension compare:@"srm"] == NSOrderedSame)
    {
      // do nothing here
    }
    else if([extension compare:@"frz"] == NSOrderedSame)
    {
      // load the selected save state
      emulator.initialSaveFileName = item.fileName;
    }
  }
  [self.searchDisplayController setActive:NO];
  [self.navigationController presentViewController:emulator animated:YES completion:nil];
  [emulator release];
}

- (void)tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath
{
  LMROMBrowserController* detailsBrowser = [[LMROMBrowserController alloc] initWithStyle:UITableViewStyleGrouped];
  LMFileListItem* item = [self LM_romItemForTableView:tableView indexPath:indexPath];
  detailsBrowser.detailsItem = item;
  [self.navigationController pushViewController:detailsBrowser animated:YES];
  [detailsBrowser release];
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
  if(editingStyle == UITableViewCellEditingStyleDelete)
  {
    // Delete the row from the data source
    int amount = [self tableView:tableView numberOfRowsInSection:indexPath.section];
    LMFileListItem* item = [self LM_romItemForTableView:tableView indexPath:indexPath];
    [[NSFileManager defaultManager] removeItemAtPath:[_romPath stringByAppendingPathComponent:item.fileName] error:nil];
    [self LM_reloadROMList:NO];
    
    BOOL isROMDetail = (_detailsItem != nil);
    if(isROMDetail == YES)
    {
      if([_romList count] == 0
         || (indexPath.section == 0 && indexPath.row == 0))
      {
        [self.navigationController popViewControllerAnimated:YES];
        return;
      }
    }
    if(amount == 1)
      [tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
    else
      [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
  }
}

@end

#pragma mark -

@implementation LMROMBrowserController(UIViewController)

- (id)initWithStyle:(UITableViewStyle)style
{
  self = [super initWithStyle:style];
  if(self)
  {
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
  
#ifdef LM_LOADING_SCREENSHOTS
  return;
#endif
  
  if(_detailsItem == nil)
  {
    self.title = NSLocalizedString(@"ROMS", nil);
    
    UISearchBar* searchbar = [[UISearchBar alloc] init];
    [searchbar sizeToFit];
    self.tableView.tableHeaderView = searchbar;
    [searchbar release];
    UISearchDisplayController* searchController = [[UISearchDisplayController alloc] initWithSearchBar:searchbar contentsController:self];
    searchController.delegate = self;
    searchController.searchResultsDataSource = self;
    searchController.searchResultsDelegate = self;
  }
  else
    self.title = _detailsItem.displayName;
  
  UIBarButtonItem* settingsButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"SETTINGS", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(LM_settingsTapped)];
  self.navigationItem.rightBarButtonItem = settingsButton;
  [settingsButton release];
  
  if(_romList != nil)
  {
    [_romList release];
    _romList = nil;
  }
  
  // documents folder
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString* documentsPath = [paths objectAtIndex:0];
  
  // set it for the ROMs
  _romPath = [documentsPath copy];
  SISetSystemPath([_romPath UTF8String]);
  // and set it for SRAM
  _sramPath = [_romPath copy];
  SISetSRAMPath([_sramPath UTF8String]);
  
  [self LM_reloadROMList];
}

- (void)viewDidUnload
{
  [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  [self LM_reloadROMList];
  
  //_fsTimer = [[NSTimer timerWithTimeInterval:5 target:self selector:@selector(LM_reloadROMList) userInfo:nil repeats:YES] retain];
  //[[NSRunLoop mainRunLoop] addTimer:_fsTimer forMode:NSDefaultRunLoopMode];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(LM_reloadROMList) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  
  [_fsTimer invalidate];
  _fsTimer = nil;
  
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (BOOL)prefersStatusBarHidden
{
  return NO;
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
  
  //[self.searchDisplayController release];
  
  [_romList release];
  _romList = nil;
  [_sectionTitles release];
  _sectionTitles = nil;
  [_sectionMarkers release];
  _sectionMarkers = nil;
  
  [_filteredRomList release];
  _filteredRomList = nil;
  [_filteredSectionTitles release];
  _filteredSectionTitles = nil;
  [_filteredSectionMarkers release];
  _filteredSectionMarkers = nil;
  
  self.detailsItem = nil;
  [_romPath release];
  _romPath = nil;
  [_sramPath release];
  _sramPath = nil;
  
  [_fsTimer invalidate];
  _fsTimer = nil;
  
  [super dealloc];
}

@end
