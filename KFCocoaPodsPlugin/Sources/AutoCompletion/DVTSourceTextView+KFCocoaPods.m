//
//  DVTSourceTextView+KFCocoaPods.m
//  KFCocoaPodsPlugin
//
//  Created by rick on 07/09/13.
//  Copyright (c) 2013 KF Interactive. All rights reserved.
//

#import "DVTSourceTextView+KFCocoaPods.h"
#import "MethodSwizzle.h"
#import "KFCocoaPodsPlugin.h"


@implementation DVTSourceTextView (KFCocoaPods)

+ (void)load
{
    MethodSwizzle(self, @selector(shouldAutoCompleteAtLocation:), @selector(swizzle_shouldAutoCompleteAtLocation:));
}


- (BOOL)swizzle_shouldAutoCompleteAtLocation:(unsigned long long)arg1
{
    BOOL shouldAutoComplete = [self swizzle_shouldAutoCompleteAtLocation:arg1];
    
    if (!shouldAutoComplete)
    {
        @try
        {
            NSRange range = NSMakeRange(0, arg1);
            NSString *string = [[self textStorage] string];
            NSRange newlineRange = [string rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:NSBackwardsSearch range:range];
            NSString *line = string;
            
            if (newlineRange.location != NSNotFound)
            {
                NSRange lineRange = NSMakeRange(newlineRange.location, arg1 - newlineRange.location);
                
                if (lineRange.location < [line length] && NSMaxRange(lineRange) < [line length])
                {
                    line = [string substringWithRange:lineRange];
                }
            }
            
            if ([line hasSuffix:@"pod "])
            {
                NSLog(@"show auto completion for pods");
                shouldAutoComplete = YES;
            }
        }
        @catch (NSException *exception)
        {
        }
    }
    
    return shouldAutoComplete;
}


@end
