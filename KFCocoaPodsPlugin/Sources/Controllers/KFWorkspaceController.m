//
//  KFWorkspaceController.m
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

#import "KFWorkspaceController.h"
#import "IDEKit.h"


#define kPodfile @"Podfile"
#define kPodfileLock @"Podfile.lock"


@implementation KFWorkspaceController


+ (BOOL)currentWorkspaceHasPodfile
{
    return [self fileNameExistsInCurrentWorkspace:kPodfile];
}


+ (BOOL)currentWorkspaceHasPodfileLock
{
    return [self fileNameExistsInCurrentWorkspace:kPodfileLock];
}


+ (NSString *)currentWorkspacePodfilePath
{
    return [[self currentWorkspaceDirectoryPath] stringByAppendingPathComponent:kPodfile];
}


+ (NSString *)currentWorkspacePodfileLockPath
{
    return [[self currentWorkspaceDirectoryPath] stringByAppendingPathComponent:kPodfileLock];
}


+ (id)workspaceForKeyWindow
{
    /*
    IDEWorkspaceWindowController *workspaceController = [IDEWorkspaceWindowController workspaceWindowControllerForWindow:[NSApp keyWindow]];
    return workspaceController.window;
     */
    
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


+ (NSString *)currentRepresentingTitle
{
    return [[self workspaceForKeyWindow] valueForKey:@"name"];
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
    return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
}


+ (BOOL)isCurrentFilePodfile
{
    return [[[[[[IDEWorkspaceWindowController workspaceWindowControllerForWindow:[NSApp keyWindow]] editorArea] primaryEditorDocument] filePath] fileName] isEqualToString:@"Podfile"];
}


@end
