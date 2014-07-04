//
//  MYRHTTPSessionTests.m
//  MYRHTTPSession
//
//  Created by park on 2014/07/04.
//
//

#import "MYRHTTPSessionTests.h"
#import "MYRHTTPSession.h"

static NSString* const kImageUrl = @"http://colorvisiontesting.com/plate%20with%205.jpg";
static NSString* const kHeavyImageUrl = @"http://upload.wikimedia.org/wikipedia/commons/1/19/DSCF1069-Castielli-Italy-Etna-Creative_Commons-High_Resolution_2.jpg";
static NSString* const kNotfoundUrl = @"http://aaaaaaaaaaaaaaaaaaaa";

@implementation MYRHTTPSessionTests

- (void)testSingleton
{
    MYRHTTPSession* s1 = [MYRHTTPSession sharedSession];
    MYRHTTPSession* s2 = [MYRHTTPSession sharedSession];
    
    GHAssertTrue(s1 == s2, @"returns same instance");
}

- (void)testCompletionHandler
{
    MYRHTTPSession* session = [MYRHTTPSession sharedSession];
    
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kImageUrl]];
    NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:kImageUrl]];
    
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
    
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kNotfoundUrl]];
    
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
    
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kImageUrl]];
    NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:kImageUrl]];
    
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
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10];
    
    [self ensureHandlersAreCleared:session];
}

- (void)testCancelAll_HeavyResource
{
    MYRHTTPSession* session = [MYRHTTPSession sharedSession];
    
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kHeavyImageUrl]];
    
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
    
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kImageUrl]];
    
    NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:kImageUrl]];
    
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
    
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kImageUrl]];
    
    NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:kImageUrl]];
    
    GHAssertTrue([data length] > 0, @"get test image");
    
    [self prepare];
    
    NSInteger max = 10;
    __block NSInteger count = 0;
    __block NSInteger canceledCount = 0;
    __block NSInteger completedCount = 0;
    
    for (int i = 0; i < max; i++) {
        [session executeRequest:req progress:nil canceled:^{
            count++;
            canceledCount++;
            if (count == max) {
                [self notify:kGHUnitWaitStatusSuccess];
            }
        } completion:^(NSHTTPURLResponse *response, NSData *body, NSError *error) {
            completedCount++;
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
    
    GHAssertTrue(canceledCount + completedCount == max, nil);
    [self ensureHandlersAreCleared:session];
}

- (void)ensureHandlersAreCleared:(MYRHTTPSession* )session
{
    NSDictionary* progressHandlers = [session valueForKey:@"progressHandlerMap"];
    NSDictionary* completionHandlers = [session valueForKey:@"completionHandlerMap"];
    NSArray* tasks = [session valueForKey:@"tasks"];
    
    GHAssertTrue([progressHandlers count] == 0, @"I worry about my implementaion. I want to make sure that all handlers are cleared");
    GHAssertTrue([completionHandlers count] == 0, @"");
    GHAssertTrue([tasks count] == 0, @"");
}

@end
