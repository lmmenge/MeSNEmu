//
//  LMAppDelegate.m
//  MeSNEmu
//
//  Created by Lucas Menge on 1/2/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import "LMAppDelegate.h"

#import "LMROMBrowserController.h"
#import "LMEmulatorController.h"

// TODO: LM: Better save UI to allow for multiple slots
// TODO: LM: save/show screenshots for save states in the save state manager

@implementation LMAppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;

- (void)dealloc
{
  [_window release];
  [_viewController release];
  [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self launch];
    BOOL callPerformActionForShortcutItem = YES;
    // Checks if force touch is available, but I'm not sure what will happen if this method is called on devices < 9.0
    if([self forceTouchAvailable])
    {
        [self threeDTouchSetup];

        UIApplicationShortcutItem *shortcutItem = [launchOptions objectForKeyedSubscript:UIApplicationLaunchOptionsShortcutItemKey];
        if(shortcutItem != nil)
        {
            [self openShortcut: shortcutItem];
            callPerformActionForShortcutItem = NO;
        }
    }
    return callPerformActionForShortcutItem;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    if([self forceTouchAvailable]) [self threeDTouchSetup];
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler
{
    BOOL shortcutItemWasOpened = [self openShortcut:shortcutItem];
    completionHandler(shortcutItemWasOpened);
}

- (BOOL)openShortcut:(UIApplicationShortcutItem *)shortcutItem
{
    BOOL opened = NO;
    
    NSString *gameName = shortcutItem.localizedTitle;
    if(gameName != nil)
    {
        LMEmulatorController* emulator = [[LMEmulatorController alloc] init];
        emulator.romFileName = gameName;
        [self.viewController presentViewController:emulator animated:YES completion:nil];
        opened = YES;
    }
    
    return opened;
}

- (BOOL)forceTouchAvailable
{
    if([[[UIScreen mainScreen] traitCollection] forceTouchCapability] == UIForceTouchCapabilityAvailable)
    {
        NSLog(@"Force Touch Available");
        return YES;
    }
    NSLog(@"Force Touch Unavailable");
    return NO;
}

- (void)threeDTouchSetup
{
    NSString *key = @"RECENTLY_TOUCHED";
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *recentGames = [defaults stringArrayForKey:key];
    if(recentGames != nil)
    {
        NSMutableArray *shortcutItems = [[NSMutableArray alloc] init];
        NSString *shortcutType = @"com.MeSNEmu.recent";
        UIApplicationShortcutIcon *shortcutFavoriteIcon = [UIApplicationShortcutIcon iconWithType:UIApplicationShortcutIconTypeFavorite];
        for(int i = 0; i < [recentGames count]; i++)
        {
            UIApplicationShortcutItem *shortcutItem = [[UIApplicationShortcutItem alloc]
                                                         initWithType:shortcutType
                                                         localizedTitle:recentGames[i]
                                                         localizedSubtitle:nil
                                                         icon:shortcutFavoriteIcon
                                                         userInfo:nil];
            [shortcutItems addObject:shortcutItem];
        }
        [UIApplication sharedApplication].shortcutItems = shortcutItems;
    }
}

- (void)launch
{
#if TARGET_IPHONE_SIMULATOR
    // where are we?
    NSLog(@"\nDocuments Directory:\n%@\n\n", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]);
#endif
    
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    
    LMROMBrowserController* romBrowser = [[LMROMBrowserController alloc] init];
    UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:romBrowser];
    self.viewController = nav;
    [nav release];
    [romBrowser release];
    
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
}

@end
