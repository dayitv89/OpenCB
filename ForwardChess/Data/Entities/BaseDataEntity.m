//
//  BaseDataEntity.m
//  AVI
//
//  Created by mark2 on 3/30/11.
//  Copyright 2011 HFS. All rights reserved.
//

#import "BaseDataEntity.h"
#import "ForwardChessAppDelegate.h"

@implementation BaseDataEntity

@dynamic entityName, idAttributeName, managedObjectContext;

- (NSString *)entityName {
    return @"";
}

- (NSManagedObjectContext *)managedObjectContext {
    ForwardChessAppDelegate *appDelegate = (ForwardChessAppDelegate *)[[UIApplication sharedApplication] delegate];
    return appDelegate.coreDataProxy.managedObjectContext;
}


- (NSArray *)getListForPredicate:(NSPredicate *)predicate sortDescriptor:(NSSortDescriptor *)sortDescriptor {
    NSManagedObjectContext *moc = self.managedObjectContext;
    NSString *en = self.entityName;
    return [moc executeFetchRequestWithPredicate:predicate andEntityName:en andSortDescriptor:sortDescriptor];

}

- (NSArray *)getListForPredicate:(NSPredicate *)predicate {
    return [self getListForPredicate:predicate sortDescriptor:nil];
}

//работает только с сохраненным контекстом!!! объекты, добавленные после последнего сохранения не попадут в выборку
- (NSArray *)distinctValuesForField:(NSString *)fieldName withPredicate:(NSPredicate *)newPredicate {
    NSEntityDescription *entity = [NSEntityDescription  entityForName:self.entityName inManagedObjectContext:self.managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    [request setResultType:NSDictionaryResultType];
    [request setReturnsDistinctResults:YES];
    [request setPropertiesToFetch:[NSArray arrayWithObject:fieldName]];
    
    if (newPredicate != nil) {
        [request setPredicate:newPredicate];
    }
    
    // Execute the fetch.
    NSError *error = nil;
    NSArray *objects = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    NSMutableArray *values = [[NSMutableArray alloc] init];
    for (NSDictionary *item in objects) {
        [values addObject:[item valueForKey:fieldName]];
    }
    
    return values;
}


- (NSManagedObject *)getItemForPredicate:(NSPredicate *)predicate{
    NSArray *items = [self getListForPredicate:predicate];
    if ([items count] > 0) {
        return [items objectAtIndex:0];
    }
    return nil;
} 

- (NSManagedObject *)getByNumberId:(NSNumber *)itemId{
    return [self getItemForPredicate:[NSPredicate predicateWithFormat:@"%K == %@", self.idAttributeName,itemId]];
}

- (NSManagedObject *)getByStringId:(NSString *)itemId{
    return [self getItemForPredicate:[NSPredicate predicateWithFormat:@"%K == %@", self.idAttributeName,itemId]];
}

- (NSManagedObject *)getByArrayId:(NSArray *)itemIds{/* НЕ ТЕСТИРОВАЛ. должен собирать предикат для составного ключа, ключ составлять через запятую в свойстве idAttributeName*/
    NSArray *keyComponents = [self.idAttributeName componentsSeparatedByString:@","];
    NSString *conditionString = @"";
    for (int i = 0; i < [keyComponents count]; i++ ) {
        conditionString = [conditionString stringByAppendingFormat:@"%@ = %@",
                           (NSString *)[keyComponents objectAtIndex:i], /* компонент ключа*/
                           @"%@"];/* место для значения ключа*/
        if (i<[keyComponents count]-1) {
            conditionString = [conditionString stringByAppendingString:@" AND "];
        }
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:conditionString argumentArray:itemIds];
    return [self getItemForPredicate:predicate];
}


- (BOOL)deleteByStringId:(NSString *)itemId {
    NSManagedObject *oldItem = [self getByStringId:itemId];
    if (oldItem) {
        [self.managedObjectContext deleteObject:oldItem];
    }
    return YES;
}

- (void)deleteAll {
    NSArray *items = [self getListForPredicate:nil];
    for (NSManagedObject *item in items) {
        [self.managedObjectContext deleteObject:item];
    }
    [self.managedObjectContext save:nil];
}

@end
