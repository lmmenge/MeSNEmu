//
//  LMBTControllerView.h
//  MeSNEmu
//
//  Created by Lucas Menge on 7/25/13.
//  Copyright (c) 2013 Lucas Menge. All rights reserved.
//

#import "iCadeReaderView.h"

typedef enum _LMBTControllerType
{
  LMBTControllerType_Custom             = 0,
  LMBTControllerType_iCade              = 1,
  LMBTControllerType_iCade8Bitty        = 2,
  LMBTControllerType_8BitdoFC30         = 3,
  LMBTControllerType_8BitdoNES30        = 4,
  LMBTControllerType_8BitdoSFC30        = 5,
  LMBTControllerType_IPEGAPG9025        = 6,
  LMBTControllerType_IPEGAPG9028        = 7,
  LMBTControllerType_SteelSeriesFree    = 8,
  LMBTControllerType_Snakebyteidroidcon = 9,
  LMBTControllerType_iMpulse            = 10
} LMBTControllerType;

@interface LMBTControllerView : iCadeReaderView {
  LMBTControllerType _controllerType;
}

- (void)setOnStateString:(const char*)onState offStateString:(const char*)offState;

@property (nonatomic) LMBTControllerType controllerType;

+ (NSArray*)supportedControllers;

@end
