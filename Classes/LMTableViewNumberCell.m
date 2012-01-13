//
//  LMTableViewNumberCell.m
//  SiOS
//
//  Created by Lucas Menge on 7/8/11.
//  Copyright 2011 Lucas Menge. All rights reserved.
//

#import "LMTableViewNumberCell.h"

@interface LMTableViewNumberCell(Privates)

- (void)updateLabel;

@end

#pragma mark -

@implementation LMTableViewNumberCell(Privates)

- (void)updateLabel
{
  if(allowsDefault == NO)
    defaultButton.enabled = NO;
  if(usesDefaultValue == YES)
    [defaultButton setTitle:NSLocalizedString(@"DEFAULT", nil) forState:UIControlStateNormal];
  else
    [defaultButton setTitle:[NSString stringWithFormat:@"%i %@", value, suffix] forState:UIControlStateNormal];
}

@end

#pragma mark -

@implementation LMTableViewNumberCell

@synthesize value;
- (void)setValue:(int)i
{
  if(i != value && i <= maximumValue && i >= minimumValue)
  {
    value = i;
    [self updateLabel];
  }
}
@synthesize minimumValue;
@synthesize maximumValue;
@synthesize suffix;
- (void)setSuffix:(NSString*)newSuffix
{
  [suffix release];
  suffix = [newSuffix copy];
  [self updateLabel];
}
@synthesize usesDefaultValue;
- (void)setUsesDefaultValue:(BOOL)newValue
{
  if(usesDefaultValue != newValue)
  {
    usesDefaultValue = newValue;
    [self updateLabel];
  }
}
@synthesize allowsDefault;
- (void)setAllowsDefault:(BOOL)newValue
{
  if(allowsDefault != newValue)
  {
    allowsDefault = newValue;
    if(allowsDefault == NO)
      self.usesDefaultValue = NO;
    [self updateLabel];
  }
}

@synthesize delegate;

- (void)setup
{  
  delegate = nil;
  
  self.accessoryType = UITableViewCellAccessoryNone;
  self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)plus:(id)sender
{
  self.usesDefaultValue = NO;
  self.value++;
  [delegate cellValueChanged:self];
}

- (void)minus:(id)sender
{
  self.usesDefaultValue = NO;
  self.value--;
  [delegate cellValueChanged:self];
}

- (void)toggleDefault:(id)sender
{
  if(allowsDefault == YES)
  {
    if(usesDefaultValue == YES)
      self.usesDefaultValue = NO;
    else
      self.usesDefaultValue = YES;
    [delegate cellValueChanged:self];
  }
}

- (id)initWithReuseIdentifier:(NSString*)reuseIdentifier
{
  self = [self initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
  return self;
}

@end

#pragma mark -

@implementation LMTableViewNumberCell(UITableViewCell)

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)reuseIdentifier
{
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if(self)
  {
    self.detailTextLabel.text = @" ";
    UIImage* plusImage = [UIImage imageNamed:@"ButtonNumberPlus.png"];
    UIImage* minusImage = [UIImage imageNamed:@"ButtonNumberMinus.png"];
    UIImage* defaultImage = [UIImage imageNamed:@"ButtonNumberDefault.png"];

    plusButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    [plusButton setBackgroundImage:plusImage forState:UIControlStateNormal];
    plusButton.bounds = (CGRect){0,0, plusImage.size};
    [plusButton addTarget:self action:@selector(plus:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:plusButton];
    
    minusButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    [minusButton setBackgroundImage:minusImage forState:UIControlStateNormal];
    minusButton.bounds = (CGRect){0,0, minusImage.size};
    [minusButton addTarget:self action:@selector(minus:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:minusButton];
    
    defaultButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    [defaultButton setBackgroundImage:defaultImage forState:UIControlStateNormal];
    defaultButton.bounds = (CGRect){0,0, defaultImage.size};
    [defaultButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [defaultButton setTitleShadowColor:[UIColor colorWithWhite:1 alpha:0.25] forState:UIControlStateHighlighted];
    defaultButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
    defaultButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    defaultButton.titleLabel.minimumFontSize = 8;
    defaultButton.adjustsImageWhenDisabled = NO;
    defaultButton.titleEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 4);
    [defaultButton addTarget:self action:@selector(toggleDefault:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:defaultButton];
    
    usesDefaultValue = NO;
    allowsDefault = YES;
    self.suffix = @"px";
    self.minimumValue = 0;
    self.maximumValue = 100;
    self.value = 1;
    
    [self setup];
  }
  return self;
}

- (void)prepareForReuse
{
  [super prepareForReuse];
  
  [self setup];
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  
  CGSize backSize = self.backgroundView.bounds.size;
  if(backSize.width > 0 && backSize.height > 0)
  {
    CGSize plusButtonSize = plusButton.bounds.size;
    CGSize defaultButtonSize = defaultButton.bounds.size;
    float y = (int)((backSize.height-1.5)/2)+0.5;
    float xPadding = y+(plusButtonSize.width-plusButtonSize.height)-2;
    plusButton.center = CGPointMake(backSize.width-xPadding, y);
    
    defaultButton.center = CGPointMake(plusButton.center.x-plusButtonSize.width/2-defaultButtonSize.width/2, y);
    defaultButton.titleLabel.font = self.detailTextLabel.font;
    [defaultButton setTitleColor:self.detailTextLabel.textColor forState:UIControlStateNormal];
    
    minusButton.center = CGPointMake(defaultButton.center.x-defaultButtonSize.width/2-minusButton.bounds.size.width/2, y);
  }
}

@end

#pragma mark -

@implementation LMTableViewNumberCell(NSObject)

- (void)dealloc
{
  [plusButton release];
  plusButton = nil;
  [minusButton release];
  minusButton = nil;
  [defaultButton release];
  defaultButton = nil;
  
  [super dealloc];
}

@end