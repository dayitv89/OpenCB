//
//  CoreDataProxy.h
//  yeehay
//
//  Created by rednekis on 9/2/10.
//  Copyright 2010 HFS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface CoreDataProxy : NSObject {
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
	BOOL transactionState;
}

@property (readonly) BOOL transactionState;
@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (weak, nonatomic, readonly) NSString *applicationDocumentsDirectory;

- (id)init;
- (void)saveData;
- (void)beginTransaction;
- (void)commitTransaction;
- (void)rollbackTransaction;

@end