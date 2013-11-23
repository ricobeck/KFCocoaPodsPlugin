//
//  KFPodSearchWindowController.h
//  KFCocoaPodsPlugin
//
//  Created by rick on 17/11/13.
//  Copyright (c) 2013 KF Interactive. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface KFPodSearchWindowController : NSWindowController


@property (nonatomic, strong, readonly) NSMutableArray *repoData;

@property (nonatomic, strong, readonly) NSArray *repoSortDescriptors;

@property (nonatomic) BOOL searchEnabled;


- (id)initWithRepoData:(NSArray *)repoData;


@end
