//
//  LMBTControllerView.m
//  MeSNEmu
//
//  Created by Lucas Menge on 7/25/13.
//  Copyright (c) 2013 Lucas Menge. All rights reserved.
//

#import "LMBTControllerView.h"

NSArray* LMBTSupportedControllers = nil;

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
    
    for(NSArray* controller in [LMBTControllerView supportedControllers])
    {
      if([[controller objectAtIndex:1] intValue] == _controllerType)
      {
        char onString[13];
        char offString[13];
        memset(onString, '.', 12*sizeof(char));
        memset(offString, '.', 12*sizeof(char));
        onString[12] = '\0';
        offString[12] = '\0';
        
        NSString* controllerString = [controller objectAtIndex:2];
        for(NSUInteger i=0; i<[controllerString length]; i++)
        {
          if(i%2==0)
            onString[i/2] = [controllerString characterAtIndex:i];
          else
            offString[i/2] = [controllerString characterAtIndex:i];
        }
        
        /*NSLog(@"on:  %s", onString);
        NSLog(@"off: %s", offString);
        NSLog(@"Original: %@", controllerString);*/
        
        /*char* customOnString = "wdxa..lkoyhj";
        char* customOffString = "eczq..vpgtrn";
        NSMutableString* rebuilt = [NSMutableString string];
        for(NSUInteger i=0; i<24; i++)
        {
          unichar character;
          if(i%2==0)
            character = customOnString[i/2];
          else
            character = customOffString[i/2];
          [rebuilt appendString:[NSString stringWithCharacters:&character length:1]];
        }
        NSLog(@"rebuilt:  %@", rebuilt);*/
        
        [self LMBT_setOnStateString:onString
                     offStateString:offString];
        break;
      }
    }
  }
}

+ (NSArray*)supportedControllers
{
  @synchronized(self)
  {
    if(LMBTSupportedControllers == nil)
    {
      // original SNES layout
      // L             R
      //               X
      //     SE ST   Y   A
      //               B
      
      // map order: UP RT DN LT SE ST  Y  B  X  A  L  R
      
      LMBTSupportedControllers = [[@[
                                    /*@[@"Custom",
                                      [NSNumber numberWithInt:LMBTControllerType_Custom],
                                      @""],*/
                                     
                                    // iCade
                                    @[@"iCade",
                                      [NSNumber numberWithInt:LMBTControllerType_iCade],
                                      @"wedcxzaqythrufjnimkpoglv"],
                                    
                                    // iCade 8-Bitty
                                    @[@"iCade 8-Bitty",
                                      [NSNumber numberWithInt:LMBTControllerType_iCade8Bitty],
                                      @"wedcxzaqytufimkpoglvhrjn"],
                                    
                                    // EX Hybrid
                                    // TODO: Properly support the EX Hybrid
                                    @[@"EX Hybrid",
                                      [NSNumber numberWithInt:LMBTControllerType_EXHybrid],
                                      @"wedcxzaqythrufjnimkpoglv"],
                                    
                                    // SteelSeries Free (thanks to Infernoten)
                                    @[@"SteelSeries Free",
                                      [NSNumber numberWithInt:LMBTControllerType_SteelSeriesFree],
                                      @"wedcxzaqoglvythrufjnimkp"],
                                    
                                    // 8Bitdo FC30 (thanks to guidoscheffler)
                                    @[@"8Bitdo FC30",
                                      [NSNumber numberWithInt:LMBTControllerType_8BitdoFC30],
                                      @"wedcxzaqytufimkpoglvhrjn"],
                                    
                                    // 8Bitdo NES30 (thanks to DerekT07)
                                    @[@"8Bitdo NES30",
                                      [NSNumber numberWithInt:LMBTControllerType_8BitdoNES30],
                                      @"wedcxzaqlvogythrjnufkpim"],
                                    
                                    // iMpulse
                                    @[@"iMpulse",
                                      [NSNumber numberWithInt:LMBTControllerType_iMpulse],
                                      @"wedcxzaq....lvkpogythrjn"],
                                    
                                    // IPEGA PG-9025 (thanks to naldin)
                                    @[@"IPEGA PG-9025",
                                      [NSNumber numberWithInt:LMBTControllerType_IPEGAPG9025],
                                      @"wedcxzaqoglvjnufythrimkp"],
                                    
                                    // Snakebyte idroid:con (thanks to Gohlan)
                                    @[@"Snakebyte idroid:con",
                                      [NSNumber numberWithInt:LMBTControllerType_Snakebyteidroidcon],
                                      @"wedcxzaqlvogythrjnufimkp"]
                                    
                                   ] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                                     return [[obj1 firstObject] compare:[obj2 firstObject]];
                                   }] copy];
    }
  }
  return LMBTSupportedControllers;
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
