//
//  KFWorkspaceController.m
//  KFCocoaPodsPlugin
//
//  Created by rick on 05.09.13.
//  Copyright (c) 2013 KF Interactive. All rights reserved.
//

#import "KFWorkspaceController.h"
#import "IDEFoundation.h"


#define kPodfile @"Podfile"

@implementation KFWorkspaceController


+ (BOOL)currentWorkspaceHasPodfile
{
    return [self fileNameExistsInCurrentWorkspace:kPodfile];
}


+ (NSString *)currentWorkspacePodfilePath
{
    return [[self currentWorkspaceDirectoryPath] stringByAppendingPathComponent:kPodfile];
}


+ (id)workspaceForKeyWindow
{
    NSArray *workspaceWindowControllers = [NSClassFromString(@"IDEWorkspaceWindowController") valueForKey:@"workspaceWindowControllers"];
    for (id controller in workspaceWindowControllers)
    {
        BOOL isKeyWindow = [[[controller valueForKey:@"window"] valueForKey:@"isKeyWindow"] boolValue];
        if (isKeyWindow)
        {
            NSLog(@"key window is window with controller: %@", controller);
            return [controller valueForKey:@"_workspace"];
        }
    }
    return nil;
}


+ (NSString *)currentWorkspaceDirectoryPath
{
    IDEWorkspace *workspace = [self workspaceForKeyWindow];
    NSString *workspacePath =  [workspace.representingFilePath pathString];
    return [workspacePath stringByDeletingLastPathComponent];
}


+ (BOOL)fileNameExistsInCurrentWorkspace:(NSString *)fileName
{
    NSString *filePath = [[self currentWorkspaceDirectoryPath] stringByAppendingPathComponent:fileName];
    NSLog(@"file exists at path: %@", filePath);
    return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
}


@end
