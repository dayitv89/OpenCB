#import <vector>
#import <string>
#import "EngineViewController.h"

static int __i__;

void __analysisHasReceived__(const std::vector<std::string> &lines);
void __analysisHasReceived__(int i, float score, int depth, const std::string &line);

extern void stopAnalyze();
extern void startAnalyze(const std::string &fen);

static EngineViewController *__engineController__;

void __analysisHasReceived__(int i, float score, int depth, const std::string &line)
{
    __i__ = i;
    [__engineController__ performSelectorOnMainThread:@selector(showAnalysis:)
                                           withObject:[NSString stringWithFormat:@"%d. (%.02f) depth=%d %s", i + 1, score, depth, line.c_str()]
                                        waitUntilDone:YES];
}

@interface EngineViewController()
{
    @public
        BOOL _isAnalysisRunning;
        UILabel *_label1, *_label2;
}

@end

@implementation EngineViewController

-(id) initWithFrame:(CGRect)frame
{
    if (self = [super init])
    {
        // We need the reference upon receiving analysis
        __engineController__ = self;

        self.view.frame = frame;
        
        #define UIColorFromRGB(rgbValue) [UIColor \
                        colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
                        green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
                        blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
        
        [self.view setBackgroundColor:UIColorFromRGB(0xEFDCCE)];

        _label1 = [[UILabel alloc] initWithFrame:CGRectZero];
        _label2 = [[UILabel alloc] initWithFrame:CGRectZero];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopAnalysis) name:@"EngineNeedToBeStopped" object:nil];
    }

    return self;
}

-(void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self stopAnalysis];
}

-(void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    [_label1 setFrame:CGRectMake(0, 0, self.view.frame.size.width, 21.0)];
    [_label2 setFrame:CGRectMake(0, _label1.frame.size.height, self.view.frame.size.width, 21.0)];
    [_label1 setTextColor:[UIColor blackColor]];

    [self.view addSubview:_label1];
    [self.view addSubview:_label2];

    CGRect frame = self.view.frame;
    frame.size.height = _label1.frame.size.height + _label2.frame.size.height;
    [self.view setFrame:frame];
}

-(void) stopAnalysis
{
    _isAnalysisRunning = NO;
    stopAnalyze();
}

-(void) startAnalysis:(NSString *)fen
{
    NSAssert(fen, @"Invalid fen received in startEngine");
    [self performSelectorInBackground:@selector(startEngineInBackground:) withObject:fen];
}

-(void) startEngineInBackground:(NSString *)fen
{
    _isAnalysisRunning = YES;
    startAnalyze([fen UTF8String]);
}

-(void) showAnalysis:(NSString *)line
{
    if (!_isAnalysisRunning)
    {
        return;
    }
    
    if (__i__)
    {
        [_label2 setText:line];
    }
    else
    {
        [_label1 setText:line];
    }
}

@end