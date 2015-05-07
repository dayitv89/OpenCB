#import "Constants.h"
#import "ForwardChessAppDelegate.h"
#import "GAITrackedViewController.h"
#import "UIViewController+Blockable.h"

@interface BaseFetchedTableViewController : GAITrackedViewController <UITableViewDelegate,UITableViewDataSource,NSFetchedResultsControllerDelegate>
{
    NSString *entityName;
    NSPredicate *predicate;
    NSArray *sortDescriptors;
    NSString *sectionNameKeyPath;
    NSFetchedResultsController *fetchedResultsController;
    UITableView *tableView;
    NSManagedObject *selectedItem;//используется при "заказе" выделения объекта по окончании добавления объекта в контекст
}

@property (nonatomic, strong) UIView *tableViewPlaceholder;
@property (nonatomic, strong) UIColor *tableViewBackgroundColor;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSString *sectionNameKeyPath;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSString *entityName;
@property (nonatomic, strong) NSPredicate *predicate;
@property (nonatomic, strong) NSArray *sortDescriptors;
@property (nonatomic, strong) ForwardChessAppDelegate *appDelegate; 

- (id)initWithFrame:(CGRect)newFrame;
- (void)performFetch;
- (void)addTableView;//используется только если не вызывается performFetch

- (UIView *)tableViewPlaceholder;

- (UITableViewCell *)prepareCellForIndexPath:(NSIndexPath *)indexPath;

- (void)processCell:(UITableViewCell *)cell fromIndexPath:(NSIndexPath *)indexPath;

- (NSString *)getTextForCellAtIndexPath:(NSIndexPath *)indexPath;

- (void)selectCellAtIndexPath:(NSIndexPath *)indexPath;
- (void)setSelectionTo:(NSManagedObject *)newSelectedItem;
- (void)applySelection;

@end

