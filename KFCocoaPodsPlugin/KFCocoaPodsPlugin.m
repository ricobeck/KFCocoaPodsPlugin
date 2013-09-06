//
//  KFCocoaPodsPlugin.m
//  KFCocoaPodsPlugin
//
//  Created by rick on 04.09.13.
//    Copyright (c) 2013 KF Interactive. All rights reserved.
//

#import "KFCocoaPodsPlugin.h"
#import "KFConsoleController.h"
#import "KFTaskController.h"
#import "KFWorkspaceController.h"
#import "KFCocoaPodController.h"

#import <YAML-Framework/YAMLSerialization.h>


@interface KFCocoaPodsPlugin ()


@property (nonatomic, strong) NSDictionary *repos;

@property (nonatomic, strong) KFConsoleController *consoleController;

@property (nonatomic, strong) KFTaskController *taskController;

@property (nonatomic, strong) KFCocoaPodController *cocoaPodController;


@end


#define kPodCommand @"/usr/bin/pod"

#define kCommandInstall @"install"
#define kCommandUpdate @"update"
#define kCommandInterprocessCommunication @"ipc"
#define kCommandOutdated @"outdated"

#define kCommandConvertPodFileToYAML @"podfile"

#define kParamdNoColor @"--no-color"


@implementation KFCocoaPodsPlugin


#pragma mark -

+ (BOOL)shouldLoadPlugin
{
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    return bundleIdentifier && [bundleIdentifier caseInsensitiveCompare:@"com.apple.dt.Xcode"] == NSOrderedSame;
}


+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static id sharedPlugin = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPlugin = [[self alloc] init];
    });
}


- (id)init
{
    if (self = [super init])
    {
        _consoleController = [KFConsoleController new];
        _taskController = [KFTaskController new];
        
        [self buildRepoIndex];
        [self insertMenu];
        
        _cocoaPodController = [[KFCocoaPodController alloc] initWithRepoData:self.repos];
    }
    return self;
}


#pragma mark - Initialization


- (void)buildRepoIndex
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [self printMessage:@"building repo index" forTask:nil];
    
    NSMutableDictionary *parsedRepos = [NSMutableDictionary new];
    
    NSArray *repos = [fileManager contentsOfDirectoryAtPath:[@"~/.cocoapods/repos/" stringByExpandingTildeInPath] error:nil];
   [self.consoleController logMessage:repos forTask:nil];
    
    for (NSString *repoDirectory in repos)
    {
        NSString *repoPath = [[@"~/.cocoapods/repos" stringByAppendingPathComponent:repoDirectory] stringByExpandingTildeInPath];
        NSArray *pods = [fileManager contentsOfDirectoryAtPath:repoPath error:nil];
         
        
        for (NSString *podDirectory in pods)
        {
            if (![podDirectory hasPrefix:@"."])
            {
                NSString *podPath = [repoPath stringByAppendingPathComponent:podDirectory];
                NSArray *versions = [fileManager contentsOfDirectoryAtPath:podPath error:nil];
                
                [parsedRepos setValue:versions forKey:podDirectory];
            }
        }
    }
    
    self.repos = [parsedRepos copy];
}


- (void)insertMenu
{
    NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"Product"];
    if (menuItem)
    {
        [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
        NSMenuItem *cocoapodsMenuItem = [[NSMenuItem alloc] initWithTitle:@"CocoaPods" action:nil keyEquivalent:@""];
        [[menuItem submenu] addItem:cocoapodsMenuItem];
        
        NSMenu *submenu = [[NSMenu alloc] initWithTitle:@"CocoaPods Submenu"];
        
        NSMenuItem *checkMenuItem = [[NSMenuItem alloc] initWithTitle:@"Check Pods" action:@selector(checkOutdatedPodsAction:) keyEquivalent:@""];
        [checkMenuItem setTarget:self];
        [submenu addItem:checkMenuItem];
        
        NSMenuItem *updateMenuItem = [[NSMenuItem alloc] initWithTitle:@"Update/Install" action:@selector(podUpdateAction:) keyEquivalent:@""];
        [updateMenuItem setTarget:self];
        [submenu addItem:updateMenuItem];
        
        NSMenuItem *reposMenuItem = [[NSMenuItem alloc] initWithTitle:@"Repos" action:nil keyEquivalent:@""];
        
        
        NSMenu *repoMenu = [[NSMenu alloc] initWithTitle:@"CocoaPods Repos"];
        
        NSArray *repos = [[self.repos allKeys] sortedArrayUsingSelector:@selector(compare:)];
        for (NSString *repo in repos)
        {
            NSMenuItem *repoMenuItem = [[NSMenuItem alloc] initWithTitle:repo action:nil keyEquivalent:@""];
            
            NSMenu *repoVersionMenu = [[NSMenu alloc] initWithTitle:repo];
            
            for (NSString *version in self.repos[repo])
            {
                NSMenuItem *versionMenuItem = [[NSMenuItem alloc] initWithTitle:version action:nil keyEquivalent:@""];
                [repoVersionMenu addItem:versionMenuItem];
            }
            
            repoMenuItem.submenu = repoVersionMenu;
            [repoMenu addItem:repoMenuItem];
        }
        reposMenuItem.submenu = repoMenu;
        [submenu addItem:reposMenuItem];
        
        cocoapodsMenuItem.submenu = submenu;
    }
}


