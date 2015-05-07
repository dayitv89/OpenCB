@protocol BookViewDelegate<NSObject>

-(void) applyPGNConvertedToHTML:(NSString *)htmlString;

-(void) applyCurrentMove:(NSString *)currentMove;

@end