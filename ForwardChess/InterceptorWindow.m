#import "InterceptorWindow.h"
#import <QuartzCore/QuartzCore.h>

@implementation InterceptorWindow

@synthesize target;
@synthesize eventsDelegate;

- (void)setWithTarget:(UIView *)targetView eventsDelegate:(UIViewController *)delegateController frame:(CGRect)aRect {
	self.target = targetView;
	self.eventsDelegate = delegateController;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

// get events (taps) on book and chessboard view;
- (void)sendEvent:(UIEvent *)event {
	// At the moment, all the events are propagated (by calling the sendEvent method
	// in the parent class) except single-finger multitaps.	
	BOOL shouldCallParent = YES;
	if (event.type == UIEventTypeTouches) {
		NSSet *touches = [event allTouches];		
		if (touches.count == 1) {
			UITouch *touch = touches.anyObject;
			
			if (touch.phase == UITouchPhaseBegan) {
				scrolling = NO;
			} else if (touch.phase == UITouchPhaseMoved) {
				scrolling = YES;
			}
			
			if (touch.tapCount > 1) {
				if (touch.phase == UITouchPhaseEnded && !scrolling) {
					// Touch is not the first of multiple subsequent touches
					[self performSelector:@selector(tap:) withObject:touch];
				}
				shouldCallParent = NO;
			} else if ([touch.view isDescendantOfView:self.target] == YES) {
				if (scrolling) {
					[self performSelector:@selector(scroll:) withObject:touch];
				} else if (touch.phase == UITouchPhaseEnded) {
					// Touch was on the target view (or one of its descendants)
					// and a single tap has just been completed
					[self performSelector:@selector(tap:) withObject:touch];
				}
			}
		}
	}
	
	if (shouldCallParent) {
		[super sendEvent:event];
	}
}

- (void)tap:(UITouch *)touch {
	[eventsDelegate userDidTap:touch];
}
- (void)scroll:(UITouch *)touch {
	[eventsDelegate userDidScroll:touch];
}


@end