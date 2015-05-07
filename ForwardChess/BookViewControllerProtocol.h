@protocol BookViewControllerDelegate <NSObject>

-(void) showChessBoard;
-(void) pageContentHasScrolled:(UIScrollView *)scrollView;

@optional

-(void) pageLoaded:(int)page;
-(void) titleChanged: (NSString *) title;

@end