MYRHTTPSession
==============

Easy to use HTTP library with progress block.

## Usage

``` objective-c
MYRHTTPSession* session = [MYRHTTPSession sharedSession];
[session executeRequest:request progress:^(int64_t doneBytes, int64_t totalBytes) {
    NSLog(@"%@%% Loaded.", @(100 * (double)doneBytes/totalBytes));
} canceled:^{
    NSLog(@"cancaled.");
} completion:^(NSHTTPURLResponse *response, NSData *body, NSError *error) {
    NSLog(@"completed.");
}];
```

## Installation

Just copy MYRHTTPSession.{h.m} to your project.
