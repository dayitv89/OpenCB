//
//  ZipDownloader.h
//  ForwardChess
//
//  Created by Nikolay Riskov on 6/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ZipArchive.h"

@protocol ZipDownloaderDelegate <NSObject>

- (void) zipDownloaderDidFinishUnzipping;

@end

@interface ZipDownloader : NSObject{
       
    NSMutableData * responseData;
    NSString * productId;
    
    BOOL bookDownloaded;
    
    
}
@property (nonatomic, strong) NSString * zipPath;
@property (nonatomic, strong) NSString * extractionPath;
@property (nonatomic, weak) id<ZipDownloaderDelegate> delegate;

- (BOOL) downloadZipAtURL: (NSString *) urlString withID: (NSString *) _productId;


@end
