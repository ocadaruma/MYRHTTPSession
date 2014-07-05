//
//  MYRHTTPSession.h
//  MYRHTTPSession
//
//  Created by haruki okada on 2014/07/04.
//
//

#import <Foundation/Foundation.h>

@interface MYRHTTPSession : NSObject

+ (instancetype)sharedSession;

- (NSURLSessionTask *)executeRequest:(NSURLRequest *)request progress:(void (^)(int64_t doneBytes, int64_t totalBytes))progress canceled:(void (^)())canceled completion:(void (^)(NSHTTPURLResponse* response, NSData* body, NSError* error))completion;

- (void)cancelAll;

@end
