#import <Foundation/Foundation.h>
#import "BookWindowViewController.h"
#import "ChessBoardViewController.h"
#import "ChessStepsViewController.h"
#import "LibraryEntity.h"
#import "BookLayoutView.h"
#import "BookViewControllerProtocol.h"
#import "BookTOCViewController.h"
#import "OptionsViewController.h"

@interface RootViewController : UIViewController <BookLayoutViewDelegate, BookViewControllerDelegate, BookTOCViewControllerDelegate, OptionsViewControllerDelegate, UITextViewDelegate>
{
    // Empty Interface
}

@property(nonatomic, strong) LibraryItem *item;

@property (nonatomic, strong) BookWindowViewController *bookWindowViewController;
 
-(id)initWithFrame:(CGRect)frame andLibraryItem:(LibraryItem *)libraryItem;
- (void)userDidTap:(UITouch *)touch;
- (void)userDidScroll:(UITouch *)touch;

- (void) clearAllSteps;
- (void) setSteps: (NSString *) stepsString;
- (void) clickedButtonAtIndex: (NSInteger) index;
- (void) onNext;
- (void) onPrevious;

@end
