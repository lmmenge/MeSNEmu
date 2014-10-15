//
//  LMGameControllerManager.h
//  MeSNEmu
//
//  Created by Adam Bell on 12/22/2013.
//
//

@class LMGameControllerManager;

@protocol LMGameControllerManagerDelegate <NSObject>

@required
- (void)gameControllerManagerGamepadDidConnect:(LMGameControllerManager*)controllerManager;
- (void)gameControllerManagerGamepadDidDisconnect:(LMGameControllerManager*)controllerManager;

@end

#pragma mark -

@class GCController;

@interface LMGameControllerManager : NSObject
{
  GCController* _gameController;
}

@property (nonatomic, readonly) BOOL gameControllerConnected;
@property (nonatomic, weak) id<LMGameControllerManagerDelegate> delegate;

+ (instancetype)sharedInstance;
+ (BOOL)gameControllersMightBeAvailable;

@end
