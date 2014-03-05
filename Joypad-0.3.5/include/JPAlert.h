//
//  JPAlert.h
//  JoypadiOSSample
//
//  Created by Warner Skoch on 6/20/12.
//  Copyright (c) 2012 Joypad Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol JPAlertDelegate;

@interface JPAlert : UIWindow
@property (nonatomic, assign) id /*<JPAlertDelegate>*/ alertDelegate;

//! Shows an autoreleased alert that is Joypad enabled for player 1.
+(void)showWithTitle:(NSString *)title
             message:(NSString *)message 
            delegate:(id /*<JPAlertDelegate>*/)delegate 
        buttonTitles:(NSString *)buttonTitles, ... NS_REQUIRES_NIL_TERMINATION;


//! Inits an alert that is Joypad enabled for player 1.  You must call -show
//! to display the alert, and you're responsible for releasing it.
-(id)initWithTitle:(NSString *)title
           message:(NSString *)message
          delegate:(id /*<JPAlertDelegate>*/)delegate 
      buttonTitles:(NSString *)buttonTitles, ... NS_REQUIRES_NIL_TERMINATION;

-(void)show;
-(void)dismissWithButtonIndex:(NSInteger)buttonIndex;

//! By default, Notifications will be displayed using the current
//! orientation of the device.  If your menu is locked into a specific 
//! orientation, pass it in here.
//!
//! For example:
//!   [JPNotification lockNotificationOrientation:UIInterfaceOrientationLandscapeRight]
+(void)lockNotificationOrientation:(UIInterfaceOrientation)orientation;

//! Display notifications using the device's orientation again.
+(void)unlockNotificationOrientation;
@end


@protocol JPAlertDelegate <NSObject>
@optional

//! Reports which button was clicked. Alerts are automatically dismissed when a 
//! button is clicked.  
-(void)alert:(JPAlert *)alert didDismissWithButtonIndex:(NSInteger)buttonIndex;
@end
