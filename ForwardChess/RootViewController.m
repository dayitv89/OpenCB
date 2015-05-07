#import "Constants.h"
#import "RootViewController.h"
#import "EngineViewController.h"
#import "OptionsViewController.h"
#import "ForwardChessAppDelegate.h"
#import "BookmarkViewController.h"

@interface UserNotes : NSObject
{
    @public
        NSString *text;
        NSNumber *offset;
        NSNumber *page;
        NSString *bookID;
}

@end

@implementation UserNotes

-(void) encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self->text   forKey:@"Text"];
    [encoder encodeObject:self->offset forKey:@"Offset"];
    [encoder encodeObject:self->page   forKey:@"Page"];
    [encoder encodeObject:self->bookID forKey:@"BookID"];
}

-(id) initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init]))
    {
        self->text   = [decoder decodeObjectForKey:@"Text"];
        self->offset = [decoder decodeObjectForKey:@"Offset"];
        self->page   = [decoder decodeObjectForKey:@"Page"];
        self->bookID = [decoder decodeObjectForKey:@"BookID"];
    }

    return self;
}

@end

RootViewController *__rootViewController__;

#define tagDecreaseFontSizeButton 100
#define tagIncreaseFontSizeButton 200

@interface RootViewController()
{
    // The note currently visible
    UserNotes *_shownNotes;

    // The note button be displayed to the right of the book
    UIButton *_shownNotesButton;

    // This is needed for the dialog
    UserNotes *_notesForDialog;

    // These are buttons required for updating
    UIButton *_saveButton, *_deleteButton;

    // The area where _saveButton and _deleteButton are shown
    UIView *_panelView;

    __weak UITextView *_textView;
    
    UIBarButtonItem *enginButton;
    UIBarButtonItem *showChessBoardButton;
    UIBarButtonItem *optionsButton;
    UIBarButtonItem *showTOCButton;
    UIBarButtonItem *scrollToTopButton;
    BOOL deviceIsOldIOS;    
    BookWindowViewController *bookWindowViewController;
    ChessBoardViewController *boardViewController;
    ChessStepsViewController * chessStepsViewController;
    EngineViewController *_engineViewController;
    BookLayoutView *bookLayoutView;
    BookTOCViewController *tocViewController;
    OptionsViewController * optionsViewController;
    UIPopoverController * tocPopover;
    UIPopoverController * optionsPopover;
    UIToolbar *navBarRightToolbar;
}

@end

@implementation RootViewController

@synthesize bookWindowViewController;

