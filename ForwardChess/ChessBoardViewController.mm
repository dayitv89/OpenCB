#import <string>
#import "Constants.h"
#import "ChessBoardViewController.h"
#import "ForwardChessAppDelegate.h"

#define tagBranchSelectionActionSheet 777
#define tagNullMoveActionSheet 778

#define constButtonWidth 55.0f
#define constButtonHeight 40.0f

typedef enum _NextMoveColor {
    NextMoveColorClear = 0,
    NextMoveColorWhite = 1,
    NextMoveColorBlack = 2
} NextMoveColor;  

@interface ChessBoardViewController()
{
    NSString *_lastBoardHTML, *_lastStylePath;
}

@end

@interface ChessBoardViewController(PrivateMethod)
- (void)drawChessCell:(int)corX y:(int)corY figure:(NSString *)figureImage;
- (void)applyPositionAndMoves;
- (void)jsBoardClick:(int)cellIndex;
- (void)reportLastMove;
- (void)setCurrentMoveIndicator:(NextMoveColor)whiteBlack;
@end
    
@implementation ChessBoardViewController

@synthesize isUserMovesEnabled;
@synthesize bookViewController;

static ChessBoardViewController *__chessBoardViewController__;

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithNibName:nil bundle:nil]))
    {
        __chessBoardViewController__ = self;

        _isRotated = NO;
        self.isUserMovesEnabled = NO;

        self.view.frame = frame;
    }

    return self;
}

-(void) viewDidLoad
{
    [super viewDidLoad];

    container = [[ChessBoardLayoutView alloc] initWithFrame:self.view.bounds];
    container.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:container];
    
    /*
     * HACK: This call creates a size for container.boardView.bounds. Without it, the bounds might be zero
     * and the UIWebView chessBoardView might crash with an error like:
     *
     *     "'CALayer position contains NaN: [nan nan]'"
     *
     * Please refer to http://stackoverflow.com/questions/7950199/ios-simulator-5-webview-error-calayerinvalidgeometry
     * for more details.
     */

    [container layoutSubviews];
    
    chessBoardView = [[UIWebView alloc] initWithFrame:container.boardView.bounds];
    chessBoardView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    chessBoardView.userInteractionEnabled = NO;
    chessBoardView.delegate = self;
    [container.boardView addSubview:chessBoardView];

    NSAssert(!CGSizeEqualToSize(container.boardView.frame.size, CGSizeZero), @"Zero size for the UIWebView for the board");

    BOOL deviceIsPad = (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone);
    const UIButtonType buttonType = (deviceIsPad == YES) ? UIButtonTypeRoundedRect : UIButtonTypeCustom;
    
    UIButton * const rotateButton = [UIButton buttonWithType:buttonType];
    rotateButton.backgroundColor = UIColor.clearColor;
    [rotateButton addTarget:self action:@selector(rotateBoard) forControlEvents:UIControlEventTouchUpInside];
    rotateButton.frame = CGRectMake(10.0f, 360.0f, constButtonHeight, constButtonHeight);
    [rotateButton setImage:[UIImage imageNamed:@"Rotate"] forState:UIControlStateNormal];
    
    UIButton * const backButton = [UIButton buttonWithType:buttonType];
    [backButton addTarget:self action:@selector(jsMoveBack) forControlEvents:UIControlEventTouchUpInside];
    backButton.frame = CGRectMake(60.0f, 360.0f, constButtonWidth, constButtonHeight);
    [backButton setImage:[UIImage imageNamed:@"Backward.png"] forState:UIControlStateNormal];
    
    UIButton * const forwardButton = [UIButton buttonWithType:buttonType];
    [forwardButton addTarget:self action:@selector(jsMoveForward) forControlEvents:UIControlEventTouchUpInside];
    forwardButton.frame = CGRectMake(120.0f, 360.0f, constButtonWidth, constButtonHeight);
    [forwardButton setImage:[UIImage imageNamed:@"Forward.png"] forState:UIControlStateNormal];
    
    currentMoveIndicator = [[UILabel alloc] initWithFrame:CGRectMake(350.0f, 373.0f, 20.0f, 20.0f)];
    currentMoveIndicator.backgroundColor = [UIColor clearColor];
    currentMoveIndicator.layer.borderColor = [UIColor clearColor].CGColor;
    currentMoveIndicator.layer.borderWidth = 2.0;
    currentMoveIndicator.layer.cornerRadius = 10;
    
    if (deviceIsPad == NO)
    {
        rotateButton.frame = CGRectOffset(rotateButton.frame, -5, -125);
        backButton.frame = CGRectOffset(backButton.frame, -15, -125);
        forwardButton.frame = CGRectOffset(forwardButton.frame, -25, -125);
        currentMoveIndicator.frame = CGRectOffset(currentMoveIndicator.frame, -100, -125);
    }
    
    [container addSubview:rotateButton];
    [container addSubview:backButton];
    [container addSubview:forwardButton];
    [container addSubview:currentMoveIndicator];
}

