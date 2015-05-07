//
//  StoreEntity.m
//  iChess
//
//  Created by katrin on 07.06.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "StoreEntity.h"
#import "Constants.h"

@implementation StoreEntity

- (id)init {
    if ((self = [super init])) {
    }
    return self;
}

- (NSString *)entityName {
    return @"StoreItem";
}

- (StoreItem *)createStoreItem {	
	return (StoreItem *)[NSEntityDescription insertNewObjectForEntityForName:self.entityName inManagedObjectContext:self.managedObjectContext];
}

- (void)depreciateStoreItems {
    NSArray *items = [self getListForPredicate:nil];
    for (StoreItem *item in items) {
        item.systemSyncStatus = constSyncStatusToDelete;
    }
}

- (void)deleteStoreItemsMarkedForRemoval {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"systemSyncStatus = %@", constSyncStatusToDelete];
    NSArray *items = [self getListForPredicate:predicate];
    for (NSManagedObject *item in items) {
        [self.managedObjectContext deleteObject:item];
    }
}


@end
