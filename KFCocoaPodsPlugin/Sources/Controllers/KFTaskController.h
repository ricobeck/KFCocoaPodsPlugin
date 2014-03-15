//
//  KFTaskController.h
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

#import <Foundation/Foundation.h>


@class DSUnixTask;


typedef void(^KFTaskControllerProgressBlock)(NSTask *task, NSString *output, NSString *error);

typedef void(^KFTaskControllerCompletionBlock)(NSTask *task, BOOL success, NSString *output, NSException *exception);



typedef void(^KFTaskOutputHandler)(DSUnixTask *taskLauncher, NSString *newOutput);

typedef void(^KFTaskTerminationHandler)(DSUnixTask *taskLauncher);

typedef void(^KFTaskFailureHandler)(DSUnixTask *taskLauncher);



@interface KFTaskController : NSObject



- (DSUnixTask *)runPodCommand:(NSArray *)arguments directory:(NSString *)directory outputHandler:(KFTaskOutputHandler)outpuBlock terminationHandler:(KFTaskTerminationHandler)terminationBlock failureHandler:(KFTaskFailureHandler)failureBlock;



@end
