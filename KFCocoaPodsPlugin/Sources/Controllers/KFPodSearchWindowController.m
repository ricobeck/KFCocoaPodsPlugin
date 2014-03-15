//
//  KFPodSearchWindowController.m
//  KFCocoaPodsPlugin
//
//  Created by rick on 17/11/13.
//  Copyright (c) 2013 KF Interactive. All rights reserved.
//

#import "KFPodSearchWindowController.h"
#import "KFRepoModel.h"
#import "KFReplController.h"
#import "KFTaskController.h"
#import <DSUnixTask/DSUnixTask.h>

@interface KFPodSearchWindowController ()


@property (nonatomic, strong, readwrite) NSMutableArray *repoData;

@property (strong) IBOutlet NSArrayController *repoArrayController;
@property (strong) IBOutlet NSButton *tryButton;
@property (strong) IBOutlet NSProgressIndicator *progressIndicator;

@property (strong) KFTaskController *taskController;

// shows a simple error for pod try
- (void)showPodTryErrorWithMessage:(NSString *)message;

@end



@implementation KFPodSearchWindowController


- (id)initWithRepoData:(NSArray *)repoData
{
    self = [super initWithWindowNibName:@"KFPodSearchWindow"];
    if(self)
    {
        [self performSelectorInBackground:@selector(parseRepoData:) withObject:repoData];
        _repoSortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"pod" ascending:YES selector:@selector(caseInsensitiveCompare:)]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(replParseCountDidChange:) name:KFReplControllerParsingCountDidChange object:nil];
    }
    return self;
}


- (void)parseRepoData:(NSArray *)repoData
{
    self.repoData = [NSMutableArray new];
    for (NSArray *podspec in repoData)
    {
        if (podspec.firstObject)
        {
            KFRepoModel *repoModel = podspec.firstObject;
            [self.repoData addObject:repoModel];
        }
    }
    [self.repoData sortUsingDescriptors:self.repoSortDescriptors];
    [self.repoData makeObjectsPerformSelector:@selector(parsePodspec)];
    
    self.searchEnabled = NO;
}


- (void)replParseCountDidChange:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSNumber *countObj = userInfo[KFReplParseCount];
    NSUInteger count = [countObj unsignedIntegerValue];
    
    BOOL changeEnabledNewValue = count == 0;
    
    if (changeEnabledNewValue != self.searchEnabled)
    {
        self.searchEnabled = changeEnabledNewValue;
    }
}


- (void)windowDidLoad
{
    [super windowDidLoad];
}


- (IBAction)confirmAction:(id)sender
{
    [NSApp endSheet:self.window];
    [self.window orderOut:self];
}

- (IBAction)tryPod:(id)sender
{
    KFRepoModel *repoModel = [[self.repoArrayController selectedObjects] firstObject];
    
    if (repoModel.pod == nil) {
        // perhaps we don't have a selected object or the repoModel is malformed.
        // bail, we'll crash later.
        return;
    }
    
    [self.tryButton setEnabled:NO];
    [self.progressIndicator startAnimation:self];
    
    if (!self.taskController) {
        self.taskController = [[KFTaskController alloc] init];
    }
    
    // try the pod.
    
    // capture all output to figure out a failure if we get one.
    NSMutableString *totalOutput = [NSMutableString string];
    
    DSUnixTask *task = [self.taskController runPodCommand:@[@"try", @"--no-color", repoModel.pod] directory:nil outputHandler:^(DSUnixTask *taskLauncher, NSString *newOutput) {
        [totalOutput appendString:newOutput];
    } terminationHandler:^(DSUnixTask *taskLauncher) {
        [self.progressIndicator stopAnimation:self];
        [self.tryButton setEnabled:YES];
    } failureHandler:^(DSUnixTask *taskLauncher) {
        
        [self.progressIndicator stopAnimation:self];
        [self.tryButton setEnabled:YES];
        
        // "Unknown arguments" is displayed when the 'pod' doesn't recognize the command.
        NSRange unknownRange = [totalOutput rangeOfString:@"Unknown arguments"];
        
        // "Unable to find any projects" is show when a pod doesn't have any projects to open.
        NSRange unableRange = [totalOutput rangeOfString:@"Unable to find any project"];
        
        if (unknownRange.location != NSNotFound) {
            // this is a version before try was supported?
            [self showPodTryErrorWithMessage:@"This version of Cocoapods does not support 'pod try'"];
        } else if (unableRange.location != NSNotFound) {
            // we weren't able to find a project.
            [self showPodTryErrorWithMessage:@"Unable to find an example project in the repository."];
        } else {
            // we just had an error or had multiple options.
            // it's hard to really tell the difference, so assume the common case.
            [self showPodTryErrorWithMessage:@"There were several projects found. Please use 'pod try' from the command line."];
        }
    }];
    
    // writing this to the standard input helps us exit the multiple options case.
    // it doesn't seem to have any ill effect on the other cases.
    [task writeStringToStandardInput:@"n\n"];
}


- (void)showPodTryErrorWithMessage:(NSString *)message
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Error Running 'pod try'"];
    [alert addButtonWithTitle:@"OK"];
    [alert setInformativeText:message];
    
    [alert beginSheetModalForWindow:self.window completionHandler:NULL];
}

- (IBAction)copyPodnameAction:(id)sender
{
    KFRepoModel *repoModel = [[self.repoArrayController selectedObjects] firstObject];
    NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
    [pasteBoard declareTypes:@[NSStringPboardType] owner:nil];
    [pasteBoard setString:repoModel.pod forType:NSStringPboardType];
}


@end
