//
//  LMAppDelegate.m
//  SiOS
//
//  Created by Lucas Menge on 1/2/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import "LMAppDelegate.h"
#import "LMROMBrowserController.h"
#import "LMSettingsController.h"
#import "JPSDK.h"

// TODO: LM: Better save UI to allow for multiple slots
// TODO: LM: save/show screenshots for save states in the save state manager

@interface LMAppDelegate()
@property (nonatomic) BOOL shouldDisplayAlert;
@property (nonatomic) DBRestClient *restClient;
@end

@implementation LMAppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;
@synthesize skipPlayerOne = _skipPlayerOne;
@synthesize askToReplacePlayerOneAgain = _askToReplacePlayerOneAgain;

- (void)dealloc
{
  [_window release];
  [_viewController release];
  [super dealloc];
}

#pragma mark Dropbox

- (DBRestClient *)restClient {
    if (!_restClient) {
        _restClient =
        [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        _restClient.delegate = self;
    }
    return _restClient;
}

- (void)setupDropbox
{
    DBSession* dbSession = [[[DBSession alloc] initWithAppKey:@"kqmc4kbeev7tyu6"
                                                    appSecret:@"trf0fvib1xbheuq"
                                                         root:kDBRootAppFolder]
                                                              autorelease];
    [DBSession setSharedSession:dbSession];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        if ([[DBSession sharedSession] isLinked]) {
            NSLog(@"App linked successfully!");
            // At this point you can start making API calls
            
            [CHBgDropboxSync clearLastSyncData];
            [CHBgDropboxSync start];
        }
        return YES;
    }
    // Add whatever other url handling code your app requires here
    return NO;
}

- (void)syncDropboxFolder
{
    [self.restClient loadMetadata:@"/"];    
}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    if (metadata.isDirectory) {
        
        // documents folder
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths objectAtIndex:0];
        
        NSFileManager *fm = [NSFileManager defaultManager];
        NSArray *localFilesList = [fm contentsOfDirectoryAtPath:documentsPath error:nil];
        NSMutableSet *localFilesSet = [NSMutableSet setWithArray:localFilesList];
        [localFilesSet removeObject:@"Inbox"];
        
        for (DBMetadata *file in metadata.contents) {
            
            if([self checkIfFileExistsLocally:file])
            {
                NSComparisonResult result = [self fileHasBeenModified:file];
                
                if (result == NSOrderedDescending)
                {
                    // Local file is newer
                    NSLog(@"local file is newer");
                }
                
                else if (result == NSOrderedAscending)
                {
                    // Dropbox file is newer
                    NSLog(@"remote file changes detected: %@", file.filename);
                    [self saveFileFromDropbox:file];
                    [localFilesSet removeObject:file.filename];
                }
                
                else if (result == NSOrderedSame)
                {
                    [localFilesSet removeObject:file.filename];
                }
            }
            else
            {
                NSLog(@"New file detected: %@", file.filename);
                [self saveFileFromDropbox:file];
            }
        }
        
        if(![localFilesSet count] == 0) {
            
            for(NSString *fileName in localFilesSet)
            {
                NSString *filePath = [documentsPath stringByAppendingPathComponent:fileName];
                [self.restClient uploadFile:fileName toPath:@"/" withParentRev:nil fromPath:filePath];
            }
        }
    }
}

- (NSComparisonResult)fileHasBeenModified:(DBMetadata *)dropboxFile
{
    // documents folder
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *localFilePath = [documentsPath stringByAppendingPathComponent:dropboxFile.filename];
    
    NSDictionary *fileAttribs = [fm attributesOfItemAtPath:localFilePath error:nil];
    
    NSDate *localModificationDate = [fileAttribs fileModificationDate];
    
    return [localModificationDate compare:dropboxFile.lastModifiedDate];

}

- (BOOL)checkIfFileExistsLocally:(DBMetadata *)dropboxFile
{
    // documents folder
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *localFilesList = [fm contentsOfDirectoryAtPath:documentsPath error:nil];
    
    for(NSString *localFile in localFilesList)
    {
        if([dropboxFile.filename isEqualToString:localFile])
        {
            return YES;
        }
    }
    
    return NO;
}

