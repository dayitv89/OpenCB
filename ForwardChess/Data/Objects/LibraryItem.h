#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface LibraryItem : NSManagedObject
{
    // Empty Interface
}

@property (nonatomic, strong) NSString * path;
@property (nonatomic, strong) NSString * bookId;
@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSString * author;
@property (nonatomic, strong) NSString * icon;

@property (nonatomic, strong) NSDate * datePurchased;
@property (nonatomic, strong) NSString * publisherName;
@property (nonatomic, strong) NSString * freePath;

@property (nonatomic, strong) NSNumber * lastPageViewed;
@property (nonatomic, strong) NSNumber * lastPageOffset;

@end