#import "CoreDataProxy.h"

@implementation CoreDataProxy

@synthesize transactionState;

#pragma mark -
#pragma mark CoreDataProxy init
- (id)init {
	if((self = [super init])) {
		[self managedObjectContext];
	}
	return self;
}

#pragma mark -
#pragma mark transaction
- (void)beginTransaction{
    [self saveData];
	transactionState = YES;
}
- (void)commitTransaction{
	transactionState = NO;
	[self saveData];
}
- (void)rollbackTransaction{
	transactionState = NO;
	[[self managedObjectContext] rollback];
}


#pragma mark -
#pragma mark Saving

-(void) saveData
{
	if (transactionState) return;
	
    NSError *error;
    if (![[self managedObjectContext] save:&error]) {
        //NSLog(@"CoreDataProxy saveData: Could Not Save Data: %@, %@", error, [error userInfo]);
    }
}

#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *) managedObjectContext {
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    return managedObjectContext;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    NSString *path = [[NSBundle mainBundle] pathForResource:@"ForwardChess" ofType:@"momd"];
    NSURL *momURL = [NSURL fileURLWithPath:path];  
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
    //managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {    
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
    
    NSURL *storeUrl = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"ForwardChess.sqlite"]];
    
    //deleting the existing store (only for development)
    //[[NSFileManager defaultManager] removeItemAtURL:storeUrl error:nil];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    NSError *error;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
   
    
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error]) {
        //NSLog(@"CoreDataProxy: Could Not Start Persistent Store: %@, %@", error, [error userInfo]);
    }    
    
    return persistentStoreCoordinator;
}


#pragma mark -
#pragma mark Application's documents directory

/**
 Returns the path to the application's documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}


#pragma mark -
#pragma mark Memory management



@end
