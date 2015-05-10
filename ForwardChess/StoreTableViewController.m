#import "StoreTableViewController.h"
#import "StoreEntity.h"
#import "StoreItem.h"
#import "LibraryEntity.h"
#import "UIViewController+Blockable.h"
#import "ZipDownloader.h"
#import "SHKActivityIndicator.h"
#import <QuartzCore/QuartzCore.h>
#import "Flurry.h"
#import "Appirater.h"

#define initialPage @"http://chess-stars.com/download/annotations.html"
#define freeText @"Free"

@interface StoreTableViewController()
{
    NSString * currentSelectedItemId;
    BOOL needShowBuyButton;
    BOOL storeRefreshed;
}

@end

@interface StoreTableViewController(PrivateMethods)

-(void) requestProductData;
-(void) restoreTransaction:(SKPaymentTransaction *)transaction;
-(void) failedTransaction:(SKPaymentTransaction *)transaction;
-(void) recordTransaction:(SKPaymentTransaction *)transaction;
-(void) completeTransaction:(SKPaymentTransaction *)transaction;

-(void) provideContent:(NSString *)productId canShowReview:(BOOL)canShowReview;

@end

@implementation StoreTableViewController

#pragma mark common methods
- (id)initWithTabBarFrame:(CGRect)frame {
    if ((self = [super initWithNibName:nil bundle:nil])) {
        
        
        [[SHKActivityIndicator currentIndicator] displayActivity:@"Please wait"];
        
        self.title = @"Store";
        self.tabBarItem.image = [UIImage imageNamed:@"Store.png"];
        self.navigationItem.title = @"Book Store";
        self.view.frame = frame;
        self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.view.opaque = YES;
        
        self.entityName = @"StoreItem";
        self.sectionNameKeyPath = nil;
        
        tableViewPlaceholderView = [[UIView alloc] init];
        //tableViewPlaceholderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            
            storeDetailsWebView = [[UIWebView alloc] init];
            storeDetailsWebView.delegate = self;
            needShowBuyButton = YES;
            [storeDetailsWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:initialPage]]];

        }
          
        storeDetailsWebView = [[UIWebView alloc] init];
        storeDetailsWebView.delegate = self;
        needShowBuyButton = YES;
        [storeDetailsWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:initialPage]]];
        activityView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        
        reloadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(onRefresh)];
        
        UIBarButtonItem * const restoreTransActionsButton = [[UIBarButtonItem alloc] initWithTitle:@"Restore Transactions" style:UIBarButtonItemStyleBordered target:self action:@selector(restoreTransactions)];
        
        self.navigationItem.rightBarButtonItems = @[reloadButton ,restoreTransActionsButton];
        
        [self.view addSubview:tableViewPlaceholderView];
        [self.view addSubview:storeDetailsWebView];
        
        
        
       //sort:
        NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc]
                                            initWithKey:@"dateUploaded" ascending:NO];
        sortDescriptors = [[NSArray alloc] initWithObjects: sortDescriptor, nil];

        [self performFetch];

        //6 Adding Transaction Observer
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        
        
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            
            tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
            tapGestureRecognizer.numberOfTapsRequired = 1;
            tapGestureRecognizer.cancelsTouchesInView = NO;
            [self.view addGestureRecognizer:tapGestureRecognizer];
        }
    }

    return self;
}

- (void) onTap: (UITapGestureRecognizer *) sender{
    if(UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)){
        [storeDetailsWebView removeFromSuperview];
    }
}

- (void) sortAndFilterData:(NSString *) pubName{
    
    self.screenName = [NSString stringWithFormat:@"Store %@", pubName];
    
    
    predicate = nil;
    
    if (pubName != nil) {
        //Filter:
        predicate = [NSPredicate predicateWithFormat:@"publisherName like[cd] %@",pubName];
        self.screenName = [NSString stringWithFormat:@"Store %@", pubName];
        
    }else{
        self.screenName = [NSString stringWithFormat:@"Store"];
    }
    //Sort:
    NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc]
                                        initWithKey:@"dateUploaded" ascending:NO];
    sortDescriptors = [[NSArray alloc] initWithObjects: sortDescriptor, nil];
    
    
    [self performFetch];
}

