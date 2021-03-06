//
//  GCDiscreetNotificationView.m
//  Mtl mobile
//
//  Created by Guillaume Campagna on 09-12-27.
//  Copyright 2009 LittleKiwi. All rights reserved.
//

#import "GCDiscreetNotificationView.h"

const CGFloat GCDiscreetNotificationViewBorderSize = 25;
const CGFloat GCDiscreetNotificationViewPadding = 5;
const CGFloat GCDiscreetNotificationViewHeight = 30;

NSString* const GCShowAnimation = @"show";
NSString* const GCShowAfterPresentation = @"showAfterPresentation";
NSString* const GCHideAnimation = @"hide";
NSString* const GCChangeTextLabelAnimation = @"changeText";
NSString* const GCChangeActivityAnimation = @"changeActivity";
NSString* const GCChangeTextAndActivityAnimation = @"changeActivityAndText";
NSString* const GCChangePresentationMode = @"changeMode";

@interface GCDiscreetNotificationView ()

@property (nonatomic, readonly) CGPoint showingCenter;
@property (nonatomic, readonly) CGPoint hidingCenter;

- (void) show:(BOOL)animated name:(NSString *)name withAnimationContext:(void *)context;
- (void) hide:(BOOL)animated name:(NSString *)name withAnimationContext:(void *)context;
- (void) showOrHide:(BOOL) hide animated:(BOOL) animated name:(NSString*) name withAnimationContext:(void *) context;
- (void) animationDidStop:(NSString *)animationID finished:(BOOL) finished context:(void *) context;

- (void) placeOnGrid;

@end

@implementation GCDiscreetNotificationView

@synthesize activityIndicator;
@synthesize presentationMode;
@synthesize view;
@synthesize label;

#pragma mark -
#pragma mark Init and dealloc

- (id) initWithText:(NSString *)text inView:(UIView *)aView {
    return [self initWithText:text showActivity:NO inView:aView];
}

- (id)initWithText:(NSString*) text showActivity:(BOOL) activity inView:(UIView*) aView {
    return [self initWithText:text showActivity:activity inPresentationMode:GCDiscreetNotificationViewPresentationModeTop inView:aView];
}

- (id) initWithText:(NSString *)text showActivity:(BOOL)activity 
 inPresentationMode:(GCDiscreetNotificationViewPresentationMode)aPresentationMode inView:(UIView *)aView {
    if ((self = [super initWithFrame:CGRectZero])) {
        self.view = aView;
        self.textLabel = text;
        self.showActivity = activity;
        self.presentationMode = aPresentationMode;
        
        self.center = self.hidingCenter;
        [self setNeedsLayout];
        
        self.userInteractionEnabled = NO;
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)dealloc {
    self.view = nil;
    
    [label release];
    label = nil;
    
    [activityIndicator release];
    activityIndicator = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark Drawing and layout

- (void) layoutSubviews {
    BOOL withActivity = self.activityIndicator != nil;
    CGFloat baseWidth = (2 * GCDiscreetNotificationViewBorderSize) + (withActivity * GCDiscreetNotificationViewPadding);
    
    CGFloat maxLabelWidth = self.view.frame.size.width - self.activityIndicator.frame.size.width * withActivity - baseWidth;
    CGSize maxLabelSize = CGSizeMake(maxLabelWidth, GCDiscreetNotificationViewHeight);
    CGSize textSize = [self.textLabel sizeWithFont:self.label.font constrainedToSize:maxLabelSize lineBreakMode:UILineBreakModeTailTruncation];
    
    CGRect bounds = CGRectMake(0, 0, baseWidth + textSize.width + (self.activityIndicator != nil) * self.activityIndicator.frame.size.width , GCDiscreetNotificationViewHeight);
    if (!CGRectEqualToRect(self.bounds, bounds)) { //The bounds have changed...
        self.bounds = bounds;
        [self setNeedsDisplay];
    }
    
    if (self.activityIndicator == nil) self.label.frame = CGRectMake(GCDiscreetNotificationViewBorderSize, 0, textSize.width, 30);
    else {
        self.activityIndicator.frame = CGRectMake(GCDiscreetNotificationViewBorderSize, GCDiscreetNotificationViewPadding, self.activityIndicator.frame.size.width, self.activityIndicator.frame.size.height);
        self.label.frame = CGRectMake(GCDiscreetNotificationViewBorderSize + GCDiscreetNotificationViewPadding + self.activityIndicator.frame.size.width, 0, textSize.width, 30);
    }
    
    [self placeOnGrid];
}


- (void) drawRect:(CGRect)rect {
    CGRect myFrame = self.bounds;
    
    CGFloat maxY = 0;
    CGFloat minY = 0;
    
    if (self.presentationMode == GCDiscreetNotificationViewPresentationModeTop) {
        maxY =  CGRectGetMinY(myFrame) - 1;
        minY = CGRectGetMaxY(myFrame);
    }
    else if (self.presentationMode == GCDiscreetNotificationViewPresentationModeBottom) {
        maxY =  CGRectGetMaxY(myFrame) + 1;
        minY = CGRectGetMinY(myFrame);
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, CGRectGetMinX(myFrame), maxY);
    CGPathAddCurveToPoint(path, NULL, CGRectGetMinX(myFrame) + GCDiscreetNotificationViewBorderSize, maxY, CGRectGetMinX(myFrame), minY, CGRectGetMinX(myFrame) + GCDiscreetNotificationViewBorderSize, minY);
    CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(myFrame) - GCDiscreetNotificationViewBorderSize, minY);
    CGPathAddCurveToPoint(path, NULL, CGRectGetMaxX(myFrame), minY, CGRectGetMaxX(myFrame) - GCDiscreetNotificationViewBorderSize, maxY, CGRectGetMaxX(myFrame), maxY);
    CGPathCloseSubpath(path);
    
    CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:0.0 alpha:0.8].CGColor);
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    
    CGContextAddPath(context, path);
    CGContextStrokePath(context);
    
    CGContextAddPath(context, path);
    CGContextFillPath(context);
    
    CGPathRelease(path);
}