-(void) setBookWindowDelegate:(id<BookViewDelegate>)newDelegate
{
    delegate = newDelegate;
}

#pragma mark ChessboardDelegate

-(void) initBoardWithFEN:(NSString *)fen SAN:(NSString *)san pgnMoveText:(NSString *)pgnMoveText
{
    jsSan = [NSString stringWithFormat:@"ApplySAN(\"%@\")",san];
    jsFen = [NSString stringWithFormat:@"Init(unescape(\"%@\"))", fen];
    jsPgn = [NSString stringWithFormat:@"ApplyPgnMoveText(unescape(\"%@\"),\"#CCCCCC\");AllowRecording(true)",pgnMoveText];
    jsGetHTMLMoveText = [NSString stringWithFormat:@"GetHTMLMoveText(0,false,true)"];

    NSString * const pgnViewerPath = [[NSBundle mainBundle] pathForResource:@"pgnviewer" ofType:nil];
    NSString * boardHTMLPath = [pgnViewerPath stringByAppendingPathComponent:@"pgnboard_compact.html"];
    NSString * boardHTMLContent = [NSString stringWithContentsOfFile:boardHTMLPath encoding:NSUTF8StringEncoding error:nil];

    if(![[[NSUserDefaults standardUserDefaults] objectForKey:COORDINATIVE_ENABLED] boolValue])
    {
        boardHTMLContent = [boardHTMLContent stringByReplacingOccurrencesOfString:@"name='RightLabels'"
                                                                       withString:@"name='RightLabels' style='visibility:hidden;'"];
        boardHTMLContent = [boardHTMLContent stringByReplacingOccurrencesOfString:@"name='BottomLabels'"
                                                                       withString:@"name='RBottomLabels' style='visibility:hidden;'"];
    }

    NSString *deviceSpecificBoardContentScaleString = @"0.85";
    boardHTMLContent = [boardHTMLContent stringByReplacingOccurrencesOfString:@"#SCALE#" withString:deviceSpecificBoardContentScaleString];
    
    NSString * styleFolderPath = @"";
    if([[NSUserDefaults standardUserDefaults] objectForKey:keyChessStyle]){
        styleFolderPath = [[NSUserDefaults standardUserDefaults] objectForKey:keyChessStyle];
    }

    _lastStylePath = styleFolderPath;
    
    BOOL deviceIsPad = (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone);

    if (deviceIsPad)
    {
        styleFolderPath = [NSString stringWithFormat:@"%@45x45",styleFolderPath];
    }
    else
    {
        styleFolderPath = [NSString stringWithFormat:@"%@31x31",styleFolderPath];
    }
    
    boardHTMLContent = [boardHTMLContent stringByReplacingOccurrencesOfString:@"#PATH#" withString:styleFolderPath];
    [chessBoardView loadHTMLString:(_lastBoardHTML = boardHTMLContent) baseURL:[NSURL fileURLWithPath:boardHTMLPath]];
    [self setCurrentMoveIndicator:NextMoveColorClear];
}

-(void) switchBoardStyle
{
    NSString * styleFolderPath = @"";
    if([[NSUserDefaults standardUserDefaults] objectForKey:keyChessStyle]){
        styleFolderPath = [[NSUserDefaults standardUserDefaults] objectForKey:keyChessStyle];
    }
    
    NSString * const pgnViewerPath = [[NSBundle mainBundle] pathForResource:@"pgnviewer" ofType:nil];
    NSString * boardHTMLPath = [pgnViewerPath stringByAppendingPathComponent:@"pgnboard_compact.html"];
    
    _lastBoardHTML = [_lastBoardHTML stringByReplacingOccurrencesOfString:_lastStylePath withString:styleFolderPath];
    [chessBoardView loadHTMLString:_lastBoardHTML baseURL:[NSURL fileURLWithPath:boardHTMLPath]];
    
    _lastStylePath = styleFolderPath;
}

