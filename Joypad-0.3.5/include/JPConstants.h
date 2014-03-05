//
//  JPConstants.h
//
//  Created by Lou Zell on 6/1/11.
//  Copyright 2011 Joypad Inc. All rights reserved.
//
//  Please email questions to lou@getjoypad.com
//  __________________________________________________________________________
//

#ifndef JoypadSDK_JPConstants_h
#define JoypadSDK_JPConstants_h

typedef enum
{
  kJPGameStateMenu,
  kJPGameStateGameplay,
}JPGameState;

typedef struct
{
  float x;
  float y;
  float z;
}JPAcceleration;

typedef struct
{
  float angle;    // radians
  float distance;
}JPStickPosition;

typedef enum
{
  kJPDpadButtonUp,
  kJPDpadButtonRight,
  kJPDpadButtonDown,
  kJPDpadButtonLeft
}JPDpadButton;

typedef enum
{
  kJPButtonShapeSquare,
  kJPButtonShapeRound,
  kJPButtonShapePill
}JPButtonShape;

typedef enum
{
  kJPButtonColorBlue,
  kJPButtonColorBlack
}JPButtonColor;

typedef enum
{
  kJPInputDpad1,
  kJPInputDpad2,
  kJPInputAnalogStick1,
  kJPInputAnalogStick2,
  kJPInputAccelerometer,
  kJPInputWheel,
  kJPInputAButton,
  kJPInputBButton,
  kJPInputCButton,
  kJPInputXButton,
  kJPInputYButton,
  kJPInputZButton,
  kJPInputSelectButton,
  kJPInputStartButton,
  kJPInputLButton,
  kJPInputRButton
}JPInputIdentifier;

typedef enum
{
  kJPNavButtonUp,
  kJPNavButtonRight,
  kJPNavButtonDown,
  kJPNavButtonLeft,
  kJPNavButtonBack,
  kJPNavButtonSelect,
}JPNavButton;

typedef enum
{
  kJPControllerNES,
  kJPControllerGBA,
  kJPControllerSNES,
  kJPControllerGenesis,
  kJPControllerN64,
  kJPControllerAnyPreinstalled,
  kJPControllerCustom
}JPControllerIdentifier;


static NSString * const kJoypadErrorConnection = @"JoypadErrorConnection";

typedef enum
{
  kJoypadErrorRCPProtocol,
  kJoypadErrorCancelled,
  kJoypadErrorTCPSocket,
  kJoypadErrorUDPSocket,
} JPErrorCode;


#define JPDefaultAnalogStickRadius    55

#endif