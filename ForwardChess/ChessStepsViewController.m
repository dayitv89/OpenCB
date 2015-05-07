#import "Constants.h"
#import "RootViewController.h"
#import "ChessStepsViewController.h"

#define buttonHeight 34
#define buttonsGeneralTopMargin 0
#define buttonsTopMargin 10
#define buttonsRightMargin 30

@implementation ChessStepsViewController

@synthesize rootController;

-(id) initWithFrame:(CGRect)frame
{
    if ((self = [super initWithNibName:nil bundle:nil]))
    {
        self.view.frame = frame;
    }

    return self;
}

- (void)viewDidLoad
{
    scrollView = [[UIScrollView alloc] initWithFrame: CGRectMake(180, 10, self.view.bounds.size.width-145, self.view.bounds.size.height-10)];
    
    prevButton = [UIButton buttonWithType: UIButtonTypeRoundedRect];
    prevButton.frame = CGRectMake(30, 10, 130, 110);
    [prevButton setTitle:@"Previous" forState:UIControlStateNormal];
    [prevButton addTarget:self action:@selector(onPrevious) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:prevButton];
    
    
    nextButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    nextButton.frame = CGRectMake(30, 130, 130, 110);
    [nextButton setTitle:@"Next" forState:UIControlStateNormal];
    [nextButton addTarget:self action:@selector(onNext) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:nextButton];
    
    [self.view addSubview:scrollView];
    [self layoutViews];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutViews) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    
}

- (void) layoutViews{
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        scrollView.frame = CGRectMake(10, 10, 200, self.view.bounds.size.height-10);
        prevButton.frame = CGRectMake(scrollView.frame.size.width+20, 50, 130, 110);
        nextButton.frame = CGRectMake(scrollView.frame.size.width+20, 180, 130, 110);
       
    }else{
        prevButton.frame = CGRectMake(30, 10, 130, 110);
        nextButton.frame = CGRectMake(30, 130, 130, 110);
        scrollView.frame = CGRectMake(180, 10, 210, self.view.bounds.size.height-10);
        
    }
    
    
    
    
    
    
    
}

#pragma mark - New methods :)

- (void) clearAllSteps{
    [[scrollView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
}
- (void) setSteps: (NSString *) stepsString{
    [self clearAllSteps];
    
    NSArray *jsCommands = [stepsString componentsSeparatedByString:@"%23%23"];
    
    int numberOfButtons = [jsCommands count];
    
    UIActionSheet * branchSelectionActionSheet;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
       //NSLog(@"kurec");
        branchSelectionActionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose next move" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles: nil];
         branchSelectionActionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    }
    for (int i = 0; i < numberOfButtons; i++) {
        NSString *variant = [NSString stringWithFormat:constEmptyStringValue];
        NSString *variantWithJSCommand = [jsCommands objectAtIndex:i];
        NSArray *components = [variantWithJSCommand componentsSeparatedByString:@"%5E%5E"];
        if ([components count] > 1) {
            variant = [components objectAtIndex:1];
            variant = [variant stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
            variant = ([variant length] > 0) ? variant : constEmptyStringValue;
        }
        
        NSRange r;
        NSString *regEx =
        @"\\d{1,}[.]{1}\\s{0,}[.]{3}\\s{1,}[-a-zA-Z0-9\\?\\!\\+]{1,}|^\\d{1,}[.]{1}\\s{0,}[-a-zA-Z0-9\\?\\!\\+]{1,}";
        r = [variant rangeOfString:regEx options:NSRegularExpressionSearch];
       
        if (r.location != NSNotFound) {
            variant = [variant substringWithRange:r];
        }
        // добавляем кнопку только, если есть описание хода (если нет описания хода, значит ход - пользовательский, и нам он не нужен)
        if (variant != nil && ![variant isEqualToString:constEmptyStringValue]) {
            
            NSArray * array = [variant componentsSeparatedByString:@" "];
            
            int br = 0;
            NSString * title = [array objectAtIndex:br];
            //If str does not contain move:
            while (! [self stringIsChessMove: title]) {
                title = [NSString stringWithFormat:@"%@%@",title,[array objectAtIndex:++br]];
            }
            
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
                 [branchSelectionActionSheet addButtonWithTitle:title];
            }else{
                [self createButtonNumber: i withText: title];
            }
            
        }
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [branchSelectionActionSheet showInView:[UIApplication sharedApplication].windows[0]];
    }
    
    [scrollView setContentSize:CGSizeMake(scrollView.bounds.size.width,10+numberOfButtons*(buttonHeight + buttonsTopMargin))];
}

-(void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self.rootController clickedButtonAtIndex: buttonIndex];
}

-(void) onButtonClick: (UIButton *)sender
{
    [self.rootController clickedButtonAtIndex: sender.tag-100];
}

-(void) createButtonNumber:(int) i withText:(NSString *)title
{
    CGRect butRect = CGRectMake(buttonsRightMargin, buttonsGeneralTopMargin+i*(buttonHeight+buttonsTopMargin), 130, buttonHeight);
    UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
    [[button layer] setCornerRadius:8.0f];
    [[button layer] setMasksToBounds:YES];
    //[[button layer] setBorderWidth:1.0f];
    //[[button layer] setBackgroundColor:[botCol CGColor]];
    button.frame = butRect;
    [button setTitle:title forState:UIControlStateNormal];
    button.tag = 100+i;
    if ([button respondsToSelector:@selector(setTintColor:)]) {
        button.tintColor = constTintColor();
    }
    button.backgroundColor = constTintColor();
    button.titleLabel.font = [UIFont fontWithName:@"Verfig-Bold" size:17.0f];
    [button addTarget:self action:@selector(onButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:button];
}

-(BOOL) stringIsChessMove: (NSString *) str
{
    NSRange range1 = [str rangeOfString:@"0-0"];
    NSRange range2 = [str rangeOfString:@"O-O"];
    NSRange range3 = [str rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"abcdefghNPQKRB"]];
    
    return (range1.location != NSNotFound || range2.location != NSNotFound || range3.location != NSNotFound);
}

#pragma mark - Buttons

-(void) onNext
{
    [self.rootController onNext];
}

-(void) onPrevious
{
    [self.rootController onPrevious];
}

#pragma mark - GameDescription protocol methods

- (void) setSubchaptersWithDictionary:(NSDictionary *)dict forChapterN:(NSInteger)chapterNum{
    
    
}

- (void)applyGameDescription:(NSString *)eventText {
    //[self jsApplyPgnMoveText:eventText colorCode:nil];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}



 
@end
