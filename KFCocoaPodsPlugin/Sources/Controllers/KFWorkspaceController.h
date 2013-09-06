//
//  KFWorkspaceController.h
//  KFCocoaPodsPlugin
//
//  Created by rick on 05.09.13.
//  Copyright (c) 2013 KF Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KFWorkspaceController : NSObject


+ (NSString *)currentRepresentingTitle;

+ (BOOL)currentWorkspaceHasPodfile;

+ (BOOL)currentWorkspaceHasPodfileLock;

+ (NSString *)currentWorkspaceDirectoryPath;

+ (NSString *)currentWorkspacePodfilePath;

+ (NSString *)currentWorkspacePodfileLockPath;


@end
