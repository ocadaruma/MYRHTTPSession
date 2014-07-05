//
//  MYRHTTPSessionTests.m
//  MYRHTTPSession
//
//  Created by haruki okada on 2014/07/04.
//
//

#import "MYRHTTPSessionTests.h"
#import "MYRHTTPSession.h"
#import <OHHTTPStubs.h>

static NSString* const kDownloadUrl = @"http://download";
static NSString* const kUnavailableHost = @"http://unavailable";
static NSString* const kUploadUrl = @"http://upload";

@implementation MYRHTTPSessionTests

- (void)setUpClass
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        NSString* url = [request.URL absoluteString];
        
        OHHTTPStubsResponse* response = nil;

        if ([url isEqualToString:kDownloadUrl]) {
            NSData* data = UIImagePNGRepresentation([UIImage imageNamed:@"lena.png"]);
            response = [OHHTTPStubsResponse responseWithData:data statusCode:200 headers:nil];
            response.responseTime = 2.0;
        } else if ([url isEqualToString:kUnavailableHost]) {
            response = [OHHTTPStubsResponse responseWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotConnectToHost userInfo:nil]];
        } else if ([url isEqualToString:kUploadUrl]) {
            response = [OHHTTPStubsResponse responseWithData:nil statusCode:200 headers:nil];
            response.requestTime = 1.0;
        }
        
        return response;
    }];
}

- (void)tearDownClass
{
    [OHHTTPStubs removeAllStubs];
}

- (void)testSingleton
{
    MYRHTTPSession* s1 = [MYRHTTPSession sharedSession];
    MYRHTTPSession* s2 = [MYRHTTPSession sharedSession];
    
    GHAssertTrue(s1 == s2, @"returns same instance");
}

- (void)testCompletionHandler
{
    MYRHTTPSession* session = [MYRHTTPSession sharedSession];
    
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kDownloadUrl]];
    NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:kDownloadUrl]];
    
    GHAssertTrue([data length] > 0, @"get test image");
    
    NSInteger max = 10;
    __block NSInteger count = 0;
    
    [self prepare];
    
    for (int i = 0; i < max; i++) {
        [session executeRequest:req progress:nil canceled:nil completion:^(NSHTTPURLResponse *response, NSData *body, NSError *error) {
            if ([data length] == [body length]) {
                count++;
            }
            if (count == max) {
                [self notify:kGHUnitWaitStatusSuccess];
            }
        }];
    }
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:20];
    
    [self ensureHandlersAreCleared:session];
}

- (void)testCompletionHandlerError
{
    MYRHTTPSession* session = [MYRHTTPSession sharedSession];
    
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kUnavailableHost]];
    
    NSInteger max = 10;
    __block NSInteger count = 0;
    
    [self prepare];
    
    for (int i = 0; i < max; i++) {
        [session executeRequest:req progress:nil canceled:nil completion:^(NSHTTPURLResponse *response, NSData *body, NSError *error) {
            if (error != nil && error.code != NSURLErrorCancelled) {
                count++;
            }
            if (count == max) {
                [self notify:kGHUnitWaitStatusSuccess];
            }
        }];
    }
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:100];
    
    [self ensureHandlersAreCleared:session];
}

- (void)testProgressHandler
{
    MYRHTTPSession* session = [MYRHTTPSession sharedSession];
    
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kDownloadUrl]];
    NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:kDownloadUrl]];
    
    GHAssertTrue([data length] > 0, @"get test image");
    
    [self prepare];
    
    __block BOOL correctSizeFlag = YES;
    __block BOOL correctDoneFlag = NO;
    [session executeRequest:req progress:^(int64_t doneBytes, int64_t totalBytes) {
        NSLog(@"percent:%@", @((double)doneBytes/totalBytes));
        
        if (totalBytes != [data length]) {
            correctSizeFlag = NO;
        }
        if (correctSizeFlag && doneBytes == [data length]) {
            correctDoneFlag = YES;
        }
    } canceled:nil completion:^(NSHTTPURLResponse *response, NSData *body, NSError *error) {
        if (correctDoneFlag && [body length] == [data length]) {
            [self notify:kGHUnitWaitStatusSuccess];
        }
    }];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:20];
    
    [self ensureHandlersAreCleared:session];
}

- (void)testCancelAll_HeavyResource
{
    MYRHTTPSession* session = [MYRHTTPSession sharedSession];
    
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kDownloadUrl]];
    
    [self prepare];
    
    [session executeRequest:req progress:nil canceled:^{
        [self notify:kGHUnitWaitStatusSuccess];
    } completion:nil];
    
    [session cancelAll];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:20];
    
    [self ensureHandlersAreCleared:session];
}

