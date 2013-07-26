//
//  LMBTControllerView.m
//  SiOS
//
//  Created by Lucas Menge on 7/25/13.
//  Copyright (c) 2013 Lucas Menge. All rights reserved.
//

#import "LMBTControllerView.h"

@implementation LMBTControllerView

@synthesize controllerType = _controllerType;
- (void)setControllerType:(LMBTControllerType)controllerType
{
  if(_controllerType != controllerType)
  {
    _controllerType = controllerType;
    
    // original SNES layout
    // L             R
    //               X
    //     SE ST   Y   A
    //               B
    
    // map order: UP RT DN LT SE ST  Y  B  X  A  L  R
    int mapSize = 12*sizeof(char);
    if(_controllerType == LMBTControllerType_iCade)
    {
      // regular iCade
      // A C E G
      // B D F H
      // SE Y X L
      // ST B A R
      // UP RT DN LT SE ST  Y  B  X  A  L  R
      // UP RT DN LT  A  B  C  D  E  F  G  H
      memcpy(_on_states,  "wdxayhujikol", mapSize);
      memcpy(_off_states, "eczqtrfnmpgv", mapSize);
    }
    else if(_controllerType == LMBTControllerType_iCade8Bitty)
    {
      // iCade 8-Bitty
      // hr             jn
      //             im og
      //     yt uf   kp lv
      // B              D
      //             E  G
      //     A  C    F  H
      // UP RT DN LT SE ST  Y  B  X  A  L  R
      // UP RT DN LT  A  B  C  D  E  F  G  H
      memcpy(_on_states,  "wdxayuikolhj", mapSize);
      memcpy(_off_states, "eczqtfmpgvrn", mapSize);
    }
    else if(_controllerType == LMBTControllerType_EXHybrid)
    {
      // //TODO: EX Hybrid
      // UP RT DN LT SE ST  Y  B  X  A  L  R
      // UP RT DN LT  A  B  C  D  E  F  G  H
      memcpy(_on_states,  "wdxayhujikol", mapSize);
      memcpy(_off_states, "eczqtrfnmpgv", mapSize);
    }
  }
}

@end

#pragma mark -

@implementation LMBTControllerView(UIView)

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if(self)
  {
    // Initialization code
  }
  return self;
}

@end
