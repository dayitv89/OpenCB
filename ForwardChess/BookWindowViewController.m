#import "BookWindowViewController.h"
#import "InterceptorWindow.h"
#import "ForwardChessAppDelegate.h"
#import "Constants.h"
#import "SHKActivityIndicator.h"
#import "ForwardChessAppDelegate.h"
#import "Flurry.h"

//#import "GAI.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"

static NSNumber *__fuckingHackOffset__;

@interface BookWindowViewController(privateMethods)
- (void)initBook:(NSString *)path;
- (void)initPageNumbersForPages:(int)count;
- (CGRect)frameForPage:(int)page;
- (void)showWebView:(UIWebView *)webView animating:(BOOL)animating;
- (void)scrollPage:(UIWebView *)webView to:(int)offset animating:(BOOL)animating;
- (void)gotoPageDelayer;
@end

@implementation BookWindowViewController

@synthesize scrollView, currPage, currentPageNumber;
@synthesize gameN = _gameN;

-(void) setGameN: (NSInteger)value
{
    if (_gameN != value)
    {
       [self getFenSanMoveTextFromHtmlForGame:value];
    }

    _gameN = value;
}

-(id) initWithFrame:(CGRect)frame delegate:(id<BookViewControllerDelegate>)newDelegate andEntity:(LibraryItem *)aBookData
{
    if ((self = [super initWithNibName:nil bundle:nil]))
    {
        bookViewDelegate = newDelegate;
        self.view.frame = frame;   
        self.view.backgroundColor = [UIColor whiteColor];

        bookData = aBookData;
        scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
        scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        scrollView.showsHorizontalScrollIndicator = YES;
        scrollView.showsVerticalScrollIndicator = NO;
        scrollView.delaysContentTouches = NO;
        scrollView.pagingEnabled = YES;
        scrollView.delegate = self;	
        [self.view addSubview:scrollView];
        
        currPage = [[UIWebView alloc] initWithFrame:scrollView.bounds];
        currPage.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        currPage.mediaPlaybackRequiresUserAction = YES;
        currPage.backgroundColor = [UIColor whiteColor];
        currPage.scalesPageToFit = NO;
        currPage.delegate = self;
        [currPage.scrollView setDelegate:self];
        currPage.alpha = 0;
        
        self.autoscrollEnabled = [[[NSUserDefaults standardUserDefaults] valueForKey:constAutscrollEnabled] boolValue];
        
        bundleBookPath = [[NSBundle mainBundle] pathForResource:bookData.path ofType:nil];
        currentBookID = bookData.bookId;
        
        //If file is on bundlePath/bookData.path
        if ([[NSFileManager defaultManager] fileExistsAtPath:bookData.path]) {
            [self initBook:bookData.path];
        }
        //If is a Sample:
        else if([[NSFileManager defaultManager] fileExistsAtPath:bookData.freePath]){
                [[SHKActivityIndicator currentIndicator] displayInfo:@"This is a sample" submessage:nil];
                [self initBook:bookData.freePath];
                
        }//If the filePath was just "/Downloads/book1"
        else if ([[NSFileManager defaultManager] fileExistsAtPath:bundleBookPath]) {
            [self initBook:bundleBookPath];
        }
        else{
                UIAlertView *feedbackAlert = [[UIAlertView alloc] initWithTitle:nil
                                                                        message:@"Book does not exist."
                                                                       delegate:self
                                                              cancelButtonTitle:@"Later"
                                                              otherButtonTitles:@"Download",nil];
                [feedbackAlert show];
        }
        
        self.screenName = @"Book Screen";
        //id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        //[tracker set:kGAIScreenName value:@"Book Screen"];
        //[tracker send:[[GAIDictionaryBuilder createAppView] build]];
        //[tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"UX" action:@"bookName" label:bookData.title value:nil] build]];
        // Clear the screen name field when we're done.
        //[tracker set:kGAIScreenName value:nil];

        UIMenuItem * const customItem = [[UIMenuItem alloc] initWithTitle:@"Highlight" action:@selector(customHighlightAction)];
        [[UIMenuController sharedMenuController] setMenuItems:[NSArray arrayWithObjects:customItem, nil]];
	}

    return self;
}

#pragma mark Highlight Actions

-(BOOL) canPerformAction:(SEL)action withSender:(id)sender
{
    return (action == @selector(customHighlightAction));
}

