#import "ZipDownloader.h"

@implementation ZipDownloader

- (BOOL) downloadZipAtURL: (NSString *) urlString withID: (NSString *) _productId{
    if (urlString == nil || urlString.length < 5) {
       //NSLog(@"NO");
        return NO;
    }
    
    productId = _productId;
    responseData = [[NSMutableData alloc] init];

    NSString *libraryDirectory = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
    NSString *pom = [NSString stringWithFormat:@"Downloads/%@%0f", productId, [[NSDate date] timeIntervalSince1970]];
    
    self.extractionPath = [libraryDirectory stringByAppendingPathComponent:pom];
    self.zipPath = [self.extractionPath stringByAppendingString:@".zip"];
    
    //Create Folder:
    [[NSFileManager defaultManager] createDirectoryAtPath: [libraryDirectory stringByAppendingPathComponent:@"Downloads"] withIntermediateDirectories:NO attributes:nil error:nil];
    
    NSURLRequest *theRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:60.0];
    NSURLConnection *theConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
   
    if (theConnection == nil) 
        return NO;

    return YES;
}
    

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{

    [responseData setLength:0];
        
}
    
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    //NSLog(@"connectionDidFinishLoading");
    bookDownloaded = YES;
 
    [[NSFileManager defaultManager] createFileAtPath:self.zipPath contents:responseData attributes:nil];
    [self extractZip];
    
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    bookDownloaded = NO;
}

   
- (void) extractZip{
    ZipArchive* zipArchive = [[ZipArchive alloc] init];

    
    BOOL success = NO;
    [zipArchive UnzipOpenFile:self.zipPath Password:@"Password1"];
    success = [zipArchive UnzipFileTo:self.extractionPath overWrite:YES];
    
    if (! success){
        [zipArchive UnzipOpenFile:self.zipPath Password:@"Password2"];
        success = [zipArchive UnzipFileTo:self.extractionPath overWrite:YES];
    }
    
    if (!success){
        [zipArchive UnzipOpenFile:self.zipPath];
        success = [zipArchive UnzipFileTo:self.extractionPath overWrite:YES];
    }
    
    

    if(success){
        [self.delegate zipDownloaderDidFinishUnzipping];
        [self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:self.extractionPath]]; //iOS 5.1
        [[NSFileManager defaultManager] removeItemAtPath:self.zipPath error:nil];
        
    }else{
        NSLog(@"unzipping failed");
    }
    
   
    [zipArchive UnzipCloseFile];
}

- (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    assert([[NSFileManager defaultManager] fileExistsAtPath: [URL path]]);
    
    NSError *error = nil;
    BOOL success = [URL setResourceValue: [NSNumber numberWithBool: YES]
                                  forKey: NSURLIsExcludedFromBackupKey error: &error];
    if(!success){
       //NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
    }
    return success;
}

@end