-(void) viewDidLoad{
    [super viewDidLoad];
    
    currentSelectedItemId = @"com.forwardChess.chessBook1";
    
    [[SHKActivityIndicator currentIndicator] hide];
}

-(void) viewDidAppear:(BOOL)animated
{
    [self didRotateFromInterfaceOrientation:nil];
    
    //refresh store only once
    if ( ! storeRefreshed)
    {
        [self loadPlistFile];
        storeRefreshed = YES;
    }    
}

- (void) onRefresh{
    [self loadPlistFile];
}

#pragma mark Restore

-(BOOL) showCanMakePayments
{
    if (![SKPaymentQueue canMakePayments])
    {
        [[[UIAlertView alloc] initWithTitle:@"Transaction Failed"
                                    message:@"Online Store is not supported on your device. Please contact Apple if you have any questions."
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil, nil] show];
        return YES;
    }

    return NO;
}

-(void) restoreTransactions
{
    if ([self showCanMakePayments])
    {
        return;
    }

    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

#pragma end

-(void) loadPlistFile
{
    responseData = [[NSMutableData alloc] init];

    //http://chess-stars.com/ipad/books.plist
    
    NSURLRequest * const request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://smallchess.com/OpenCB/books.plist"] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:60.0];
    NSURLConnection *theConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];

    if (theConnection) {
        //NSLog(@"Connection open.");
    }
    else {
        //NSLog(@"Failed connecting.");
    }
}

-(void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [responseData setLength:0];
}

-(void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [responseData appendData:data];
}

-(void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    remoteArray = [NSPropertyListSerialization propertyListWithData:responseData options:NSPropertyListImmutable format:nil error:nil];
    
    [self requestProductData];
    

}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    //NSLog(@"connectionDidFailWithError %@",error);
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return YES;
}


-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if(UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)){
            [self.view addSubview: storeDetailsWebView];
            tableViewPlaceholderView.frame = CGRectMake(0, 0, self.view.bounds.size.width/2.0, self.view.bounds.size.height);
            storeDetailsWebView.frame = CGRectMake(self.view.bounds.size.width/2.0, 0, self.view.bounds.size.width/2.0, self.view.bounds.size.height);
            ////NSLog(@"%f, %f", storeDetailsWebView.frame.size.width, storeDetailsWebView.frame.size.height);
            storeDetailsWebView.hidden = NO;
        }
        else{
            [storeDetailsWebView removeFromSuperview];
            tableViewPlaceholderView.frame = self.view.bounds;
            storeDetailsWebView.frame = CGRectMake((self.view.bounds.size.width-512)/2.0, (self.view.bounds.size.height-655)/2.0, 512, 655);
        }
    }else{ //IPHONE:
        [storeDetailsWebView removeFromSuperview];
        tableViewPlaceholderView.frame = self.view.bounds;
    }
}



#pragma mark store items info methods
- (void)requestProductData {
    //NSLog(@"StoreTableViewController requestProductData");

    [reloadButton setEnabled:NO];
    [self blockView:tableViewPlaceholderView];
    NSMutableSet *productSet = [[NSMutableSet alloc] init];
        
    for (NSDictionary *item in remoteArray) {
        NSString *productId = [item valueForKey:@"id"];
       [productSet addObject:productId];
    }
    if (remoteArray.count > 0) {
        currentSelectedItemId = [[remoteArray objectAtIndex:0] valueForKey:@"id"];
    }
        
    /*3 Sending Request*/
    SKProductsRequest *productRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productSet];
    productRequest.delegate = self;
    [productRequest start];
}

