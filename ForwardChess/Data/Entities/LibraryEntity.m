#import "LibraryEntity.h"

@implementation LibraryEntity

- (id)init {
    if ((self = [super init])) {
    }
    return self;
}

- (NSString *)entityName {
    return @"LibraryItem";
}

- (LibraryItem *)createLibraryItem {	
    
    LibraryItem *item = [NSEntityDescription insertNewObjectForEntityForName:self.entityName inManagedObjectContext:self.managedObjectContext];
    return item;
}


@end
