#import "ChessBoardLayoutView.h"

@implementation ChessBoardLayoutView

-(void) layoutSubviews
{
    [super layoutSubviews];
    
    const BOOL deviceIsPad = (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone);

    CGRect boardFrame, toolbarFrame;
    float toolbarHeight = (deviceIsPad == YES) ? 50.0f : 20.0f;
    CGRectDivide(self.bounds, &toolbarFrame, &boardFrame, toolbarHeight, CGRectMaxYEdge);
    if (deviceIsPad == NO) {
        boardFrame = CGRectOffset(boardFrame, 0, -10);
    }
    
    _boardView.frame = boardFrame;
    //  boardToolbar.frame = toolbarFrame;
    
    float xOffset;
    float yOffset;
    float side;
    
    if (deviceIsPad == YES)
    {
        side = 38.0f;
        xOffset = (self.frame.size.width - side*8)/2 - 10.0f; //10.0f - left margin in pgnboard_compact.html
        yOffset = 12.0f; //10.0f - top margin in pgnboard_compact.html
    } else
    {
        side = 26.0f;
        xOffset = (self.frame.size.width - side*8)/2 - 10.0f; //10.0f - left margin in pgnboard_compact.html
        yOffset = 12.0f; //10.0f - top margin in pgnboard_compact.html
    }

    for (int r = 0; r < 8; r++)
    {
        for (int c = 0; c < 8; c++) {
            [_cellRects replaceObjectAtIndex:(8*r+c)
                                  withObject:[NSValue valueWithCGRect:CGRectMake(xOffset+side*c, yOffset+side*r, side, side)]];
            
            
            /*
             UIView *viewxa = [[UIView alloc] initWithFrame:CGRectMake(xOffset+side*c, yOffset+side*r, side, side)];
             viewxa.backgroundColor = [UIColor redColor];
             viewxa.layer.cornerRadius = 5;
             [self addSubview:viewxa];
             */
        }
    }
}

-(id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _cellRects = [[NSMutableArray alloc] init];
        
        for (int i = 0; i<64; i++)
        {
            [_cellRects addObject:[NSValue valueWithCGRect:CGRectZero]];
        }
        
        _boardView = [[UIView alloc] initWithFrame:CGRectZero];
        
        _lastMoveLabel = [[UILabel alloc] initWithFrame:CGRectMake(150.0f, 360.0f, 195.0f, 50.0f)];
        _lastMoveLabel.backgroundColor = [UIColor clearColor];
        _lastMoveLabel.textColor = [UIColor blackColor];
        _lastMoveLabel.textAlignment = UITextAlignmentRight;
        //lastMoveLabel.font = [UIFont boldSystemFontOfSize:16.0f];
        _lastMoveLabel.font = [UIFont fontWithName:@"Verfig-Bold" size:15.0f];
        
        BOOL deviceIsPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);

        if (deviceIsPhone)
        {
            _lastMoveLabel.font = [UIFont fontWithName:@"Verfig-Bold" size:11.0f];
            _lastMoveLabel.frame = CGRectOffset(_lastMoveLabel.frame, -110, -125);
        }
               
        [self addSubview:_boardView];
        [self addSubview:_lastMoveLabel];
    }
    
    return self;
}


@end