#import "GameDescriptionProtocol.h"

@class RootViewController;

@interface ChessStepsViewController : UIViewController <GameDescriptionDelegate, UIActionSheetDelegate>
{
    UIScrollView *scrollView;
    UIButton * nextButton;
    UIButton * prevButton;
}

@property(weak) RootViewController *rootController;

- (id)initWithFrame:(CGRect)frame;
- (void) clearAllSteps;
- (void) setSteps: (NSString *) stepsString;
- (void) createButtonNumber: (int) i withText: (NSString *) variant;
- (BOOL) stringIsChessMove: (NSString *) str;

@end