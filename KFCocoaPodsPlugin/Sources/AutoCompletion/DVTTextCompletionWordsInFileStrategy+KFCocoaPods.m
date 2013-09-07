//
//  IDEIndexCompletionStrategy+KFCocoaPods.m
//  KFCocoaPodsPlugin
//
//  Created by rick on 07/09/13.
//  Copyright (c) 2013 KF Interactive. All rights reserved.
//

#import "DVTTextCompletionWordsInFileStrategy+KFCocoaPods.h"
#import "MethodSwizzle.h"
#import "KFCocoaPodsPlugin.h"


@implementation DVTTextCompletionWordsInFileStrategy (KFCocoaPods)


+ (void)load
{
    MethodSwizzle(self, @selector(completionItemsForDocumentLocation:context:areDefinitive:), @selector(swizzle_completionItemsForDocumentLocation:context:areDefinitive:));
}

- (id)swizzle_completionItemsForDocumentLocation:(id)arg1 context:(id)arg2 areDefinitive:(char *)arg3
{
    id items = [self swizzle_completionItemsForDocumentLocation:arg1 context:arg2 areDefinitive:arg3];
    @try
    {
        DVTSourceCodeLanguage *sourceCodeLanguage = [arg2 valueForKey:@"DVTTextCompletionContextSourceCodeLanguage"];
        
        if ([sourceCodeLanguage.identifier isEqualToString:@"Xcode.SourceCodeLanguage.Ruby"])
        {
            DVTSourceTextView *sourceTextView = [arg2 objectForKey:@"DVTTextCompletionContextTextView"];
            DVTTextStorage *textStorage = [arg2 valueForKey:@"DVTTextCompletionContextTextStorage"];
            NSRange selectedRange = [sourceTextView selectedRange];
            
            NSString *string = [textStorage string];
            NSRange itemRange = NSMakeRange(0, selectedRange.location);
            NSString *itemString = [string substringWithRange:itemRange];
            
            NSRange newlineRange = [itemString rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:NSBackwardsSearch];
            
            if (newlineRange.location != NSNotFound)
            {
                itemRange.length = itemRange.length - newlineRange.location;
                itemRange.location = itemRange.location + newlineRange.location;
                
                if (itemRange.length < [string length] && NSMaxRange(itemRange) < [string length])
                {
                    itemString = [string substringWithRange:itemRange];
                }
            }
            
            if ([[itemString lowercaseString] hasSuffix:@"pod "])
            {
                items = [[KFCocoaPodsPlugin sharedPlugin] autoCompletionItems];
            }
        }
    }
    @catch (NSException *exception)
    {
        
    }
    
    return items;
}
    
    
@end
