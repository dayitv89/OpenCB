@interface EngineViewController : UIViewController
{
    // Empty Interface
}

-(id) initWithFrame:(CGRect)frame;

-(void) stopAnalysis;
-(void) startAnalysis:(NSString *)fen;

@end