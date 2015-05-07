#import <Foundation/Foundation.h>
#import "BaseFetchedTableViewController.h"
#import "RootViewController.h"

@interface LibraryTableViewController : BaseFetchedTableViewController
{
    UIView *tableViewPlaceholderView;
}

-(id) initWithTabBarFrame:(CGRect)frame;

@end