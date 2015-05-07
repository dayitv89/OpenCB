#import "LibraryItem.h"
#import "ChessboardProtocol.h"
#import "GameDescriptionProtocol.h"
#import "BookViewProtocol.h"
#import "BookViewControllerProtocol.h"
#import "ZipDownloader.h"
#import "GAITrackedViewController.h"

@interface BookWindowViewController : GAITrackedViewController <UIScrollViewDelegate, UIWebViewDelegate, BookViewDelegate, UIAlertViewDelegate, ZipDownloaderDelegate>
{
    @public
    NSString *currentBookID;
    
    UIScrollView *scrollView;
    UIWebView *currPage;
    
    NSString *documentsBookPath;
    NSString *bundleBookPath;
    NSMutableArray *pages;
    NSMutableDictionary *subchaptersDict; //for every key holds an array with SUBchapter filenames!
    int currentPageNumber;
    NSString *pageNameFromURL;
    BOOL currentPageIsDelayingLoading;
   
    LibraryItem *bookData;
    id<BookViewControllerDelegate> bookViewDelegate;
    id<ChessboardDelegate> chessBoardDelegate;
    id<GameDescriptionDelegate> gameDescriptionDelegate;

    NSMutableData * responseData; //bugfix for the update of app - see implementation file
    
    BOOL shouldChangePageOffset;
}

@property(nonatomic, strong) UIScrollView *scrollView;
@property(nonatomic, strong) UIWebView *currPage;
@property() int currentPageNumber;
@property(nonatomic) BOOL autoscrollEnabled;
@property(nonatomic) NSInteger gameN;

// When user changed board we use this to remember the last viewed move
@property(nonatomic, strong)  NSString * lastJSMoveMade;

-(id) initWithFrame:(CGRect)frame
           delegate:(id<BookViewControllerDelegate>)newDelegate 
          andEntity:(LibraryItem *)aBookData;

-(NSNumber *) getCurrentPage;
-(NSNumber *) getCurrentOffset;

- (void)setChessBoardDelegate:(id<ChessboardDelegate>)newDelegate;
- (void)setGameDescriptionDelegate:(id<GameDescriptionDelegate>)newDelegate;

- (void) getFenSanMoveTextFromHtmlForGame: (NSInteger) gameNumber;

-(void) switchToPageWithOffset:(NSUInteger)page offset:(CGFloat)offset;

- (void)resetScrollView;
- (BOOL)processUserTapWithPoint:(UITouch *)touch;
- (void)goUpInPage:(int)offset animating:(BOOL)animating;
- (void)goDownInPage:(int)offset animating:(BOOL)animating;
- (void)changePage: (NSString *) pageString;
- (BOOL)loadWebView:(UIWebView*)webView withPage:(int)page;

@end