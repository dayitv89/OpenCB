#import "ChessBoardLayoutView.h"
#import "BookWindowViewController.h"
#import "BookViewProtocol.h"

@class RootViewController;

@interface ChessBoardViewController : UIViewController <UIWebViewDelegate, ChessboardDelegate, UIActionSheetDelegate>
{
    ChessBoardLayoutView *container;
    UIWebView  *chessBoardView;
    NSArray *chessBoardArray;
    NSString *jsSan;
    NSString *jsFen;
    NSString *jsPgn;
    NSString *jsEvent;
    NSString *jsGetHTMLMoveText;
    
    id<BookViewDelegate> delegate;
    NSString *generatedHtmlForRenderedPGNFile;
    
    int boardClickParamValue;
    UILabel *currentMoveIndicator;
    NSString *confirmBranchSelectionParamValue;
    
    BOOL isUserMovesEnabled;
    BOOL chessStepsPresented;
}

@property BOOL isRotated;
@property (weak) RootViewController * bookViewController;
@property () BOOL isUserMovesEnabled;

- (id)initWithFrame:(CGRect)frame;
- (void)setBookWindowDelegate:(id<BookViewDelegate>)newDelegate;
- (BOOL)processUserTapWithPoint:(UITouch *)touch;
- (void)jsBoardClick:(int)cellIndex;
- (void)jsBoardClick:(int)cellIndex force:(BOOL)force;
- (void)jsMoveBack;
- (void)jsMoveForward;
- (void) clickedButtonAtIndex: (NSInteger) index;

-(NSString *) getFEN;

@end