-(void) customHighlightAction
{
    NSString * const script = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Highlight" ofType:@"js"]
                                                        encoding:NSUTF8StringEncoding
                                                           error:nil];
    
    NSLog(@"%@", [currPage stringByEvaluatingJavaScriptFromString:script]);
    NSLog(@"%@", [currPage stringByEvaluatingJavaScriptFromString:@"action()"]);


}

#pragma end

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Download"]) {
        [[SHKActivityIndicator currentIndicator] displayActivity:@"Loading..."];
        [self loadPlistFile];
        
    }
}

- (void)setChessBoardDelegate:(id<ChessboardDelegate>)newDelegate {
    chessBoardDelegate = newDelegate;
}

- (void)setGameDescriptionDelegate:(id<GameDescriptionDelegate>)newDelegate {
    gameDescriptionDelegate = newDelegate;
}

#pragma mark ChessBoardViewControllerDelegate methods

-(void) applyPGNConvertedToHTML:(NSString *)htmlString
{
    [currPage stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById('BOOKPARSEDHTML').innerHTML = '%@'",htmlString]];    
}

-(void) applyCurrentMove:(NSString *)currentMove
{
    //current move is of type: m2v4
    NSString * highlightString = [NSString stringWithFormat: @"g%d%@",self.gameN,currentMove];
    //adding g1 to m2v4 = g1m2v4
    
    //UnHighlights all links!
    [currPage stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"var links = document.getElementsByTagName(\"a\"); for (var i = 0; i < links.length; i++) { var link = links.item(i); link.style.backgroundColor = \"\" }"]];

    if (self.autoscrollEnabled)
        [currPage stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"HighlightMove('%@')", highlightString]];
    else
        [currPage stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"HighlightMoveNoScrolling('%@')", highlightString]];
}

#pragma mark UIWebViewDelegate

/*
 * It's quite complicated to execute a JavaScript after the other without rewriting at least a part of the architecture and workflow.
 * Here, we content to a simple but hacky implementation - the next JavaScript to be executed is stored in a variable.
 */

static NSString *_elementToJump = nil;

-(void) gotoElement:(UIWebView *)webView;
{
    [webView performSelector:@selector(stringByEvaluatingJavaScriptFromString:) withObject:[NSString stringWithFormat:@"contents_href('%@')", _elementToJump]];
    _elementToJump = nil;
    [self performSelector:@selector(hideWebViewAfterDelay:) withObject:webView afterDelay:0.30];
}

-(void) hideWebViewAfterDelay:(UIWebView *)webView
{
    [webView setHidden:NO];
}

