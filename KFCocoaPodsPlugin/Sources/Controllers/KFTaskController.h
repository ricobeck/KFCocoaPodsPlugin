//
//  KFTaskController.h
//  KFCocoaPodsPlugin
//
//  Created by rick on 05.09.13.
//  Copyright (c) 2013 KF Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void(^KFTaskControllerProgressBlock)(NSTask *task, NSString *output, NSString *error);

typedef void(^KFTaskControllerCompletionBlock)(NSTask *task, BOOL success, NSString *output, NSException *exception);

@interface KFTaskController : NSObject


- (void)runShellCommand:(NSString *)command withArguments:(NSArray *)arguments directory:(NSString *)directory progress:(KFTaskControllerProgressBlock)progressBlock completion:(KFTaskControllerCompletionBlock)completionBlock;


@end
