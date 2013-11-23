//
//  KFReplController.m
//  KFCocoaPodsPlugin
//
//  Created by rick on 17/11/13.
//  Copyright (c) 2013 KF Interactive. All rights reserved.
//

#import "KFReplController.h"

#import <DSUnixTask/DSUnixTaskSubProcessManager.h>
#import <DSUnixTask/DSUnixShellTask.h>

#import <YAML-Framework/YAMLSerialization.h>


NSString * const KFReplControllerParsingCountDidChange = @"ReplControllerParsingCountDidChange";

NSString * const KFReplParseCount = @"ReplParseCount";

@interface KFReplController ()


@property (nonatomic, strong) DSUnixShellTask *task;

@property (strong) NSMutableArray *queue;

@property (nonatomic, strong) NSMutableDictionary *completionBlockMap;

@property (atomic) BOOL isProcessing;

@property (nonatomic, strong) NSMutableString *currentOutput;


@end


@implementation KFReplController


+ (instancetype)sharedController
{
    static KFReplController *sharedInstance = nil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        sharedInstance = [[KFReplController alloc] init];
    });
    
    return sharedInstance;
}


- (id)init
{
    self = [super init];
    if (self)
    {
        _completionBlockMap = [NSMutableDictionary new];
        
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void)
        {
            [self initTask];
        });
    }
    return self;
}


- (void)initTask
{
     __weak typeof(self) weakSelf = self;
    
    self.task = [DSUnixTaskSubProcessManager shellTask];
    [[DSUnixTaskSubProcessManager sharedManager] setLoggingEnabled:NO];
    NSString *fixedLanguage = @"en_US.UTF-8";
    self.task.environment = @{@"LC_ALL": fixedLanguage};
    [self.task setCommand:@"pod"];
    [self.task setArguments:@[@"ipc repl"]];
    [self.task launch];
    
    [self.task setStandardOutputHandler:^(DSUnixTask *task, NSString *output)
     {
         [weakSelf.currentOutput appendString:output];
         unichar lastCharacter = [weakSelf.currentOutput characterAtIndex:[weakSelf.currentOutput length] - 1];
         unichar penultimateCharacter = [weakSelf.currentOutput characterAtIndex:[weakSelf.currentOutput length] - 2];         
         
         NSError *error = nil;
         
         if (lastCharacter == NSNewlineCharacter && penultimateCharacter == NSCarriageReturnCharacter)
         {
             if (error == nil && [weakSelf.queue firstObject])
             {
                 NSString *currentSpec = [weakSelf.queue firstObject];
                 [weakSelf.queue removeObjectAtIndex:0];
                 
                 [[NSNotificationCenter defaultCenter] postNotificationName:KFReplControllerParsingCountDidChange object:weakSelf userInfo:@{KFReplParseCount: @([weakSelf.queue count])}];
                 
                 
                 KFReplSpecParseCompletionBlock block = weakSelf.completionBlockMap[currentSpec];
                 [weakSelf.completionBlockMap removeObjectForKey:currentSpec];
                 
                 if (block)
                 {
                     block(@{@"summary": output});
                 }
             }
             else
             {
                 NSLog(@"error: %@", error);
             }
             
             weakSelf.isProcessing = NO;
             [weakSelf processNextSpec];
         }
         else
         {
             if (lastCharacter == NSNewlineCharacter)
             {
                 NSLog(@"current output: %@\nfile: %@", weakSelf.currentOutput, [weakSelf.queue firstObject]);
             }
         }
     }];
    
    self.isProcessing = NO;
}


- (void)parseSpec:(NSString *)specFilePath withCompletionBlock:(KFReplSpecParseCompletionBlock)completionBlock
{
    if (_queue == nil)
    {
        _queue = [NSMutableArray new];
    }

    NSRange whiteSpaceRange = [specFilePath rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
    if (whiteSpaceRange.location == NSNotFound)
    {
        [self.queue addObject:specFilePath];
        self.completionBlockMap[specFilePath] = completionBlock;
        [self processNextSpec];
        [[NSNotificationCenter defaultCenter] postNotificationName:KFReplControllerParsingCountDidChange object:@([self.queue count])];
    }
    else
    {
        completionBlock(@{@"summary": @"Path containts spaces. This will lead to an error."});
    }
}


- (void)processNextSpec
{
    if (!self.isProcessing && [self.queue count] > 0)
    {
        self.isProcessing = YES;
        self.currentOutput = [NSMutableString new];
        [self.task writeStringToStandardInput:[NSString stringWithFormat:@"spec %@\n", [self.queue firstObject]]];
    }
}



@end
