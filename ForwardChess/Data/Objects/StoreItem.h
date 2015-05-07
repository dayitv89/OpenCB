//
//  StoreItem.h
//  iChess
//
//  Created by Likhachev Dmitry on 7/5/11.
//  Copyright (c) 2011 "Systema-Soft". All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface StoreItem : NSManagedObject {
@private
}
@property (nonatomic, strong) NSString * bookId;
@property (nonatomic, strong) NSString * author;
@property (nonatomic, strong) NSDate   * purchaseDate;
@property (nonatomic, strong) NSString * systemSyncStatus;
@property (nonatomic, strong) NSString * price;
@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSString * icon;
@property (nonatomic, strong) NSString * path;

@property (nonatomic, strong) NSString * bookDetails;

@property (nonatomic, strong) NSDate * dateUploaded;
@property (nonatomic, strong) NSString * freePath;
@property (nonatomic, strong) NSString * publisherName;



@end
