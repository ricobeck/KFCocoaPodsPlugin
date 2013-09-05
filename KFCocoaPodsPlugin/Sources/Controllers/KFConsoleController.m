//
//  KFConsoleController.m
//  KFCocoaPodsPlugin
//
//  Created by rick on 05.09.13.
//  Copyright (c) 2013 KF Interactive. All rights reserved.
//

#import "KFConsoleController.h"
#import "IDEKit.h"


@interface KFConsoleController ()


@property (nonatomic, strong) NSMutableDictionary *consoleForTask;


@end


@implementation KFConsoleController



- (id)init
{
    self = [super init];
    if (self)
    {
        _consoleForTask = [NSMutableDictionary new];
    }
    return self;
}



- (void)logMessage:(id)object forTask:(NSTask *)task
{
    [self logMessage:object printBold:NO forTask:task];
}


- (void)logMessage:(id)object printBold:(BOOL)isBold forTask:(NSTask *)task
{
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
            [self.consoleForTask setObject:console forKey:@(task.processIdentifier)];
        }
    }
    
    
    console.logMode = isBold ? 2 : 1;
    
    [console insertText:object];
    [console insertNewline:self];
    
    console.logMode = 0;
}


- (void)removeTask:(NSTask *)task
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


@end
