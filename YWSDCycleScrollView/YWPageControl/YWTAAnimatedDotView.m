//
//  YWTAAnimatedDotView.m
//  YWTAPageControl
//
//  Created by Tanguy Aladenise on 2015-01-22.
//  Copyright (c) 2015 Tanguy Aladenise. All rights reserved.
//

#import "YWTAAnimatedDotView.h"

static CGFloat const kAnimateDuration = 1;

@implementation YWTAAnimatedDotView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initialization];
    }
    
    return self;
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialization];
    }
    return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialization];
    }
    
    return self;
}

- (void)setDotColor:(UIColor *)dotColor
{
    _dotColor = dotColor;
    self.layer.borderColor  = dotColor.CGColor;
}

- (void)initialization
{
    _dotColor = [UIColor whiteColor];
    self.backgroundColor    = [UIColor colorWithWhite:1 alpha:0.5];
    self.layer.cornerRadius = 2;
//    self.layer.borderColor  = [UIColor whiteColor].CGColor;
//    self.layer.borderWidth  = 2;
}


- (void)changeActivityState:(BOOL)active
{
    if (active) {
        [self animateToActiveState];
    } else {
        [self animateToDeactiveState];
    }
}


- (void)animateToActiveState
{
    [UIView animateWithDuration:kAnimateDuration delay:0 usingSpringWithDamping:.5 initialSpringVelocity:-20 options:UIViewAnimationOptionCurveLinear animations:^{
        self.backgroundColor = _dotColor;
        self.transform = CGAffineTransformMakeScale(1.4, 1.4);
    } completion:nil];
}

- (void)animateToDeactiveState
{
    [UIView animateWithDuration:kAnimateDuration delay:0 usingSpringWithDamping:.5 initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.backgroundColor = self.normalColor;
        self.transform = CGAffineTransformIdentity;
    } completion:nil];
}

@end