-(id) initWithFrame:(CGRect)frame andLibraryItem:(LibraryItem *)libraryItem
{
    if((self = [super initWithNibName:nil bundle:nil]))
    {
        _item = libraryItem;
        
        self.hidesBottomBarWhenPushed = YES; 
        BOOL deviceIsPad = UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone;
        if (deviceIsPad == YES) {
            self.navigationItem.title = libraryItem.title;
        }

        deviceIsOldIOS = [[[UIDevice currentDevice] systemVersion] floatValue] <= 5.9 ? YES : NO;

        bookLayoutView = [[BookLayoutView alloc] initWithFrame:frame delegate:self];
        bookLayoutView.showChessBoard = NO;
        self.view = bookLayoutView;
        
        /*
         * Initalize JavaScript chess board
         */
        
        boardViewController = [[ChessBoardViewController alloc] initWithFrame:bookLayoutView.boardView.bounds];
        [boardViewController setBookViewController:self];

        /*
         * Initalize book view (for showing the book contents)
         */
        
        bookWindowViewController = [[BookWindowViewController alloc] initWithFrame:bookLayoutView.bookView.bounds delegate:self andEntity:libraryItem];
        [bookWindowViewController setChessBoardDelegate:boardViewController];

        /*
         * Initalize engine view
         */
        
        _engineViewController = [[EngineViewController alloc] initWithFrame:bookLayoutView.engineView.bounds];

        [bookLayoutView.engineView addSubview:_engineViewController.view];
        [bookLayoutView.boardView addSubview:boardViewController.view];
        [bookLayoutView.bookView addSubview:bookWindowViewController.view];

        [boardViewController setBookWindowDelegate:bookWindowViewController];

        chessStepsViewController = [[ChessStepsViewController alloc] initWithFrame:bookLayoutView.stepsView.bounds];
        chessStepsViewController.rootController = self;

        if (deviceIsPad == YES)
        {
            [bookLayoutView.stepsView addSubview:chessStepsViewController.view];
        }

        [bookWindowViewController setGameDescriptionDelegate:chessStepsViewController];
        
        InterceptorWindow *win = ((ForwardChessAppDelegate *)[[UIApplication sharedApplication] delegate]).interceptorWindow;
        [win setWithTarget:bookLayoutView eventsDelegate:self frame:self.view.bounds];    

        navBarRightToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 200.0f, 44.0f)];
        navBarRightToolbar.autoresizingMask = UIViewAutoresizingFlexibleHeight;

        showTOCButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Contents.png"]
                                                         style:UIBarButtonItemStyleBordered
                                                        target:self
                                                        action:@selector(showContentToolbarButtonPressed:)];

        enginButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Engine.png"]
                                                       style:UIBarButtonItemStyleBordered
                                                      target:self
                                                      action:@selector(showEnginePressed)];
        
        showChessBoardButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Board.png"]
                                                                style:UIBarButtonItemStyleBordered
                                                               target:self
                                                               action:@selector(showChessBoardButtonPressed)];

        optionsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Settings.png"]
                                                         style:UIBarButtonItemStylePlain
                                                        target:self
                                                        action:@selector(onOptions:)];

        scrollToTopButton = [[UIBarButtonItem alloc] initWithTitle:@"Top"
                                                             style:UIBarButtonItemStyleBordered
                                                            target:self
                                                            action:@selector(scrollToTop)];

        [showChessBoardButton setEnabled:NO];
        [scrollToTopButton setEnabled:NO];
        [optionsButton setEnabled:NO];
        [showTOCButton setEnabled:YES];
        [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:scrollToTopButton, optionsButton, enginButton, showChessBoardButton, showTOCButton, nil]];
        
        tocViewController = [[BookTOCViewController alloc] initWithTocVCDelegate:self];
        optionsViewController = [[OptionsViewController alloc] initWithNibName:nil bundle:nil];
        optionsViewController.delegate = self;

        if (deviceIsPad == YES)
        {
            tocPopover = [[UIPopoverController alloc] initWithContentViewController:tocViewController];
            optionsPopover = [[UIPopoverController alloc] initWithContentViewController:optionsViewController];
            [optionsPopover setPopoverContentSize:optionsViewController.view.frame.size];
        }
        
        __rootViewController__ = self;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startAnalysis) name:@"BoardHasUpdated" object:nil];
    }
    
    return self;
}

-(void) viewDidLoad
{
    [super viewDidLoad];
    [self optionsViewControllerDismissed];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    bookLayoutView.borderLine.hidden = NO;
}

-(void) reloadLayout
{
    [bookLayoutView setNeedsLayout];
}

-(void) dismissOptionsPopTip
{
    [optionsPopover dismissPopoverAnimated:YES];
}

#pragma mark OptionsViewControllerDelegate

UIPopoverController *popController;

-(void) dismissBookmarkForiPad
{
    [popController dismissPopoverAnimated:YES];
    [self dismissOptionsPopTip];
}

-(void) bookmarkDidClicked
{
    if ((UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone))
    {
        UIViewController * const controller = [[BookmarkViewController alloc] initWithNibName:@"BookmarkViewController~ipad" bundle:nil];
        popController = [[UIPopoverController alloc] initWithContentViewController:controller];
        [popController presentPopoverFromBarButtonItem:optionsButton permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }
    else
    {
        UIViewController * const controller = [[BookmarkViewController alloc] initWithNibName:@"BookmarkViewController~iphone" bundle:nil];
        [self dismissViewControllerAnimated:YES completion:^{
            [self presentModalViewController:controller animated:YES];
        }];
    }
}

-(void) notesDidClicked
{
    if ((UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone))
    {
        [self showNotesDialog:nil];
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:^{
            [self showNotesDialog:nil];
        }];
    }
}

