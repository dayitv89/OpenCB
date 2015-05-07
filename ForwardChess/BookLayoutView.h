
@protocol BookLayoutViewDelegate<NSObject>
    - (void)onLayout;
@end

@interface BookLayoutView : UIView
{
    UIView  *boardView;
    UIView  *stepsView;
    UIView  *bookView;
    UIView  *borderLine;
    UILabel *labelView;
    
    id<BookLayoutViewDelegate> delegate;
    BOOL showChessBoard;
}

@property(nonatomic, strong) UIView  *engineView;
@property(nonatomic, strong) UIView  *boardView;
@property(nonatomic, strong) UIView  *stepsView;
@property(nonatomic, strong) UIView  *bookView;
@property(nonatomic, strong) UIView  *borderLine;
@property(nonatomic, strong) UILabel  *labelView;

@property(nonatomic) BOOL showEngine;
@property(nonatomic) BOOL showChessBoard;

-(id) initWithFrame:(CGRect)frame delegate:(id<BookLayoutViewDelegate>)newDelegate;

@end