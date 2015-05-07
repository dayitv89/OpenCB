#import "SettingsViewController.h"

@implementation SettingsViewController

-(id)initWithTabBar
{
    if ((self = [self init]))
    {
        self.title = @"Settings";
        self.tabBarItem.image = [UIImage imageNamed:@"settingsIcon.png"];
        self.navigationItem.title=@"Settings";
    }

    return self;
}

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end