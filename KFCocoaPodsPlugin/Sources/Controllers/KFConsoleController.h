//
//  KFConsoleController.h
//  KFCocoaPodsPlugin
//
//  Created by rick on 05.09.13.
//  Copyright (c) 2013 KF Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IDEConsoleTextView;


@interface KFConsoleController : NSObject


- (void)logMessage:(id)object;

- (void)logMessage:(id)object printBold:(BOOL)isBold;


@end