- (void)testCancelAll
{
    MYRHTTPSession* session = [MYRHTTPSession sharedSession];
    
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kDownloadUrl]];
    
    NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:kDownloadUrl]];
    
    GHAssertTrue([data length] > 0, @"get test image");
    
    [self prepare];
    
    NSInteger max = 10;
    __block NSInteger count = 0;
    for (int i = 0; i < max; i++) {
        [session executeRequest:req progress:nil canceled:^{
            count++;
            if (count == max) {
                [self notify:kGHUnitWaitStatusSuccess];
            }
        } completion:^(NSHTTPURLResponse *response, NSData *body, NSError *error) {
            if (!error && [body length] == [data length]) {
                count++;
            }
            if (count == max) {
                [self notify:kGHUnitWaitStatusSuccess];
            }
        }];
    }
    
    [session cancelAll];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:20];
    
    [self ensureHandlersAreCleared:session];
}

- (void)testCancelAll_CompletionNotCalled
{
    MYRHTTPSession* session = [MYRHTTPSession sharedSession];
    
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kDownloadUrl]];
    
    NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:kDownloadUrl]];
    
    GHAssertTrue([data length] > 0, @"get test image");
    
    [self prepare];
    
    NSInteger max = 10;
    __block NSInteger count = 0;

    NSMutableSet* canceledSet = [NSMutableSet set];
    NSMutableSet* completedSet = [NSMutableSet set];
    
    for (int i = 0; i < max; i++) {
        [session executeRequest:req progress:nil canceled:^{
            [canceledSet addObject:@(i)];
            count++;
            if (count == max) {
                [self notify:kGHUnitWaitStatusSuccess];
            }
        } completion:^(NSHTTPURLResponse *response, NSData *body, NSError *error) {
            if (!error && [body length] == [data length]) {
                count++;
                [completedSet addObject:@(i)];
            }
            if (count == max) {
                [self notify:kGHUnitWaitStatusSuccess];
            }
        }];
    }
    
    [session cancelAll];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:20];
    
    GHAssertTrue([canceledSet count] + [completedSet count] == max, nil);
    GHAssertTrue(![canceledSet intersectsSet:completedSet], nil);
    [self ensureHandlersAreCleared:session];
}

- (void)testUpload
{
    MYRHTTPSession* session = [MYRHTTPSession sharedSession];
    
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kDownloadUrl]];
    [req setHTTPMethod:@"PUT"];
    [req setHTTPBody:UIImagePNGRepresentation([UIImage imageNamed:@"lena.png"])];

    NSInteger max = 10;
    __block NSInteger count = 0;
    
    [self prepare];
    
    for (int i = 0; i < max; i++) {
        [session executeRequest:req progress:nil canceled:nil completion:^(NSHTTPURLResponse *response, NSData *body, NSError *error) {
            if (response.statusCode == 200) {
                count++;
            }
            if (count == max) {
                [self notify:kGHUnitWaitStatusSuccess];
            }
        }];
    }
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:20];
    
    [self ensureHandlersAreCleared:session];
}

- (void)testIndivisualTaskCancel
{
    MYRHTTPSession* session = [MYRHTTPSession sharedSession];
    
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kDownloadUrl]];
    NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:kDownloadUrl]];
    
    GHAssertTrue([data length] > 0, @"get test image");
    
    NSInteger max = 10;
    __block NSInteger count = 0;
    NSURLSessionTask* target = nil;
    
    [self prepare];
    
    for (int i = 0; i < max; i++) {
        NSURLSessionTask* task = [session executeRequest:req progress:nil canceled:^{
            count++;
            if (count == max) {
                [self notify:kGHUnitWaitStatusSuccess];
            }
        } completion:^(NSHTTPURLResponse *response, NSData *body, NSError *error) {
            if ([data length] == [body length]) {
                count++;
            }
            if (count == max) {
                [self notify:kGHUnitWaitStatusSuccess];
            }
        }];
        
        if (i == 5) {
            target = task;
        }
    }
    
    [target cancel];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:20];
    
    GHAssertTrue(count == max, nil);

    [self ensureHandlersAreCleared:session];
}

- (void)ensureHandlersAreCleared:(MYRHTTPSession* )session
{
    NSDictionary* progressHandlers = [session valueForKey:@"progressHandlerMap"];
    NSDictionary* completionHandlers = [session valueForKey:@"completionHandlerMap"];
    NSArray* tasks = [session valueForKey:@"tasks"];
    
    GHAssertTrue([progressHandlers count] == 0, @"I want to make sure that all handlers are cleared");
    GHAssertTrue([completionHandlers count] == 0, @"");
    GHAssertTrue([tasks count] == 0, @"");
}

@end