#pragma mark Notes

-(void) showNotesDialog:(UserNotes *)notes
{
    // We need it so when we return we know it's a new add entry or an existing entry
    _notesForDialog = notes;
    
    [__rootViewController__ performSelector:@selector(dismissOptionsPopTip) withObject:nil];
    
    NSLog(@"There're %d notes in total", [[self getNotes] count]);
    NSLog(@"There're %d notes on this page", [[self getNotes:__rootViewController__.item.bookId page:[[bookWindowViewController getCurrentPage] intValue]] count]);
    
    UITextView * const textView = [[UITextView alloc] init];
    [textView setAlpha:0.70];
    [textView setTextColor:[UIColor whiteColor]];
    [textView setFont:[UIFont systemFontOfSize:17.0f]];
    [textView setBackgroundColor:[UIColor blackColor]];
    
    const UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    // We need to adjust the number of lines if we also need to show the save and delete buttons
    const BOOL needToShowSaveAndDelete = _notesForDialog;

    if ((UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone))
    {
        if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)
        {
            [textView setFrame:CGRectMake(170, 10, 700, 250)];
        }
        else
        {
            [textView setFrame:CGRectMake(100, 10, 570, 400)];
        }
    }
    else
    {
        #define IS_IPHONE_5 ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )
        
        if (!IS_IPHONE_5)
        {
            if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)
            {
                [textView setFrame:CGRectMake(10, 10, 370, needToShowSaveAndDelete ? 43 : 60)];
            }
            else
            {
                [textView setFrame:CGRectMake(10, 10, 300, 130)];
            }
        }
        else
        {
            if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)
            {
                [textView setFrame:CGRectMake(10, 10, 370, needToShowSaveAndDelete ? 50 : 80)];
            }
            else
            {
                [textView setFrame:CGRectMake(10, 10, 300, 200)];
            }
        }
    }

    [__rootViewController__.view addSubview:textView];
    
    // If this is an update, we'll need an option to delete it
    if (_notesForDialog)
    {
        const CGFloat width = textView.frame.size.width;
        const CGFloat padding = 5.0;

        const CGFloat buttonWidth = (width - (3 * padding)) / 2.0;
        const CGFloat y = textView.frame.origin.y + textView.frame.size.height + 5.0;

        _panelView = [[UIView alloc] initWithFrame:CGRectMake(textView.frame.origin.x, y, textView.frame.size.width, 44.0)];
        [_panelView setBackgroundColor:[UIColor blackColor]];
        [_panelView setAlpha:0.7];

        _saveButton   = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _deleteButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];

        [_saveButton setTitle:@"Save" forState:UIControlStateNormal];
        [_saveButton setFrame:CGRectMake(textView.frame.origin.x + padding, y, buttonWidth, 44.0)];

        [_deleteButton setTitle:@"Delete" forState:UIControlStateNormal];
        [_deleteButton setFrame:CGRectMake(textView.frame.origin.x + width - padding - buttonWidth, y, buttonWidth, 44.0)];

        [_saveButton.titleLabel setFont:[UIFont boldSystemFontOfSize:21.0]];
        [_deleteButton.titleLabel setFont:[UIFont boldSystemFontOfSize:21.0]];
        [_saveButton.titleLabel setTextColor:[UIColor whiteColor]];
        [_deleteButton.titleLabel setTextColor:[UIColor whiteColor]];

        [_saveButton addTarget:self action:@selector(updateButtonDidClicked) forControlEvents:UIControlEventTouchDown];
        [_deleteButton addTarget:self action:@selector(deleteButtonDidClicked) forControlEvents:UIControlEventTouchDown];

        // We'll need a reference to dismiss it
        _textView = textView;

        [textView setText:_notesForDialog->text];
        [__rootViewController__.view addSubview:_panelView];
        [__rootViewController__.view addSubview:_saveButton];
        [__rootViewController__.view addSubview:_deleteButton];
    }

    [textView setDelegate:self];
    [textView becomeFirstResponder];
}

