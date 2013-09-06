//
//  KFRepoModel.m
//  KFCocoaPodsPlugin
//
//  Created by rick on 06.09.13.
//  Copyright (c) 2013 KF Interactive. All rights reserved.
//

#import "KFRepoModel.h"

@implementation KFRepoModel


- (NSString *)description
{
    return [NSString stringWithFormat:@"%@, installed: %@, available: %@", self.pod, self.installedVersion, self.version];
}


@end
