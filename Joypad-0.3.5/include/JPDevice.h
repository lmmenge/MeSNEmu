//
//  JPDevice.h
//
//  Created by Lou Zell on 2/25/11.
//  Copyright 2011 Joypad Inc. All rights reserved.
//
//  Please email questions to lou@getjoypad.com
//  __________________________________________________________________________
//

#import <Foundation/Foundation.h>
#import "JPConstants.h"

@protocol JPDeviceDelegate;

@interface JPDevice : NSObject

// See the JPDeviceDelegate protocol at the bottom of this header.
@property (nonatomic, assign) id<JPDeviceDelegate> delegate;
@property (nonatomic, readonly) NSString *name;

// This will be set automatically by the sdk based on the order of connections.
// As players drop out in a multiplayer game, new players will fill their old
// spots in ascending order.
@property (nonatomic, readonly) NSUInteger playerNumber;
@property (nonatomic, readonly) NSUInteger index;
@property (nonatomic, readonly) BOOL isConnected;
-(void)disconnect;

@end


@protocol JPDeviceDelegate <NSObject>
@optional
-(void)joypadDevice:(JPDevice *)device didAccelerate:(JPAcceleration)accel;
-(void)joypadDevice:(JPDevice *)device dPad:(JPInputIdentifier)dpad buttonUp:(JPDpadButton)dpadButton;
-(void)joypadDevice:(JPDevice *)device dPad:(JPInputIdentifier)dpad buttonDown:(JPDpadButton)dpadButton;
-(void)joypadDevice:(JPDevice *)device buttonUp:(JPInputIdentifier)button;
-(void)joypadDevice:(JPDevice *)device buttonDown:(JPInputIdentifier)button;
-(void)joypadDevice:(JPDevice *)device analogStick:(JPInputIdentifier)stick didMove:(JPStickPosition)newPosition;
-(void)joypadDevice:(JPDevice *)device didNavigate:(JPNavButton)navButton;
@end
