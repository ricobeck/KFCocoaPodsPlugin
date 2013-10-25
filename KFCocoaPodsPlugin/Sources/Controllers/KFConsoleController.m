//
//  KFConsoleController.m
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

#import "KFConsoleController.h"
#import "KFConsoleThemeModel.h"
#import "IDEKit.h"
#import "AMR_ANSIEscapeHelper.h"
#import <DSUnixTask/DSUnixTask.h>


@interface KFConsoleController ()


@property (nonatomic, strong) NSMutableDictionary *consoleForTask;

@property (nonatomic, strong) AMR_ANSIEscapeHelper *ansiEscapeHelper;


@end


@implementation KFConsoleController



- (id)init
{
    self = [super init];
    if (self)
    {
        _consoleForTask = [NSMutableDictionary new];
        _ansiEscapeHelper = [[AMR_ANSIEscapeHelper alloc] init];
    }
    return self;
}


- (KFConsoleThemeModel *)currentConsoleTheme
{
    DVTSourceTextView *sourceTextView = [self sourceTextView:[NSApp mainWindow].contentView];
    DVTFontAndColorTheme *currentTheme = [sourceTextView currentTheme];
    
    if (currentTheme != nil)
    {
        KFConsoleThemeModel *themeModel = [KFConsoleThemeModel new];
        themeModel.outputTextColor = [currentTheme consoleDebuggerOutputTextColor];
        themeModel.outputTextFont = [currentTheme consoleDebuggerOutputTextFont];
        
        return themeModel;
    }
    else
    {
        return nil;
    }
}


- (void)logMessage:(id)object printBold:(BOOL)isBold forTask:(DSUnixTask *)task
{
    if ([object isKindOfClass:[NSString class]])
    {
        KFConsoleThemeModel *model = [self currentConsoleTheme];
        
        NSString *cleanString = nil;
        if ([[self.ansiEscapeHelper escapeCodesForString:object cleanString:&cleanString] count] > 0)
        {
            if (model != nil)
            {
                self.ansiEscapeHelper.defaultStringColor = model.outputTextColor;
            }
            
             NSAttributedString *attributedString = attributedString = [self.ansiEscapeHelper attributedStringWithANSIEscapedString:object];
            object = attributedString;
        }
        else
        {
            
            
            if (model != nil)
            {
                NSDictionary *attributes = @{NSFontAttributeName:model.outputTextFont, NSForegroundColorAttributeName:model.outputTextColor};
                NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:object attributes:attributes];
                object = attributedString;
            }
        }
    }
    IDEConsoleTextView *console;
    if (task == nil)
    {
        console = [self consoleView:[NSApp mainWindow].contentView];
    }
    else
    {
        console = [self.consoleForTask objectForKey:@(task.processIdentifier)];
        if (console == nil)
        {
            console = [self consoleView:[NSApp mainWindow].contentView];
            
            if (console)
            {
                [self.consoleForTask setObject:console forKey:@(task.processIdentifier)];
            }
        }
    }
    
    
    console.logMode = isBold ? 2 : 1;
    
    [console insertText:object];
    [console insertNewline:self];
    
    console.logMode = 0;
}


- (void)removeTask:(DSUnixTask *)task
{
    [self.consoleForTask removeObjectForKey:@(task.processIdentifier)];
}



- (IDEConsoleTextView *)consoleView:(NSView *)parentView
{
    for (NSView *view in [parentView subviews])
    {
        if ([view isKindOfClass:NSClassFromString(@"IDEConsoleTextView")])
        {
            return (IDEConsoleTextView *)view;
        }
        else
        {
            NSView *childView = [self consoleView:view];
            if ([childView isKindOfClass:NSClassFromString(@"IDEConsoleTextView")])
            {
                return (IDEConsoleTextView *)childView;
            }
        }
    }
    return nil;
}


- (DVTSourceTextView *)sourceTextView:(NSView *)parentView
{
    for (NSView *view in [parentView subviews])
    {
        if ([view isKindOfClass:NSClassFromString(@"DVTSourceTextView")])
        {
            return (DVTSourceTextView *)view;
        }
        else
        {
            NSView *childView = [self sourceTextView:view];
            if ([childView isKindOfClass:NSClassFromString(@"DVTSourceTextView")])
            {
                return (DVTSourceTextView *)childView;
            }
        }
    }
    return nil;
}

@end
