#import <StoreKit/StoreKit.h>
#import "BaseFetchedTableViewController.h"
#import "RootViewController.h"
#import "StoreTableCell.h"
#import "BookDetailsViewController.h"
#import "ZipDownloader.h"

@interface StoreTableViewController : BaseFetchedTableViewController 
    <StoreTableCellDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver, UIWebViewDelegate, ZipDownloaderDelegate> {
    UIView *tableViewPlaceholderView;
    UIBarButtonItem *reloadButton;
    
    NSMutableData * responseData;
    NSMutableArray *remoteArray;

    UIWebView * storeDetailsWebView;
    UIActivityIndicatorView *activityView;
   
    UITapGestureRecognizer * tapGestureRecognizer;
}

- (id)initWithTabBarFrame:(CGRect)frame;

- (void) sortAndFilterData:(NSString *) pubName;

- (void)requestProductData;
- (void)productPurchaseRequested:(NSIndexPath *)indexPath;
- (void)requestProductData;
- (void)buyProduct:(NSString*)productId;

@end
