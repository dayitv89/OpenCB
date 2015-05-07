//
//  StoreEntity.h
//  iChess
//
//  Created by katrin on 07.06.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BaseDataEntity.h"
#import "StoreItem.h"

@interface StoreEntity : BaseDataEntity {
}

- (id)init;
- (StoreItem *)createStoreItem;
- (void)depreciateStoreItems;
- (void)deleteStoreItemsMarkedForRemoval;

@end
