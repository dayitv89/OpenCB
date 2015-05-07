@protocol BookTOCViewControllerDelegate<NSObject>
- (void)navigateToPage:(NSString*) pageString;
- (void)dismiss;
@end

@interface BookTOCViewController : UIViewController <UIWebViewDelegate>
{
    UIWebView *tocWebView;
    id<BookTOCViewControllerDelegate> delegate;
}

@property (nonatomic,strong) UIWebView *tocWebView;

-(id) initWithTocVCDelegate:(id<BookTOCViewControllerDelegate>)newDelegate;

@end