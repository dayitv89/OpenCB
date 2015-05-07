#import "OptionsViewController.h"
#import "Constants.h"
#import "RootViewController.h"

extern RootViewController *__rootViewController__;

@implementation OptionsViewController
@synthesize delegate;

-(id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
    {
        // Empty Implementation
    }

    return self;
}

-(void) viewDidLoad
{
    [super viewDidLoad];
    [fontSizeSlider setMinimumValue:constFontSizePercentageMin];
    [fontSizeSlider setMaximumValue:constFontSizePercentageMax];
    
    [boardSizeSlider setMinimumValue:constBoardSizePercentageMin];
    [boardSizeSlider setMaximumValue:constBoardSizePercentageMax];

    NSUserDefaults * const defaults = [NSUserDefaults standardUserDefaults];
    [fontSizeSlider  setValue: [[defaults objectForKey:constFontSizePercentage ] intValue]];
    [boardSizeSlider setValue: [[defaults objectForKey:constBoardSizePercentage] intValue]];

    if ([defaults objectForKey:keyChessStyle])
    {
        NSString * const style = [defaults objectForKey:keyChessStyle];

        //Figures:
        if ([style hasPrefix:@"Classic"])
        {
            [figuresSegmentedControl setSelectedSegmentIndex:0];
        }
        else
        {
            [figuresSegmentedControl setSelectedSegmentIndex:1];
        }
        
        //Board:
        if ([style hasSuffix:@"Blue/"]) {
            [boardSegmentedControl setSelectedSegmentIndex:0];
        }else if ([style hasSuffix:@"Green/"]) {
            [boardSegmentedControl setSelectedSegmentIndex:1];
        }else if ([style hasSuffix:@"Brown/"]) {
            [boardSegmentedControl setSelectedSegmentIndex:2];
        }else{
            [boardSegmentedControl setSelectedSegmentIndex:3];
        }
    }
    
    [_orientationControl setSelectedSegmentIndex:0];
    
    if ([[defaults objectForKey:@"BoardOrientationRight"] boolValue])
    {
        [_orientationControl setSelectedSegmentIndex:1];
    }
    
    [_coordSwitch setOn:[[defaults objectForKey:COORDINATIVE_ENABLED] boolValue]];
    [autoscrollSwitch setOn:[[defaults objectForKey:constAutscrollEnabled] boolValue]];
}

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [super touchesBegan:touches withEvent:event];
    
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self.view];
    
    if (touchPoint.y < 280 && [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        [self dismissModalViewControllerAnimated:YES];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.delegate optionsViewControllerDismissed];
    }
}

-(IBAction) myBookmarkClicked:(UIButton *)button
{
    [self.delegate bookmarkDidClicked];
}

-(IBAction) notesClicked:(UIButton *)button
{
    [self.delegate notesDidClicked];
}

- (IBAction) onFontSliderChange:(UISlider *)sender
{
    int subtract = sender.value/constFontSizePercentageStep;
    int fontSizePercentage = subtract*constFontSizePercentageStep;
   
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:fontSizePercentage] forKey:constFontSizePercentage];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.delegate optionsViewControllerDismissed];
}

- (IBAction) onBoardSliderChange:(UISlider *)sender{
    int subtract = sender.value/constBoardSizePercentageStep;
    int boardSizePercentage = subtract*constBoardSizePercentageStep;
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:boardSizePercentage] forKey:constBoardSizePercentage];

    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.delegate optionsViewControllerDismissed];
}

-(IBAction) onCoordinativeChange:(UISwitch *)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:sender.on] forKey:COORDINATIVE_ENABLED];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.delegate optionViewControllerCoordChanged];
}

-(IBAction) onAutoscrollSwitchChange:(UISwitch *)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:sender.on] forKey:constAutscrollEnabled];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.delegate optionsViewControllerDismissed];
}

-(IBAction) orientationHasChanged:(UISegmentedControl *)sender
{
    if ([sender selectedSegmentIndex] == 0)
    {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:@"BoardOrientationRight"];
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"BoardOrientationRight"];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];    
    [__rootViewController__ performSelector:@selector(reloadLayout) withObject:nil];
}

-(IBAction) onFiguresSegmentedControlChange:(UISegmentedControl *) sender
{
    [self determineBoardStyle];
}

-(IBAction) onBoardSegmentedControlChange:(UISegmentedControl *) sender
{
    [self determineBoardStyle];
}

-(void) determineBoardStyle
{
    NSString * style = @"Classic";
    
    if([figuresSegmentedControl selectedSegmentIndex] == 1)
    {
        style = @"Retro";
    }
    
    if ([boardSegmentedControl selectedSegmentIndex] == 0)
    {
        style = [style stringByAppendingString:@"Blue"];
    }
    else if ([boardSegmentedControl selectedSegmentIndex] == 1)
    {
        style = [style stringByAppendingString:@"Green"];
    }
    else if ([boardSegmentedControl selectedSegmentIndex] == 2)
    {
        style = [style stringByAppendingString:@"Brown"];
    }
    else
    {
        style = [style stringByAppendingString:@"Maple"];
    }

    style = [style stringByAppendingString:@"/"];
    
    [[NSUserDefaults standardUserDefaults] setObject:style forKey:keyChessStyle];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.delegate optionsViewControllerChangedBoardStyle];
}

@end