- (void)saveFileFromDropbox:(DBMetadata *)file
{
    // documents folder
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    NSString *savePath = [documentsPath stringByAppendingPathComponent:file.filename];
    
    [self.restClient loadFile:file.path intoPath:savePath];
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error {
    NSLog(@"Error loading metadata: %@", error);
}
- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)localPath {
    NSLog(@"File loaded into path: %@", localPath);
}

- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error {
    NSLog(@"There was an error loading the file - %@", error);
}

#pragma mark JoypadDelegate

- (void)setupJoypad
{
    JPManager *manager = [JPManager sharedManager];
    [manager setApplicationName:@"SNES"];
    [manager setMaxPlayerCount:5];
    [manager setDisplayDebugFrames:NO];
    [manager setBustImageCache:NO];
    // If you have created custom JPControllerLayout(s), specify all
    // images used by them here:
    [manager setImageNames:[NSArray arrayWithObjects:
                            // @"image.png",
                            // @"image2.png",
                            nil]];
    [manager setControllerLayout:[JPControllerLayout snesLayout]];
    [manager setGameState:kJPGameStateMenu];
    [manager addListener:self];
    
    self.skipPlayerOne = NO;
    self.askToReplacePlayerOneAgain = YES;
    self.shouldDisplayAlert = YES;
}

- (void)joypadManager:(JPManager *)manager deviceDidConnect:(JPDevice *)device
{
    NSLog(@"app delegate did connect");
    if(self.askToReplacePlayerOneAgain) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Joypad Detected!"
                                                        message:@"Do you want to replace the touchscreen controls?"
                                                       delegate:self
                                              cancelButtonTitle:@"No (don't ask again)"
                                              otherButtonTitles:@"Yes", @"No", nil];
        
        if (self.shouldDisplayAlert) {
            [alert show];
            [alert release];
            self.shouldDisplayAlert = NO;
        }
    }    
}

- (void)joypadManager:(JPManager *)manager deviceDidDisconnect:(JPDevice *)device
{
    NSLog(@"app delegate did disconnect");
    if(manager.devicesCount == 0)
    {
        self.askToReplacePlayerOneAgain = YES;
        self.shouldDisplayAlert = YES;
        
        double oldTransparencyValue = [[NSUserDefaults standardUserDefaults] doubleForKey:kLMSettingsOldTransparencyValue];
        
        [[NSUserDefaults standardUserDefaults] setDouble:oldTransparencyValue forKey:kLMSettingsHideButtons];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kLMSettingsChangedNotification object:nil userInfo:nil];
    }
}

#pragma mark AlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];

    if(buttonIndex == alertView.cancelButtonIndex)
    {
        self.skipPlayerOne = YES;
        self.askToReplacePlayerOneAgain = NO;
    }
    else if([title isEqualToString:@"No"])
    {
        self.skipPlayerOne = YES;
    }
    else if([title isEqualToString:@"Yes"])
    {
        self.skipPlayerOne = NO;
        self.askToReplacePlayerOneAgain = NO;
        
        self.playerOneNumber = [[JPManager sharedManager] devicesCount];
        
        double currentTransparencyValue = [[NSUserDefaults standardUserDefaults] doubleForKey:kLMSettingsHideButtons];
        
        [[NSUserDefaults standardUserDefaults] setDouble:currentTransparencyValue forKey:kLMSettingsOldTransparencyValue];
        
        [[NSUserDefaults standardUserDefaults] setDouble:0.0 forKey:kLMSettingsHideButtons];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kLMSettingsChangedNotification object:nil userInfo:nil];
}
    
    self.shouldDisplayAlert = YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
  
  LMROMBrowserController* romBrowser = [[LMROMBrowserController alloc] init];
  UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:romBrowser];
  self.viewController = nav;
  [nav release];
  [romBrowser release];

    [self setupJoypad];
    [self setupDropbox];

    /*if([[DBSession sharedSession] isLinked]) {
        [self syncDropboxFolder];
    }*/

    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    
    [CHBgDropboxSync clearLastSyncData];
    [CHBgDropboxSync start];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

@end
