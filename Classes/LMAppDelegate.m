//
//  LMAppDelegate.m
//  MeSNEmu
//
//  Created by Lucas Menge on 1/2/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import "LMAppDelegate.h"

#import "LMROMBrowserController.h"
#import "LMDropBoxBrowserViewController.h"
#import <DropboxSDK/DropboxSDK.h>

// TODO: LM: Better save UI to allow for multiple slots
// TODO: LM: save/show screenshots for save states in the save state manager

@implementation LMAppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if TARGET_IPHONE_SIMULATOR
  // where are we?
  NSLog(@"\nDocuments Directory:\n%@\n\n", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]);
#endif
    
  [self setUpDropBox];
  
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  
//  LMROMBrowserController* romBrowser = [[LMROMBrowserController alloc] init];
    LMDropBoxBrowserViewController *romBrowser = [LMDropBoxBrowserViewController new];
  UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:romBrowser];
  self.viewController = nav;

  self.window.rootViewController = self.viewController;
  [self.window makeKeyAndVisible];
  return YES;
}

- (void)setUpDropBox {
    NSString *dbCreds = [[NSBundle mainBundle] pathForResource:@"dropbox_credentials" ofType:@"json" inDirectory:@"dropbox_credentials"];
    if (!dbCreds) {
        NSLog(@"No DropBox credentials found. To enable DropBox, create a dropbox_credentials.json file in the dropbox_credentials directory, following the example in there.");
    }
    
    NSString *content = [NSString stringWithContentsOfFile:dbCreds encoding:NSUTF8StringEncoding error:nil];
    NSData *jsonData = [content dataUsingEncoding:NSUTF8StringEncoding];
    NSError *e;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:nil error:&e];
    if (e) {
        NSLog(@"Couldn't parse dropbox_credentials.json: %@", [e localizedDescription]);
        return;
    }
    
    DBSession *dbSession = [[DBSession alloc]
                            initWithAppKey:[dict valueForKey:@"app_key"]
                            appSecret:[dict valueForKey:@"secret"]
                            root:kDBRootAppFolder];
    [DBSession setSharedSession:dbSession];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url
  sourceApplication:(NSString *)source annotation:(id)annotation {
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        if ([[DBSession sharedSession] isLinked]) {
            NSLog(@"App linked successfully!");
            // At this point you can start making API calls
        }
        return YES;
    }
    // Add whatever other url handling code your app requires here
    return NO;
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