-(void) updateButtonDidClicked
{
    NSAssert(_notesForDialog, @"Failed to update something that is not visible");
    [self textViewDidEndEditing:_textView];
}

-(void) deleteButtonDidClicked
{
    NSAssert(_notesForDialog, @"Failed to delete something that is not visible");
    [self deleteNotes:_notesForDialog];
}

-(void) saveForNotes:(NSMutableArray *)root
{
    NSData * const encodedObject = [NSKeyedArchiver archivedDataWithRootObject:root];
    NSUserDefaults * const defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:encodedObject forKey:@"KeyForNotes"];
    [defaults synchronize];
}

-(void) deleteNotes:(UserNotes *)notes
{
    NSMutableArray * const newNotes = [[NSMutableArray alloc] init];
    NSMutableArray * const oldNotes = [[NSMutableArray alloc] initWithArray:[self getNotes]];

    BOOL deleted = NO;
    
    for (UserNotes * oldNote in oldNotes)
    {
        if (!deleted && [oldNote->bookID isEqualToString:notes->bookID] && [oldNote->page floatValue] == [notes->page floatValue] && [oldNote->offset floatValue] == [notes->offset floatValue] && [oldNote->text isEqualToString:notes->text])
        {
            deleted = YES;
            continue;
        }

        [newNotes addObject:oldNote];
    }

    NSAssert(deleted, @"Failed to find a user notes to delete");

    [self dismissTextView:_textView];
    [self saveForNotes:newNotes];
    [self showNotes];
}

-(void) updateNotes:(UserNotes *)notes
{
    NSMutableArray * const mRoot = [[NSMutableArray alloc] initWithArray:[self getNotes]];

    for (UserNotes * mNotes in mRoot)
    {
        if ([mNotes->bookID isEqualToString:notes->bookID] && [mNotes->page floatValue] == [notes->page floatValue] && [mNotes->offset floatValue] == [notes->offset floatValue])
        {
            mNotes->text = notes->text;
            [self saveForNotes:mRoot];
            
            // We've found the updating entry
            return;
        }
    }

    NSAssert(NO, @".... We're asked to update, but we can't find one!!!!");
}

-(void) addNotes:(NSString *)bookID page:(NSUInteger)page offset:(CGFloat)offset text:(NSString *)text
{
    NSArray * root = [self getNotes];
    
    if (!root)
    {
        root = [[NSArray alloc] init];
    }

    NSMutableArray * const mRoot = [[NSMutableArray alloc] initWithArray:root];
    
    UserNotes * const notes = [[UserNotes alloc] init];
    notes->bookID = bookID;
    notes->page = [NSNumber numberWithInt:page];
    notes->offset = [NSNumber numberWithFloat:offset];
    notes->text = text;
    [mRoot addObject:notes];

    NSData * const encodedObject = [NSKeyedArchiver archivedDataWithRootObject:mRoot];
    NSUserDefaults * const defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:encodedObject forKey:@"KeyForNotes"];
    [defaults synchronize];

    NSLog(@"After adding, there're %d notes", [[self getNotes] count]);

    // Let's update the user interface
    [self showNotes];
}

// Returns all notes for all books
-(NSArray *) getNotes
{
    NSUserDefaults * const defaults = [NSUserDefaults standardUserDefaults];
    NSData * const encodedObject = [defaults objectForKey:@"KeyForNotes"];
    return [NSKeyedUnarchiver unarchiveObjectWithData:encodedObject];
}

// Returns notes for a particular book and page
-(NSArray *) getNotes:(NSString *)bookID page:(NSUInteger)page
{
    NSMutableArray * const y = [[NSMutableArray alloc] init];
    NSMutableArray * const x = [[NSMutableArray alloc] initWithArray:[self getNotes]];

    for (NSUInteger i = 0; i < [x count]; i++)
    {
        UserNotes * const notes = [x objectAtIndex:i];
        
        if ([notes->bookID isEqualToString:bookID] && [notes->page intValue] == page)
        {
            [y addObject:notes];
        }
    }
    
    return y;
}

