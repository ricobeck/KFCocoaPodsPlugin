//
//  KFPodDescriptionValueTransformer.m
//  KFCocoaPodsPlugin
//
//  Created by rick on 23/11/13.
//  Copyright (c) 2013 KF Interactive. All rights reserved.
//

#import "KFPodDescriptionValueTransformer.h"

@implementation KFPodDescriptionValueTransformer


+ (Class)transformedValueClass
{
    return [NSAttributedString class];
}


+ (BOOL)allowsReverseTransformation
{
    return NO;
}


- (id)transformedValue:(id)value
{
    NSString *originValue = value;
    NSAttributedString *transformedValue;
    
    if (originValue != nil)
    {
        transformedValue = [[NSAttributedString alloc] initWithString:originValue attributes:nil];
    }
    else
    {
        transformedValue = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"No Description", nil) attributes:nil];
    }
    return transformedValue;
}


@end
