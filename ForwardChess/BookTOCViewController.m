#import "BookTOCViewController.h"

@implementation BookTOCViewController

@synthesize tocWebView;

-(id) initWithTocVCDelegate:(id<BookTOCViewControllerDelegate>)newDelegate
{
    if ((self = [super initWithNibName:nil bundle:nil]))
    {
        self.contentSizeForViewInPopover = CGSizeMake(600.0f, 600.0f);
        BOOL deviceIsPad = (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone);
             
        delegate = newDelegate;
        
        UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
        self.tocWebView = webView;
        tocWebView.delegate = self;

        if (!deviceIsPad)
        {
            CGRect toolbarFrame, tocViewFrame;
            
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
            {
                CGRectDivide(self.view.bounds, &toolbarFrame, &tocViewFrame, 54.0f, CGRectMinYEdge);
            }
            else
            {
                CGRectDivide(self.view.bounds, &toolbarFrame, &tocViewFrame, 34.0f, CGRectMinYEdge);
            }
            
            UIToolbar * const tocViewControllerToolbar = [[UIToolbar alloc] initWithFrame:toolbarFrame];
            tocViewControllerToolbar.barStyle = UIBarStyleDefault;
            tocWebView.frame = tocViewFrame;
            tocWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
            
            tocViewControllerToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            
            UIBarButtonItem * const tocDismissButton =
                [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:delegate action:@selector(dismiss)];
            UIBarButtonItem * const tocToolbarFlexSpace =
                [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            
            [tocViewControllerToolbar setItems:[NSArray arrayWithObjects:tocToolbarFlexSpace, tocDismissButton, nil]];
            [self.view addSubview:tocViewControllerToolbar];
        }
        
        [self.view addSubview:tocWebView];
    }

    return self;
}

#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSString *currentMoveCaptchured;
    currentMoveCaptchured = [[request URL] relativeString];
    if([currentMoveCaptchured hasPrefix:@"file://contents_href:"]) {
        
        NSString * pageString = [currentMoveCaptchured stringByReplacingOccurrencesOfString:@"file://contents_href:" withString:@""];
        [delegate navigateToPage:pageString];
        [delegate dismiss];
        return NO;
    }
    return YES;
}

-(void) webViewDidFinishLoad:(UIWebView *)webView
{
    NSString * const jsString1 = [NSString stringWithFormat:@"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust='%d%%';", 150];
    [tocWebView stringByEvaluatingJavaScriptFromString: jsString1];
    
    
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        webView.frame = CGRectMake(webView.frame.origin.x, webView.frame.origin.y, self.contentSizeForViewInPopover.width, self.contentSizeForViewInPopover.height);
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
     return YES;
}

- (BOOL) shouldAutorotate{
    return YES;
}

- (void)dealloc {
    tocWebView.delegate = nil;
}
@end