/*4 Getting request from iTunes Connect*/
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    //NSLog(@"StoreTableViewController productsRequest didReceiveResponse");
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    StoreEntity *storeEntity = [[StoreEntity alloc] init];
    [storeEntity depreciateStoreItems];
    
    NSArray *storeData = response.products;
    
    for (SKProduct *item in storeData) {
        NSPredicate *storeEntityPredicate = [NSPredicate predicateWithFormat:@"bookId == %@", item.productIdentifier];
        StoreItem *storeItem = (StoreItem *)[storeEntity getItemForPredicate:storeEntityPredicate];
        
        
        //This if is only used for the initial storeDetailsWebView page
        if ([item.productIdentifier isEqualToString:currentSelectedItemId]) {
            if (storeItem != nil){
                if (storeItem.purchaseDate != nil) {
                    needShowBuyButton = NO;
                    [storeDetailsWebView stringByEvaluatingJavaScriptFromString:@"document.getElementById('buyButton').style.display='none';"];
                }
            }
        }
    
        if (storeItem == nil) {
            
            for (NSDictionary *localItem in remoteArray) {
                NSString *localProductId = [localItem valueForKey:@"id"];
                if([item.productIdentifier isEqualToString:localProductId]) {
                    storeItem = [storeEntity createStoreItem];
                    storeItem.bookId = item.productIdentifier;
                    storeItem.title = [localItem valueForKey:@"title"];
                    storeItem.icon = [localItem valueForKey:@"icon"];
                    storeItem.author = [localItem valueForKey:@"author"];
                    storeItem.path = [localItem valueForKey:@"path"];
                    
                    storeItem.bookDetails = [localItem valueForKey:@"bookDetailsURL"];
                    
                    //new
                    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                    [dateFormat setDateFormat:@"dd/MM/yyyy"];
                    NSDate *date = [dateFormat dateFromString:[localItem valueForKey:@"dateUploaded"]];
                    storeItem.dateUploaded = date;
                    storeItem.publisherName = [localItem valueForKey:@"publisher"];
                    storeItem.freePath = [localItem valueForKey:@"freePath"];
                    
                    break;
                }
            }
        }else{ //update that item:
            
            for (NSDictionary *localItem in remoteArray) {
                NSString *localProductId = [localItem valueForKey:@"id"];
                if([item.productIdentifier isEqualToString:localProductId]) {
                    storeItem.bookId = item.productIdentifier;
                    storeItem.title = [localItem valueForKey:@"title"];
                    storeItem.icon = [localItem valueForKey:@"icon"];
                    storeItem.author = [localItem valueForKey:@"author"];
                    storeItem.path = [localItem valueForKey:@"path"];
                    
                    storeItem.bookDetails = [localItem valueForKey:@"bookDetailsURL"];

                    //new
                    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                    [dateFormat setDateFormat:@"dd/MM/yyyy"];
                    NSDate *date = [dateFormat dateFromString:[localItem valueForKey:@"dateUploaded"]];
                    storeItem.dateUploaded = date;
                    storeItem.publisherName = [localItem valueForKey:@"publisher"];
                    storeItem.freePath = [localItem valueForKey:@"freePath"];

                    
                    break;
                }
            }
        }
        
        [numberFormatter setLocale:item.priceLocale];
        NSString *price = [numberFormatter stringFromNumber:item.price];
        storeItem.price = price;        
        storeItem.systemSyncStatus = constSyncStatusWorking;
        
    }
    
    
    //Free Items:
    NSArray * failedProducts = response.invalidProductIdentifiers;
    for (NSDictionary *localItem in remoteArray) {
        NSString *localProductId = [localItem valueForKey:@"id"];
                
        for (NSString * failedProductID in failedProducts) {
            if ([failedProductID isEqualToString:localProductId]) {
                if ([[localItem objectForKey:@"free"] isEqualToString:@"isFree"]) {
                    
                    NSPredicate *storeEntityPredicate = [NSPredicate predicateWithFormat:@"bookId == %@", failedProductID];
                    StoreItem *storeItem = (StoreItem *)[storeEntity getItemForPredicate:storeEntityPredicate];
                    
                    if (storeItem == nil) {
                        storeItem = [storeEntity createStoreItem];
                    }
                    
                    storeItem.bookId = failedProductID;
                    storeItem.title = [localItem valueForKey:@"title"];
                    storeItem.icon = [localItem valueForKey:@"icon"];
                    storeItem.author = [localItem valueForKey:@"author"];
                    storeItem.path = [localItem valueForKey:@"path"];
                    storeItem.bookDetails = [localItem valueForKey:@"bookDetailsURL"];
                    storeItem.publisherName = [localItem valueForKey:@"publisher"];
                    
                    storeItem.price = freeText;
                    storeItem.systemSyncStatus = constSyncStatusWorking;
                    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                    [dateFormat setDateFormat:@"dd/MM/yyyy"];
                    NSDate *date = [dateFormat dateFromString:[localItem valueForKey:@"dateUploaded"]];
                    storeItem.dateUploaded = date;
                    
                    break;
                }
            }
        }
        
    }
    
    [storeEntity deleteStoreItemsMarkedForRemoval];
    
    [self.appDelegate.coreDataProxy saveData];
    
    [reloadButton setEnabled:YES];
    [self unblock];
}

