#import "Flurry.h"
#import "LibraryItem.h"
#import "LibraryEntity.h"
#import "LibraryTableCell.h"
#import "LibraryTableViewController.h"

@interface LibraryTableViewController(PrivateMethods)
- (void)prepareTestData;
@end

@implementation LibraryTableViewController

-(id) initWithTabBarFrame:(CGRect)frame
{
    if ((self = [super initWithNibName:nil bundle:nil]))
    {
        self.view.frame = frame;

        [self setTitle:@"My books"];
        [self.navigationItem setTitle:@"My books"];
        [self.tabBarItem setImage:[UIImage imageNamed:@"MyBooks.png"]];
        
        self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.view.opaque = YES;

        self.entityName = @"LibraryItem";
        self.predicate = nil;
        self.sectionNameKeyPath = nil;
        self.sortDescriptors = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES],nil];
        
        tableViewPlaceholderView = [[UIView alloc] initWithFrame:self.view.bounds];
        tableViewPlaceholderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self.view addSubview:tableViewPlaceholderView];
        
        [self prepareTestData];
        [self performFetch];
    }

    return self;
}

- (void)prepareTestData
{
	LibraryEntity *libraryEntity = [[LibraryEntity alloc] init];
    NSArray *boughtItems = [libraryEntity getListForPredicate:nil];
    if ([boughtItems count] == 0) {
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"StoreBookList" ofType:@"plist"];
        NSMutableArray *list = [[NSMutableArray alloc] initWithContentsOfFile:plistPath];
        for (NSDictionary *item in list) {
            LibraryItem *libraryItem = [libraryEntity createLibraryItem];
            libraryItem.title = [item valueForKey:@"name"];
            libraryItem.author = [item valueForKey:@"author"];
            libraryItem.path = [item valueForKey:@"path"];
            libraryItem.icon = [item valueForKey:@"icon"];
            libraryItem.bookId = [item valueForKey:@"id"];
            [self.appDelegate.coreDataProxy saveData];
        }
    }
}

-(void) viewDidLoad
{
    [super viewDidLoad];
    [self deleteAllSampleBooksOnce];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.screenName = @"Library";    
}

/**
 *  This is a method that deletes all sample books only once:
 *  There was some kind of a human error on sample books and some users downloaded valuable content..
 *  so we're about to delete all their sample books:
 */
- (void) deleteAllSampleBooksOnce{
    //DELETE All sample books ONLY once:
    if (! [[NSUserDefaults standardUserDefaults] boolForKey:@"allSampleBooksDeleted"]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"allSampleBooksDeleted"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        LibraryEntity *libraryEntity = [[LibraryEntity alloc] init];
        NSArray * array = [libraryEntity getListForPredicate:nil];
        for (int i=0; i<array.count; i++) {
            LibraryItem * libraryItem = array[i];
            libraryItem.freePath = @"";
            if(libraryItem.path.length ==  0){
                //if the book is not purchased, so we need to delete that empty sample book:
                [[libraryItem managedObjectContext] deleteObject:libraryItem];
            }
        }
        ForwardChessAppDelegate * appDelegate = (ForwardChessAppDelegate *) [UIApplication sharedApplication].delegate;
        [appDelegate.coreDataProxy saveData];
        
    }
}

#pragma mark Inherited from BaseFetchTableViewController