-(void) showCoords
{
    const BOOL enabled = [[[NSUserDefaults standardUserDefaults] objectForKey:COORDINATIVE_ENABLED] boolValue];
    
    if (enabled)
    {
        [chessBoardView stringByEvaluatingJavaScriptFromString:@"document.getElementById('RLabels').style.visibility=''"];
        [chessBoardView stringByEvaluatingJavaScriptFromString:@"document.getElementById('BLabels').style.visibility=''"];
    }
    else
    {
        [chessBoardView stringByEvaluatingJavaScriptFromString:@"document.getElementById('RLabels').style.visibility='hidden'"];
        [chessBoardView stringByEvaluatingJavaScriptFromString:@"document.getElementById('BLabels').style.visibility='hidden'"];
    }
}

-(void) webViewDidFinishLoad:(UIWebView *)webView
{
    [chessBoardView stringByEvaluatingJavaScriptFromString:jsSan];
    [chessBoardView stringByEvaluatingJavaScriptFromString:jsFen];
    [chessBoardView stringByEvaluatingJavaScriptFromString:jsPgn];

    generatedHtmlForRenderedPGNFile = [[chessBoardView stringByEvaluatingJavaScriptFromString:jsGetHTMLMoveText] copy];
    [delegate applyPGNConvertedToHTML:generatedHtmlForRenderedPGNFile];

    [self reportLastMove];
    
    /*
     * This is ugly but necessary because starting an analysis is only possible once the JavaScript board has done updating.
     */
    
    [self performSelector:@selector(boardHasUpdated) withObject:nil afterDelay:0.8];
}

#pragma mark Chessboard Moves

-(void) setCurrentMoveIndicator:(NextMoveColor)whiteBlack
{
    UIColor *backColor = [UIColor clearColor];
    UIColor *radiusColor = [UIColor clearColor];

    switch (whiteBlack)
    {
        case NextMoveColorWhite:
            backColor = [UIColor whiteColor];
            radiusColor = [UIColor grayColor];
            break;
        case NextMoveColorBlack:
            backColor = [UIColor blackColor];
            radiusColor = [UIColor grayColor];
            break;
        default:
            break;
    }

    [currentMoveIndicator setBackgroundColor:backColor];
    [currentMoveIndicator.layer setMasksToBounds:YES];
    [currentMoveIndicator.layer setBorderColor:radiusColor.CGColor];
}

-(void) reportLastMove
{
    NSString * const lastMove = [chessBoardView stringByEvaluatingJavaScriptFromString:@"TransformSAN(HistMove[MoveCount-StartMove-1])"];

    if ([lastMove length] == 0)
    {
        [self setCurrentMoveIndicator:NextMoveColorClear];
        container.lastMoveLabel.text = constEmptyStringValue;
    }
    else
    {
        container.lastMoveLabel.text = [NSString stringWithFormat:@"%@ %@", @"After", lastMove];
        if ([[lastMove stringByReplacingOccurrencesOfString:@"..." withString:@""] length] != [lastMove length])
        {
            [self setCurrentMoveIndicator:NextMoveColorWhite];
        }
        else
        {
            [self setCurrentMoveIndicator:NextMoveColorBlack];
        }
    }
}

int __i__;

void __getMoveIndexOnMainThread__();
-(void) __getMoveIndexOnMainThread__
{
    NSString * const value = [__chessBoardViewController__->chessBoardView stringByEvaluatingJavaScriptFromString:@"GetMoveIndex();"];
    __i__ = [value intValue];
}

int __getMoveIndex__();
int __getMoveIndex__()
{
    [__chessBoardViewController__ performSelectorOnMainThread:@selector(__getMoveIndexOnMainThread__) withObject:nil waitUntilDone:YES];
    return __i__;
}

extern void stopAnalyze();
extern void startAnalyze(const std::string &fen);

-(void) boardHasUpdated
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BoardHasUpdated" object:nil];
}

-(NSString *) getFEN
{
    return [chessBoardView stringByEvaluatingJavaScriptFromString:@"GetFEN(false);"];
}

#pragma mark UIWebViewDelegate

