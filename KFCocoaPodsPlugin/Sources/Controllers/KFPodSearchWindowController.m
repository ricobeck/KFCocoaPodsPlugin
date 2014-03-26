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
#import "KFTryController.h"

@interface KFPodSearchWindowController ()


@property (nonatomic, strong, readwrite) NSMutableArray *repoData;

@property (strong) IBOutlet NSArrayController *repoArrayController;
@property (strong) IBOutlet NSButton *tryButton;
@property (strong) IBOutlet NSProgressIndicator *progressIndicator;

@property (strong) KFTryController *tryController;

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
    
    // try the pod.
    if (!self.tryController) {
        self.tryController = [[KFTryController alloc] init];
    }
    
    [self.tryButton setEnabled:NO];
    [self.progressIndicator setIndeterminate:YES];
    [self.progressIndicator startAnimation:self];
    [self.progressIndicator setHidden:NO];
    
    [self.tryController tryPodWithName:repoModel.pod progress:^(CGFloat progress) {
        
        if (progress > 0) {
            [self.progressIndicator setIndeterminate:NO];
            [self.progressIndicator setDoubleValue:progress];
        }
        
    } completion:^(NSError *error) {
        
        [self.tryButton setEnabled:YES];
        [self.progressIndicator stopAnimation:self];
        [self.progressIndicator setHidden:YES];
        
        if (error) {
            [self showPodTryErrorWithMessage:[error localizedDescription]];
        }
    }];
    
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
