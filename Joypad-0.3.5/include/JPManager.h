//
//  JPManager.h
// 
//  Created by Lou Zell on 2/26/11.  
//  Copyright 2011 Joypad Inc. All rights reserved.
// 
//  Please email questions to lou@getjoypad.com
//  __________________________________________________________________________
//


#import <Foundation/Foundation.h>
#import "JPConstants.h"

// Forward declarations.
@class JPDevice;
@class JPControllerLayout;

@protocol JPManagerDelegate;
@protocol JPDeviceDelegate;

// Exceptions.
extern NSString *const JPManagerException;

@interface JPManager : NSObject

+(JPManager *)sharedManager;

// Update the SDK on the state of your game.  The SDK will handle when it should
// search for devices running Joypad.
@property (nonatomic, assign) JPGameState gameState;

#pragma mark - Development Aids
@property (nonatomic, assign) BOOL bustImageCache;
@property (nonatomic, assign) BOOL displayDebugFrames;

#pragma mark - Configuration
// Used to display the "Connected to <your-game-here>!" modal on Joypad Controller.
@property (nonatomic, copy) NSString *applicationName;

// See the JPManagerDelegate protocol at the bottom of this header.
@property (nonatomic, assign) id<JPManagerDelegate> delegate;

// Sets the maximum number of Joypads to connect to.  JPManager will automatically stop
// searching for devices once the max player count is hit. Defaults to 1.
@property (nonatomic, assign) NSUInteger maxPlayerCount;

// List all images that you use for your controller layouts here.  Joypad Controller
// will request all images upon connection and cache them.  This way, layout changes
// will occur instantly. During development you can set -bustImageCache to YES so
// that changes to your image files are always reflected on Joypad Controller.
@property (nonatomic, copy) NSArray *imageNames;

// See the JPControllerLayout.h header for instructions on building a custom layout.
@property (nonatomic, retain) JPControllerLayout *controllerLayout;

// Turns off the Joypad launch window.  If you do this you must add a Joypad icon
// to your main menu and/or add our Joypad splash page to your game.
@property (nonatomic, assign) BOOL launchWindowDisabled;

#pragma mark - Status
// Contains all devices that are currently connected.  You can receive events 
// from connected devices.  Make sure to set a delegate object for each device
// that you are interested in receiving events from.  This could be done
// in your implementation of -joypadManager:deviceDidConnect:player:.  
// For example: 
//
//   -(void)joypadManager:(JPManager *)manager 
//       deviceDidConnect:(JPDevice *)device 
//                 player:(unsigned int)player
//   {
//     device.delegate = self;
//   }
//
@property (nonatomic, readonly) NSMutableArray *connectedDevices;

-(NSUInteger) devicesCount;

//! Begin receiving events from JPManager and connected JPDevices for all
//! events with delegate implementations on 'object'.
-(void) addListener:(id)object capture:(BOOL)capture;
-(void) addListener:(id)object;

//! Stop receiving all events from JPManager and connected JPDevices on 'object'.
-(void) removeListener:(id)object;

@end


#pragma mark - JPManagerDelegate Protocol
@protocol JPManagerDelegate <NSObject>
@optional

// When we find joypad.
// This is called before establishing a connection to Joypad.  If you implement
// this and return NO, the connection will be cancelled.
-(BOOL)joypadManager:(JPManager *)manager
 deviceShouldConnect:(JPDevice *)device;

// If we fail to resolve joypad.
-(void)joypadManager:(JPManager *)manager
  deviceFailedToConnect:(JPDevice *)device
          withErrorCode:(NSError*)errCode;

// Called when a device running Joypad has connected. At this point you
// are ready to receive input from it.
-(void)joypadManager:(JPManager *)manager 
    deviceDidConnect:(JPDevice *)device;

// Called when a device that you were connected to dropped the connection.
// You should use this to set the device's delegate to nil.
-(void)joypadManager:(JPManager *)manager 
 deviceDidDisconnect:(JPDevice *)device;

// Tells you that Joypad Console is about to be launched, meaning your game
// will return to the background.  You can return NO to cancel the launch, but only 
// do this if your game is in the middle of something that cannot be paused - doing
// so will lead to inconsistent behavior for Joypad users.
-(BOOL)joypadManagerWillLaunchConsole:(JPManager *)manager;

// Called when the manager's JPGameState changes.
-(void)joypadManagerChangedGameState:(JPManager *)manager;


@end
