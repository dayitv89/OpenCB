#import "ForwardChessAppDelegate.h"
#import "RootViewController.h"
#import "LibraryTableViewController.h"
#import "StoreTableViewController.h"
#import "StorePublishersViewController.h"
#import "Flurry.h"
#import "GAI.h"
#import "Appirater.h"

#import "Board/bitboard.h"
#import "Board/mersenne.h"
#import "Board/movepick.h"
#import "Board/position.h"
#import "Board/direction.h"

extern void stockfish_init();

@implementation ForwardChessAppDelegate

@synthesize interceptorWindow, tabBarController, libraryTableViewController, settingsViewController,storeTableViewController, storePublishersViewController, coreDataProxy;

- (CoreDataProxy *)coreDataProxy {
    if (coreDataProxy == nil) {
        coreDataProxy = [[CoreDataProxy alloc] init];
    }
    return coreDataProxy;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *) w {
    return UIInterfaceOrientationMaskAll;
}

-(void) initEngine
{
    stockfish_init();
}

-(void) initBoardRepresentation
{
    using namespace Chess;
    
    @autoreleasepool
    {
        init_mersenne();
        init_direction_table();
        init_bitboards();
        Position::init_zobrist();
        Position::init_piece_square_tables();
        MovePicker::init_phase_table();
        
        // Make random number generation less deterministic, for book moves
        NSInteger i = abs(get_system_time() % 10000);
        
        for (int j = 0; j < i; j++)
        {
            genrand_int32();
        }
    }
}

#pragma mark Application lifecycle

-(BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self initEngine];
    [self initBoardRepresentation];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSNumber *textSizePercentage = [defaults objectForKey:constFontSizePercentage];
    if (textSizePercentage == nil) {
        [defaults setObject:[NSNumber numberWithInt:constFontSizePercentageDefault] forKey:constFontSizePercentage];
        [defaults synchronize];        
    }
    
    NSMutableDictionary *defaultDefaults = [NSMutableDictionary dictionary];
    [defaultDefaults setObject:[NSNumber numberWithBool:YES] forKey:constAutscrollEnabled];
    [defaultDefaults setObject:[NSNumber numberWithInt:constBoardSizePercentageDefault] forKey:constBoardSizePercentage];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultDefaults];
    
    
    //Flurry account:
    //dshadow3@mail.bg
    //pass is dig.....
    [Flurry setCrashReportingEnabled:YES];
    [Flurry startSession:@"TVH4NQ7R7M6SKCH3DX26"];
    
    
    //Google analitycs:
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    [GAI sharedInstance].dispatchInterval = 20;
    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelVerbose];
    //id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:@"UA-46105122-4"];

    interceptorWindow = [[InterceptorWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    interceptorWindow.backgroundColor = [UIColor whiteColor];
	interceptorWindow.userInteractionEnabled = YES;
    
    NSMutableArray *localControllersArray = [[NSMutableArray alloc] initWithCapacity:2];
    
    tabBarController = [[UITabBarController alloc] initWithNibName:nil bundle:nil];
    tabBarController.delegate = self;
    
    libraryTableViewController = [[LibraryTableViewController alloc] initWithTabBarFrame:tabBarController.view.bounds]; 
    booksNav = [[UINavigationController alloc] initWithRootViewController:libraryTableViewController];
    booksNav.navigationBar.barStyle = UIBarStyleDefault;
    booksNav.navigationBar.translucent = NO;
    booksNav.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [localControllersArray addObject:booksNav];
    
    storePublishersViewController = [[StorePublishersViewController alloc] init];
   // storeTableViewController = [[StoreTableViewController alloc] initWithTabBarFrame:tabBarController.view.bounds];
    
    storeNav = [[UINavigationController alloc] initWithRootViewController:storePublishersViewController];
    storeNav.navigationBar.barStyle = UIBarStyleDefault;
    storeNav.navigationBar.translucent = NO;
    storeNav.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [localControllersArray addObject:storeNav];
    
    /*
    settingsViewController = [[SettingsViewController alloc] initWithTabBar];
    UINavigationController *settingsNav = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
    settingsNav.navigationBar.barStyle = UIBarStyleDefault;
    settingsNav.navigationBar.translucent = NO;
    [settingsNav release];
     */
    
    tabBarController.viewControllers = localControllersArray;
    
    interceptorWindow.rootViewController = tabBarController;
    	
    [interceptorWindow addSubview:tabBarController.view];
    [interceptorWindow makeKeyAndVisible];
    
    [Appirater setAppId:@"543005909"];
    [Appirater appLaunched:NO];

    return YES;
}

-(void) applicationWillEnterForeground:(UIApplication *)application
{
    [Appirater appEnteredForeground:NO];
}

-(void) applicationWillTerminate:(UIApplication *)application
{
    [self.coreDataProxy saveData];
}

#pragma mark - TabBarController Delegate:

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController{
    if ([viewController isEqual:storeNav]) {
        [storeNav popToRootViewControllerAnimated:NO];
    }
    return YES;
}



@end
