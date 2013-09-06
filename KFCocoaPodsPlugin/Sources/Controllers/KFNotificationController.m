//
//  KFNotificationController.m
//  KFCocoaPodsPlugin
//
//  Created by rick on 06/09/13.
//  Copyright (c) 2013 KF Interactive. All rights reserved.
//

#import "KFNotificationController.h"


@interface KFNotificationController ()<NSUserNotificationCenterDelegate>


@end


@implementation KFNotificationController


- (id)init
{
    self = [super init];
    if (self)
    {
        _active = YES;
    }
    return self;
}


- (void)showNotificationWithTitle:(NSString *)title andMessage:(NSString *)message
{
    if (!self.isActive)
    {
        return;
    }
    NSUserNotification *userNotification = [NSUserNotification new];
    userNotification.title = title;
    userNotification.subtitle = message;
    [NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:userNotification];
}


#pragma mark - NSUserNotificationCenterDelegate methods


- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}


@end
