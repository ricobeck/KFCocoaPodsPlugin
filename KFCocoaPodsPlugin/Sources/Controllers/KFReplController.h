//
//  KFReplController.h
//  KFCocoaPodsPlugin
//
//  Created by rick on 17/11/13.
//  Copyright (c) 2013 KF Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void(^KFReplSpecParseCompletionBlock)(NSDictionary *parsedSpec);


extern NSString * const KFReplControllerParsingCountDidChange;

extern NSString * const KFReplParseCount;


@interface KFReplController : NSObject


+ (instancetype)sharedController;


- (void)parseSpec:(NSString *)specFilePath withCompletionBlock:(KFReplSpecParseCompletionBlock)completionBlock;


@end