-(void) webViewDidFinishLoad:(UIWebView *)webView
{
    [self setGameN:0];
    [self getFenSanMoveTextFromHtmlForGame:0];
    
    [bookViewDelegate titleChanged:[webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByTagName('title')[0].innerHTML;"]];
    [bookViewDelegate pageLoaded:currentPageNumber];
    [self showWebView:webView animating:YES];

    if (_elementToJump)
    {
        [self gotoElement:webView];
    }
    else if (webView.hidden)
    {
        [self performSelector:@selector(hideWebViewAfterDelay:) withObject:webView afterDelay:0.50];
    }
}

-(BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString * link = [[request URL] relativeString];
    NSLog(@"%@", link);

    /*
     * Atrributes:
     *
     *  1. Crosslink
     *
     *    Crosslink is a link that would allow to to go from one chapter ("page") to another.
     *    One obvious use of such links is indices in the end of the book - players, openings, etc.
     *
     *      "file://contents_href:<chapter_number>#<game_move_variation_name>"
     *      where everything after '#' will be consider a element name for jumping inside that 'chapter_number'
     *
     *      example: file://contents_href:3#g0m38v0
     *      Some existing books will only have file://contents_href:3. as in the Contents
     */

    if ([link hasPrefix:@"file://contents_href"])
    {
        NSArray * const components = [[[link componentsSeparatedByString:@":"] objectAtIndex:2] componentsSeparatedByString:@"#"];
        NSString * chapter   = [components objectAtIndex:0];
        chapter = [chapter stringByReplacingOccurrencesOfString: @"/" withString:@""];

        if ([components count] >= 2)
        {
            NSString * const element = [components objectAtIndex:1];
            
            /*
             * Comments from ForwardChess
             *
             *   "Android allows us to intercept any link clicked in the "webview" and informs the developer about it in a method called "shouldOverrideUrlLoading".
             *    In this method, the developer decides what to do about the link that the user has clicked and take any action. Its straightforward after that
             *    and I only need to check if the link clicked has a "#". What follows after the # is assumed to be the anchor to which we need to scroll after
             *    loading the page. Scrolling to that anchor is achieved with the following javascript (key is the anchor found above):
             *
             *    function scroll() { var elem = document.getElementsByName('"
             *                          + key
             *                          + "')[0]; var x = 0; var y = 0; while (elem != null) { x += elem.offsetLeft; y += elem.offsetTop; elem = elem.offsetParent;} window.scrollTo(x, y - (window.innerHeight/2 - 10)); })"
             */
            
            if (currentPageNumber == [chapter intValue])
            {
                [self gotoContent:element];
            }
            else
            {
                _elementToJump = element;
                [self changePage:chapter];
            }
        }
        else
        {
            [self changePage: [link stringByReplacingOccurrencesOfString:@"file://contents_href:" withString:@""]];
        }

        return NO;
    }
    
    // Contains strings like: file:///SetMove(1,9,0) where gameN #1, move #9, variant #0
    else if ([link hasPrefix:@"file:///SetMove"])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"EngineNeedToBeStopped" object:nil];
        
        NSString *moveStringJS = [link stringByReplacingOccurrencesOfString:@"file:///" withString:@""];

        if ([moveStringJS length])
        {
            /*
             *moveStringJS contains strings like SetMove(1,9,0)
             */
            
            NSArray * array = [moveStringJS componentsSeparatedByString:@","];
            float delay = 0.2;
            
            if(array.count >= 3){
                //getting gameN from array[0];
                NSArray * array2 = [[array objectAtIndex: 0] componentsSeparatedByString:@"("];
                
                if (array2.count >= 2) {
                    int value = [[array2 objectAtIndex: 1] intValue];
                    if(_gameN != value)
                        delay = 0.8;
                    
                    // Note: if this's a new game, the JavaScript board will start a new game
                    self.gameN = value;
                }
                
                moveStringJS = [NSString stringWithFormat:@"SetMove(%@,%@",[array objectAtIndex:1], [array objectAtIndex:2]];
                
                /*
                 * Now moveStringJS should contain strings like SetMove(9,0) where move #9, variant #0
                 */
            }
            
            [bookViewDelegate showChessBoard];
            
            [self performSelector:@selector(executeJS:) withObject:moveStringJS afterDelay:delay];
            
            if (((ChessBoardViewController *)chessBoardDelegate).isRotated)
            {
                [(ChessBoardViewController *)chessBoardDelegate performSelector:@selector(rotateBoardToBlack) withObject:nil afterDelay:delay];
            }
            
            NSString *unhighlightJSString = @"a:hover { color:#FFFFFF; background-color:#000000 }";
            [webView performSelector:@selector(stringByEvaluatingJavaScriptFromString:) withObject:unhighlightJSString afterDelay:0.8+delay];
            
            return NO;
        }
    }
    else if ([link hasPrefix:@"file:///GoToGame"])
    {
        NSArray * const array = [link componentsSeparatedByString:@"("];
        self.gameN = [[array objectAtIndex: 1] intValue];
        NSString * const js = @"SetMove(0,0)";
        [bookViewDelegate showChessBoard];
        [chessBoardDelegate executeJS:js];
        return NO;
    }
    else if ([link hasPrefix:@"file:///GoToNextGame"])
    {
        self.gameN++;
        NSString * js = @"SetMove(0,0)";
        [chessBoardDelegate executeJS:js];
        return NO;
    }
    else if ([link hasPrefix:@"file:///Show("])
    {
        NSArray * const components =  [link componentsSeparatedByString:@"("];
        if ([components count] >= 2) {
            NSString * name = [components objectAtIndex:1];
            if ([name characterAtIndex:name.length-1] == ')') {
                name = [name substringToIndex:name.length-1];
            }
            
            NSString * JSString = [NSString stringWithFormat:@"if(document.getElementById(\'%@\').style.display=='none'){document.getElementById(\'%@\').style.display='';}else{document.getElementById(\'%@\').style.display='none';}",name,name,name];
            [webView stringByEvaluatingJavaScriptFromString:JSString];
            return NO;
        }
    }

    return YES;
}

