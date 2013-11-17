//
//  KFPodSearchWindowController.m
//  KFCocoaPodsPlugin
//
//  Created by rick on 17/11/13.
//  Copyright (c) 2013 KF Interactive. All rights reserved.
//

#import "KFPodSearchWindowController.h"


@interface KFPodSearchWindowController ()


@property (nonatomic, strong, readwrite) NSDictionary *repoData;


@end



@implementation KFPodSearchWindowController


- (id)initWithRepoData:(NSDictionary *)repoData
{
    self = [super initWithWindowNibName:@"KFPodSearchWindow"];
    if(self)
    {
        _repoData = repoData;
    }
    return self;
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

@end
