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
#import "KFNotificationController.h"

#import "KFRepoModel.h"

#import <YAML-Framework/YAMLSerialization.h>
#import <KSCrypto/KSSHA1Stream.h>


typedef NS_ENUM(NSUInteger, KFMenuItemTag)
{
    KFMenuItemTagEditPodfile,
    KFMenuItemTagCheckForOutdatedPods,
    KFMenuItemTagUpdate
};



@interface KFCocoaPodsPlugin ()


@property (nonatomic, strong) NSDictionary *repos;

@property (nonatomic, strong) KFConsoleController *consoleController;

@property (nonatomic, strong) KFTaskController *taskController;

@property (nonatomic, strong) KFCocoaPodController *cocoaPodController;

@property (nonatomic, strong) KFNotificationController *notificationController;


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
        _notificationController = [KFNotificationController new];
        
        [self buildRepoIndex];
        [self insertMenu];

        _cocoaPodController = [[KFCocoaPodController alloc] initWithRepoData:self.repos];
    }
    return self;
}


- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    switch (menuItem.tag)
    {
        case KFMenuItemTagEditPodfile:
        case KFMenuItemTagCheckForOutdatedPods:
        case KFMenuItemTagUpdate:
            return [KFWorkspaceController currentWorkspaceHasPodfile];
            break;
        default:
            return YES;
            break;
    }
}


#pragma mark - Initialization


- (void)buildRepoIndex
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [self printMessage:@"building repo index"];
    
    NSMutableDictionary *parsedRepos = [NSMutableDictionary new];
    NSArray *repos = [fileManager contentsOfDirectoryAtPath:[@"~/.cocoapods/repos/" stringByExpandingTildeInPath] error:nil];
    
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
                
                NSMutableArray *specs = [NSMutableArray new];
                
                for (NSString *version in versions)
                {
                    KFRepoModel *repoModel = [KFRepoModel new];
                    repoModel.pod = podDirectory;
                    repoModel.version = version;
                    
                    NSString *specPath = [podPath stringByAppendingPathComponent:version];
                    NSArray *files = [fileManager contentsOfDirectoryAtPath:specPath error:nil];
                    for (NSString *podspec in files)
                    {
                        if ([podspec.pathExtension isEqualToString:@"podspec"])
                        {
                            NSData *contents = [NSData dataWithContentsOfFile:[specPath stringByAppendingPathComponent:podspec]];
                            repoModel.checksum = [contents ks_SHA1DigestString];
                        }
                    }
                    [specs addObject:repoModel];
                }
                [parsedRepos setValue:[specs sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"version" ascending:YES]]] forKey:podDirectory];
            }
        }
    }
    
    self.repos = [parsedRepos copy];
}