#pragma mark -
#pragma mark Show/Hide 

- (void)showAnimated {
    [self show:YES];
}

- (void)hideAnimated {
    [self hide:YES];
}

- (void) hideAnimatedAfter:(NSTimeInterval) timeInterval {
   [self performSelector:@selector(hideAnimated) withObject:nil afterDelay:timeInterval]; 
}

- (void)showAndDismissAutomaticallyAnimated {
    [self showAndDismissAfter:1.0];
}

- (void)showAndDismissAfter:(NSTimeInterval)timeInterval {
    [self showAnimated];
    [self performSelector:@selector(hideAnimated) withObject:nil afterDelay:timeInterval];
}

- (void) show:(BOOL)animated {
    [self show:animated name:GCShowAnimation withAnimationContext:nil];
}

- (void) hide:(BOOL)animated {
    [self hide:animated name:GCHideAnimation withAnimationContext:nil];
}

- (void) show:(BOOL)animated name:(NSString*) name withAnimationContext:(void *)context {
    [self showOrHide:NO animated:animated name:name withAnimationContext:context];
}

- (void) hide:(BOOL)animated name:(NSString*) name withAnimationContext:(void *)context {
    [self showOrHide:YES animated:animated name:name withAnimationContext:context];
}

- (void) showOrHide:(BOOL)hide animated:(BOOL)animated name:(NSString *)name withAnimationContext:(void *)context {
    if ((hide && self.isShowing) || (!hide && !self.isShowing)) {
        if (animated) {
            [UIView beginAnimations:name context:context];
            [UIView setAnimationBeginsFromCurrentState:name != GCShowAfterPresentation];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
        }
        
        if (hide) self.center = self.hidingCenter;
        else {
            [self.activityIndicator startAnimating];
            self.center = self.showingCenter;
        }
        
        [self placeOnGrid];
        
        if (animated) [UIView commitAnimations]; 
    }
}

#pragma mark -
#pragma mark Animations

- (void) animationDidStop:(NSString *)animationID finished:(BOOL) finished context:(void *) context {
    if (animationID == GCHideAnimation) [self.activityIndicator stopAnimating];
    else if (animationID != GCShowAnimation) {
        if (animationID == GCChangeTextLabelAnimation) {
            NSString* theText = (NSString*) context;
            
            self.textLabel = theText;
        }
        else if (animationID == GCChangeActivityAnimation) {
            NSNumber* activityNumber = (NSNumber*) context;
            BOOL activity = [activityNumber boolValue];
            
            self.showActivity = activity;
        }
        else if (animationID == GCChangeTextAndActivityAnimation) {
            NSArray* arrayOfChanges = (NSArray*) context;
            NSString* aText = [arrayOfChanges objectAtIndex:0];
            BOOL activity = [[arrayOfChanges objectAtIndex:1] boolValue];
            
            self.textLabel = aText;
            self.showActivity = activity;
        }
        else if (animationID == GCChangePresentationMode) {
            NSNumber* presentationNumber = (NSNumber*) context;
            
            self.presentationMode = (GCDiscreetNotificationViewPresentationMode) [presentationNumber intValue];
            [self show:YES name:GCShowAfterPresentation withAnimationContext:nil];
        }
        
        [self setNeedsLayout];
        
        if (animationID != GCChangePresentationMode) [self show:YES];
    }
}


