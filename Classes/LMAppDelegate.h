//
//  LMAppDelegate.h
//  SiOS
//
//  Created by Lucas Menge on 1/2/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>
#import "CHBgDropboxSync.h"

@class LMEmulatorController;

@interface LMAppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate, DBRestClientDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UIViewController *viewController;

@property (nonatomic) BOOL skipPlayerOne;
@property (nonatomic) BOOL askToReplacePlayerOneAgain;
@property (nonatomic) int playerOneNumber;

@end