-(void) executeJS:(NSString *)str
{
    self.lastJSMoveMade = str;
    [chessBoardDelegate executeJS:str];
}

-(void) getFenSanMoveTextFromHtmlForGame:(NSInteger)gameNumber
{
    NSString *san = [currPage stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById('SAN%d').value", gameNumber]];
    NSString *fen = [currPage stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById('FEN%d').value",  gameNumber]];
    NSString *moveText = [currPage stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById('MOVETEXT%d').value",  gameNumber]];
    NSString *eventText = [currPage stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById('EVENT%d').innerHTML",  gameNumber]];
    
    //Replacing ?? with ? in MoveText:
    moveText = [moveText stringByReplacingOccurrencesOfString:@"??" withString:@"?"];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    int fontSizePercentage = [[defaults objectForKey:constFontSizePercentage] intValue];
    int boardSizePercentage = [[defaults objectForKey:constBoardSizePercentage] intValue];
    
    NSString *jsString1 = [NSString stringWithFormat:@"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust='%d%%';", fontSizePercentage];
    [currPage stringByEvaluatingJavaScriptFromString:jsString1];
    
    NSString *jsString2 = [NSString stringWithFormat:@"var elems = document.getElementsByClassName('dia12'); for(var i = 0; i < elems.length; i++) { elems[i].style.webkitTextSizeAdjust = '%d%%'; }",boardSizePercentage];
    [currPage stringByEvaluatingJavaScriptFromString:jsString2];

    NSString *jsString3 = [NSString stringWithFormat:@"var elems = document.getElementsByClassName('diagram'); for(var i = 0; i < elems.length; i++) { elems[i].style.webkitTextSizeAdjust = '%d%%'; }",boardSizePercentage];
    [currPage stringByEvaluatingJavaScriptFromString:jsString3];
    
    
    NSString * const bookJScript = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"book" ofType:@"js"]
                                                             encoding:NSUTF8StringEncoding
                                                                error:nil];
    [currPage stringByEvaluatingJavaScriptFromString:bookJScript];
    
    [chessBoardDelegate initBoardWithFEN:fen SAN:san pgnMoveText:moveText];
    [gameDescriptionDelegate applyGameDescription:eventText];
}

-(void) showWebView:(UIWebView *)webView animating:(BOOL)animating
{
	if (animating == YES)
    {
		webView.alpha = 0.0;
		[UIView beginAnimations:@"webViewVisibility" context:nil]; {
			[UIView setAnimationDuration:0.25];
			webView.alpha = 1.0;
            
            if (__fuckingHackOffset__)
            {
                webView.scrollView.contentOffset = CGPointMake(0, [__fuckingHackOffset__ floatValue]);
            }
            else if (shouldChangePageOffset)
            {
                webView.scrollView.contentOffset = CGPointMake(0, [bookData.lastPageOffset floatValue]);
                shouldChangePageOffset = NO;
            }
            
            __fuckingHackOffset__ = nil;
		}

		[UIView commitAnimations];		
	} 
    else
    {
		webView.alpha = 1.0;
	}
}

-(void) initBook:(NSString *)path
{
    if (pages != nil)
		[pages removeAllObjects];
	else
		pages = [NSMutableArray array];
	
	NSArray *dirContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    NSMutableArray *bookFileNames = [[NSMutableArray alloc] initWithCapacity:0];

    for (NSString *fileName in dirContent)
    {
		if (([[fileName pathExtension] isEqualToString:@"html"] ||
             [[fileName pathExtension] isEqualToString:@"htm"]) &&
            ![fileName isEqualToString:@"0_annotation.html"]) {
            [bookFileNames addObject:fileName];
        }
    }
    
    NSArray *sortedBookFileNames = [bookFileNames sortedArrayUsingComparator:^(id obj1, id obj2)
    {
        int page1Id = [[[(NSString *)obj1 componentsSeparatedByString:constBookPageIdSeparator] objectAtIndex:0] intValue];
        NSNumber *page1Number = [NSNumber numberWithInt:page1Id];
        int page2Id = [[[(NSString *)obj2 componentsSeparatedByString:constBookPageIdSeparator] objectAtIndex:0] intValue];
        NSNumber *page2Number  = [NSNumber numberWithInt:page2Id];
        return (NSComparisonResult)[page1Number compare:page2Number];
    }];
    
	for (NSString *fileName in sortedBookFileNames)
    {
        [pages addObject:[path stringByAppendingPathComponent:fileName]];
	}

	if ([pages count] > 0)
    {
        currentPageNumber = [bookData.lastPageViewed intValue] ? [bookData.lastPageViewed intValue] : 0;

        [self resetScrollView];
		[scrollView addSubview:currPage];
		[self loadWebView:currPage withPage:currentPageNumber];
        
        if ([bookData.lastPageOffset floatValue])
        {
            shouldChangePageOffset = YES;
        }
	}
    else
    {
        UIAlertView *feedbackAlert = [[UIAlertView alloc] initWithTitle:nil
                                                                message:@"Book does not exist."
                                                               delegate:self
                                                      cancelButtonTitle:@"Later"
                                                      otherButtonTitles:@"Download",nil];
        [feedbackAlert show];
        
    }
}

-(void) resetScrollView
{
	for (id subview in scrollView.subviews)
    {
		if (![subview isKindOfClass:[UIWebView class]]) {
			[subview removeFromSuperview];
		}
	}

    scrollView.contentSize = CGSizeMake(self.view.bounds.size.width * [pages count], self.view.bounds.size.height);
	scrollView.frame = self.view.bounds;
    
    [self initPageNumbersForPages:[pages count]];
    
	currPage.frame = [self frameForPage:currentPageNumber];
	[scrollView bringSubviewToFront:currPage];
	[scrollView scrollRectToVisible:[self frameForPage:currentPageNumber] animated:NO];
}

- (void)initPageNumbersForPages:(int)count {	
	for (int i = 0; i < count; i++) {
		// ****** Numbers
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width * i + (self.view.bounds.size.width) / 2, self.view.bounds.size.height / 2 - 6, 100, 50)];
		label.backgroundColor = [UIColor clearColor];
		label.textColor = [UIColor blackColor];
		label.alpha = 0.2;
        
		NSString *labelText = [[NSString alloc] initWithFormat:@"%d", i-1];
        
        if(i == 0)
            labelText = @"";
           
		label.font = [UIFont fontWithName:@"Helvetica" size:40.0];
        label.textAlignment = UITextAlignmentLeft;
		label.text = labelText;
		
		[scrollView addSubview:label];
	}
}