#pragma mark -
#pragma mark Getter and setters

- (NSString *) textLabel {
    return self.label.text;
}

- (void) setTextLabel:(NSString *) aText {
    self.label.text = aText;
    [self setNeedsLayout];
}

- (UILabel *)label {
    if (label == nil) {
        label = [[UILabel alloc] init];
        
        label.font = [UIFont boldSystemFontOfSize:15.0];
        label.textColor = [UIColor whiteColor];
        label.shadowColor = [UIColor blackColor];
        label.shadowOffset = CGSizeMake(0, 1);
        label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        label.backgroundColor = [UIColor clearColor];
        
        [self addSubview:label];
    }
    return label;
}

- (BOOL) showActivity {
    return (self.activityIndicator != nil);
}

- (void) setShowActivity:(BOOL) activity {
    if (activity != self.showActivity) {
        if (activity) {
            activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
            [self addSubview:activityIndicator];
        }
        else {
            [activityIndicator removeFromSuperview];
            
            [activityIndicator release];
            activityIndicator = nil;
        }
        
        [self setNeedsLayout];
    }
}

- (void) setView:(UIView *) aView {
    if (view != aView) {
        [self retain];
        [self removeFromSuperview];
        
        view = aView;
        [view addSubview:self];
        [self setNeedsLayout];
        
        [self release];
    }
}

- (void) setPresentationMode:(GCDiscreetNotificationViewPresentationMode) newPresentationMode {
    if (presentationMode != newPresentationMode) {        
        presentationMode = newPresentationMode;
        if (presentationMode == GCDiscreetNotificationViewPresentationModeTop) {
            self.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        }
        else if (presentationMode == GCDiscreetNotificationViewPresentationModeBottom) {
            self.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        }
        
        self.center = self.isShowing ? self.showingCenter : self.hidingCenter;
        
        [self setNeedsDisplay];
        [self placeOnGrid];
    }
}

- (BOOL) isShowing {
    return (self.center.y == self.showingCenter.y);
}

- (CGPoint) showingCenter {
    CGFloat y = 0;
    if (self.presentationMode == GCDiscreetNotificationViewPresentationModeTop) y = 15;
    else if (self.presentationMode == GCDiscreetNotificationViewPresentationModeBottom) y = self.view.frame.size.height - 15;
    return CGPointMake(self.view.frame.size.width / 2, y);
}

- (CGPoint) hidingCenter {
    CGFloat y = 0;
    if (self.presentationMode == GCDiscreetNotificationViewPresentationModeTop) y = - 15;
    else if (self.presentationMode == GCDiscreetNotificationViewPresentationModeBottom) y = 15 + self.view.frame.size.height;
    return CGPointMake(self.view.frame.size.width / 2, y);
}

#pragma mark -
#pragma mark Animated Setters

- (void) setTextLabel:(NSString *)aText animated:(BOOL)animated {
    if (animated && self.isShowing) {
        [self hide:YES name:GCChangeTextLabelAnimation withAnimationContext:aText];
    }
    else self.textLabel = aText;
}

- (void) setShowActivity:(BOOL)activity animated:(BOOL)animated {
    if (animated && self.isShowing) {
        NSNumber* context = [NSNumber numberWithInt:activity];
        [self hide:YES name:GCChangeActivityAnimation withAnimationContext:context];
    }
    else self.showActivity = activity;
}

- (void) setTextLabel:(NSString *)aText andSetShowActivity:(BOOL)activity animated:(BOOL)animated {
    if (animated && self.isShowing) {
        NSArray* context = [NSArray arrayWithObjects:aText, [NSNumber numberWithBool:activity], nil];
        [self hide:YES name:GCChangeTextAndActivityAnimation withAnimationContext:context];
    }
    else {
        self.textLabel = aText;
        self.showActivity = activity;
    }
}

- (void) setPresentationMode:(GCDiscreetNotificationViewPresentationMode)newPresentationMode animated:(BOOL)animated {
    if (animated && self.isShowing) {
        NSNumber* context = [NSNumber numberWithInt:newPresentationMode];
        [self hide:YES name:GCChangePresentationMode withAnimationContext:context];
    }
    else self.presentationMode = newPresentationMode;
}

#pragma mark -
#pragma mark Helper Methods

- (void) placeOnGrid {
    CGRect frame = self.frame;
    
    frame.origin.x = roundf(frame.origin.x);
    frame.origin.y = roundf(frame.origin.y);
    
    self.frame = frame;
}

@end
