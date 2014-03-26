//
//  KFTaskController.m
//  KFCocoaPodsPlugin
//
//  Copyright (c) 2013 Rico Becker, KF Interactive
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "KFTaskController.h"
#import <DSUnixTask/DSUnixTaskSubProcessManager.h>

@implementation KFTaskController


- (DSUnixTask *)runPodCommand:(NSArray *)arguments directory:(NSString *)directory outputHandler:(KFTaskOutputHandler)outpuBlock terminationHandler:(KFTaskTerminationHandler)terminationBlock failureHandler:(KFTaskFailureHandler)failureBlock
{    
    DSUnixTask *task = [DSUnixTaskSubProcessManager shellTask];
    [[DSUnixTaskSubProcessManager sharedManager] setLoggingEnabled:YES];
    
    //NSLocale *currentLocale = [NSLocale currentLocale];
    //NSString *laguage = [[currentLocale localeIdentifier] stringByAppendingString:@".UTF-8"];
    NSString *laguage = @"en_US.UTF-8";
    task.environment = @{@"LC_ALL": laguage};
    
    
    [task setCommand:@"pod"];
    
    if (directory != nil)
    {
        [task setWorkingDirectory:directory];
    }
        
    [task setArguments:arguments];
    
    [task setStandardErrorHandler:^(DSUnixTask *task, NSString *error)
    {
        NSLog(@"DSUnixTask error: %@", error);
    }];
    
    [task setStandardOutputHandler:outpuBlock];
    [task setTerminationHandler:terminationBlock];
    [task setFailureHandler:failureBlock];
    
    [task launch];
    
    return task;
}


@end
