//
//  KFSyntaxAutoCompletionItem.m
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

#import "KFSyntaxAutoCompletionItem.h"


@interface KFSyntaxAutoCompletionItem ()


@property (nonatomic, strong) NSString *itemType;
    
@property (nonatomic, strong) NSString *templateDisplay;
    
@property (nonatomic, strong) NSString *templateDescription;


@end


@implementation KFSyntaxAutoCompletionItem


- (id)initWithName:(NSString *)name type:(NSString *)type template:(NSString *)itemTemplate templateDisplay:(NSString *)templateDisplay andTemplateDescription:(NSString *)templateDescription
{
    self = [super init];
    if (self)
    {
        _itemName = name;
        _itemType = type;
        _itemTemplate = itemTemplate;
        _templateDisplay = templateDisplay;
        _templateDescription = templateDescription;
    }
    return self;
}


- (NSString *)name
{
    return _itemName;
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
    return [[NSAttributedString alloc] initWithString:self.templateDescription];
}


- (NSString *)displayType
{
    return self.itemType;
}


- (NSString *)displayText
{
    return self.templateDisplay;
}


- (NSString *)completionText
{
    return self.itemTemplate;
}

@end