-(void) selectCellAtIndexPath:(NSIndexPath *)indexPath
{
    LibraryItem *libraryItem = (LibraryItem *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    RootViewController * const bookViewController = [[RootViewController alloc] initWithFrame:self.view.bounds andLibraryItem:libraryItem];
    [self.navigationController pushViewController:bookViewController animated:YES];

    @try
    {
        NSString * isSampleString = @"NO";
        if (libraryItem.path.length == 0)
            isSampleString = @"YES";

        [Flurry logEvent:@"OpenedBook" withParameters:@{@"title":libraryItem.title, @"author":libraryItem.author,@"publisher": libraryItem.publisherName, @"isSample": isSampleString}];
    }
    @catch (NSException *exception)
    {
        [Flurry logEvent:@"OpenedBook" withParameters:@{@"title":libraryItem.title}];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UIView *)tableViewPlaceholder {
    return tableViewPlaceholderView;
}

- (UITableViewCell *)prepareCellForIndexPath:(NSIndexPath *)indexPath {
    LibraryTableCell *cell = (LibraryTableCell *)[self.tableView dequeueReusableCellWithIdentifier:@"cell1"];
    if (!cell) {
        cell = [[LibraryTableCell alloc] initWithReuseIdentifier:@"cell1"];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)processCell:(UITableViewCell *)cell fromIndexPath:(NSIndexPath *)indexPath {
    LibraryTableCell *libraryTableCell = (LibraryTableCell *)cell;
    LibraryItem *item = (LibraryItem *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    
    libraryTableCell.textLabel.text = item.title;
    if (item.path.length < 1) {
        libraryTableCell.textLabel.text = [item.title stringByAppendingString:@" SAMPLE"];
    }
    libraryTableCell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@", item.author, item.title];
    
    libraryTableCell.imageView.image = [UIImage imageNamed:@"ForwardChess_cover.jpg"];
    [self downloadingServerImageFromUrl:libraryTableCell.imageView AndUrl:item.icon withIndexPath:indexPath];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    [self selectCellAtIndexPath:indexPath];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (void)tableView:(UITableView *)_tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        LibraryItem *item = (LibraryItem *)[self.fetchedResultsController objectAtIndexPath:indexPath];
       
        
        @try {
            NSString * isSampleString = @"NO";
            if (item.path.length == 0) {
                isSampleString = @"YES";
            }
            [Flurry logEvent:@"DELETEDBook" withParameters:@{@"title":item.title, @"author":item.author, @"publisher": item.publisherName, @"isSample": isSampleString}];
        }
        @catch (NSException *exception) {}
        
        //NSString * str = [NSString stringWithString:item.path];
        //[self performSelector:@selector(removeItemAtPathString:) withObject:str afterDelay:0.5];
        
        [[item managedObjectContext] deleteObject:item];
        
        [[item managedObjectContext] save:nil];
       
        [_tableView reloadData];
    }
}

-(void) removeItemAtPathString: (NSString *) path
{
    NSError * error;
    NSFileManager *fileManager =[NSFileManager defaultManager];
    [fileManager removeItemAtPath:path error:&error];
}

-(void)downloadingServerImageFromUrl:(UIImageView*)imgView AndUrl:(NSString*)strUrl withIndexPath: (NSIndexPath *) indexPath{
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[[NSBundle mainBundle].bundlePath stringByAppendingPathComponent:strUrl]]) {
        imgView.image = [UIImage imageNamed:strUrl];
        return;
    }
    
    NSString* theFileName = [NSString stringWithFormat:@"%@.png",[[strUrl lastPathComponent] stringByDeletingPathExtension]];
    
    
    NSFileManager *fileManager =[NSFileManager defaultManager];
    NSString *fileName = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"tmp/%@",theFileName]];
    
    
    
    imgView.backgroundColor = [UIColor darkGrayColor];
    UIActivityIndicatorView *actView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [imgView addSubview:actView];
    [actView startAnimating];
    
    CGSize boundsSize = imgView.bounds.size;
    CGRect frameToCenter = actView.frame;
    // center horizontally
    if (frameToCenter.size.width < boundsSize.width)
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    else
        frameToCenter.origin.x = 0;
    
    // center vertically
    if (frameToCenter.size.height < boundsSize.height)
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    else
        frameToCenter.origin.y = 0;
    
    actView.frame = frameToCenter;
    
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        NSData *dataFromFile = nil;
        NSData *dataFromUrl = nil;
        
        dataFromFile = [fileManager contentsAtPath:fileName];
        if(dataFromFile==nil){
            dataFromUrl=[[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:strUrl]];
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            //Trying to fix the changing covers glitch!
            if(dataFromFile!=nil){
                imgView.image = [UIImage imageWithData:dataFromFile];
               
            }else if(dataFromUrl!=nil){
                imgView.image = [UIImage imageWithData:dataFromUrl];
                NSString *fileName = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"tmp/%@",theFileName]];
                
                BOOL filecreationSuccess = [fileManager createFileAtPath:fileName contents:dataFromUrl attributes:nil];
                if(filecreationSuccess == NO){
                    //NSLog(@"Failed to create the html file");
                }
                
            }else{
                imgView.image = [UIImage imageNamed:@"libraryIcon.png"];
            }
            
                      
            [actView removeFromSuperview];
            [imgView setBackgroundColor:[UIColor clearColor]];
        });
    });
}

@end