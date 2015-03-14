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
  LMBTControllerType_Custom = 0,
  LMBTControllerType_iCade = 1,
  LMBTControllerType_iCade8Bitty = 2,
  LMBTControllerType_EXHybrid = 3,
  LMBTControllerType_SteelSeriesFree = 4,
  LMBTControllerType_8BitdoFC30 = 5,
  LMBTControllerType_iMpulse = 6,
  LMBTControllerType_8BitdoNES30 = 7,
  LMBTControllerType_IPEGAPG9025 = 8,
  LMBTControllerType_Snakebyteidroidcon = 9
} LMBTControllerType;

@interface LMBTControllerView : iCadeReaderView {
  LMBTControllerType _controllerType;
}

- (void)setOnStateString:(const char*)onState offStateString:(const char*)offState;

@property (nonatomic) LMBTControllerType controllerType;

+ (NSArray*)supportedControllers;

@end
