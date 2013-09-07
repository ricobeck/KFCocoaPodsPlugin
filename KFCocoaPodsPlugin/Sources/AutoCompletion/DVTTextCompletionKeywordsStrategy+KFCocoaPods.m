//
//  IDEIndexCompletionStrategy+KFCocoaPods.m
//  KFCocoaPodsPlugin
//
//  Created by rick on 07/09/13.
//  Copyright (c) 2013 KF Interactive. All rights reserved.
//

#import "DVTTextCompletionKeywordsStrategy+KFCocoaPods.h"
#import "MethodSwizzle.h"
#import "KFCocoaPodsPlugin.h"


@implementation DVTTextCompletionWordsInFileStrategy (KFCocoaPods)


+ (void)load
{
    MethodSwizzle(self, @selector(completionItemsForDocumentLocation:context:areDefinitive:), @selector(swizzle_completionItemsForDocumentLocation:context:areDefinitive:));
}

/*
 arg1 = DVTTextDocumentLocation
 arg2 = NSDictionary
 DVTTextCompletionContextSourceCodeLanguage <DVTSourceCodeLanguage>
 DVTTextCompletionContextTextStorage <DVTTextStorage>
 DVTTextCompletionContextTextView <DVTSourceTextView>
 IDETextCompletionContextDocumentKey <IDESourceCodeDocument>
 IDETextCompletionContextEditorKey <IDESourceCodeEditor>
 IDETextCompletionContextPlatformFamilyNamesKey (macosx, iphoneos?)
 IDETextCompletionContextUnsavedDocumentStringsKey <NSDictionary>
 IDETextCompletionContextWorkspaceKey <IDEWorkspace>
 arg3 = unsure, not changing it
 returns = IDEIndexCompletionArray
 */

- (id)swizzle_completionItemsForDocumentLocation:(id)arg1 context:(id)arg2 areDefinitive:(char *)arg3
{
    id items = [self swizzle_completionItemsForDocumentLocation:arg1 context:arg2 areDefinitive:arg3];
    NSLog(@"i am active: %@", arg2);
    @try
    {
        DVTSourceCodeLanguage *sourceCodeLanguage = [arg2 valueForKey:@"DVTTextCompletionContextSourceCodeLanguage"];
        
        if ([sourceCodeLanguage.identifier isEqualToString:@"Xcode.SourceCodeLanguage.Ruby"])
        {
            DVTSourceTextView *sourceTextView = [arg2 objectForKey:@"DVTTextCompletionContextTextView"];
            DVTTextStorage *textStorage = [arg2 valueForKey:@"DVTTextCompletionContextTextStorage"];
            NSRange selectedRange = [sourceTextView selectedRange];
            
            NSString *string = [textStorage string];
            NSString *itemString = [string substringWithRange:NSMakeRange(0, selectedRange.location)];
            NSLog(@"item string: %@", itemString);
        }
        items = [[KFCocoaPodsPlugin sharedPlugin] autoCompletionItems];
    }
    @catch (NSException *exception)
    {
        NSLog(@"exception %@", exception);
    }
    
    return items;
}
    
    
@end