// Display buttons for user notes to the right of the book
-(void) showNotes
{
    [_shownNotesButton removeFromSuperview];
    _shownNotesButton = nil;

    /*
     * We'll need to position the notes to the right. How do we do it? The x-position should be depend
     * on the width of the container. The y-position should be depend on the offset.
     */
    
    NSArray * const notes = [self getNotes:__rootViewController__.item.bookId page:[[bookWindowViewController getCurrentPage] intValue]];

    const CGFloat width  = 48.0;
    const CGFloat height = 48.0;

    /*
     * The behavior is similar to the Android app. We add it to a fixed position relative to the container.
     */
    
    const CGFloat x = (bookLayoutView.bookView.frame.origin.x + bookLayoutView.bookView.frame.size.width - width - 5.0);
    const CGFloat y = 15.0;

    // We need the current offset to determine whether we'd want to show anything
    const CGFloat offset = [[bookWindowViewController getCurrentOffset] floatValue];

    // This is the value from a note to another
    const CGFloat margin = 250.0;

    NSLog(@"...Checking to show any notes button, there're %d.", [notes count]);

    for (NSUInteger i = 0; i < [notes count]; i++)
    {
        UserNotes * const note = [notes objectAtIndex:i];

        /*
         * Just because we have something, it doesn't mean that we'll show it. We only show it if
         * it's within some margin of our current offset.
         */

        if (fabs(offset - [note->offset floatValue]) <= margin)
        {
            _shownNotes = note;

            NSLog(@"--------- Showed a note button on offset: %f", offset);
            
            _shownNotesButton = [[UIButton alloc] initWithFrame:CGRectMake(x, y, width, height)];
            [_shownNotesButton setImage:[UIImage imageNamed:@"ic_menu_note"] forState:UIControlStateNormal];
            [_shownNotesButton addTarget:self action:@selector(noteButtonDidClicked:) forControlEvents:UIControlEventTouchDown];

            // The consequence is that the button doesn't move while scrolling (like the Android app)
            [bookLayoutView.bookView addSubview:_shownNotesButton];

            /*
             * We always only need to show at most one, there could be more but they must have been added after
             * this selection. Our implementation is an array and we always add a new entry to the back of it.
             */
            
            return;
        }
    }
}

-(void) noteButtonDidClicked:(UIButton *)button
{
    [self showNotesDialog:_shownNotes];
}

#pragma end

#pragma mark UITextViewDelegate

-(void) dismissTextView:(UITextView *)textView
{
    [textView removeFromSuperview];
    [textView resignFirstResponder];

    // Don't see a scenario that we still need this reference (only for an existing entry)
    _textView = nil;
}

-(void) textViewDidEndEditing:(UITextView *)textView
{
    [_panelView removeFromSuperview];
    [_saveButton removeFromSuperview];
    [_deleteButton removeFromSuperview];

    _saveButton = _deleteButton = nil;

    if (_notesForDialog)
    {
        _notesForDialog->text = textView.text;
        [self updateNotes:_notesForDialog];
    }
    else
    {
        [self addNotes:__rootViewController__.item.bookId
                  page:[[bookWindowViewController getCurrentPage] intValue]
                offset:[[bookWindowViewController getCurrentOffset] floatValue]
                  text:textView.text];
    }

    [self dismissTextView:textView];
    [self showNotes];
    _notesForDialog = nil;
}

#pragma end

