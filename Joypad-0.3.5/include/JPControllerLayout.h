//
//  JPControllerLayout.h
//
//  Created by Lou Zell on 3/14/11.
//  Copyright 2011 Joypad Inc. All rights reserved.
//
//  Please email questions to lou@getjoypad.com
//  __________________________________________________________________________
//
//  Examples of several custom controllers can be found in MyJoypadLayout.m in 
//  the JoypadiOSSample project that comes with the SDK download.
//
//  This is the class that you will use to create a custom layout for your
//  application.  Each method listed in the Public API section below adds
//  one component to your controller.  Currently, you can add: 
//
//       * Analog sticks
//       * Re-centering analog sticks
//       * Dpads
//       * Buttons
//       * Accelerometer Data (this components doesn't add a view)
//
//  See the comments at the top of each method for instructions on using it.

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import <CoreGraphics/CGGeometry.h>
#endif
#import "JPConstants.h"

@interface JPControllerLayout : NSObject

/**
 * Returns a new autoreleased layout:
 *   JPControllerLayout *myLayout = [JPControllerLayout layout];
 */
+(JPControllerLayout *)layout;

/**
 * Creates the default Joypad nagivation layout: a four-way dpad, a back button,
 * and an OK button.  Implement the delegate method -joypadDevice:didNavigate:
 * to get input from this layout (see JPDevice.h).
 */
+(JPControllerLayout *)navigationLayout;

/**
 * Set the name of this layout.  This name will be displayed in the Connection Modal on Joypad
 * when a connection occurs.
 */
-(void)setName:(NSString *)layoutName;
-(NSString *)name;


-(void)setBackgroundImageName:(NSString *)imgName;

/**
 * This is the simplest method to add a button.  It adds a blue square button with
 * no label.  You pass in a JPInputIdentifier (found in JPConstants.h) that you 
 * will use later to identify when this button is being pressed.  When you press and
 * release buttons on Joypad, your implementations of the following delegate
 * methods are called: 
 *
 *  -(void)joypadDevice:(JPDevice *)device buttonUp:(JPInputIdentifier)button;
 *  -(void)joypadDevice:(JPDevice *)device buttonDown:(JPInputIdentifier)button;
 *
 * As you can see, a JPInputIdentifier is passed as a parameter to these methods.
 */
-(void)addButtonWithFrame:(CGRect)rect identifier:(JPInputIdentifier)inputId;

-(void)addButtonWithFrame:(CGRect)rect imageName:(NSString *)imgName identifier:(JPInputIdentifier)inputId;

/**
 * More options than the method above.  See JPConstants.h for JPButtonShape
 * and JPButtonColor enums.
 */
-(void)addButtonWithFrame:(CGRect)rect label:(NSString *)label fontSize:(unsigned int)fontSize shape:(JPButtonShape)shape color:(JPButtonColor)color identifier:(JPInputIdentifier)inputId;


/**
 * This is one of the preferred methods to add a dpad.  The touch frame is the
 * total hit area of the dpad.  The image frame is where the dpad image will be drawn,
 * _relative_ to the touch frame.
 *
 * You should make the touchFrame as large as you can, without colliding with other
 * components, to provide customers with a margin of error around the dpad edges.
 *
 *          touchFrame
 *    +--------------+  
 *    |              |
 *    |   imageFrame |
 *    | +---_---+    |
 *    | | _| |_ |    |
 *    | ||_   _||    |
 *    | |  |_|  |    |
 *    | +-------+    |
 *    +--------------+
 *
 * For any touch in the outer rect, the angle from the center of the _inner_ rect
 * is calculated and the appropriate dpad direction is reported.
 * 
 * The default dpad can be drawn with: 
 * 
 *   [layout addDpadWithTouchFrame:CGRectMake(0, 44, 280, 256) 
 *                      imageFrame:CGRectMake(20, 48, 180, 180)   // relative to touch frame
 *                      identifier:kJPInputDpad1];
 */
-(void)addDpadWithTouchFrame:(CGRect)outerRect imageFrame:(CGRect)innerRect identifier:(JPInputIdentifier)inputId;

/**
 * Adds a dpad with the specified frame, and automatically places its origin at the
 * center of the frame. This is the quickest way to drop a dpad down.  However, 
 * we recommend using either -addDpadWithFrame:dpadOrigin:identifier, 
 * or -addDpadWithTouchFrame:imageFrame:identifier:
 */
-(void)addDpadWithFrame:(CGRect)rect identifier:(JPInputIdentifier)inputId;

