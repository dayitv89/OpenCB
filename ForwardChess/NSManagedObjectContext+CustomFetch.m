//
//  NSManagedObjectContext+CustomFetch.m
//  iSharePoint
//
//  Created by Laughedelic on 20.03.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSManagedObjectContext+CustomFetch.h"

@implementation NSManagedObjectContext (CustomFetch)

- (NSArray *)executeFetchRequestWithPredicate:(NSPredicate *)predicate 
                                andEntityName:(NSString *)entityName 
                            andSortDescriptor:(NSSortDescriptor *)sortDescriptor{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self];
    [fetchRequest setEntity:entity];
    
    if (predicate != nil) {
        [fetchRequest setPredicate:predicate];
    }
    if (sortDescriptor != nil) {
        [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    }
    
    NSError *errorFetch = nil;
    NSArray *items = [self executeFetchRequest:fetchRequest error:&errorFetch];
    if (errorFetch != nil) {
        //NSLog(@"executeFetchRequestWithPredicate error: %@", [errorFetch localizedDescription]);
    }
    return items;    

}

- (NSArray *)executeFetchRequestWithPredicate:(NSPredicate *)predicate andEntityName:(NSString *)entityName {
    return [self executeFetchRequestWithPredicate:predicate andEntityName:entityName andSortDescriptor:nil];
}

- (NSArray *)executeFetchRequestFilteringByAttribute:(NSString *)key withValue:(NSString *)value andEntityName:(NSString *)entityName { 
    return [self executeFetchRequestWithPredicate:[NSPredicate predicateWithFormat:@"%K = %@", key, value]
                                    andEntityName:entityName];
}

@end
