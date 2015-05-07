#import "BaseFetchedTableViewController.h"

@interface BaseFetchedTableViewController(PrivateMethods)
- (void)fetchControllerUpdateRowAtIndexPath:(NSIndexPath *)indexPath;
@end

@implementation BaseFetchedTableViewController

@dynamic tableViewPlaceholder, tableViewBackgroundColor, appDelegate;

@synthesize tableView, fetchedResultsController, entityName, predicate, sortDescriptors,sectionNameKeyPath;

- (id)initWithFrame:(CGRect)newFrame {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.view.frame = newFrame;
        self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        selectedItem = nil;
    }
    return self;
}

- (ForwardChessAppDelegate *)appDelegate {
    return (ForwardChessAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (UIView *)tableViewPlaceholder {
    return self.view;
}

- (UIColor *)tableViewBackgroundColor {
    return nil;
}

- (void)addTableView {
    if(tableView != nil){
        [tableView removeFromSuperview];//если фильтр изменился - необходимо полностью пересоздать таблицу. обновление не помогает, таблица рассинхронизируется с fc (бага fc)        
        tableView = nil;
    }
    tableView = [[UITableView alloc] initWithFrame:self.tableViewPlaceholder.bounds style:UITableViewStylePlain];
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.rowHeight = constTableRowHeight;
    if (self.tableViewBackgroundColor) {
        tableView.backgroundColor = self.tableViewBackgroundColor;
    }
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.tableViewPlaceholder addSubview:tableView];
    
    
}

- (void)performFetch {
    self.fetchedResultsController = nil;//сброс fc перед изменением предиката и сортировки, и пока не создана таблица. это важно. иначе - рассинхронизация
    [self addTableView];
    
    NSError *error = nil;
    [self.fetchedResultsController performFetch:&error];
    if (error) {
        [[[UIAlertView alloc]initWithTitle:@"BaseFetchedTableViewController" 
                                    message:[error localizedDescription] 
                                   delegate:nil 
                          cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
    }
}

#pragma mark - Override methods
- (UITableViewCell *)prepareCellForIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell1"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell1"];
        [cell.textLabel setFont:[UIFont systemFontOfSize:constTableRowCellFontSize]];
    }
    return cell;
}

- (NSString *)getTextForCellAtIndexPath:(NSIndexPath *)indexPath {
    return [NSString stringWithFormat:@"%i",indexPath.row];
}

- (void)processCell:(UITableViewCell *)cell fromIndexPath:(NSIndexPath *)indexPath{
    NSString *cellValue = [self getTextForCellAtIndexPath:indexPath];
    cell.textLabel.text = cellValue;
}

- (void)selectCellAtIndexPath:(NSIndexPath *)indexPath {
}

#pragma mark - UITableViewDelegate

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self selectCellAtIndexPath:indexPath];
}

#pragma end

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    int sectionsCount = [[self.fetchedResultsController sections] count];
    return sectionsCount;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    int rowsCount = [sectionInfo numberOfObjects];
    return rowsCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self prepareCellForIndexPath:indexPath];
    [self processCell:cell fromIndexPath:indexPath];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    id<NSFetchedResultsSectionInfo>sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo indexTitle];
}

- (NSString *)controller:(NSFetchedResultsController *)controller sectionIndexTitleForSectionName:(NSString *)sectionName{
    return sectionName;
}

#pragma mark -
#pragma mark Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController {
    if (fetchedResultsController != nil) {
        return fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName 
                                              inManagedObjectContext:self.appDelegate.coreDataProxy.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    if (predicate) [fetchRequest setPredicate:predicate];
    if (sortDescriptors) [fetchRequest setSortDescriptors:sortDescriptors];
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] 
                                                             initWithFetchRequest:fetchRequest 
                                                             managedObjectContext:self.appDelegate.coreDataProxy.managedObjectContext 
                                                             sectionNameKeyPath:self.sectionNameKeyPath
                                                             cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    
    return fetchedResultsController;
}    

- (void)fetchControllerUpdateRowAtIndexPath:(NSIndexPath *)indexPath{
    [self processCell:[tableView cellForRowAtIndexPath:indexPath] fromIndexPath:indexPath];
}

#pragma mark -
#pragma mark Fetched results controller delegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
        {
            [self fetchControllerUpdateRowAtIndexPath:indexPath];
        }
            break;
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
    [self applySelection];
}

- (void)setSelectionTo:(NSManagedObject *)newSelectedItem
{
    selectedItem = newSelectedItem;
}

- (void)applySelection{
    if (selectedItem != nil) {
        NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:selectedItem];
        [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
    }
    selectedItem = nil;
}


#pragma mark -


@end
