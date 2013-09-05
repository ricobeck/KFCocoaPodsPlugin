//
//  KFWorkspaceController.h
//  KFCocoaPodsPlugin
//
//  Created by rick on 05.09.13.
//  Copyright (c) 2013 KF Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KFWorkspaceController : NSObject


+ (BOOL)currentWorkspaceHasPodfile;

+ (NSString *)currentWorkspaceDirectoryPath;

+ (NSString *)currentWorkspacePodfilePath;

+ (NSString *)currentWorkspacePodfileLockPath;


@end
