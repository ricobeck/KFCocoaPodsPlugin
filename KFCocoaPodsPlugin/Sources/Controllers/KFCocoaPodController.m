//
//  KFCocoaPodController.m
//  KFCocoaPodsPlugin
//
//  Created by rick on 05.09.13.
//  Copyright (c) 2013 KF Interactive. All rights reserved.
//

#import "KFCocoaPodController.h"

@interface KFCocoaPodController ()


@property (nonatomic, strong) NSDictionary *repoData;
@end


@implementation KFCocoaPodController


- (id)initWithRepoData:(NSDictionary *)repoData
{
    self = [super init];
    if (self)
    {
        _repoData = repoData;
    }
    return self;
}


- (NSArray *)outdatedPodsForLockFileContents:(NSString *)lockFileContents
{
    return @[lockFileContents];
}


@end
