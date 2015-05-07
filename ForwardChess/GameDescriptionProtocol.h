//
//  BookWindowGameDescriptionProtocol.h
//  iChess
//
//  Created by mark2 on 6/25/11.
//  Copyright 2011 HFS. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GameDescriptionDelegate <NSObject>
- (void)applyGameDescription:(NSString *)eventText;
- (void)setSubchaptersWithDictionary: (NSDictionary *) dict forChapterN: (NSInteger) chapterNum;
@end
