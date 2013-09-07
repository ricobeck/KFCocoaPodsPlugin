//
//  KFPodAutomCompletionItem.h
//  KFCocoaPodsPlugin
//
//  Created by rick on 07/09/13.
//  Copyright (c) 2013 KF Interactive. All rights reserved.
//

#import "IDEFoundation.h"

@interface KFPodAutomCompletionItem : IDEIndexCompletionItem


- (id)initWithTitle:(NSString *)title andVersion:(NSString *)version;


@end
