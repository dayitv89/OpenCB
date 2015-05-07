//
//  BlockableViewController.m
//  yeehay
//
//  Created by mark2 on 8/19/10.
//  Copyright 2010 HFS. All rights reserved.
//

#import "UIViewController+Blockable.h"
#import <QuartzCore/QuartzCore.h>
#import "Constants.h"

#define constActivityIndicatorView 7777
#define constProgressBarView 7778
#define constMediumFontSize 15

UIView *HFS_BLOCKER_VIEW;
UIView *HFS_PROGRESSBAR_VIEW;
BOOL HFS_ISBLOCKED_FLAG;
long long HFS_PROGRESSBAR_STOPPER;

@interface UIViewController(PrivateMethods)

- (UIView *)pickCurrentTopView;

@end

@implementation UIViewController(Blockable)
- (UIView *)pickCurrentTopView {
	UIWindow *activeAppWindow = [UIApplication sharedApplication].keyWindow;
	UIView *topView = ([activeAppWindow.rootViewController class]==[UINavigationController class])?((UINavigationController *)activeAppWindow.rootViewController).topViewController.view : nil;
	return topView != nil ? topView : activeAppWindow;
}

- (void)block {
    [self blockView:nil];
}
- (void)blockView:(UIView *)viewToBlock {
	if (HFS_ISBLOCKED_FLAG) return;
	
	HFS_PROGRESSBAR_STOPPER = 0;
	UIView *topView = (viewToBlock == nil ? [self pickCurrentTopView] : viewToBlock);
	if (topView == nil) {
        return;
    }
	//init activityIndicatorView
	HFS_BLOCKER_VIEW = [[UIView alloc] initWithFrame:topView.frame];//CGRectMake(0.0f, 0.0f, 320.0f, 416.0f)];
	HFS_BLOCKER_VIEW.opaque = NO;
	HFS_BLOCKER_VIEW.userInteractionEnabled = YES;
	HFS_BLOCKER_VIEW.clipsToBounds = YES;
	HFS_BLOCKER_VIEW.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.5f];
	HFS_BLOCKER_VIEW.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	HFS_BLOCKER_VIEW.tag = constActivityIndicatorView;
	
	UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] 
								initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	activityIndicator.frame = CGRectMake(topView.frame.size.width/2-18.0f,
										 topView.frame.size.height/2-18.0f,
										 37.0f, 37.0f);//(141.0f, 192.0f, 37.0f, 37.0f);
	activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
	[activityIndicator startAnimating];
	
	[HFS_BLOCKER_VIEW addSubview:activityIndicator];
	[topView addSubview:HFS_BLOCKER_VIEW];

	HFS_ISBLOCKED_FLAG = YES;
	
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.001]];	
}

- (void)unblock {
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.001]];	
	
	if (!HFS_ISBLOCKED_FLAG) return;

	[HFS_BLOCKER_VIEW removeFromSuperview];
	HFS_BLOCKER_VIEW = nil;
	
	if (HFS_PROGRESSBAR_VIEW != nil) {
		[HFS_PROGRESSBAR_VIEW removeFromSuperview];
		HFS_PROGRESSBAR_VIEW = nil;
	}
	
	HFS_ISBLOCKED_FLAG = NO;
}

- (void)setProgressMessage:(NSString *)message {
	if (!HFS_ISBLOCKED_FLAG) return;

	HFS_PROGRESSBAR_STOPPER++;
	BOOL debug = NO;
	NSTimeInterval delay = debug ? 1 : 0.001;
	if (debug || HFS_PROGRESSBAR_STOPPER == 1 || HFS_PROGRESSBAR_STOPPER%77 == 0) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:delay]];	
	}

	UILabel *percentLabel = nil;

	if (HFS_PROGRESSBAR_VIEW == nil) {
		HFS_PROGRESSBAR_VIEW = [[UIView alloc] initWithFrame:CGRectMake(HFS_BLOCKER_VIEW.bounds.size.width/2-150.0f, 
																	HFS_BLOCKER_VIEW.bounds.size.height/2-150.0f, 
																	300.0f, 240.0f)];
		HFS_PROGRESSBAR_VIEW.tag = constProgressBarView;
		HFS_PROGRESSBAR_VIEW.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
		[HFS_BLOCKER_VIEW addSubview:HFS_PROGRESSBAR_VIEW];
		
		CGRect top,bottom;
		CGRectDivide(HFS_PROGRESSBAR_VIEW.bounds, &top, &bottom, 180.0f, CGRectMinYEdge);
		
		percentLabel = [[UILabel alloc] initWithFrame:bottom];
		percentLabel.textAlignment = UITextAlignmentCenter;
		percentLabel.font = [UIFont systemFontOfSize:constMediumFontSize];
		percentLabel.backgroundColor = constColorLightTransparentWhite();
		percentLabel.textColor = constColorFontGreen();
		percentLabel.layer.cornerRadius = 5.0f;
		[HFS_PROGRESSBAR_VIEW addSubview:percentLabel];
	}
	percentLabel = [[HFS_PROGRESSBAR_VIEW subviews] objectAtIndex:0];
	percentLabel.text = message;
}

@end
