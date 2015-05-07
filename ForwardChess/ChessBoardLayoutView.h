@interface ChessBoardLayoutView : UIView
{
    // Empty Interface
}

@property (nonatomic, strong) UIView *boardView;
@property (nonatomic, strong) UILabel *lastMoveLabel;
@property (nonatomic, strong) NSMutableArray *cellRects;

@end