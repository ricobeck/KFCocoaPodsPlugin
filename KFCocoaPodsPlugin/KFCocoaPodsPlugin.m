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


@interface KFCocoaPodsPlugin ()


@property (nonatomic, strong) NSDictionary *repos;

@property (nonatomic, strong) KFConsoleController *consoleController;

@property (nonatomic, strong) KFTaskController *taskController;


@end


#define kPodCommand @"/usr/bin/pod"
#define kCommandNoColor @"--no-color"

@implementation KFCocoaPodsPlugin


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
    }
    return self;
}


- (void)buildRepoIndex
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [self.consoleController logMessage:@"building repo index"];
    
    NSMutableDictionary *parsedRepos = [NSMutableDictionary new];
    
    NSArray *repos = [fileManager contentsOfDirectoryAtPath:[@"~/.cocoapods/repos/" stringByExpandingTildeInPath] error:nil];
   [self.consoleController logMessage:repos];
    
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
    
    self.repos = [[parsedRepos copy] retain];
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
        
        NSMenuItem *updateMenuItem = [[NSMenuItem alloc] initWithTitle:@"Update/Install" action:@selector(doMenuAction) keyEquivalent:@""];
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
                [versionMenuItem release];
            }
            
            repoMenuItem.submenu = repoVersionMenu;
            [repoVersionMenu release];
            
            [repoMenu addItem:repoMenuItem];
            [repoMenuItem release];
        }
        reposMenuItem.submenu = repoMenu;
        [submenu addItem:reposMenuItem];
        [repoMenu release];
        
        cocoapodsMenuItem.submenu = submenu;
        [cocoapodsMenuItem release];
        [submenu release];
    }
}


- (void)doMenuAction
{
    [self performSelectorInBackground:@selector(podUpdate) withObject:nil];
}


- (void)podUpdate
{
    if ([KFWorkspaceController currentWorkspaceHasPodfile])
    {
        [self performSelectorOnMainThread:@selector(printMessageBold:) withObject:@"start pod update" waitUntilDone:NO];

        [[KFTaskController new] runShellCommand:kPodCommand withArguments:@[@"update", kCommandNoColor] directory:[KFWorkspaceController currentWorkspaceDirectoryPath] progress:^(NSTask *task, NSString *output, NSString *error)
         {
             if (output != nil)
             {
                 [self performSelectorOnMainThread:@selector(printMessage:) withObject:output waitUntilDone:NO];
             }
             else
             {
                 [self performSelectorOnMainThread:@selector(printMessage:) withObject:error waitUntilDone:NO];
             }
         }
         completion:^(NSTask *task, BOOL success, NSException *exception)
         {
             if (success)
             {
                 [self performSelectorOnMainThread:@selector(printMessageBold:) withObject:@"pod update done" waitUntilDone:NO];
             }
             else
             {
                 [self performSelectorOnMainThread:@selector(printMessageBold:) withObject:@"pod update failed" waitUntilDone:NO];
             }
         }];
    }
    else
    {
        [self performSelectorOnMainThread:@selector(printMessageBold:) withObject:@"no podfile - no pod update" waitUntilDone:NO];
    }
}


- (void)printMessage:(NSString *)message
{
   [self.consoleController logMessage:message printBold:NO];
}


- (void)printMessageBold:(NSString *)message
{
    [self.consoleController logMessage:message printBold:YES];
}





- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.repos release];
    [super dealloc];
}


@end