-(void) optionsViewControllerDismissed
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    int fontSizePercentage = [[defaults objectForKey:constFontSizePercentage] intValue];
    int boardSizePercentage = [[defaults objectForKey:constBoardSizePercentage] intValue];
    
    NSString *jsString1 = [NSString stringWithFormat:@"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust='%d%%';", fontSizePercentage];
    [bookWindowViewController.currPage stringByEvaluatingJavaScriptFromString:jsString1];
    
    NSString *jsString2 = [NSString stringWithFormat:@"var elems = document.getElementsByClassName('dia12'); for(var i = 0; i < elems.length; i++) { elems[i].style.webkitTextSizeAdjust = '%d%%'; }",boardSizePercentage];
    [bookWindowViewController.currPage stringByEvaluatingJavaScriptFromString:jsString2];
    
    NSString *jsString3 = [NSString stringWithFormat:@"var elems = document.getElementsByClassName('diagram'); for(var i = 0; i < elems.length; i++) { elems[i].style.webkitTextSizeAdjust = '%d%%'; }",boardSizePercentage];
    [bookWindowViewController.currPage stringByEvaluatingJavaScriptFromString:jsString3];

    bookWindowViewController.autoscrollEnabled = [[defaults objectForKey:constAutscrollEnabled] boolValue];
}

-(void) optionsViewControllerChangedBoardStyle
{
    [bookWindowViewController->chessBoardDelegate performSelector:@selector(switchBoardStyle)];
    //    [bookWindowViewController getFenSanMoveTextFromHtmlForGame:0];
  //  [bookWindowViewController performSelector:@selector(executeJS:) withObject:bookWindowViewController.lastJSMoveMade afterDelay:0.8];
}

-(void) optionViewControllerCoordChanged
{
    [bookWindowViewController->chessBoardDelegate showCoords];
}

#pragma end

#pragma mark BookTOCViewControllerDelegate methods:

- (void)navigateToPage:(NSString *) pageString{
    [bookWindowViewController changePage: pageString];
}

- (void)dismiss {
    BOOL deviceIsPad = (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone);
    if (!deviceIsPad) {
        [self dismissModalViewControllerAnimated:YES];
    }
    else {
        [tocPopover dismissPopoverAnimated:YES];
    }
}

#pragma mark BookViewDelegate

-(void) pageContentHasScrolled:(UIScrollView *)scrollView
{
    // The simplest way to update is just remove it and try again
    [self showNotes];
}

-(void) pageLoaded:(int)page
{
    [self showNotes];
    
    if (page == constBookCoverPageNumber) {
        [showChessBoardButton setEnabled:NO];
        [optionsButton setEnabled:NO];
        [showTOCButton setEnabled:YES];
        [scrollToTopButton setEnabled:NO];
    }else if(page == constBookContentsPageNumber){
        [showChessBoardButton setEnabled:NO];
        [optionsButton setEnabled:YES];
        [showTOCButton setEnabled:NO];
        [scrollToTopButton setEnabled:YES];
    }else{
        [showChessBoardButton setEnabled:YES];
        [optionsButton setEnabled:YES];
        [showTOCButton setEnabled:YES];
        [scrollToTopButton setEnabled:YES];
        
        if(deviceIsOldIOS){
            bookLayoutView.showChessBoard = YES;
        }
    }

    if (page == constBookContentsPageNumber || page == constBookCoverPageNumber)
    {
        bookLayoutView.showChessBoard = NO;
        [bookLayoutView setNeedsLayout];
    }
}

#pragma mark tab bar actions

