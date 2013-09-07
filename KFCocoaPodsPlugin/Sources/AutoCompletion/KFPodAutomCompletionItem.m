//
//  KFPodAutomCompletionItem.m
//  KFCocoaPodsPlugin
//
//  Created by rick on 07/09/13.
//  Copyright (c) 2013 KF Interactive. All rights reserved.
//

#import "KFPodAutomCompletionItem.h"


@interface KFPodAutomCompletionItem ()


@property (nonatomic, strong) NSString *title;

@property (nonatomic, strong) NSString *version;


@end


@implementation KFPodAutomCompletionItem


- (id)initWithTitle:(NSString *)title andVersion:(NSString *)version
{
    self = [super init];
    if (self)
    {
        _title = title;
        _version = version;
    }
    return self;
}


- (NSString *)name
{
    return self.title;
}


- (long long)priority
{
    return 50;
    
}


- (DVTSourceCodeSymbolKind *)symbolKind
{
    return nil;
}


- (BOOL)notRecommended
{
    return NO;
}


- (void)_fillInTheRest
{
    
}

- (NSAttributedString *)descriptionText
{
    return [[NSAttributedString alloc] initWithString:self.title];
}


- (NSString *)displayType
{
    return @"CocoaPod";
}


- (NSString *)displayText
{
    return [NSString stringWithFormat:@"%@, %@", self.title, self.version];
}


- (NSString *)completionText
{
    return [NSString stringWithFormat:@"'%@', '~> %@'", self.title, self.version];
}


@end
