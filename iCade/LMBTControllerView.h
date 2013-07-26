//
//  LMBTControllerView.h
//  SiOS
//
//  Created by Lucas Menge on 7/25/13.
//  Copyright (c) 2013 Lucas Menge. All rights reserved.
//

#import "iCadeReaderView.h"

typedef enum _LMBTControllerType
{
  LMBTControllerType_iCade,
  LMBTControllerType_iCade8Bitty,
  LMBTControllerType_EXHybrid
} LMBTControllerType;

@interface LMBTControllerView : iCadeReaderView {
  LMBTControllerType _controllerType;
}

@property (nonatomic) LMBTControllerType controllerType;

@end
