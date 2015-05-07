@interface BookmarkViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>
{
    IBOutlet UITableView *_tableView;
    IBOutlet UINavigationItem *_item;
}

@end