-(BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString * const link = [[request URL] relativeString];

    if ([link hasPrefix:@"file:///ConfirmBranchSelection??"])
    {
        NSArray *moveStringComponents =  [link componentsSeparatedByString:@"??"];
        if ([moveStringComponents count] == 2) {
            confirmBranchSelectionParamValue = [[moveStringComponents objectAtIndex:1] copy];
            [self.bookViewController setSteps: confirmBranchSelectionParamValue];
            chessStepsPresented = YES;
            return NO;
        }
    }
    else if ([link hasPrefix:@"file:///HighlightMove?"])
    {
        NSArray * const moveStringComponents = [link componentsSeparatedByString:@"?"];

        if ([moveStringComponents count] == 2)
        {
            chessStepsPresented = NO;
            [self.bookViewController clearAllSteps];
            
            [delegate applyCurrentMove:[moveStringComponents objectAtIndex:1]];
            [self reportLastMove];
            return NO;
        }
    }
    else if ([link hasPrefix:@"cocoa:"])
    {
        NSArray *params = [link componentsSeparatedByString:@":"];
        NSString *message = ([[params objectAtIndex:1] isEqualToString:@"confirm_white_nullmove"] ? 
                             @"White null move?" : 
                             @"Black null move?");
        boardClickParamValue = [[params objectAtIndex:2] intValue];
        
        UIActionSheet *nullMoveActionSheet = [[UIActionSheet alloc] initWithTitle:message 
                                                                         delegate:self 
                                                                cancelButtonTitle:@"Cancel" 
                                                           destructiveButtonTitle:nil 
                                                                otherButtonTitles:@"Ok", nil];
        nullMoveActionSheet.tag = tagNullMoveActionSheet;
        nullMoveActionSheet.actionSheetStyle = UIActionSheetStyleDefault;

        if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone)
        {
            [nullMoveActionSheet showInView:self.view];
        }
        else
        {
            ForwardChessAppDelegate * const appDelegate = (ForwardChessAppDelegate *)[[UIApplication sharedApplication] delegate];
            [nullMoveActionSheet showFromTabBar:appDelegate.tabBarController.tabBar];
        }

        return NO;
    }

    return YES;
}

#pragma end

-(void) clickedButtonAtIndex:(NSInteger)index
{
    NSArray *jsCommands = [confirmBranchSelectionParamValue componentsSeparatedByString:@"%23%23"]; // %23%23 = ##
    for (int i = 0; i<[jsCommands count]; i++) {
        if (index == i) {
            NSArray *jsCommand = [[jsCommands objectAtIndex:i] componentsSeparatedByString:@"%5E%5E"]; //%5E%5E = ^^
            [chessBoardView stringByEvaluatingJavaScriptFromString:[jsCommand objectAtIndex:0]];
            [self reportLastMove];
            break;
        }
    }
}

-(void) executeJS:(NSString *)script
{
    [chessBoardView stringByEvaluatingJavaScriptFromString:script];
    [self reportLastMove];
    [self boardHasUpdated];
}

-(void) jsMoveBack
{
    [chessBoardView stringByEvaluatingJavaScriptFromString:@"MoveBack(1)"];

    if (chessStepsPresented)
    {
        [chessBoardView stringByEvaluatingJavaScriptFromString:@"MoveBack(1)"];
    }

    [self boardHasUpdated];
}

-(void) jsMoveForward
{
    if (chessStepsPresented)
    {
        [self clickedButtonAtIndex:0];
    }
    else
    {
        [chessBoardView stringByEvaluatingJavaScriptFromString:@"MoveForward(1)"];
    }
    
    [self boardHasUpdated];
}

-(void) rotateBoardToBlack
{
    _isRotated = NO;
    [self rotateBoard];
}
    
-(void) rotateBoard
{
    _isRotated = !_isRotated;

    if (_isRotated)
    {
        [chessBoardView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"RotateBoard(true)"]];
    }
    else
    {
        [chessBoardView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"RotateBoard(false)"]];
    }
 }

-(BOOL) processUserTapWithPoint:(UITouch *)touch
{
    BOOL isProcessed = NO;
    if (constIsUserMovesEnabled == YES) {
        CGPoint tapPoint = [touch locationInView:chessBoardView];  
        for (int i = 0; i < 64; i++) {
            CGRect cellFrame = [[container.cellRects objectAtIndex:i] CGRectValue];
            if (CGRectContainsPoint(cellFrame, tapPoint)) {
                [self jsBoardClick:i];
                isProcessed = YES;
            }
        }
    }
    return isProcessed;
}

- (void)jsBoardClick:(int)cellIndex {
    [self jsBoardClick:cellIndex force:NO];
}

- (void)jsBoardClick:(int)cellIndex force:(BOOL)force {
    NSString *forceStatus = force == YES ? @"true" : @"false";
    [chessBoardView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"BoardClick(%i, false, %@)", cellIndex, forceStatus]];
    [self reportLastMove];
}

#pragma mark uiviewcontroller methods

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;	
}

#pragma mark back/forward button draw

-(void) deselect:(id)sender
{
    [sender setHighlighted:NO];
}

-(void) dealloc
{
    confirmBranchSelectionParamValue = nil;
    
    jsSan = nil;
    jsPgn = nil;
    jsFen = nil;
    jsEvent = nil;
    jsGetHTMLMoveText = nil;
    generatedHtmlForRenderedPGNFile = nil;
}

@end