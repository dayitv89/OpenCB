#import "RootViewController.h"

@interface InterceptorWindow : UIWindow
{
	UIView *target;     
    RootViewController *eventsDelegate;
	BOOL scrolling;
}

@property (nonatomic, strong) UIView *target;
@property (nonatomic,strong) UIViewController *eventsDelegate;

- (void)setWithTarget:(UIView *)targetView eventsDelegate:(UIViewController *)delegateController frame:(CGRect)aRect;
- (void)tap:(UITouch *)touch;
- (void)scroll:(UITouch *)touch;

@end
