//
//  MYRHTTPSession.m
//  MYRHTTPSession
//
//  Created by haruki okada on 2014/07/04.
//
//

#import "MYRHTTPSession.h"

static MYRHTTPSession* _session = nil;

@interface MYRHTTPSession ()<NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate>

@property (atomic) NSMutableSet* tasks;
@property (atomic) NSMutableDictionary* progressHandlerMap;
@property (atomic) NSMutableDictionary* completionHandlerMap;
@property (atomic) NSMutableDictionary* cancelHandlerMap;

@property (atomic) NSURLSession* urlSession;

@end

@implementation MYRHTTPSession

+ (instancetype)sharedSession
{
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        _session = [MYRHTTPSession new];
    });
    
    return _session;
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        _tasks = [NSMutableSet set];
        
        _progressHandlerMap = [NSMutableDictionary dictionary];
        _cancelHandlerMap = [NSMutableDictionary dictionary];
        _completionHandlerMap = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (NSURLSessionTask *)sendRequest:(NSURLRequest *)request progress:(void (^)(int64_t, int64_t))progress cancelled:(void (^)())cancelled completion:(void (^)(NSHTTPURLResponse *, NSData *, NSError *))completion
{
    NSURLSessionTask* task = [_urlSession downloadTaskWithRequest:request];
    
    @synchronized(self) {
        [_tasks addObject:task];
        
        if (progress) {
            [_progressHandlerMap setObject:[progress copy] forKey:task];
        }
        if (cancelled) {
            [_cancelHandlerMap setObject:[cancelled copy] forKey:task];
        }
        if (completion) {
            [_completionHandlerMap setObject:[completion copy] forKey:task];
        }
    }
    
    [task resume];
    return task;
}

- (void)cancelAll
{
    [_tasks enumerateObjectsUsingBlock:^(NSURLSessionTask* obj, BOOL *stop) {
        [obj cancel];
    }];
}

- (void)removeKeyFromMaps:(NSURLSessionTask *)key
{
    [_progressHandlerMap removeObjectForKey:key];
    [_cancelHandlerMap removeObjectForKey:key];
    [_completionHandlerMap removeObjectForKey:key];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    @synchronized(self){
        void (^canceled)() = _cancelHandlerMap[task];
        void (^completion)(NSHTTPURLResponse *, NSData *, NSError *) = _completionHandlerMap[task];
        
        if (error && error.code == NSURLErrorCancelled) {
            if (canceled) {
                canceled();
            }
        } else if(completion) {
            completion((id)task.response, nil, task.error);
        }
        
        [self removeKeyFromMaps:task];
        [_tasks removeObject:task];
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    @synchronized(self){
        void (^canceled)() = _cancelHandlerMap[downloadTask];
        void (^completion)(NSHTTPURLResponse *, NSData *, NSError *) = _completionHandlerMap[downloadTask];
        
        NSError* error = downloadTask.error;
        NSData* data = [NSData dataWithContentsOfURL:location];
        
        if (error && error.code == NSURLErrorCancelled && canceled) {
            canceled();
        } else if(completion) {
            completion((id)downloadTask.response, data, error);
        }
        
        [self removeKeyFromMaps:downloadTask];
        [_tasks removeObject:downloadTask];
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    NSString* method = downloadTask.originalRequest.HTTPMethod;
    
    if (([method isEqualToString:@"GET"] || [method isEqualToString:@"HEAD"]) && _progressHandlerMap[downloadTask]) {
        void (^progress)(int64_t, int64_t);
        progress = _progressHandlerMap[downloadTask];
        progress(totalBytesWritten, totalBytesExpectedToWrite);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    NSString* method = task.originalRequest.HTTPMethod;
    
    if (!([method hasPrefix:@"GET"] || [method hasPrefix:@"HEAD"]) && _progressHandlerMap[task]) {
        void (^progress)(int64_t, int64_t);
        progress = _progressHandlerMap[task];
        progress(totalBytesSent, totalBytesExpectedToSend);
    }
}

@end
