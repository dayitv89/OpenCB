//
//  BaseDataEntity.h
//  AVI
//
//  Created by mark2 on 3/30/11.
//  Copyright 2011 HFS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSManagedObjectContext+CustomFetch.h"

@interface BaseDataEntity : NSObject {
}

@property (nonatomic, strong) NSString *entityName;
@property (nonatomic, strong) NSString *idAttributeName;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

- (NSArray *)getListForPredicate:(NSPredicate *)predicate;
- (NSArray *)getListForPredicate:(NSPredicate *)predicate sortDescriptor:(NSSortDescriptor *)sortDescriptor;
- (NSArray *)distinctValuesForField:(NSString *)fieldName withPredicate:(NSPredicate *)newPredicate;

- (NSManagedObject *)getItemForPredicate:(NSPredicate *)predicate;
- (NSManagedObject *)getByStringId:(NSString *)itemId;
- (NSManagedObject *)getByNumberId:(NSNumber *)itemId;
- (NSManagedObject *)getByArrayId:(NSArray *)itemIds;

- (BOOL)deleteByStringId:(NSString *)itemId;
- (void)deleteAll;

@end
