#import "GAITrackedViewController.h"

@interface BookDetailsViewController : GAITrackedViewController <UIScrollViewDelegate, UIWebViewDelegate> {
    NSDictionary *currentItem;
}

@property(nonatomic, strong) NSDictionary *currentItem;

- (void)showWebViewWithBuyButtin:(BOOL) needBuyButton;

@end