#pragma mark - sample request

- (void) freeSampleRequested: (NSIndexPath *) indexPath{
    StoreItem *storeItem = (StoreItem *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    
    [self provideSampleContent:storeItem.bookId];
    
}

#pragma mark - store items purchase methods -

-(void) productPurchaseRequested:(NSIndexPath *)indexPath
{
    //NSLog(@"StoreTableViewController productPurchaseRequested");
    StoreItem * const storeItem = (StoreItem *)[self.fetchedResultsController objectAtIndexPath:indexPath];

    if ([storeItem.price isEqualToString:freeText])
    {
        [self provideContent:storeItem.bookId canShowReview:YES];
    }
    else
    {
        [self buyProduct:storeItem.bookId];
    }
}

-(void) buyProduct:(NSString *)productId
{
    StoreEntity * const storeEntity = [[StoreEntity alloc] init];
    NSPredicate * const storeEntityPredicate = [NSPredicate predicateWithFormat:@"bookId == %@", productId];
    StoreItem * const storeItem = (StoreItem *)[storeEntity getItemForPredicate:storeEntityPredicate];

    if (storeItem)
    {
        if ([storeItem.price isEqualToString:freeText] && [storeItem.bookId isEqualToString:productId])
        {
            // Never show a review prompt if the user isn't purchasing anything
            [self provideContent:storeItem.bookId canShowReview:NO];
            return;
        }
    }
    
	if ([SKPaymentQueue canMakePayments])
    {
		[[SKPaymentQueue defaultQueue] addPayment:[SKPayment paymentWithProductIdentifier:productId]];

        @try
        {
             [Flurry logEvent:@"userBuysBook" withParameters:@{@"bookName":storeItem.title, @"publisher": storeItem.publisherName, @"author" : storeItem.author, @"price" : storeItem.price}];
        }
        @catch (NSException *exception)
        {
            [Flurry logEvent:@"userBuysBook" withParameters:@{@"bookName":storeItem.title}];
        }
	}
	else
    {
		[[[UIAlertView alloc] initWithTitle:@"AppStore Purchase Request Failure"
                                    message:@"User is not allowed to purchase from AppStore"
                                   delegate:self
                          cancelButtonTitle:@"OK"
                                otherButtonTitles: nil] show];
	}
}

#pragma mark SKPaymentTransactionObserver

-(void) paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased: { [self completeTransaction:transaction]; break; }
            case SKPaymentTransactionStateFailed:    { [self failedTransaction:transaction];   break; }
            case SKPaymentTransactionStateRestored:  { [self restoreTransaction:transaction];  break; }
        }
    }
}

-(void) completeTransaction:(SKPaymentTransaction *)transaction
{
    [self recordTransaction:transaction];
    [self provideContent:transaction.payment.productIdentifier canShowReview:YES];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

-(void) restoreTransaction:(SKPaymentTransaction *)transaction
{
    [Flurry logEvent:@"RestoredTransaction"];
    [self recordTransaction:transaction];
    
    // Never ask for review for books that have already been purchased
    [self provideContent:transaction.originalTransaction.payment.productIdentifier canShowReview:NO];

    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

-(void) failedTransaction:(SKPaymentTransaction *)transaction
{
    //NSLog(@"StoreTableViewController failedTransaction");
    if (transaction.error.code != SKErrorPaymentCancelled) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"AppStore Purchase Request Failure" 
                                                        message:transaction.error.localizedDescription
													   delegate:self 
                                              cancelButtonTitle:@"OK" 
                                              otherButtonTitles: nil];
		[alert show];
    }

    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)recordTransaction:(SKPaymentTransaction *)transaction {
    //NSLog(@"StoreTableViewController recordTransaction");    
}

#pragma end

