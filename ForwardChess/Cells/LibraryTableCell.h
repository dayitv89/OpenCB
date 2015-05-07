@interface LibraryTableCell : UITableViewCell
{
    // Empty Interface
}

@property (nonatomic, strong) UIImageView * iconView;
@property (nonatomic, strong) UILabel * primaryLabel;
@property (nonatomic, strong) UILabel * secondaryLabel;

-(id) initWithReuseIdentifier:(NSString *)reuseIdentifier;

@end