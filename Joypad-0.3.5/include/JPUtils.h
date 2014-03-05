//
//  JPUtils.h
//  JoypadiOSSample
//
//  Created by Warner Skoch on 6/20/12.
//  Copyright (c) 2012 Zell Applications. All rights reserved.
//

#ifndef Joypad_JPUtils_h
#define Joypad_JPUtils_h

#import "JPManager.h"
#import "JPDevice.h"

// Sets JPManager's delegate and all connected JPDevices' delegates to obj
void JPUpdateDelegates(id /*<JPManagerDelegate, JPDeviceDelegate>*/ obj);

// Only update JPManager and JPDevice delegates if they are set to obj.
void JPSafelyRemoveDelegatesFromObj(id obj);
uint16_t JPGetDelegateFlags(id obj);

#endif
