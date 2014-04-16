//
//  KFCocoaPodController.m
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

#import "KFCocoaPodController.h"
#import "KFCocoaPodsPlugin.h"
#import "KFTaskController.h"
#import "KFWorkspaceController.h"

#import <DSUnixTask/DSUnixShellTask.h>
#import <DSUnixTask/DSUnixTaskSubProcessManager.h>

#import <YAML-Framework/YAMLSerialization.h>

#include <signal.h>


NSString * const KFMajorVersion = @"majorVersion";

NSString * const KFMinorVersion = @"minorVersion";

NSString * const KFBuildVersion = @"buildVersion";


@interface KFCocoaPodController ()


@property (nonatomic, strong) NSDictionary *repoData;


@end


@implementation KFCocoaPodController


- (id)initWithRepoData:(NSDictionary *)repoData
{
    self = [super init];
    if (self)
    {
        _repoData = repoData;
    }
    return self;
}


- (void)cocoaPodsVersion:(KFCocoaPodsVersionBlock)versionBlock
{
    DSUnixShellTask *task = [DSUnixTaskSubProcessManager shellTask];
    //NSLocale *currentLocale = [NSLocale currentLocale];
    //NSString *laguage = [[currentLocale localeIdentifier] stringByAppendingString:@".UTF-8"];
    NSString *fixedLanguage = @"en_US.UTF-8";
    task.environment = @{@"LC_ALL": fixedLanguage};
    [[DSUnixTaskSubProcessManager sharedManager] setLoggingEnabled:NO];
    [task setCommand:@"pod"];
    [task setArguments:@[@"ipc repl"]];
    
    [task setStandardOutputHandler:^(DSUnixTask *task, NSString *output)
    {
        NSError *error = nil;
        NSMutableArray *yaml = [YAMLSerialization YAMLWithData:[task.standardOutput dataUsingEncoding:NSUTF8StringEncoding] options:kYAMLReadOptionStringScalars error:&error];
        
        if (error == nil)
        {
            NSDictionary *versionDictionary = yaml[0];
            
            if(![versionDictionary isKindOfClass:[NSDictionary class]])
            {
                versionBlock(nil);
            }
            else
            {
                NSString *version = versionDictionary[@"version"];
                NSArray *versionComponents = [version componentsSeparatedByString:@"."];
                if ([versionComponents count] == 3)
                {
                    versionBlock(@{KFMajorVersion: versionComponents[0], KFMinorVersion: versionComponents[1], KFBuildVersion: versionComponents[2]});
                }
                else
                {
                    versionBlock(nil);
                }
            }
        }
        else
        {
            NSLog(@"error: %@", error);
        }
    }];
    
    [task launch];
    double delayInSeconds = .3;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void)
    {
        kill(task.processIdentifier, SIGINT);
    });
}


- (NSArray *)outdatedPodsForLockFileContents:(NSString *)lockFileContents
{
    return @[lockFileContents];
}


@end
