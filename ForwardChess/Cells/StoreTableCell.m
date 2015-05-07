#import "StoreTableCell.h"


@implementation StoreTableCell

@synthesize indexPath, bookTitle, detailInfo, purchaseButton, freeButton, purchaseDate;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id<StoreTableCellDelegate>)newDelegate {
    if ((self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier])) {
        delegate = newDelegate;
        
        self.selectionStyle = UITableViewCellSelectionStyleGray;
        
        CGRect textFrame, purchaiseInfoFrame, leftMarginFrame, bookTitleFrame, detailInfoFrame, iconImageFrame;
        iconImageFrame = CGRectMake(5, 5, (self.contentView.bounds.size.height-10)*2/3, self.contentView.bounds.size.height-10);
        
        
        CGRectDivide(CGRectOffset(CGRectInset(self.contentView.bounds, 5, 3), -5, 0), &purchaiseInfoFrame, &textFrame, 90.0f, CGRectMaxXEdge);
        CGRectDivide(textFrame, &leftMarginFrame, &textFrame, 4.0f, CGRectMinXEdge);
        CGRectDivide(textFrame, &bookTitleFrame, &detailInfoFrame, textFrame.size.height/2, CGRectMinYEdge);
        
        textFrame = CGRectOffset(textFrame, iconImageFrame.size.width+5, 0);
        bookTitleFrame = CGRectOffset(bookTitleFrame, iconImageFrame.size.width+5, 0);
        detailInfoFrame = CGRectOffset(detailInfoFrame, iconImageFrame.size.width+5, 0);
        
        
        UILabel *tmpLabel = [[UILabel alloc] initWithFrame:bookTitleFrame];
        self.bookTitle = tmpLabel;
        bookTitle.font = [UIFont systemFontOfSize:15.0f];
        bookTitle.textColor = [UIColor blackColor];
        bookTitle.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self.contentView addSubview:bookTitle];
        
        tmpLabel = [[UILabel alloc] initWithFrame:detailInfoFrame];
        self.detailInfo = tmpLabel;
        detailInfo.font = [UIFont systemFontOfSize:13.0f];
        detailInfo.textColor = [UIColor grayColor];
        detailInfo.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self.contentView addSubview:detailInfo];
        
        self.purchaseButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [purchaseButton setTitle:@"Buy" forState:UIControlStateNormal];
        [purchaseButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [purchaseButton addTarget:self action:@selector(buyButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        purchaseButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
        purchaseButton.frame = purchaiseInfoFrame;
        [self.contentView addSubview:purchaseButton];
        
        self.freeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [freeButton setTitle:@"Sample" forState:UIControlStateNormal];
        [freeButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
        [freeButton addTarget:self action:@selector(onSampleButton:) forControlEvents:UIControlEventTouchUpInside];
        freeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
        freeButton.frame = CGRectOffset(purchaseButton.frame, -purchaseButton.frame.size.width, 0);
        [self.contentView addSubview:freeButton];
        
        tmpLabel = [[UILabel alloc] initWithFrame:purchaiseInfoFrame];
        self.purchaseDate = tmpLabel;
        purchaseDate.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
        purchaseDate.backgroundColor = [UIColor clearColor];
        purchaseDate.textColor = [UIColor greenColor];
        purchaseDate.font = [UIFont systemFontOfSize:15.0f];
        purchaseDate.textAlignment = UITextAlignmentRight;
        [self.contentView addSubview:purchaseDate];
        
        //icon
        self.iconView = [[UIImageView alloc] initWithFrame:iconImageFrame];
        [self.contentView addSubview:self.iconView];
        
        
    }
    return self;
}

- (void)buyButtonPressed:(id)sender {
    [delegate productPurchaseRequested:indexPath];
}

- (void) onSampleButton:(id) sender{
    [delegate freeSampleRequested:indexPath];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}


@end
