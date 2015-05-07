#import "CoreDataProxy.h"
#import "InterceptorWindow.h"
#import "SettingsViewController.h"

@class RootViewController, LibraryTableViewController, StoreTableViewController, StorePublishersViewController;

@interface ForwardChessAppDelegate : NSObject <UIApplicationDelegate, UINavigationControllerDelegate, UITabBarControllerDelegate> {
    InterceptorWindow *interceptorWindow;
    LibraryTableViewController *libraryTableViewController;
    SettingsViewController *settingsViewController;
    
    StorePublishersViewController * storePublishersViewController;
    StoreTableViewController *storeTableViewController;
    
    UINavigationController *booksNav;
    CoreDataProxy *coreDataProxy;
    
    UINavigationController *storeNav;
    UITabBarController *tabBarController;
}

@property (nonatomic, strong) InterceptorWindow *interceptorWindow;
@property (nonatomic, strong) UITabBarController *tabBarController;
@property (nonatomic, strong) LibraryTableViewController *libraryTableViewController;
@property (nonatomic, strong) SettingsViewController *settingsViewController;

@property (nonatomic, strong) StoreTableViewController *storeTableViewController;
@property (nonatomic, strong) StorePublishersViewController * storePublishersViewController;

@property (nonatomic, strong) CoreDataProxy *coreDataProxy;

@end