- (void)insertMenu
{
    NSMenuItem *productsMenuItem = [[NSApp mainMenu] itemWithTitle:@"Product"];
    if (productsMenuItem)
    {
        
        NSMenuItem *cocoapodsMenuItem = [[NSMenuItem alloc] initWithTitle:@"CocoaPods" action:nil keyEquivalent:@""];
        NSMenuItem *seperatorItem = [NSMenuItem separatorItem];
        NSUInteger index = [productsMenuItem.submenu indexOfItemWithTitle:@"Perform Action"] + 1;
        [[productsMenuItem submenu] insertItem:seperatorItem atIndex:index];
        [[productsMenuItem submenu] insertItem:cocoapodsMenuItem atIndex:index +1];
        
        NSMenu *submenu = [[NSMenu alloc] initWithTitle:@"CocoaPods Submenu"];
        
        NSMenuItem *editPodfileMenuItem = [[NSMenuItem alloc] initWithTitle:@"Edit Podfile" action:@selector(editPodfileAction:) keyEquivalent:@""];
        [editPodfileMenuItem setTarget:self];
        editPodfileMenuItem.tag = KFMenuItemTagEditPodfile;
        [submenu addItem:editPodfileMenuItem];
        
        NSMenuItem *checkMenuItem = [[NSMenuItem alloc] initWithTitle:@"Check For Outdated Pods" action:@selector(checkOutdatedPodsAction:) keyEquivalent:@""];
        [checkMenuItem setTarget:self];
        checkMenuItem.tag = KFMenuItemTagCheckForOutdatedPods;
        [submenu addItem:checkMenuItem];
        
        NSMenuItem *updateMenuItem = [[NSMenuItem alloc] initWithTitle:@"Run Update/Install" action:@selector(podUpdateAction:) keyEquivalent:@""];
        [updateMenuItem setTarget:self];
        updateMenuItem.tag = KFMenuItemTagUpdate;
        [submenu addItem:updateMenuItem];
        

        NSMenuItem *reposMenuItem = [[NSMenuItem alloc] initWithTitle:@"Repos" action:nil keyEquivalent:@""];
        
        NSMenu *repoMenu = [[NSMenu alloc] initWithTitle:@"CocoaPods Repos"];
        
        NSArray *repos = [[self.repos allKeys] sortedArrayUsingSelector:@selector(compare:)];
        for (NSString *repo in repos)
        {
            NSMenuItem *repoMenuItem = [[NSMenuItem alloc] initWithTitle:repo action:nil keyEquivalent:@""];
            
            NSMenu *repoVersionMenu = [[NSMenu alloc] initWithTitle:repo];
            
            for (KFRepoModel *repoModel in self.repos[repo])
            {
                NSMenuItem *versionMenuItem = [[NSMenuItem alloc] initWithTitle:repoModel.version action:nil keyEquivalent:@""];
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


- (void)editPodfileAction:(id)sender
{
    [self openFileInIDE:[KFWorkspaceController currentWorkspacePodfilePath]];
}


- (void)podUpdateAction:(id)sender
{
    NSString *workspaceTitle = [KFWorkspaceController currentRepresentingTitle];
    __weak typeof(self) weakSelf = self;
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(queue, ^
    {
        if ([KFWorkspaceController currentWorkspaceHasPodfile])
        {
            [weakSelf printMessageBold:@"start pod update"];
            
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
                 NSString *title;
                 NSString *message = workspaceTitle;
                 if (success)
                 {
                     title = NSLocalizedString(@"Cocoapods update succeeded", nil);
                 }
                 else
                 {
                     title = NSLocalizedString(@"Cocoapods update failed", nil);
                 }
                 [weakSelf printMessageBold:title forTask:task];
                 [weakSelf.notificationController showNotificationWithTitle:title andMessage:message];
                 [weakSelf.consoleController removeTask:task];
             }];
        }
        else
        {
            [weakSelf printMessageBold:@"no podfile - no pod update"];
        }
    });
}


- (void)checkOutdatedPodsAction:(id)sender
{
    NSError *error = nil;
    NSString *content = [NSString stringWithContentsOfFile:[KFWorkspaceController currentWorkspacePodfileLockPath] encoding:NSUTF8StringEncoding error:&error];
    
    if (error == nil)
    {
        [self printMessageBold:NSLocalizedString(@"Start checking for updated Pods", nil)];
        
        NSMutableArray *yaml = [YAMLSerialization YAMLWithData:[content dataUsingEncoding:NSUTF8StringEncoding] options:kYAMLReadOptionStringScalars error:&error];
        
        /*
        [self printMessageBold:@"parsed lock file"];
        [self printMessage:[[yaml firstObject] description]];
         */
        
        NSDictionary *specChecksums = [yaml firstObject][@"SPEC CHECKSUMS"];
        NSArray *installedPods = [yaml firstObject][@"PODS"];
        
        NSMutableArray *podsWithUpdates = [NSMutableArray new];
        NSCharacterSet *trimSet = [NSCharacterSet characterSetWithCharactersInString:@" ()"];
        
        for (NSString *spec in specChecksums)
        {
            NSString *checksum = specChecksums[spec];
            KFRepoModel *latestVersionRepoModel = [self.repos[spec] lastObject];
            
            for (id object in installedPods)
            {
                if ([object isKindOfClass:[NSString class]])
                {
                    NSString *installedPod = object;
                    if ([installedPod hasPrefix:spec])
                    {
                        installedPod = [installedPod substringFromIndex:[spec length]];
                        latestVersionRepoModel.installedVersion = [installedPod stringByTrimmingCharactersInSet:trimSet];
                        break;
                    }
                }
            }
            
            if (latestVersionRepoModel != nil && ![latestVersionRepoModel.checksum isEqualToString:checksum])
            {
                [podsWithUpdates addObject:latestVersionRepoModel];
            }
        }
        
        if ([podsWithUpdates count] > 0)
        {
            [self printMessageBold:NSLocalizedString(@"The following Pods have updates available", nil)];
            for (KFRepoModel *repoModel in podsWithUpdates)
            {
                [self printMessage:[repoModel description]];
            }
            [self.notificationController showNotificationWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%d Updateable Pods", nil), [podsWithUpdates count]] andMessage:[[podsWithUpdates valueForKey:@"pod"] componentsJoinedByString:@", "]];
            
            [self openFileInIDE:[KFWorkspaceController currentWorkspacePodfilePath]];
        }
        else
        {
            [self printMessageBold:NSLocalizedString(@"No updates available", nil)];
        }
    }
    else
    {
        [self printMessage:error.description];
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


- (void)checkForOutdatedPodsViaCommand
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(queue, ^
    {
        if ([KFWorkspaceController currentWorkspaceHasPodfile])
        {
            [weakSelf printMessageBold:@"start pod outdated check"];

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
            } completion:^(NSTask *task, BOOL success, NSString *output, NSException *exception)
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
            [weakSelf printMessageBold:@"no podfile - no outdated pods"];
        }
    });
}


- (void)openFileInIDE:(NSString *)file
{
    [[[NSApplication sharedApplication] delegate] application:[NSApplication sharedApplication] openFile:file];
}


#pragma mark - Logging


- (void)printMessage:(NSString *)message
{
    [self printMessageBold:message forTask:nil];
}


- (void)printMessage:(NSString *)message forTask:(NSTask *)task
{
     __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.consoleController logMessage:message printBold:NO forTask:task];
    });
}


- (void)printMessageBold:(NSString *)message
{
    [self printMessageBold:message forTask:nil];
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
