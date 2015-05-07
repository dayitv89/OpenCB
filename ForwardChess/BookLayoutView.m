#import "BookLayoutView.h"

@implementation BookLayoutView

@synthesize boardView, stepsView, bookView, borderLine, showChessBoard, labelView;

-(void) dealloc
{
    delegate = nil;
}

-(id) initWithFrame:(CGRect)frame delegate:(id<BookLayoutViewDelegate>)newDelegate
{
    if ((self = [super initWithFrame:frame]))
    {
        delegate = newDelegate;
        
        boardView = [[UIView alloc] initWithFrame:CGRectZero];
        bookView = [[UIView alloc] initWithFrame:CGRectZero];
        stepsView = [[UIView alloc] initWithFrame:CGRectZero];
        _engineView = [[UIView alloc] initWithFrame:CGRectZero];
        labelView = [[UILabel alloc] initWithFrame:CGRectZero];
        labelView.textAlignment = UITextAlignmentCenter;
        borderLine = [[UIView alloc] initWithFrame:CGRectZero];
        borderLine.backgroundColor = [UIColor grayColor];
        
        [self addSubview:borderLine];
        [self addSubview:labelView];
        [self addSubview:boardView];
        [self addSubview:stepsView];
        [self addSubview:self.engineView];
        [self addSubview:bookView]; //top-most view
    }

    return self;
}

- (void)setShowChessBoard:(BOOL)state{
    showChessBoard = state;
    [self setFrames];
}

-(void) setEngine:(BOOL)showEngine
{
    _showEngine = showEngine;
    [self setFrames];
}

- (BOOL)isInPortraitOrientation {
	BOOL deviceIsPad = (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone);
	float comparedWidth = (deviceIsPad) ? 800.0f : 400.0f; //greater than regular portrait width of ipad | iphone
	return (self.frame.size.width < comparedWidth) ? YES : NO;
}

-(void) setFrames
{
    CGRect temp;
    CGRect bookFrame, boardFrame, stepsFrame, borderFrame, labelFrame, engineFrame;

	NSNumber * const isRight = [[NSUserDefaults standardUserDefaults] objectForKey:@"BoardOrientationRight"];

    if ((UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone))
    {
        if ([self isInPortraitOrientation])
        {
            CGRectDivide(self.bounds, &boardFrame, &bookFrame, 406.0f, CGRectMinYEdge);
            CGRectDivide(boardFrame, &boardFrame, &stepsFrame, 390.0f, CGRectMinXEdge);
            CGRectDivide(bookFrame, &borderFrame, &bookFrame, 1.0f, CGRectMinYEdge);
            labelFrame = CGRectMake(stepsFrame.origin.x, 0, stepsFrame.size.width, 40);
        }
        else
        {
            if (isRight && [isRight boolValue])
            {
                CGRectDivide(self.bounds, &bookFrame, &boardFrame, self.bounds.size.width - 390.0f, CGRectMinXEdge);
                CGRectDivide(boardFrame, &boardFrame, &stepsFrame, 406.0f, CGRectMinYEdge);
                CGRectDivide(bookFrame, &bookFrame, &borderFrame, bookFrame.size.width - 1.0, CGRectMinXEdge);
                boardFrame = CGRectOffset(boardFrame, 0, 33);
                labelFrame = CGRectMake(0, 0, boardFrame.size.width, 40);
            }
            else
            {
                CGRectDivide(self.bounds, &boardFrame, &bookFrame, 390.0f, CGRectMinXEdge);
                CGRectDivide(boardFrame, &boardFrame, &stepsFrame, 406.0f, CGRectMinYEdge);
                CGRectDivide(bookFrame, &borderFrame, &bookFrame, 1.0f, CGRectMinXEdge);
                boardFrame = CGRectOffset(boardFrame, 0, 33);
                labelFrame = CGRectMake(0, 0, boardFrame.size.width, 40);
            }
        }

        stepsFrame = CGRectMake(stepsFrame.origin.x, stepsFrame.origin.y + 40, stepsFrame.size.width, stepsFrame.size.height - 40);
        borderLine.frame = borderFrame;
        labelView.frame = labelFrame;
    }
    else
    {
        stepsFrame = CGRectMake(0, 0, 1, 1);
        
        const CGFloat heightForEngine = 0; //self.showEngine ? 100.0f : 0;
        const CGFloat heightForBoard  = self.showChessBoard ? [self isInPortraitOrientation] ? 280.0f : 270.0f : 0;
        const CGFloat heightForTemp   = heightForBoard + heightForEngine;
        
        if ([self isInPortraitOrientation])
        {
            CGRectDivide(self.bounds, &temp, &bookFrame, heightForTemp, CGRectMinYEdge);
            CGRectDivide(bookFrame, &borderFrame, &bookFrame, 1.0f, CGRectMinYEdge);
        }
        else
        {
            if (isRight && [isRight boolValue])
            {
                CGRectDivide(self.bounds, &bookFrame, &temp, heightForTemp, CGRectMinXEdge);
                CGRectDivide(bookFrame, &borderFrame, &bookFrame, 1.0f, CGRectMinXEdge);
            }
            else
            {
                CGRectDivide(self.bounds, &temp, &bookFrame, heightForTemp, CGRectMinXEdge);
                CGRectDivide(bookFrame, &borderFrame, &bookFrame, 1.0f, CGRectMinXEdge);
            }
        }
        
        if (heightForBoard)
        {
            CGRectDivide(temp, &boardFrame, &temp, heightForBoard, CGRectMinYEdge);
        }
        else
        {
            boardFrame = CGRectZero;
        }
        
        if (heightForEngine)
        {
            CGRectDivide(temp, &engineFrame, &temp, heightForEngine, CGRectMinYEdge);
        }
        else
        {
            engineFrame = CGRectZero;
        }
    }
    
    if (!self.showChessBoard && !self.showEngine)
    {
        bookFrame = self.bounds;
    }
    
    bookView.frame = bookFrame;
    boardView.frame = boardFrame;
    stepsView.frame = stepsFrame;
    
    if (self.showEngine)
    {
        [_engineView setHidden:NO];
        
        if ([self isInPortraitOrientation])
        {
            [_engineView setFrame:CGRectMake(0, boardView.frame.origin.y + boardView.frame.size.height, bookView.frame.size.width, 42.0)];
        }
        else
        {
            [_engineView setFrame:CGRectMake(bookView.frame.origin.x,
                                             bookView.frame.origin.y + bookView.frame.size.height - 42.0,
                                             bookView.frame.size.width,
                                             42.0)];
            CGRect a = _engineView.frame;
            a = a;
        }
    }
    else
    {
        [_engineView setHidden:YES];
    }
    
    [_engineView.superview bringSubviewToFront:_engineView];
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    [self setFrames];
    [delegate onLayout];
}

@end