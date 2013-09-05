//
//  KFCocoaPodController.h
//  KFCocoaPodsPlugin
//
//  Created by rick on 05.09.13.
//  Copyright (c) 2013 KF Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KFCocoaPodController : NSObject


- (id)initWithRepoData:(NSDictionary *)repoData;

- (NSArray *)outdatedPodsForLockFileContents:(NSString *)lockFileContents;


@end
