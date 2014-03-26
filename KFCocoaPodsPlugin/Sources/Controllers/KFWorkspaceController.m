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

/* the signature in IDEFoundation.h is incorrect (oudated?) for xcode5 
 * @see https://github.com/questbeat/Lin/blob/master/Lin/Lin.m
 */
@interface IDEIndex (fix)
- (id)filesContaining:(id)arg1 anchorStart:(BOOL)arg2 anchorEnd:(BOOL)arg3 subsequence:(BOOL)arg4 ignoreCase:(BOOL)arg5 cancelWhen:(id)arg6;
@end

#define kPodfile @"Podfile"
#define kPodfileLock @"Podfile.lock"


@implementation KFWorkspaceController


+ (BOOL)currentWorkspaceHasPodfile
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[self currentWorkspacePodfilePath]];
}


+ (BOOL)currentWorkspaceHasPodfileLock
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[self currentWorkspacePodfileLockPath]];
}


+ (NSString *)currentWorkspacePodfilePath
{
    return [self pathForFileNameInCurrentWorkspace:kPodfile];
}


+ (NSString *)currentWorkspacePodfileLockPath
{
    return [[[self pathForFileNameInCurrentWorkspace:kPodfile] stringByDeletingLastPathComponent] stringByAppendingPathComponent:kPodfileLock];
}


+ (id)workspaceForKeyWindow
{
    return [[self keyWindowController] valueForKey:@"_workspace"];
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

+ (NSString *)pathForFileNameInCurrentWorkspace:(NSString *)fileName
{
    IDEWorkspace *workspace = [self workspaceForKeyWindow];
    
    if (workspace == nil)
    {
        return nil;
    }
    
    IDEIndexCollection *indexCollection = [workspace.index filesContaining:fileName anchorStart:NO anchorEnd:NO subsequence:NO ignoreCase:NO cancelWhen:nil];
    
    for(DVTFilePath *filePath in indexCollection)
    {
        return filePath.pathString;
    }
    
    return nil;
}

+ (BOOL)fileNameExistsInCurrentWorkspace:(NSString *)fileName
{
    /* try to find in workspace first */
    NSString * filePath = [self pathForFileNameInCurrentWorkspace:fileName];
    if(filePath) {
        return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    }
    /* if that fails, try to locate it relative to the current workspace
     * directory */
    filePath = [[self currentWorkspaceDirectoryPath] stringByAppendingPathComponent:fileName];
    return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
}


+ (BOOL)isCurrentFilePodfile
{
    return [[[[[[IDEWorkspaceWindowController workspaceWindowControllerForWindow:[NSApp keyWindow]] editorArea] primaryEditorDocument] filePath] fileName] isEqualToString:@"Podfile"];
}


+ (IDEWorkspaceWindowController *)keyWindowController
{
    NSArray *workspaceWindowControllers = [NSClassFromString(@"IDEWorkspaceWindowController") valueForKey:@"workspaceWindowControllers"];
    for (IDEWorkspaceWindowController *controller in workspaceWindowControllers)
    {
        if (controller.window.isKeyWindow)
        {
           return controller;
        }
    }
    return nil;
}

@end
