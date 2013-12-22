//
//  LMGameControllerManager.h
//  SiOS
//
//  Created by Adam Bell on 12/22/2013.
//
//

#import "../SNES9XBridge/Snes9xMain.h"

@class LMGameControllerManager;

@protocol LMGameControllerManagerDelegate <NSObject>

@required
- (void)gameControllerManagerGamepadDidConnect:(LMGameControllerManager *)controllerManager;
- (void)gameControllerManagerGamepadDidDisconnect:(LMGameControllerManager *)controllerManager;

@end

@interface LMGameControllerManager : NSObject

+(instancetype)sharedInstance;

@property (nonatomic, readonly) BOOL gameControllerConnected;

@property (nonatomic, weak) id<LMGameControllerManagerDelegate> delegate;

@end
