//
//  LibraryEntity.h
//  iChess
//
//  Created by katrin on 19.05.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BaseDataEntity.h"
#import "LibraryItem.h"

@interface LibraryEntity : BaseDataEntity {
}

- (id)init;
- (LibraryItem *)createLibraryItem;
@end