/**
 * Adds a dpad with the origin somewhere other than the center of the frame. This is
 * useful for giving your user more play around the edge of the dpad.  For example,
 * if you specified an origin and frame as follows, you would give your users a larger
 * hit area to the right side of the dpad: 
 *
 *    +----------+
 *    |          |
 *    |   *      |
 *    |          |
 *    +----------+
 *
 * Users tend to have a good grasp of where the edge of the device is, so the area to the
 * left of the dpad can be less than the right.  The dpad image itself is 180x180.  We find 
 * that extending the touch area past the edge of the dpad on the top, right, and bottom is
 * very beneficial to the experience. As a starting point, try: 
 *  
 *   [customLayout addDpadWithFrame:CGRectMake(0, 44, 280, 256) 
 *                       dpadOrigin:CGPointMake(110, 182) 
 *                       identifier:kJPInputDpad1];
 *
 * These are the dimensions that we use for the pre-installed controllers.
 */
-(void)addDpadWithFrame:(CGRect)rect dpadOrigin:(CGPoint)origin identifier:(JPInputIdentifier)inputId;

/**
 * Get accelerometer data from the device running Joypad.  Does not add a view.
 */
-(void)addAccelerometer;

/**
 * Custom analog sticks.  Provide a disk image and a base image.  Always use HD (@2x) images!
 */
-(void)addAnalogStickWithFrame:(CGRect)frame 
                 baseImageName:(NSString *)baseImageName
                 diskImageName:(NSString *)diskImageName
                   recentering:(BOOL)recentering
                        radius:(NSUInteger)radius
                    identifier:(JPInputIdentifier)inputId;


-(void)addAnalogStickWithFrame:(CGRect)frame 
                 baseImageName:(NSString *)baseImageName
                 diskImageName:(NSString *)diskImageName
                relativeCenter:(CGPoint)centerPoint
                   recentering:(BOOL)recentering
                        radius:(NSUInteger)radius
                    identifier:(JPInputIdentifier)inputId;



// Do I even want to leave this call in?   Could make it: -addAnalogStickWithFrame:radius:identifier;

/**
 * Adds an analog stick with specified touch frame.  The analog stick image will be 
 * drawn in the center of the touch frame.  This stick does not recenter around the 
 * initial touch point.  See the next method for more flexibility.
 */
-(void)addAnalogStickWithFrame:(CGRect)rect identifier:(JPInputIdentifier)inputId;

/**
 * The touch frame is the total area that this component will respond to touches in.
 * The relative center point identifies where the center of the analog stick image is
 * (relative to the touchFrame).  The radius is distance that the disk can travel 
 * from center to full tilt.  Set JPManager's displayDebugFrames property to YES to 
 * draw the boundary of the touch frame and the radius.
 * 
 * As a starting point try: 
 *
 *   [customLayout addAnalogStickWithTouchFrame:CGRectMake(0, 70, 240, 240)
 *                               relativeCenter:CGPointMake(x,y)
 *                                       radius:JPDefaultAnalogStickRadius
 *                                   identifier:kJPInputAnalogStick1];
 */
-(void)addAnalogStickWithTouchFrame:(CGRect)touchFrame
                     relativeCenter:(CGPoint)centerPoint
                             radius:(NSUInteger)radius
                         identifier:(JPInputIdentifier)inputId;



/**
 * Same as above with an extra parameter to specify if the analog stick should recenter at the 
 * initial touch down point.  This gives it a hybrid feel between an analog stick and trackpad.
 * Recentering analog sticks are ideal for camera movement in a FPS.  For player movement, 
 * it is best to stick with a stationary analog stick (i.e. pass NO as the last argument).
 */
-(void)addAnalogStickWithFrame:(CGRect)rect identifier:(JPInputIdentifier)inputId recentering:(BOOL)recentering;

/**
 * Pre-installed layouts to get you started.  Note that even when using these
 * built in layouts, you should still name the layout after your game (this name
 * is displayed on Joypad when a connection occurs).  Also, if you use one of 
 * these, then the built in skins can be applied over your controller.   
 */
+(JPControllerLayout *)nesLayout;
+(JPControllerLayout *)gbaLayout;
+(JPControllerLayout *)snesLayout;

/**
 * Equal if controller layouts have the same name and input components (buttons, labels, dpads, etc.)
 */
-(BOOL)isEqualToControllerLayout:(JPControllerLayout *)otherLayout;


@end
