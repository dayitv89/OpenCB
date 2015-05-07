#import "BookDetailsViewController.h"
#import "StoreTableViewController.h"

@implementation BookDetailsViewController

BOOL needShowBuyButton;

@synthesize currentItem;

-(id) init
{
    if (self = [super initWithNibName:nil bundle:nil])
    {
        self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }

    return self;
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.screenName = @"Book Details";
}

-(void) showWebViewWithBuyButtin:(BOOL)needBuyButton
{
    UIWebView * const annotationView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    annotationView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    annotationView.mediaPlaybackRequiresUserAction = YES;
    annotationView.backgroundColor = [UIColor clearColor];
    annotationView.scalesPageToFit = NO;
    annotationView.delegate = self;
    
    NSString *urlString = [self.currentItem valueForKey:@"sample"];
    NSURL * url = [NSURL URLWithString:urlString];
    [annotationView loadRequest:[NSURLRequest requestWithURL:url]];
    
    needShowBuyButton = needBuyButton;
    [self.view addSubview:annotationView];   

    UIActivityIndicatorView * ind = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(500, 500, 50, 50)];
    [ind startAnimating];
    ind.tag = 456;
    [self.view addSubview:ind];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{

    if ([request.URL.absoluteString rangeOfString:@"onBuyButton"].location != NSNotFound) {
        NSArray *controllerArray = self.navigationController.viewControllers;
        if ([controllerArray count]>1) {
            [[controllerArray objectAtIndex:[controllerArray count]-2] buyProduct:[self.currentItem valueForKey:@"id"]];
            [self.navigationController popViewControllerAnimated:YES];
        }
        return NO;
    }
    
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [[self.view viewWithTag:456] removeFromSuperview];
    
    
    if (needShowBuyButton == NO) {
        [webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('buyButton').style.display='none';"];
        
    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark - Table view data source




@end
