#import "LibraryTableCell.h"

@implementation LibraryTableCell

@synthesize iconView;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier])) {
        CGRect iconImageFrame = CGRectMake(2, 5, (self.contentView.bounds.size.height-10)*2/3, self.contentView.bounds.size.height-10);
        self.iconView = [[UIImageView alloc] initWithFrame:iconImageFrame];
        [self.contentView addSubview:self.iconView];
        
        
        self.textLabel.font = [UIFont systemFontOfSize:15.0f];
        self.textLabel.textColor = [UIColor blackColor];
        self.textLabel.frame = CGRectOffset(self.textLabel.frame, iconImageFrame.size.width+iconImageFrame.origin.x, 0);
        self.detailTextLabel.font = [UIFont systemFontOfSize:13.0f];
        self.detailTextLabel.frame = CGRectOffset(self.textLabel.frame, iconImageFrame.size.width+iconImageFrame.origin.x, 0);
        self.selectionStyle = UITableViewCellSelectionStyleGray;
        
        /*
        self.primaryLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.iconView.bounds.size.width+6, 0, self.bounds.size.width-self.iconView.bounds.size.width-9, self.bounds.size.height/2.0*1.2)];
        self.primaryLabel.backgroundColor = UIColor.clearColor;
        self.primaryLabel.font = [UIFont systemFontOfSize:15];
        [self.contentView addSubview:self.primaryLabel];
        
        
        self.secondaryLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.iconView.bounds.size.width+6, self.bounds.size.height/2.0, self.bounds.size.width-self.iconView.bounds.size.width-9, self.bounds.size.height/2.3)];
        self.secondaryLabel.backgroundColor = UIColor.clearColor;
        self.secondaryLabel.font = [UIFont systemFontOfSize:9];
        [self.contentView addSubview:self.secondaryLabel];
        */
        
        
    }
    return self;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
    }
    return self;
}

@end