- (void) onOptions:(UIBarButtonItem *)barButton {
    
    BOOL deviceIsPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    if (deviceIsPad) {
        [optionsPopover presentPopoverFromBarButtonItem:barButton permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
        
    }
    else {
        optionsViewController.modalTransitionStyle = UIModalTransitionStylePartialCurl;
        [self presentModalViewController:optionsViewController animated:YES];
    }

}

/*
- (IBAction)changeTextFontSize:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    int fontSizePercentage = [[defaults objectForKey:constFontSizePercentage] intValue];
    int tag = ((UIBarButtonItem *)sender).tag;
    switch (tag) {
        case tagDecreaseFontSizeButton:
            fontSizePercentage = 
                (fontSizePercentage > constFontSizePercentageMin) ? fontSizePercentage - constFontSizePercentageStep : fontSizePercentage;
            break;
        case tagIncreaseFontSizeButton:
            fontSizePercentage = 
                (fontSizePercentage < constFontSizePercentageMax) ? fontSizePercentage + constFontSizePercentageStep : fontSizePercentage;
            break;            
        default:
            break;
    }   
    [defaults setObject:[NSNumber numberWithInt:fontSizePercentage] forKey:constFontSizePercentage];
    [defaults synchronize];
    
    NSString *jsString = 
        [NSString stringWithFormat:@"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust='%d%%';", fontSizePercentage];
    [bookWindowViewController.currPage stringByEvaluatingJavaScriptFromString:jsString];
}
*/

-(void) showContentToolbarButtonPressed:(UIBarButtonItem *)item
{
    [bookWindowViewController loadWebView:tocViewController.tocWebView withPage:constBookContentsPageNumber];
    [tocViewController.tocWebView setAlpha:1.0f];

    NSString * const jsString1 = [NSString stringWithFormat:@"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust='%d%%';", 150];
    [tocViewController.tocWebView stringByEvaluatingJavaScriptFromString:jsString1];
    [tocViewController.tocWebView performSelector:@selector(stringByEvaluatingJavaScriptFromString:) withObject:jsString1 afterDelay:0.2];

    if ((UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone))
    {
        [tocPopover presentPopoverFromBarButtonItem:item permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }
    else
    {
        [self presentModalViewController:tocViewController animated:YES];
    }
}

-(void) scrollToTop
{
    [bookWindowViewController.currPage.scrollView setContentOffset:CGPointZero animated:YES];
}

-(void) showEnginePressed
{
    bookLayoutView.showEngine = !bookLayoutView.showEngine;
    [bookLayoutView setNeedsLayout];

    if (bookLayoutView.showEngine)
    {
        [self startAnalysis];
    }
    else
    {
        [_engineViewController stopAnalysis];
    }
}

-(void) startAnalysis
{
    if (bookLayoutView.showEngine)
    {
        [_engineViewController startAnalysis:[boardViewController getFEN]];
    }
}

-(void) showChessBoardButtonPressed
{
    bookLayoutView.showChessBoard = !bookLayoutView.showChessBoard;
    [bookLayoutView setNeedsLayout];
}

-(void) showChessBoard
{
    if(bookLayoutView.showChessBoard == NO)
    {
        bookLayoutView.showChessBoard = YES;
        [bookLayoutView setNeedsLayout];    
    }
}

- (void) titleChanged:(NSString *)title{
    bookLayoutView.labelView.text = title;
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    bookLayoutView.borderLine.hidden = YES;
    [bookLayoutView layoutSubviews];
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    bookLayoutView.borderLine.hidden = NO;
}

#pragma mark BookLayoutViewDelegate methods:
- (void)onLayout {
    /*
    optionsButton.imageInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    showChessBoardButton.imageInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    showTOCButton.imageInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    scrollToTopButton.imageInsets = UIEdgeInsetsMake(0, 0, 0, 0);
*/
    [bookWindowViewController resetScrollView];
}

-(void) userDidTap:(UITouch *)touch
{
    if (!bookLayoutView.showChessBoard || (bookLayoutView.showChessBoard && ![boardViewController processUserTapWithPoint:touch]))
    {
        [bookWindowViewController processUserTapWithPoint:touch];
    }
}
 
- (void)userDidScroll:(UITouch *)touch {
	////NSLog(@"User did scroll");
}

#pragma mark

#pragma mark - Communiation between chessStepsVC and chessBoardVC:

- (void) clearAllSteps{
    [chessStepsViewController clearAllSteps];
}

- (void) setSteps: (NSString *) stepsString{
    [chessStepsViewController setSteps:stepsString];
}

- (void) clickedButtonAtIndex: (NSInteger) index{
    [boardViewController clickedButtonAtIndex: index];
}

- (void) onNext{
    [boardViewController jsMoveForward];
}

- (void) onPrevious{
    [boardViewController jsMoveBack];
}

@end