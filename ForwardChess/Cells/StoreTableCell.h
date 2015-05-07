//
//  StoreTableCell.h
//  iChess
//
//  Created by katrin on 07.06.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol StoreTableCellDelegate <NSObject>
- (void)productPurchaseRequested:(NSIndexPath *)indexPath;
- (void)freeSampleRequested:(NSIndexPath *) indexPath;
@end

@interface StoreTableCell : UITableViewCell {
    NSIndexPath *indexPath;
    UILabel *bookTitle;
    UILabel *detailInfo;
    UILabel *purchaseDate;
    UIButton *purchaseButton;
    UIButton *freeButton;
    id<StoreTableCellDelegate> delegate;    
}

@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, strong) UILabel *bookTitle;
@property (nonatomic, strong) UILabel *detailInfo;
@property (nonatomic, strong) UILabel *purchaseDate;
@property (nonatomic, strong) UIButton *purchaseButton;
@property (nonatomic, strong) UIButton *freeButton;

@property (nonatomic, strong) UIImageView * iconView;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id<StoreTableCellDelegate>)newDelegate;

@end

