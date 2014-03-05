//
//  LMBTControllerView.m
//  SiOS
//
//  Created by Lucas Menge on 7/25/13.
//  Copyright (c) 2013 Lucas Menge. All rights reserved.
//

#import "LMBTControllerView.h"

@implementation LMBTControllerView(Privates)

- (void)LMBT_setOnStateString:(const char*)onState offStateString:(const char*)offState
{
  int mapSize = 12*sizeof(char);
  memcpy(_on_states,  onState, mapSize);
  memcpy(_off_states, offState, mapSize);
}

@end

#pragma mark -

@implementation LMBTControllerView

- (void)setOnStateString:(const char*)onState offStateString:(const char*)offState
{
  @synchronized(self)
  {
    self.controllerType = LMBTControllerType_Custom;
    [self LMBT_setOnStateString:onState offStateString:offState];
  }
}

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
    if(_controllerType == LMBTControllerType_iCade)
    {
      // regular iCade
      // A C E G
      // B D F H
      // SE Y X L
      // ST B A R
      // UP RT DN LT SE ST  Y  B  X  A  L  R
      // UP RT DN LT  A  B  C  D  E  F  G  H
      [self LMBT_setOnStateString:"wdxayhujikol"
                   offStateString:"eczqtrfnmpgv"];
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
      [self LMBT_setOnStateString:"wdxayuikolhj"
                   offStateString:"eczqtfmpgvrn"];
    }
    else if(_controllerType == LMBTControllerType_EXHybrid)
    {
      // //TODO: Properly support the EX Hybrid
      // UP RT DN LT SE ST  Y  B  X  A  L  R
      // UP RT DN LT  A  B  C  D  E  F  G  H
      [self LMBT_setOnStateString:"wdxayhujikol"
                   offStateString:"eczqtrfnmpgv"];
    }
    else if(_controllerType == LMBTControllerType_SteelSeriesFree)
    {
      // SteelSeries Free (thanks to Infernoten)
      // submitted string: wedcxzaqoglvythrufjnimkp
      [self LMBT_setOnStateString:"wdxaolyhujik"
                   offStateString:"eczqgvtrfnmp"];
    }
    else if(_controllerType == LMBTControllerType_8BitdoFC30)
    {
      // 8Bitdo FC30 (thanks to guidoscheffler)
      // submitted string for English layout: wedcxzaqytufimkpoglvhrjn
      [self LMBT_setOnStateString:"wdxayuikolhj"
                   offStateString:"eczqtfmpgvrn"];
      // submitted string for German layout:  wedcxyaqztufimkpoglvhrjn
      //[self LMBT_setOnStateString:"wdxazuikolhj"
      //             offStateString:"ecyqtfmpgvrn"];
    }
    else if(_controllerType == LMBTControllerType_iMpulse)
    {
        [self LMBT_setOnStateString:"wdxa..lkoyhj"
                     offStateString:"eczq..vpgtrn"];
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
