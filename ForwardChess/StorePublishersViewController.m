#import "StorePublishersViewController.h"
#import "StoreTableViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "Flurry.h"

@interface StorePublishersViewController (){
    NSArray * publishersArray;
}

@end

@implementation StorePublishersViewController

-(id) init
{
    if ((self = [super init]))
    {
        [self setTitle:@"Store"];
        [self.tabBarItem setImage:[UIImage imageNamed:@"Store.png"]];

        publishersArray = @[@"Quality Chess", @"Mongoose Press", @"Chess Stars", @"Russell Enterprises", @"New In Chess", @"Chess Informant", @"Independent"];

        self.storeTableViewController = [[StoreTableViewController alloc] initWithTabBarFrame:self.tabBarController.view.bounds];

        [self drawPublishers];
    }

    return self;
}

-(void) viewDidAppear:(BOOL)animated
{
    [self setButtonFrames];
    self.screenName = @"Publishers Screen";
}

#pragma mark - Drawing Publishers

-(void) drawPublishers
{
    UIColor * const textColor = [UIColor colorWithRed:0 green:128.0/254.0 blue:1.00 alpha:1];

    for (NSUInteger i = 0; i < publishersArray.count; i++)
    {
        UIButton * const b = [UIButton buttonWithType:UIButtonTypeCustom];
        [b setTitle:publishersArray[i] forState:UIControlStateNormal];
        b.tag = 100+i;
        [b addTarget:self action:@selector(onPublisher:) forControlEvents:UIControlEventTouchUpInside];

        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
        {
            [b setTitleColor:textColor forState:UIControlStateNormal];
        }
        else
        {
            b.layer.borderWidth = 2.0;
            b.layer.borderColor = [UIColor colorWithRed:0.1 green: 0.1 blue:0.1 alpha:0.5].CGColor;
            b.layer.cornerRadius = 15.0;
            b.backgroundColor = constTintColor();
            [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        }
        
        b.tintColor = constTintColor();
        b.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:22];
        [self.view addSubview:b];
    }
    
    UIButton * b = [UIButton buttonWithType:UIButtonTypeCustom];
    [b setTitle:@"View Complete List" forState:UIControlStateNormal];
    b.tag = 99;
    [b addTarget:self action:@selector(onViewAll) forControlEvents:UIControlEventTouchUpInside];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        [b setTitleColor:textColor forState:UIControlStateNormal];
    }
    else
    {
        b.layer.borderWidth = 2.0;
        b.layer.borderColor = [UIColor colorWithRed:0.1 green: 0.1 blue:0.1 alpha:0.5].CGColor;
        b.layer.cornerRadius = 15.0;
        b.backgroundColor = constTintColor();
        [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    }

    b.tintColor = constTintColor();
    b.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:22];
    
    [self.view addSubview:b];
    [self setButtonFrames];
}

-(void) setButtonFrames
{
    [UIView beginAnimations:@"anim" context:nil];

    UIButton * const completeListButton = (UIButton *)[self.view viewWithTag:99];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        const CGFloat height = 100.0f;

        if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) // iPad Portrait
        {
            for (NSUInteger i = 0; i < publishersArray.count; i++)
            {
                [(UIButton *)[self.view viewWithTag:100+i] setFrame:CGRectMake(150, 10 + (height * i), self.view.frame.size.width-300, 70)];
            }

            [completeListButton setFrame:CGRectMake(50, self.view.frame.size.height - 200, self.view.frame.size.width-100, 70)];
        }
        else // iPad Landscape
        {
            int numColumns = 3;
            int buttonWidth = self.view.bounds.size.width / (MIN(publishersArray.count, numColumns)) - 10;

            for (int i=0; i<publishersArray.count; i++)
            {
                UIButton * b = (UIButton *)[self.view viewWithTag:100+i];
                CGFloat x = 10+(i%numColumns * (buttonWidth+5));
                CGFloat y = 20+(i/numColumns * height);
                b.frame = CGRectMake(x, y, buttonWidth, height);
            }

            [completeListButton setFrame:CGRectMake(10, self.view.bounds.size.height-220, self.view.bounds.size.width - 20, height)];
        }
    }
    else // iPhone
    {
        if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) // iPhone Portrait
        {
            for (int i = 0; i < publishersArray.count; i++)
            {
                UIButton * b = (UIButton *)[self.view viewWithTag:100+i];
                b.frame = CGRectMake(50, 15+50*i, self.view.frame.size.width-100, 35);
                b.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:15];
            }
            
            [completeListButton setFrame:CGRectMake(50, self.view.frame.size.height - 100, self.view.frame.size.width - 100, 40)];
            
            if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0)
            {
                CGRect frame = completeListButton.frame;
                frame.origin.y += 30.0;
                [completeListButton setFrame:frame];
            }
        }
        else // iPhone Landscape
        {
            int numColumns = 3;
            int buttonWidth = self.view.bounds.size.width/(MIN(publishersArray.count, numColumns))-10;
            int buttonHeight = 55;
            
            for (int i = 0; i < publishersArray.count; i++)
            {
                UIButton * b = (UIButton *)[self.view viewWithTag:100+i];
                CGFloat x = 10+(i%numColumns*(buttonWidth+5));
                CGFloat y = 20+(i/numColumns*buttonHeight);
                b.frame = CGRectMake(x, y, buttonWidth, buttonHeight);
                b.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:13];
            }
            
            [completeListButton setFrame:CGRectMake(10, self.view.bounds.size.height-120, self.view.bounds.size.width-20, 65)];
        }
    }

    [UIView commitAnimations];
}

- (void) onPublisher: (UIButton *) b{
    int publihserNum = b.tag - 100;
    if(publihserNum < publishersArray.count){
        NSString * publisherName = publishersArray[publihserNum];
        
        [Flurry logEvent:@"ViewedPublisher" withParameters:@{@"publisherName":publisherName}];
        
        [self.navigationController pushViewController:self.storeTableViewController animated:YES];
        [self.storeTableViewController sortAndFilterData:publisherName];
        self.storeTableViewController.title = publisherName;
    }
    
    
}



- (void) onViewAll{
    
    [Flurry logEvent:@"ViewedPublisher" withParameters:@{@"publisherName":@"All"}];
    
    [self.navigationController pushViewController:self.storeTableViewController animated:YES];
    [self.storeTableViewController sortAndFilterData:nil];
    self.storeTableViewController.title = @"Book Store";
}


-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    [self setButtonFrames];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


- (void) dealloc{
    
    publishersArray= nil;
}

@end
