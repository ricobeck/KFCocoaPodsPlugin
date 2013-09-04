//
//  KFCocoaPodsPlugin.m
//  KFCocoaPodsPlugin
//
//  Created by rick on 04.09.13.
//    Copyright (c) 2013 KF Interactive. All rights reserved.
//

#import "KFCocoaPodsPlugin.h"


@interface KFCocoaPodsPlugin ()


@property (nonatomic, strong) NSDictionary *repos;


@end


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
        [self buildRepoIndex];
        [self insertMenu];
    }
    return self;
}


- (void)buildRepoIndex
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSLog(@"building repo index");
    
    NSMutableDictionary *parsedRepos = [NSMutableDictionary new];
    
    NSArray *repos = [fileManager contentsOfDirectoryAtPath:[@"~/.cocoapods/repos/" stringByExpandingTildeInPath] error:nil];
    NSLog(@"repost: %@", repos);
    
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
    NSAlert *alert = [NSAlert alertWithMessageText:@"Hello, World" defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
    [alert runModal];
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.repos release];
    [super dealloc];
}


@end