-(void) addProductToDevice:(NSString *)productID
{
    NSArray * const purchasedSet = [[NSUserDefaults standardUserDefaults] objectForKey:@"PurchasedProductIDs"];
    
    NSMutableArray * const purchasedMSet = purchasedSet ? [[NSMutableArray alloc] initWithArray:purchasedSet] :
                                                          [[NSMutableArray alloc] init];
    [purchasedMSet addObject:productID];

    [[NSUserDefaults standardUserDefaults] setObject:purchasedMSet forKey:@"PurchasedProductIDs"];
}

-(void) provideContent:(NSString *)productId canShowReview:(BOOL)canShowReview
{
    StoreEntity *storeEntity = [[StoreEntity alloc] init];
    NSPredicate *storeEntityPredicate = [NSPredicate predicateWithFormat:@"bookId == %@", productId];
    StoreItem *storeItem = (StoreItem *)[storeEntity getItemForPredicate:storeEntityPredicate];
    
    //Provide content only if productID exists on storeEntity
    if (!storeItem)
    {
        return;
    }
   
    if (  !  [storeItem.price isEqualToString:freeText]) {
        storeItem.purchaseDate = [NSDate date];
    }

    LibraryEntity *libraryEntity = [[LibraryEntity alloc] init];
    NSPredicate *libraryEntityPredicate = [NSPredicate predicateWithFormat:@"bookId == %@", productId];
    LibraryItem *libraryItem = (LibraryItem *)[libraryEntity getItemForPredicate:libraryEntityPredicate];

    /*
     * Show a prompt if this is the second or more purchase. tryToShowPrompt will handle cases that the
     * user has already declined to rate.
     */

    if (canShowReview && [[[NSUserDefaults standardUserDefaults] objectForKey:@"PurchasedProductIDs"] count] >= 1)
    {
        [Appirater tryToShowPrompt];
    }

    ZipDownloader * const zipDownloader = [[ZipDownloader alloc] init];
    [zipDownloader downloadZipAtURL:storeItem.path withID:productId];
    zipDownloader.delegate = self;

    [self addProductToDevice:productId];
   
    if (libraryItem == nil) {
        libraryItem = [libraryEntity createLibraryItem];
        libraryItem.title = storeItem.title;
        libraryItem.author = storeItem.author;
        libraryItem.path = zipDownloader.extractionPath;
        libraryItem.icon = storeItem.icon;
        libraryItem.bookId = storeItem.bookId;
    }else{
        
        //delete old folder
        NSError * error;
        NSFileManager *fileManager =[NSFileManager defaultManager];
        [fileManager removeItemAtPath:libraryItem.path error:&error];
        
        //save path of the new one
        libraryItem.path = zipDownloader.extractionPath;
    }
    
    //Delete Sample:
    NSError * error;
    NSFileManager *fileManager =[NSFileManager defaultManager];
    [fileManager removeItemAtPath:libraryItem.freePath error:&error];

    [self.appDelegate.coreDataProxy saveData];
    [[SHKActivityIndicator currentIndicator] displayActivity:@"Downloading book"];
}

//FREE SAMPLES:
-(void) provideSampleContent:(NSString *)productId
{
    [[SHKActivityIndicator currentIndicator] displayActivity:@"Downloading Sample book"];
    
    StoreEntity *storeEntity = [[StoreEntity alloc] init];
    NSPredicate *storeEntityPredicate = [NSPredicate predicateWithFormat:@"bookId == %@", productId];
    StoreItem *storeItem = (StoreItem *)[storeEntity getItemForPredicate:storeEntityPredicate];

    //Provide content only if productID exists on storeEntity
    if (storeItem == nil) {
        return;
    }

    LibraryEntity *libraryEntity = [[LibraryEntity alloc] init];
    NSPredicate *libraryEntityPredicate = [NSPredicate predicateWithFormat:@"bookId == %@", productId];
    LibraryItem *libraryItem = (LibraryItem *)[libraryEntity getItemForPredicate:libraryEntityPredicate];
    
    
    ZipDownloader * zipDownloader = [[ZipDownloader alloc] init];
    const BOOL success = [zipDownloader downloadZipAtURL:storeItem.freePath withID:productId];

    if (success == NO)
    {
        [[SHKActivityIndicator currentIndicator] displayWarning:@"Sample not found!"];
    }
    else
    {
        zipDownloader.delegate = self;

        if (libraryItem == nil)
        {
            libraryItem = [libraryEntity createLibraryItem];
            libraryItem.title = storeItem.title;
            libraryItem.author = storeItem.author;
            libraryItem.freePath = zipDownloader.extractionPath; // :)
            libraryItem.icon = storeItem.icon;
            libraryItem.bookId = storeItem.bookId;
            libraryItem.datePurchased = [NSDate date];
            libraryItem.publisherName = storeItem.publisherName;
        }
        else
        {
            //delete old folder
            NSError * error;
            NSFileManager *fileManager =[NSFileManager defaultManager];
            [fileManager removeItemAtPath:libraryItem.freePath error:&error];
            
            //save path of the new one
            libraryItem.freePath = zipDownloader.extractionPath;
        }

        [self.appDelegate.coreDataProxy saveData];
    }
    
    @try {
        [Flurry logEvent:@"freeSampleDownloaded" withParameters:@{@"bookName":storeItem.title, @"publisher": storeItem.publisherName, @"author" : storeItem.author, @"price" : storeItem.price}];
    }
    @catch (NSException *exception) {
        [Flurry logEvent:@"freeSampleDownloaded" withParameters:@{@"bookName":storeItem.title}];
    }
}

