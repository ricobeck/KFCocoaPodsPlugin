//
//  KFTryController.h
//  KFCocoaPodsPlugin
//
//  Created by Zac White on 3/17/14.
//  Copyright (c) 2014 KF Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KFTryController : NSObject

- (void)tryPodWithName:(NSString *)podName progress:(void(^)(CGFloat progress))progressCallback completion:(void(^)(NSError *error))completionCallback;

@end