-(CGRect) frameForPage:(int)page
{
    return CGRectMake(self.view.bounds.size.width * page, 0, self.view.bounds.size.width, self.view.bounds.size.height);
}

-(BOOL) loadWebView:(UIWebView*)webView withPage:(int)page
{
	NSString * const path = [pages objectAtIndex:page];

	if ([[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        [webView setAlpha:0];
		[webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];

        //[currPage setHidden:NO];
		return YES;
	}

	return NO;
}

- (BOOL)processUserTapWithPoint:(UITouch *)touch {
    BOOL isProcessed = NO;
    CGPoint tapPoint = [touch locationInView:currPage]; 
    if (CGRectContainsPoint(currPage.bounds, tapPoint)) {
        isProcessed = YES;
    }
        
    return isProcessed;
}

- (void)goUpInPage:(int)offset animating:(BOOL)animating {
    NSString *currPageOffset = [currPage stringByEvaluatingJavaScriptFromString:@"window.scrollY;"];
	int currentPageOffset = [currPageOffset intValue];
    int targetOffset = currentPageOffset - offset;
    if (targetOffset < 0)
        targetOffset = 0;
    [self scrollPage:currPage to:targetOffset animating:animating];
    
}

- (void)goDownInPage:(int)offset animating:(BOOL)animating {
	
    NSString *currPageOffset = [currPage stringByEvaluatingJavaScriptFromString:@"window.scrollY;"];
	int currentPageOffset = [currPageOffset intValue];	
    [self scrollPage:currPage to:currentPageOffset+offset animating:animating];
}

-(void) scrollPage:(UIWebView *)webView to:(int)offset animating:(BOOL)animating
{
    NSString *jsCommand = [NSString stringWithFormat:@"window.scrollTo(0,%i);", offset];
	if (animating) {
		[UIView beginAnimations:@"scrollPage" context:nil]; {
			[UIView setAnimationDuration:0.35];
			[webView stringByEvaluatingJavaScriptFromString:jsCommand];
		}

		[UIView commitAnimations];
	} 
    else
    {
		[webView stringByEvaluatingJavaScriptFromString:jsCommand];
	}
}

-(void) changePage:(NSString *)goToStr
{
    const NSInteger offsetPage = [goToStr intValue];

    if (offsetPage < 0)
    {
		currentPageNumber = 0;
	}
    else if (offsetPage >= [pages count])
    {
        LibraryEntity *libraryEntity = [[LibraryEntity alloc] init];
        NSPredicate *libraryEntityPredicate = [NSPredicate predicateWithFormat:@"bookId == %@", currentBookID];
        LibraryItem *libraryItem = (LibraryItem *)[libraryEntity getItemForPredicate:libraryEntityPredicate];

        if (libraryItem != nil)
        {
            @try
            {
                NSString * isSampleString = @"NO";
                if (libraryItem.path.length == 0)
                    isSampleString = @"YES";

                [Flurry logEvent:@"ReachedTheEndOfBook" withParameters:@{@"title":libraryItem.title, @"author":libraryItem.author,@"publisher": libraryItem.publisherName, @"isSample": isSampleString, @"pageNum" : @(offsetPage)}];
            }
            @catch (NSException *exception) {}
        }

		currentPageNumber = [pages count] - 1;
	}
    else if (offsetPage != currentPageNumber)
    {
		currentPageNumber = offsetPage;
        [scrollView setScrollEnabled:NO];
        [scrollView scrollRectToVisible:[self frameForPage:currentPageNumber] animated:NO];
        float delay = 0.0;

        if ([[[UIDevice currentDevice] systemVersion] floatValue] <= 5.9)
        {
            delay = 0.35;
        }

        [currPage setHidden:YES];
        [self performSelector:@selector(gotoPageDelayer) withObject:nil afterDelay:delay];
	}
}

-(void) saveLastPageViewed:(NSInteger)offsetPage
{
    LibraryEntity *libraryEntity = [[LibraryEntity alloc] init];
    NSPredicate *libraryEntityPredicate = [NSPredicate predicateWithFormat:@"bookId == %@", currentBookID];
    LibraryItem *libraryItem = (LibraryItem *)[libraryEntity getItemForPredicate:libraryEntityPredicate];

    if (libraryItem)
    {
        libraryItem.lastPageViewed = [NSNumber numberWithInteger:offsetPage];
        libraryItem.lastPageOffset = [NSNumber numberWithFloat:currPage.scrollView.contentOffset.y];
    }
    
    ForwardChessAppDelegate * appDelegate = (ForwardChessAppDelegate *) [UIApplication sharedApplication].delegate;
    [appDelegate.coreDataProxy saveData];
}

-(NSNumber *) getCurrentPage
{
    return [NSNumber numberWithInteger:currentPageNumber];
}

-(NSNumber *) getCurrentOffset
{
    return [NSNumber numberWithFloat:currPage.scrollView.contentOffset.y];
}

-(void) gotoPageDelayer
{
	if (currentPageIsDelayingLoading)
    {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(gotoPage) object:nil];
    }

	[currPage setHidden:YES];
	currentPageIsDelayingLoading = YES;
    [self performSelector:@selector(gotoPage) withObject:nil afterDelay:0.15];
}

#pragma mark Page Manipulation

-(void) gotoContent:(NSString *)content
{
    [currPage performSelector:@selector(stringByEvaluatingJavaScriptFromString:) withObject:[NSString stringWithFormat:@"contents_href('%@')", content]];
}

-(void) gotoPage
{
    [self gotoPage:currentPageNumber];
    [self.scrollView setScrollEnabled:YES];
}

-(void) gotoPage:(NSUInteger)n
{
	NSString * const path = [pages objectAtIndex:n];
    [self saveLastPageViewed:n];

	if ([[NSFileManager defaultManager] fileExistsAtPath:path])
    {
		[currPage stopLoading];
    	[currPage setFrame:[self frameForPage:n]];
		[self loadWebView:currPage withPage:n];
	}
}

-(void) switchToPageWithOffset:(NSUInteger)page offset:(CGFloat)offset
{
    currentPageNumber = page;
    __fuckingHackOffset__ = [NSNumber numberWithFloat:offset];

    [self resetScrollView];
    [scrollView addSubview:currPage];
    [self loadWebView:currPage withPage:currentPageNumber];
}

#pragma end

#pragma mark UIScrollViewDelegate

-(void) scrollViewDidScroll:(UIScrollView *)scroll
{
    // Invoke only if the contents of the page has scrolled
    if (scroll == currPage.scrollView)
    {
        [bookViewDelegate pageContentHasScrolled:scroll];
    }
}

-(void) scrollViewDidEndDecelerating:(UIScrollView *)scroll
{
    if (scroll == scrollView)
    {
        const int gotoPage = (int)(self.scrollView.contentOffset.x / self.view.bounds.size.width);
        
        if (currentPageNumber != gotoPage)
        {
            currentPageNumber = gotoPage;
            [self gotoPageDelayer];
        }
    }
    else if (scroll == currPage.scrollView)
    {
        [bookViewDelegate pageContentHasScrolled:scroll];
    }
}

#pragma end

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;	
}

