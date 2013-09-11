//
//  DVTTextCompletionKeywordsStrategy+KFCocoaPods.m
//  KFCocoaPodsPlugin
//
//  Created by Gunnar Herzog on 11.09.13.
//  Copyright (c) 2013 KF Interactive. All rights reserved.
//

#import "DVTTextCompletionKeywordsStrategy+KFCocoaPods.h"
#import "MethodSwizzle.h"
#import "KFWorkspaceController.h"


@implementation DVTTextCompletionKeywordsStrategy (KFCocoaPods)


+ (void)load
{
    MethodSwizzle(self, @selector(completionItemsForDocumentLocation:context:areDefinitive:), @selector(kf_swizzle_completionItemsForDocumentLocation:context:areDefinitive:));
}


- (id)kf_swizzle_completionItemsForDocumentLocation:(id)arg1 context:(id)arg2 areDefinitive:(char *)arg3
{
    id items = [self kf_swizzle_completionItemsForDocumentLocation:arg1 context:arg2 areDefinitive:arg3];
    @try
    {
        DVTSourceCodeLanguage *sourceCodeLanguage = [arg2 valueForKey:@"DVTTextCompletionContextSourceCodeLanguage"];
        if ([sourceCodeLanguage.identifier isEqualToString:@"Xcode.SourceCodeLanguage.Ruby"]  && [KFWorkspaceController isCurrentFilePodfile])
        {
            return nil;
        }
    }
    @catch (NSException *exception)
    {
        
    }
    
    return items;
}


@end
