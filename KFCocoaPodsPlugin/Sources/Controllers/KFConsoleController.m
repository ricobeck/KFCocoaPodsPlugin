//
//  KFConsoleController.m
//  KFCocoaPodsPlugin
//
//  Created by rick on 05.09.13.
//  Copyright (c) 2013 KF Interactive. All rights reserved.
//

#import "KFConsoleController.h"
#import "IDEKit.h"


@implementation KFConsoleController


- (void)logMessage:(id)object
{
    [self logMessage:object printBold:NO];
}


- (void)logMessage:(id)object printBold:(BOOL)isBold
{
    IDEConsoleTextView *console = [self consoleView:[NSApp mainWindow].contentView];
    console.logMode = isBold ? 2 : 1;
    
    [console insertText:object];
    [console insertNewline:self];
    
    console.logMode = 0;
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


@end