-(void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self resetScrollView];
    [currPage setNeedsDisplay];
}

-(void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self saveLastPageViewed:currentPageNumber];
    [[SHKActivityIndicator currentIndicator] hide];
}

-(void) viewDidUnload
{
	[super viewDidUnload];
    currPage.delegate = nil;
}

-(void) dealloc
{
    [subchaptersDict removeAllObjects];
    bookViewDelegate = nil;
    chessBoardDelegate = nil;
    gameDescriptionDelegate = nil;
}

#pragma mark - BUGFIX: (re-downloads the book again, if missing)
#pragma mark -

- (void) loadPlistFile{
    responseData = [[NSMutableData alloc] init];
    NSURLRequest *theRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://chess-stars.com/ipad/books.plist"] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:60.0];
    NSURLConnection *theConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
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
    NSArray * const remoteArray = [NSPropertyListSerialization propertyListWithData:responseData options:NSPropertyListImmutable format:nil error:nil];
    NSAssert(remoteArray, @"Failed to load plist from the server. Is the file a valid plist?");
    

    for (int i = 0; i<remoteArray.count; i++)
    {
        NSDictionary * dict = [remoteArray objectAtIndex:i];
        NSString *productId = [dict valueForKey:@"id"];
       //NSLog(@"productID %@, currBookID %@",productId, currentBookID);
        
        if ([productId isEqualToString:currentBookID]) {
            LibraryEntity *libraryEntity = [[LibraryEntity alloc] init];
            NSPredicate *libraryEntityPredicate = [NSPredicate predicateWithFormat:@"bookId == %@", productId];
            LibraryItem *libraryItem = (LibraryItem *)[libraryEntity getItemForPredicate:libraryEntityPredicate];
            
            
            ZipDownloader * zipDownloader = [[ZipDownloader alloc] init];
            if (libraryItem != nil) {
                if (libraryItem.path.length > 5) {
                    [zipDownloader downloadZipAtURL:[dict objectForKey:@"path"] withID:productId];
                    zipDownloader.delegate = self;
                    [[SHKActivityIndicator currentIndicator] displayActivity:@"Downloading book"];
                    
                    libraryItem.path = zipDownloader.extractionPath; // :)
                }else if (libraryItem.freePath.length > 5) {
                    [zipDownloader downloadZipAtURL:[dict objectForKey:@"freePath"] withID:productId];
                    zipDownloader.delegate = self;
                    [[SHKActivityIndicator currentIndicator] displayActivity:@"Downloading sample"];
                    
                    libraryItem.freePath = zipDownloader.extractionPath; // :)
                }
                
                
                
            }
            
            ForwardChessAppDelegate * appDelegate = (ForwardChessAppDelegate *) [UIApplication sharedApplication].delegate;
            [appDelegate.coreDataProxy saveData];
            break;
        }
    }
}

- (void) zipDownloaderDidFinishUnzipping{
    [[SHKActivityIndicator currentIndicator] displayCompleted:@"Done!"];
    
    LibraryEntity *libraryEntity = [[LibraryEntity alloc] init];
    NSPredicate *libraryEntityPredicate = [NSPredicate predicateWithFormat:@"bookId == %@", currentBookID];
    LibraryItem *libraryItem = (LibraryItem *)[libraryEntity getItemForPredicate:libraryEntityPredicate];
    if (libraryItem != nil) {
        if (libraryItem.path.length > 4) {
            [self initBook:libraryItem.path ];
        }else{
            [self initBook:libraryItem.freePath ];

        }
    }
    
}

@end