//
//  KFNotificationController.h
//  KFCocoaPodsPlugin
//
//  Created by rick on 06/09/13.
//  Copyright (c) 2013 KF Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KFNotificationController : NSObject


/**
 *  Determines whether notifications get displayed or not.
 */
@property (nonatomic, getter = isActive) BOOL active;


/**
 *  Shows a Notification via OSX´ NotificationCenter when notifications are active.
 *
 *  @param title The title text to display
 *  @param message The subtitle
 */
- (void)showNotificationWithTitle:(NSString *)title andMessage:(NSString *)message;

@end
