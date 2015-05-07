#import "RootViewController.h"
#import "BookmarkViewController.h"

// It's a hack... Otherwise it'd been hard to retrieve information from the controller.
extern RootViewController *__rootViewController__;

@interface Bookmark : NSObject
{
    @public
        NSString *name;
}

@end

@implementation Bookmark
@end

@implementation BookmarkViewController

-(void) viewDidLoad
{
    UIBarButtonItem * const left  = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(removeBookmark)];
    UIBarButtonItem * const right = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addBookmark)];

    if ((UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone))
    {
        [_item setLeftBarButtonItem:left];
        [_item setRightBarButtonItem:right];
    }
    else
    {
        [_item setRightBarButtonItems:[[NSArray alloc] initWithObjects:left, right, nil]];
        [_item setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelBookmark)]];
    }
}

-(NSMutableArray *) getBookmarks
{
    NSDictionary * const books = [[NSUserDefaults standardUserDefaults] objectForKey:@"SavedBookmarks"];

    if (!books)
    {
        [[NSUserDefaults standardUserDefaults] setObject:[[NSDictionary alloc] init] forKey:@"SavedBookmarks"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return [self getBookmarks];
    }
    
    NSData * const data = [books objectForKey:__rootViewController__.item.bookId];
    
    return data ? [[NSMutableArray alloc] initWithArray:[NSKeyedUnarchiver unarchiveObjectWithData:data]] :
                  [[NSMutableArray alloc] init];
}

-(void) saveBookmarks:(NSArray *)bookmarks
{
    NSDictionary * const books = [[NSUserDefaults standardUserDefaults] objectForKey:@"SavedBookmarks"];
    NSAssert(books, @"There must be an entry in SavedBookmarks in saveBookmarks:bookmarks");
    
    NSMutableDictionary * const mBooks = [[NSMutableDictionary alloc] initWithDictionary:books];
    [mBooks setObject:[NSKeyedArchiver archivedDataWithRootObject:bookmarks] forKey:__rootViewController__.item.bookId];

    [[NSUserDefaults standardUserDefaults] setObject:mBooks forKey:@"SavedBookmarks"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void) addBookmark
{
    NSArray * const bookmarks = [self getBookmarks];
    
    UIAlertView * const alert = [[UIAlertView alloc] initWithTitle:@"Add Bookmark"
                                                           message:nil
                                                          delegate:self
                                                 cancelButtonTitle:@"Cancel"
                                                 otherButtonTitles:@"OK", nil];
    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[alert textFieldAtIndex:0] setText:[NSString stringWithFormat:@"Bookmark %d",[bookmarks count] + 1]];
    [alert show];
}

-(void) cancelBookmark
{
    [__rootViewController__ dismissViewControllerAnimated:YES completion:nil];
}

-(void) removeBookmark
{
    [_tableView setEditing:!_tableView.isEditing animated:YES];
}

#pragma mark UIAlertViewDelegate

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        NSMutableDictionary * const bookmark = [[NSMutableDictionary alloc] init];

        [bookmark setObject:[alertView textFieldAtIndex:0].text forKey:@"Name"];
        [bookmark setObject:[__rootViewController__.bookWindowViewController getCurrentPage] forKey:@"Page"];
        [bookmark setObject:[__rootViewController__.bookWindowViewController getCurrentOffset] forKey:@"Offset"];

        NSLog(@"%d %f", [[__rootViewController__.bookWindowViewController getCurrentPage] intValue],
                        [[__rootViewController__.bookWindowViewController getCurrentOffset] floatValue]);
        
        NSMutableArray * const bookmarks = [self getBookmarks];
        [bookmarks addObject:bookmark];

        [self saveBookmarks:bookmarks];
        [_tableView reloadData];
    }
}

#pragma end

#pragma mark UITableViewDataSource

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self getBookmarks] count];
}

-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary * const bookmark = [[self getBookmarks] objectAtIndex:indexPath.row];
    
    UITableViewCell * const cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    [cell.textLabel setText:[bookmark objectForKey:@"Name"]];
    
    return cell;
}

#pragma end

#pragma mark UITableViewDelegate

-(void) scrollToBookmark:(NSIndexPath *)indexPath
{
    NSDictionary * const bookmark = [[self getBookmarks] objectAtIndex:indexPath.row];
    [__rootViewController__.bookWindowViewController switchToPageWithOffset:[[bookmark objectForKey:@"Page"] intValue]
                                                                     offset:[[bookmark objectForKey:@"Offset"] floatValue]];
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [_tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ((UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone))
    {
        [__rootViewController__ performSelector:@selector(dismissBookmarkForiPad) withObject:nil];
        [self scrollToBookmark:indexPath];
    }
    else
    {
        [__rootViewController__ dismissViewControllerAnimated:YES completion:^{
            [self scrollToBookmark:indexPath];
        }];
    }
}

-(void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSMutableArray * const bookmarks = [self getBookmarks];
        [bookmarks removeObjectAtIndex:indexPath.row];
        [self saveBookmarks:bookmarks];
        [_tableView reloadData];
    }
}

#pragma end

@end