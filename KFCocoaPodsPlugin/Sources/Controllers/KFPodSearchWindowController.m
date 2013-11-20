//
//  KFPodSearchWindowController.m
//  KFCocoaPodsPlugin
//
//  Created by rick on 17/11/13.
//  Copyright (c) 2013 KF Interactive. All rights reserved.
//

#import "KFPodSearchWindowController.h"
#import "KFRepoModel.h"

@interface KFPodSearchWindowController ()


@property (nonatomic, strong, readwrite) NSMutableArray *repoData;

@property (strong) IBOutlet NSArrayController *repoArrayController;

@end



@implementation KFPodSearchWindowController


- (id)initWithRepoData:(NSArray *)repoData
{
    self = [super initWithWindowNibName:@"KFPodSearchWindow"];
    if(self)
    {
        [self performSelectorInBackground:@selector(parseRepoData:) withObject:repoData];
        _repoSortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"pod" ascending:YES selector:@selector(caseInsensitiveCompare:)]];
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