-(void) zipDownloaderDidFinishUnzipping
{
   [[SHKActivityIndicator currentIndicator] displayCompleted:@"Done!"];
}

#pragma mark UITableView methods

-(void)downloadingServerImageFromUrl:(UIImageView*)imgView AndUrl:(NSString*)strUrl{
    
    //strUrl = [strUrl encodeUrl];
    
    NSString* theFileName = [NSString stringWithFormat:@"%@.png",[[strUrl lastPathComponent] stringByDeletingPathExtension]];
    
    
    NSFileManager *fileManager =[NSFileManager defaultManager];
    NSString *fileName = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"tmp/%@",theFileName]];
    
    
    
    imgView.backgroundColor = [UIColor darkGrayColor];
    UIActivityIndicatorView *actView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [imgView addSubview:actView];
    [actView startAnimating];
    
    CGSize boundsSize = imgView.bounds.size;
    CGRect frameToCenter = actView.frame;
    // center horizontally
    if (frameToCenter.size.width < boundsSize.width)
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    else
        frameToCenter.origin.x = 0;
    
    // center vertically
    if (frameToCenter.size.height < boundsSize.height)
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    else
        frameToCenter.origin.y = 0;
    
    actView.frame = frameToCenter;
    
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        NSData *dataFromFile = nil;
        NSData *dataFromUrl = nil;
        
        dataFromFile = [fileManager contentsAtPath:fileName];
        if(dataFromFile==nil){
            dataFromUrl=[[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:strUrl]];
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            if(dataFromFile!=nil){
                imgView.image = [UIImage imageWithData:dataFromFile];
               // [tableView reloadData];
            }else if(dataFromUrl!=nil){
                imgView.image = [UIImage imageWithData:dataFromUrl];
                NSString *fileName = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"tmp/%@",theFileName]];
                
                BOOL filecreationSuccess = [fileManager createFileAtPath:fileName contents:dataFromUrl attributes:nil];
                if(filecreationSuccess == NO){
                    //NSLog(@"Failed to create the html file");
                }
                
            }else{
                imgView.image = [UIImage imageNamed:@"Store.png"];  
            }
            [actView removeFromSuperview];
            [imgView setBackgroundColor:[UIColor clearColor]];
            //[tableView reloadData];
        });
    });
    
    
}

- (void)selectCellAtIndexPath:(NSIndexPath *)indexPath {
    StoreItem *storeItem = (StoreItem *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    
    @try {
        [Flurry logEvent:@"ViewedDetailsForBook" withParameters:@{@"bookName":storeItem.title, @"publisher": storeItem.publisherName, @"author" : storeItem.author, @"price" : storeItem.price}];
    }
    @catch (NSException *exception) {}

    
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        BookDetailsViewController * vc= [[BookDetailsViewController alloc] initWithNibName:nil bundle:nil];
        currentSelectedItemId = storeItem.bookId;
        vc.currentItem = @{@"id": currentSelectedItemId, @"sample": storeItem.bookDetails};
        [vc showWebViewWithBuyButtin:needShowBuyButton];
        
        [self.navigationController pushViewController:vc animated:YES];
    }else{
        
        
        [storeDetailsWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString: storeItem.bookDetails]]];
        
        currentSelectedItemId = storeItem.bookId;
        needShowBuyButton = (storeItem.purchaseDate == nil);
        
        activityView.frame = CGRectMake(storeDetailsWebView.bounds.size.width/2, storeDetailsWebView.bounds.size.height/2, 100, 100);
        [storeDetailsWebView addSubview:activityView];
        [activityView startAnimating];
        
        if(UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)){
            [self.view addSubview:storeDetailsWebView];
        }
    }
    
}