#pragma mark - Actions


- (void)podUpdateAction:(id)sender
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);

    __weak typeof(self) weakSelf = self;
    dispatch_async(queue, ^
    {
        if ([KFWorkspaceController currentWorkspaceHasPodfile])
        {
            [weakSelf printMessageBold:@"start pod update" forTask:nil];
            
            NSString *command =[KFWorkspaceController currentWorkspaceHasPodfileLock] ? kCommandUpdate : kCommandInstall;
            [[KFTaskController new] runShellCommand:kPodCommand withArguments:@[command, kParamdNoColor] directory:[KFWorkspaceController currentWorkspaceDirectoryPath] progress:^(NSTask *task, NSString *output, NSString *error)
             {
                 if (output != nil)
                 {
                     [weakSelf printMessage:output forTask:task];
                 }
                 else
                 {
                     [weakSelf printMessage:error forTask:task];
                 }
             }
             completion:^(NSTask *task, BOOL success, NSString *output, NSException *exception)
             {
                 if (success)
                 {
                     [weakSelf printMessageBold:@"pod update done" forTask:task];
                 }
                 else
                 {
                     [weakSelf printMessageBold:@"pod update failed" forTask:task];
                 }
                 [weakSelf.consoleController removeTask:task];
             }];
        }
        else
        {
            [weakSelf printMessageBold:@"no podfile - no pod update" forTask:nil];
        }
    });
}


- (void)checkOutdatedPodsAction:(id)sender
{
    //[self parseYAMLForPodfile:[KFWorkspaceController currentWorkspacePodfilePath]];

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(queue, ^
    {
       if ([KFWorkspaceController currentWorkspaceHasPodfile])
       {
           [weakSelf printMessageBold:@"start pod outdated check" forTask:nil];
           
           [[KFTaskController new] runShellCommand:kPodCommand withArguments:@[kCommandOutdated, kParamdNoColor] directory:[KFWorkspaceController currentWorkspaceDirectoryPath] progress:^(NSTask *task, NSString *output, NSString *error)
            {
                if (output != nil)
                {
                    [weakSelf printMessage:output forTask:task];
                }
                else
                {
                    [weakSelf printMessage:error forTask:task];
                }
            }
           completion:^(NSTask *task, BOOL success, NSString *output, NSException *exception)
            {
                if (success)
                {
                    [weakSelf printMessageBold:@"pod outdated done" forTask:task];
                }
                else
                {
                    [weakSelf printMessageBold:@"pod outdated failed" forTask:task];
                }
                [weakSelf.consoleController removeTask:task];
            }];
       }
       else
       {
           [weakSelf printMessageBold:@"no podfile - no outdated pods" forTask:nil];
       }
    });
    
    
    //TODO: maybe implement own checking?
    
    NSError *error = nil;
    NSString *content = [NSString stringWithContentsOfFile:[KFWorkspaceController currentWorkspacePodfileLockPath] encoding:NSUTF8StringEncoding error:&error];
    
    if (error == nil)
    {
        NSMutableArray *yaml = [YAMLSerialization YAMLWithData:[content dataUsingEncoding:NSUTF8StringEncoding] options:kYAMLReadOptionStringScalars error:&error];
        
        //NSArray *outdatedPods = [self.cocoaPodController outdatedPodsForLockFileContents:content];
        [self printMessageBold:@"parsed lock file" forTask:nil];
        [self printMessage:[yaml description] forTask:nil];
    }
    else
    {
        [self printMessage:error.description forTask:nil];
    }
}


- (void)parseYAMLForPodfile:(NSString *)podfile
{
     __weak typeof(self) weakSelf = self;
    [[KFTaskController new] runShellCommand:kPodCommand withArguments:@[kCommandInterprocessCommunication, kCommandConvertPodFileToYAML, podfile] directory:[KFWorkspaceController currentWorkspaceDirectoryPath] progress:nil completion:^(NSTask *task, BOOL success, NSString *output, NSException *exception)
    {
        if (success)
        {
            [weakSelf printMessageBold:@"parsed podfile:" forTask:task];
            NSMutableArray *lines = [[output componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] mutableCopy];
            [lines removeObjectAtIndex:0];
            output = [lines componentsJoinedByString:@"\n"];
            NSError *error = nil;
            NSMutableArray *yaml = [YAMLSerialization YAMLWithData:[output dataUsingEncoding:NSUTF8StringEncoding] options:kYAMLReadOptionStringScalars error:&error];
            if (error == nil)
            {
                [weakSelf printMessage:[yaml description] forTask:task];
            }
            else
            {
                [weakSelf printMessageBold:error.description forTask:task];
            }
            
            
        }
    }];
}

#pragma mark - Logging


- (void)printMessage:(NSString *)message forTask:(NSTask *)task
{
     __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.consoleController logMessage:message printBold:NO forTask:task];
    });
}


- (void)printMessageBold:(NSString *)message forTask:(NSTask *)task
{
     __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.consoleController logMessage:message printBold:YES forTask:task];
    });
}


#pragma mark -

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
