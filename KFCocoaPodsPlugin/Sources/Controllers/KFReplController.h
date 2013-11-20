//
//  KFReplController.h
//  KFCocoaPodsPlugin
//
//  Created by rick on 17/11/13.
//  Copyright (c) 2013 KF Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void(^KFReplSpecParseCompletionBlock)(NSDictionary *parsedSpec);


@interface KFReplController : NSObject


+ (instancetype)sharedController;


- (void)parseSpec:(NSString *)specFilePath withCompletionBlock:(KFReplSpecParseCompletionBlock)completionBlock;


@end
