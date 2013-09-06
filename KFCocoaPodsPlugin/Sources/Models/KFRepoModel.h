//
//  KFRepoModel.h
//  KFCocoaPodsPlugin
//
//  Created by rick on 06.09.13.
//  Copyright (c) 2013 KF Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KFRepoModel : NSObject


@property (nonatomic, strong) NSString *pod;

@property (nonatomic, strong) NSString *version;

@property (nonatomic, strong) NSString *checksum;

@property (nonatomic, strong) NSString *installedVersion;


@end
