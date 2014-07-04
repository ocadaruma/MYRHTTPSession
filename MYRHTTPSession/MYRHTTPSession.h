//
//  MYRHTTPSession.h
//  MYRHTTPSession
//
//  Created by park on 2014/07/04.
//
//

#import <Foundation/Foundation.h>

@interface MYRHTTPSession : NSObject

+ (instancetype)sharedSession;

- (void)executeRequest:(NSURLRequest *)request progress:(void (^)(int64_t doneBytes, int64_t totalBytes))progress completion:(void (^)(NSHTTPURLResponse* response, NSData* body, NSError* error))completion;
- (void)cancelAll;

@end
