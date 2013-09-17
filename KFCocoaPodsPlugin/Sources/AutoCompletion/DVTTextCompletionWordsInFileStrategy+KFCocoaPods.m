//
//  IDEIndexCompletionStrategy+KFCocoaPods.m
//  KFCocoaPodsPlugin
//
//  Copyright (c) 2013 Rico Becker, KF Interactive
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "DVTTextCompletionWordsInFileStrategy+KFCocoaPods.h"
#import "MethodSwizzle.h"
#import "KFCocoaPodsPlugin.h"
#import "KFSyntaxAutoCompletionItem.h"
#import "KFWorkspaceController.h"


@implementation DVTTextCompletionWordsInFileStrategy (KFCocoaPods)


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
        
        if ([sourceCodeLanguage.identifier isEqualToString:@"Xcode.SourceCodeLanguage.Ruby"] && [KFWorkspaceController isCurrentFilePodfile])
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
                itemString = [[itemString substringFromIndex:newlineRange.location + 1] lowercaseString];
            }
            
            if ([itemString rangeOfString:@"pod " options:NSCaseInsensitiveSearch].location != NSNotFound)
            {
                items = [[KFCocoaPodsPlugin sharedPlugin] podCompletionItems];
            }
            else
            {
                NSArray *allItems = [[KFCocoaPodsPlugin sharedPlugin] syntaxCompletionItems];
                
                if (itemString == nil || [[itemString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0)
                {
                    return allItems;
                }
                else
                {
                    items = [allItems filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(KFSyntaxAutoCompletionItem *evaluatedItem, NSDictionary *bindings)
                    {
                        return [evaluatedItem.itemTemplate hasPrefix:itemString] || [evaluatedItem.name hasPrefix:itemString];
                    }]];
                    
                    if ([items count] == 0)
                    {
                        items = nil;
                    }
                }
            }
        }
    }
    @catch (NSException *exception)
    {
        
    }
    
    return items;
}
    
    
@end
