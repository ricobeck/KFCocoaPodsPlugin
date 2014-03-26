//
//  KFTryController.m
//  KFCocoaPodsPlugin
//
//  Created by Zac White on 3/17/14.
//  Copyright (c) 2014 KF Interactive. All rights reserved.
//

#import "KFTryController.h"
#import "KFTaskController.h"
#import <DSUnixTask/DSUnixTask.h>

@interface KFTryController ()

@property (strong, nonatomic) KFTaskController *taskController;

- (CGFloat)progressForOutput:(NSString *)output;

@end

@implementation KFTryController

static NSString *kKFTryErrorDomain = @"kKFTryErrorDomain";

static const NSUInteger kKFTryErrorCodeCrash = 100;
static const NSUInteger kKFTryErrorCodeUnsupportedVersion = 101;
static const NSUInteger kKFTryErrorCodeNoProjectFound = 102;
static const NSUInteger kKFTryErrorCodeMultipleProjectsFound = 103;

- (void)tryPodWithName:(NSString *)podName progress:(void(^)(CGFloat progress))progressCallback completion:(void(^)(NSError *error))completionCallback
{
    if (!self.taskController) {
        self.taskController = [[KFTaskController alloc] init];
    }
    
    // capture all output to figure out a failure if we get one.
    NSMutableString *totalOutput = [NSMutableString string];
    
    NSString *verbose = @"";
    if (progressCallback) verbose = @"--verbose";
    
    DSUnixTask *task = [self.taskController runPodCommand:@[@"try", @"--no-color", verbose, podName] directory:nil outputHandler:^(DSUnixTask *taskLauncher, NSString *newOutput) {
        [totalOutput appendString:newOutput];
        
        CGFloat progress = [self progressForOutput:totalOutput];
        if (progressCallback && progress > 0.0f) {
            dispatch_async(dispatch_get_main_queue(), ^{
                progressCallback(progress);
            });
        }
        
    } terminationHandler:^(DSUnixTask *taskLauncher) {
        if (completionCallback) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionCallback(nil);
            });
        }
    } failureHandler:^(DSUnixTask *taskLauncher) {
        
        // "Unknown arguments" is displayed when the 'pod' doesn't recognize the command.
        NSRange unknownRange = [totalOutput rangeOfString:@"Unknown arguments"];
        
        // "Unable to find any projects" is show when a pod doesn't have any projects to open.
        NSRange unableRange = [totalOutput rangeOfString:@"Unable to"];
        
        // "an error occurred" is shown when cocoapods crashes.
        NSRange crashRange = [totalOutput rangeOfString:@"an error occurred"];
        
        NSError *error = nil;
        if (crashRange.location != NSNotFound) {
            // this happens to some pods. See: https://github.com/CocoaPods/cocoapods-try/issues/16
            error = [NSError errorWithDomain:kKFTryErrorDomain code:kKFTryErrorCodeCrash userInfo:@{ NSLocalizedDescriptionKey: @"There was an error while running 'pod try'. Please use from the command line."}];
        } else if (unknownRange.location != NSNotFound) {
            // this is a version before try was supported?
            error = [NSError errorWithDomain:kKFTryErrorDomain code:kKFTryErrorCodeUnsupportedVersion userInfo:@{ NSLocalizedDescriptionKey: @"This version of Cocoapods does not support 'pod try'"}];
        } else if (unableRange.location != NSNotFound) {
            // we weren't able to find a project.
            error = [NSError errorWithDomain:kKFTryErrorDomain code:kKFTryErrorCodeNoProjectFound userInfo:@{ NSLocalizedDescriptionKey: @"Unable to find an example project in the repository."}];
        } else {
            // we just had an error or had multiple options.
            // it's hard to really tell the difference, so assume the common case.
            error = [NSError errorWithDomain:kKFTryErrorDomain code:kKFTryErrorCodeMultipleProjectsFound userInfo:@{ NSLocalizedDescriptionKey: @"There were several projects found. Please use 'pod try' from the command line."}];
        }
        
        if (completionCallback) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionCallback(error);
            });
        }
    }];
    
    // writing this to the standard input helps us exit the multiple options case.
    // it doesn't seem to have any ill effect on the other cases.
    [task writeStringToStandardInput:@"n\n"];
}

- (CGFloat)progressForOutput:(NSString *)output
{
    // the different strings we're looking for in the verbose output.
    NSArray *steps = @[@"Updating spec repositories",
                       @"Updating spec repo ",
                       @"Trying ",
                       @"Cloning to Pods folder",
                       @"Switched to a new branch"];
    
    // the current step used to determine progress.
    NSUInteger currentStep = 0;
    NSUInteger maxLocation = 0;
    
    for (NSUInteger stepIndex = 0; stepIndex < [steps count]; stepIndex++) {
        
        // find the range of the step string.
        NSRange stepRange = [output rangeOfString:steps[stepIndex]];
        
        if (stepRange.location != NSNotFound) {
            
            // if the location is the farthest we've encountered, it represents the current step.
            if (stepRange.location > maxLocation) {
                maxLocation = stepRange.location;
                currentStep = stepIndex;
            }
        }
    }
    
    // return the progress percentage. add one to currentStep so it's unit indexed.
    return (currentStep + 1) / (CGFloat)[steps count];
}

@end