- (UITableViewCell *)prepareCellForIndexPath:(NSIndexPath *)indexPath {
    StoreTableCell *cell = (StoreTableCell *)[self.tableView dequeueReusableCellWithIdentifier:@"storeCell"];
    if (!cell) {
        cell = [[StoreTableCell alloc] initWithReuseIdentifier:@"storeCell" delegate:self];
        cell.accessoryType = UITableViewCellAccessoryNone;
        
    }
    return cell;
}

- (void)processCell:(UITableViewCell *)cell fromIndexPath:(NSIndexPath *)indexPath {
    StoreTableCell *storeTableCell = (StoreTableCell *)cell;
    StoreItem *storeItem = (StoreItem *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    storeTableCell.bookTitle.text = storeItem.title;
    storeTableCell.detailInfo.text = [NSString stringWithFormat:@"%@", storeItem.author];
    storeTableCell.indexPath = indexPath;

    
    
    if (storeItem.purchaseDate != nil) {
        storeTableCell.purchaseButton.hidden = YES;
        storeTableCell.purchaseDate.hidden = NO;
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MMM dd, yyyy"];
        NSString *dateString = [dateFormatter stringFromDate:storeItem.purchaseDate];
        storeTableCell.purchaseDate.text = dateString;
        
        storeTableCell.freeButton.hidden = YES;
   }
   else {
       storeTableCell.purchaseButton.hidden = NO; 
        [storeTableCell.purchaseButton setTitle:storeItem.price forState:UIControlStateNormal];
       storeTableCell.purchaseDate.hidden = YES;
       
       
       if (storeItem.freePath) {
           storeTableCell.freeButton.hidden = NO;
       }else{
           storeTableCell.freeButton.hidden = YES;
       }

       
   }
    
    [self downloadingServerImageFromUrl:storeTableCell.iconView AndUrl:storeItem.icon];
    
    
    //If book is free... hide sample button:
    if ([storeItem.price isEqualToString:freeText]) {
        storeTableCell.freeButton.hidden = YES;
    }

    
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    [self selectCellAtIndexPath:indexPath];
}

- (UIView *)tableViewPlaceholder {
    return tableViewPlaceholderView;
}

#pragma mark - UIWebViewDelagate

-(void) webViewDidFinishLoad:(UIWebView *)webView
{
    [activityView stopAnimating];
    [activityView removeFromSuperview];

    if (needShowBuyButton == NO) {
        [webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('buyButton').style.display='none';"];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    //...
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if([[request.URL absoluteString] isEqualToString:initialPage]) {
        return YES;
    }
    
    StoreEntity *storeEntity = [[StoreEntity alloc] init];
    NSPredicate *storeEntityPredicate = [NSPredicate predicateWithFormat:@"bookId == %@", currentSelectedItemId];
    StoreItem *storeItem = (StoreItem *)[storeEntity getItemForPredicate:storeEntityPredicate];
    if ([storeItem.bookDetails isEqualToString: [request.URL absoluteString]]) {
        return YES;
    }else{
        if ([request.URL.absoluteString rangeOfString:@"onBuyButton"].location != NSNotFound) {
            [self buyProduct:currentSelectedItemId];
            return NO;
        }else {//if ([request.URL.absoluteString rangeOfString:@".pdf"].location != NSNotFound) {
            BOOL succes = [[UIApplication sharedApplication] openURL:[request URL]];
            return !succes;
        }

    
    }
    return YES;
}


#pragma mark - touches

#pragma mark - misc methods
- (void)dealloc {
    storeDetailsWebView.delegate = nil;
    
    
    
}
@end

