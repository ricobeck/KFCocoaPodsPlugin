//
//  KFCocoaPodsPlugin.m
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

#import "KFCocoaPodsPlugin.h"
#import "KFConsoleController.h"
#import "KFTaskController.h"
#import "KFWorkspaceController.h"
#import "KFCocoaPodController.h"
#import "KFNotificationController.h"
#import "KFPodSearchWindowController.h"
#import "KFReplController.h"

#import "KFRepoModel.h"
#import "KFPodAutoCompletionItem.h"
#import "KFSyntaxAutoCompletionItem.h"
#import "IDEKit.h"

#import <YAML-Framework/YAMLSerialization.h>
#import <KSCrypto/KSSHA1Stream.h>
#import <DSUnixTask/DSUnixTask.h>


#define SHOW_REPO_MENU 0

typedef NS_ENUM(NSUInteger, KFMenuItemTag)
{
    KFMenuItemTagEditPodfile,
    KFMenuItemTagCheckForOutdatedPods,
    KFMenuItemTagUpdate,
    KFMenuItemTagPodInit,
    KFMenuItemTagPodSearch,
    KFMenuItemTagShowConsole
};



@interface KFCocoaPodsPlugin ()


@property (nonatomic, strong) NSDictionary *repos;

@property (nonatomic, strong) KFConsoleController *consoleController;

@property (nonatomic, strong) KFCocoaPodController *cocoaPodController;

@property (nonatomic, strong) KFNotificationController *notificationController;

@property (nonatomic, strong) KFTaskController *taskController;

@property (nonatomic, strong) NSMenuItem *podInitItem;

@property (nonatomic, strong) KFPodSearchWindowController *podSearchWindowController;

+ (void)kf_applicationDidFinishLaunching:(NSNotification *)notification;

@end


#define kCommandInit @"init"
#define kCommandInstall @"install"
#define kCommandUpdate @"update"
#define kCommandInterprocessCommunication @"ipc"
#define kCommandOutdated @"outdated"

#define kCommandConvertPodFileToYAML @"podfile"

#define kKFAlwaysShowConsoleEnabledStatus @"KFAlwaysShowConsoleEnabledStatus"


@implementation KFCocoaPodsPlugin


#pragma mark -


+ (BOOL)shouldLoadPlugin
{
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    return bundleIdentifier && [bundleIdentifier caseInsensitiveCompare:@"com.apple.dt.Xcode"] == NSOrderedSame;
}


+ (void)pluginDidLoad:(NSBundle *)plugin
{
    if ([self shouldLoadPlugin])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(kf_applicationDidFinishLaunching:) name:NSApplicationDidFinishLaunchingNotification object:[NSApplication sharedApplication]];
    }
}

+ (void)kf_applicationDidFinishLaunching:(NSNotification *)notification {
    [self sharedPlugin];
}

+ (instancetype)sharedPlugin
{
    static id sharedPlugin = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedPlugin = [[self alloc] init];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:[NSApplication sharedApplication]];
	});
    
    return sharedPlugin;
}


- (id)init
{
    if (self = [super init])
    {
        _consoleController = [KFConsoleController new];
        _taskController = [KFTaskController new];
        _notificationController = [KFNotificationController new];
        
        KFCocoaPodsPlugin __block *weakself = self;
        
        [self insertLoadingMenu];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            [KFReplController sharedController];
            
            [weakself buildRepoIndex];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                _cocoaPodController = [[KFCocoaPodController alloc] initWithRepoData:weakself.repos];
                
                [[NSUserDefaults standardUserDefaults] registerDefaults:@{kKFAlwaysShowConsoleEnabledStatus : @YES}];
                
                [weakself insertMenu];
            });
        });
    }
    
    return self;
}


- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    switch (menuItem.tag)
    {
        case KFMenuItemTagEditPodfile:
        case KFMenuItemTagCheckForOutdatedPods:
        case KFMenuItemTagUpdate:
            return [KFWorkspaceController currentWorkspaceHasPodfile];
        case KFMenuItemTagPodInit:
            return [KFWorkspaceController currentWorkspacePodfilePath] != nil && ![KFWorkspaceController currentWorkspaceHasPodfile];
        default:
            return YES;
    }
}


- (void)showConsole
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kKFAlwaysShowConsoleEnabledStatus])
    {
        IDEEditorArea *editorArea = [KFWorkspaceController keyWindowController].editorArea;

        if (![editorArea showDebuggerArea])
        {
            [editorArea showDebuggerArea:nil];
        }
    }
}


#pragma mark - Initialization


- (void)buildRepoIndex
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [self printMessage:NSLocalizedString(@"Building repo index", nil)];
    
    NSMutableDictionary *parsedRepos = [NSMutableDictionary new];
    NSString *cocoapodsReposPath = [@"~/.cocoapods/repos/" stringByExpandingTildeInPath];
    NSArray *repos = [fileManager contentsOfDirectoryAtPath:cocoapodsReposPath error:nil];
    
    NSBundle *pluginBundle = [NSBundle bundleForClass:[self class]];
    NSString *cachesPath = [pluginBundle pathForResource:@"ReposCache" ofType:@""];
    
    NSData *cachedReposData = [NSData dataWithContentsOfFile:cachesPath];
    NSDictionary *cachedRepos;
    NSTimeInterval cachesLastModifiedDate = 0.0;
    
    if (cachedReposData) {
        cachedRepos = [NSJSONSerialization JSONObjectWithData:cachedReposData options:0 error:nil];
        cachesLastModifiedDate = [[cachedRepos objectForKey:@"lastModifiedDate"] doubleValue];
    }
    
    NSError *error = nil;
    
    NSDictionary *cocoapodsReposAttributes = [fileManager attributesOfItemAtPath:cocoapodsReposPath error:&error];
    NSTimeInterval cocoapodsReposLastModifiedDate = [[cocoapodsReposAttributes objectForKey:NSFileModificationDate] timeIntervalSince1970];
        
    if (cocoapodsReposLastModifiedDate != cachesLastModifiedDate) {
        
        NSMutableDictionary *serializedRepos = [NSMutableDictionary new];
        
        for (NSString *repoDirectory in repos)
        {
            
            NSString *repoPath = [[@"~/.cocoapods/repos" stringByAppendingPathComponent:repoDirectory] stringByExpandingTildeInPath];
            NSArray *pods = [fileManager contentsOfDirectoryAtPath:repoPath error:nil];
            
            for (NSString *podDirectory in pods)
            {
                if (![podDirectory hasPrefix:@"."])
                {
                    NSString *podPath = [repoPath stringByAppendingPathComponent:podDirectory];
                    NSArray *versions = [fileManager contentsOfDirectoryAtPath:podPath error:nil];
                    
                    NSMutableArray *specs = [NSMutableArray new];
                    
                    for (NSString *version in versions)
                    {
                        KFRepoModel *repoModel = [KFRepoModel new];
                        repoModel.pod = podDirectory;
                        repoModel.version = version;
                        
                        NSString *specPath = [podPath stringByAppendingPathComponent:version];
                        NSArray *files = [fileManager contentsOfDirectoryAtPath:specPath error:nil];
                        for (NSString *podspec in files)
                        {
                            if ([podspec.pathExtension isEqualToString:@"podspec"])
                            {
                                NSString *specFilePath = [specPath stringByAppendingPathComponent:podspec];
                                NSData *contents = [NSData dataWithContentsOfFile:specFilePath];
                                repoModel.checksum = [contents ks_SHA1DigestString];
                                repoModel.podspec = contents;
                                repoModel.specFilePath = specFilePath;
                            }
                        }
                        [specs addObject:repoModel];
                    }
                    NSArray *sortedSpecs = [specs sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"version" ascending:NO]]];
                    
                    [serializedRepos setObject:[self serializeSpecs:sortedSpecs] forKey:podDirectory];
                    [parsedRepos setObject:sortedSpecs forKey:podDirectory];
                }
            }
        }
        NSDictionary *newCacheDictionary = @{@"lastModifiedDate": @(cocoapodsReposLastModifiedDate), @"parsedContents" : serializedRepos};
        [[NSJSONSerialization dataWithJSONObject:newCacheDictionary options:0 error:nil] writeToFile:cachesPath atomically:YES];
        
    } else {
        NSDictionary *cachedSerializedRepos = [cachedRepos objectForKey:@"parsedContents"];
        for (id podDirectory in cachedSerializedRepos) {
            NSArray *serializedSpecs = cachedSerializedRepos[podDirectory];
            [parsedRepos setObject:[self deserializeSpecs:serializedSpecs] forKey:podDirectory];
        }
    }
    self.repos = [parsedRepos copy];
}

- (NSArray *)serializeSpecs:(NSArray *)sortedSpecs {
    NSMutableArray *serializedSpecs = [NSMutableArray arrayWithCapacity:sortedSpecs.count];
    for (KFRepoModel *repoModel in sortedSpecs) {
        [serializedSpecs addObject:[repoModel dictionaryRepresentation]];
    }
    return [serializedSpecs copy];
}

- (NSArray *)deserializeSpecs:(NSArray *)specs {
    NSMutableArray *deserializedSpecs = [NSMutableArray arrayWithCapacity:specs.count];
    for (NSDictionary *spec in specs) {
        KFRepoModel *model = [[KFRepoModel alloc] initWithDictionaryRepresentation:spec];
        [deserializedSpecs addObject:model];
    }
    return [deserializedSpecs copy];
}


- (void)insertLoadingMenu {
    NSMenuItem *productsMenuItem = [[NSApp mainMenu] itemWithTitle:@"Product"];
    if (productsMenuItem)
    {
        NSMenuItem *cocoapodsMenuItem = [[NSMenuItem alloc] initWithTitle:@"CocoaPods" action:nil keyEquivalent:@""];
        NSMenuItem *seperatorItem = [NSMenuItem separatorItem];
        NSUInteger index = [productsMenuItem.submenu indexOfItemWithTitle:@"Perform Action"] + 1;
        [[productsMenuItem submenu] insertItem:seperatorItem atIndex:index];
        [[productsMenuItem submenu] insertItem:cocoapodsMenuItem atIndex:index +1];
        
        NSMenu *loadingSubmenu = [[NSMenu alloc] initWithTitle:@"Cocoapods loading submenu"];
        [loadingSubmenu addItemWithTitle:@"Indexing pods repos..." action:nil keyEquivalent:@"IndexingRepo"];
        
        cocoapodsMenuItem.submenu = loadingSubmenu;
    }
}

- (void)insertMenu
{
    NSMenuItem *productsMenuItem = [[NSApp mainMenu] itemWithTitle:@"Product"];
    if (productsMenuItem)
    {
        NSMenuItem *cocoapodsMenuItem = [productsMenuItem.submenu itemWithTitle:@"CocoaPods"];
        
        if (cocoapodsMenuItem) {
            NSMenu *submenu = [[NSMenu alloc] initWithTitle:@"CocoaPods Submenu"];
            
            
            NSMenuItem *editPodfileMenuItem = [[NSMenuItem alloc] initWithTitle:@"Edit Podfile" action:@selector(editPodfileAction:) keyEquivalent:@""];
            [editPodfileMenuItem setTarget:self];
            [editPodfileMenuItem setTag:KFMenuItemTagEditPodfile];
            [submenu addItem:editPodfileMenuItem];
            
            NSMenuItem *checkMenuItem = [[NSMenuItem alloc] initWithTitle:@"Check For Outdated Pods" action:@selector(checkOutdatedPodsAction:) keyEquivalent:@""];
            [checkMenuItem setTarget:self];
            [checkMenuItem setTag:KFMenuItemTagCheckForOutdatedPods];
            [submenu addItem:checkMenuItem];
            
            NSMenuItem *updateMenuItem = [[NSMenuItem alloc] initWithTitle:@"Run Update/Install" action:@selector(podUpdateAction:) keyEquivalent:@""];
            [updateMenuItem setTarget:self];
            [updateMenuItem setTag:KFMenuItemTagUpdate];
            [submenu addItem:updateMenuItem];
            
#if SHOW_REPO_MENU
            NSMenuItem *reposMenuItem = [[NSMenuItem alloc] initWithTitle:@"Repos" action:nil keyEquivalent:@""];
            
            NSMenu *repoMenu = [[NSMenu alloc] initWithTitle:@"CocoaPods Repos"];
            
            NSArray *repos = [[self.repos allKeys] sortedArrayUsingSelector:@selector(compare:)];
            for (NSString *repo in repos)
            {
                NSMenuItem *repoMenuItem = [[NSMenuItem alloc] initWithTitle:repo action:nil keyEquivalent:@""];
                
                NSMenu *repoVersionMenu = [[NSMenu alloc] initWithTitle:repo];
                
                for (KFRepoModel *repoModel in self.repos[repo])
                {
                    NSMenuItem *versionMenuItem = [[NSMenuItem alloc] initWithTitle:repoModel.version action:nil keyEquivalent:@""];
                    [repoVersionMenu addItem:versionMenuItem];
                }
                
                repoMenuItem.submenu = repoVersionMenu;
                [repoMenu addItem:repoMenuItem];
            }
            reposMenuItem.submenu = repoMenu;
            [submenu addItem:reposMenuItem];
#endif
            [submenu addItem:[NSMenuItem separatorItem]];
            
            NSMenuItem *showConsoleItem = [[NSMenuItem alloc] initWithTitle:@"Always Show Console" action:@selector(showConsoleAction:) keyEquivalent:@""];
            [showConsoleItem setTarget:self];
            [showConsoleItem setTag:KFMenuItemTagShowConsole];
            
            BOOL onState = [[NSUserDefaults standardUserDefaults] boolForKey:kKFAlwaysShowConsoleEnabledStatus];
            [showConsoleItem setState:onState ? NSOnState : NSOffState];
            [submenu addItem:showConsoleItem];
            
            [submenu addItem:[NSMenuItem separatorItem]];
            
            self.podInitItem = [[NSMenuItem alloc] initWithTitle:@"Initialize Project" action:@selector(podInitAction:) keyEquivalent:@""];
            [self.podInitItem setTarget:self];
            [self.podInitItem setTag:KFMenuItemTagPodInit];
            [submenu addItem:self.podInitItem];
            
            NSMenuItem *searchPodItem = [[NSMenuItem alloc] initWithTitle:@"Search Pod ..." action:@selector(podSearchAction:) keyEquivalent:@""];
            [searchPodItem setTarget:self];
            [searchPodItem setTag:KFMenuItemTagPodSearch];
            [submenu addItem:searchPodItem];
            
            NSMenuItem *versionItem = [[NSMenuItem alloc] initWithTitle:@"CocoaPods Version: " action:nil keyEquivalent:@""];
            [self.cocoaPodController cocoaPodsVersion:^(NSDictionary *version)
             {
                 if (version != nil)
                 {
                     NSString *versionString = [NSString stringWithFormat:@"CocoaPods Version: %@.%@.%@", version[KFMajorVersion], version[KFMinorVersion], version[KFBuildVersion]];
                     [versionItem setTitle:versionString];
                 }
                 else
                 {
                     [versionItem setTitle:NSLocalizedString(@"<Unknown CocoaPods Version>", nil)];
                 }
             }];
            
            [submenu addItem:versionItem];
            
            cocoapodsMenuItem.submenu = submenu;
        }
    }
}

#pragma mark - Static Methods


- (NSArray *)podCompletionItems
{
    NSMutableArray *completionItems = [NSMutableArray new];
    
    NSArray *repos = [[self.repos allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    for (NSString *repo in repos)
    {
        for (KFRepoModel *repoModel in self.repos[repo])
        {
            KFPodAutoCompletionItem *item = [[KFPodAutoCompletionItem alloc] initWithTitle:repoModel.pod andVersion:repoModel.version];
            [completionItems addObject:item];
        }
    }
    
    return [completionItems copy];
}


- (NSArray *)syntaxCompletionItems
{
    NSURL *definitionsURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"PodSyntax" withExtension:@"plist"];
    NSArray *syntaxDefinitions = [NSArray arrayWithContentsOfURL:definitionsURL];
    NSMutableArray *completionItems = [NSMutableArray new];
    
    for (NSDictionary *syntaxItem in syntaxDefinitions)
    {
        NSString *itemName = syntaxItem[@"itemName"];
        NSString *itemType = syntaxItem[@"itemType"];
        NSString *template = syntaxItem[@"template"];
        NSString *templateDisplay = syntaxItem[@"templateDisplay"];
        NSString *templateDescription = syntaxItem[@"templateDescription"];
        
        KFSyntaxAutoCompletionItem *completionItem = [[KFSyntaxAutoCompletionItem alloc] initWithName:itemName type:itemType template:template templateDisplay:templateDisplay andTemplateDescription:templateDescription];
        
        [completionItems addObject:completionItem];
    }
    
    return [completionItems copy];
}


#pragma mark - Actions


- (void)editPodfileAction:(id)sender
{
    [self openFileInIDE:[KFWorkspaceController currentWorkspacePodfilePath]];
}


- (void)podUpdateAction:(id)sender
{
    [self showConsole];

    NSString *workspaceTitle = [KFWorkspaceController currentRepresentingTitle];
    __weak typeof(self) weakSelf = self;
    
    BOOL shouldUpdate = [KFWorkspaceController currentWorkspaceHasPodfileLock];
    NSString *command = shouldUpdate ? kCommandUpdate : kCommandInstall;
    
    if (shouldUpdate)
    {
        [self printMessageBold:NSLocalizedString(@"Start pod update", nil)];
    }
    else
    {
        [self printMessageBold:NSLocalizedString(@"Start pod install", nil)];
    }
    
    [_taskController runPodCommand:@[command] directory:[KFWorkspaceController currentWorkspaceDirectoryPath] outputHandler:^(DSUnixTask *taskLauncher, NSString *newOutput)
    {
        [weakSelf printMessage:newOutput forTask:taskLauncher];
        
    } terminationHandler:^(DSUnixTask *task)
    {
        NSString *title = NSLocalizedString(@"Cocoapods update succeeded", nil);
        NSString *message = workspaceTitle;
        [weakSelf printMessageBold:title forTask:task];
        
        BOOL didCreateWorkspace = NO;
        
        @try
        {
            didCreateWorkspace = [weakSelf checkForWorkspaceCreation:task.standardOutput];
        }
        @catch (NSException *exception)
        {
        }
        @finally
        {
            if (!didCreateWorkspace)
            {
                [weakSelf.notificationController showNotificationWithTitle:title andMessage:message];
                [weakSelf.consoleController removeTask:task];
            }
        }
        
    } failureHandler:^(DSUnixTask *task)
    {
        NSString *title = NSLocalizedString(@"Cocoapods update failed", nil);
        
        NSString *notificationMessage = [NSString stringWithFormat:@"%@: %@", workspaceTitle, task.standardError];
        [weakSelf.notificationController showNotificationWithTitle:title andMessage:notificationMessage];
        
        NSString *consoleMessage = [NSString stringWithFormat:@"%@: %@", title, task.standardError];
        [weakSelf printMessageBold:consoleMessage forTask:task];
        
        [weakSelf.consoleController removeTask:task];
    }];
}


- (BOOL)checkForWorkspaceCreation:(NSString *)aggregatedOutput
{
    NSError *regexError = nil;
    NSRegularExpressionOptions options = 0;
    NSString *pattern = @"(?<=\\[!]\\WFrom\\Wnow\\Won\\Wuse\\W`).*?.xcworkspace(?=`.)";
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:pattern options:options error:&regexError];
    
    NSMatchingOptions matchingOptions = 0;
    NSRange range = NSMakeRange(0, [aggregatedOutput length]);
    NSUInteger matchCount = [expression numberOfMatchesInString:aggregatedOutput options:matchingOptions range:range];
    
    if (matchCount == 1)
    {
        __block NSString *projectFilename;
        
        [expression enumerateMatchesInString:aggregatedOutput options:matchingOptions range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
        {
            projectFilename = [aggregatedOutput substringWithRange:[result rangeAtIndex:0]];
        }];
        
        NSString *filePath = [[KFWorkspaceController currentWorkspaceDirectoryPath] stringByAppendingPathComponent:projectFilename];
        
        NSBeginAlertSheet(NSLocalizedString(@"Open the created Workspace", nil), NSLocalizedString(@"Open", nil), nil, NSLocalizedString(@"Cancel", nil), [[NSApplication sharedApplication] keyWindow], self, nil, @selector(sheetDidDismiss:returnCode:contextInfo:), (__bridge_retained void *)(@{@"filePath": filePath}), @"CocoaPod Projects use Workspaces. You should close this Project and open the newly created '%@'.", projectFilename,nil);
        return YES;
    }
    else
    {
        return NO;
    }
}


- (void)sheetDidDismiss:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSOKButton)
    {
        NSDictionary *context = (__bridge_transfer NSDictionary *)(contextInfo);
        NSLog(@"opening file: %@", context[@"filePath"]);
        
        [[[NSApplication sharedApplication] keyWindow] close];
        [[[NSApplication sharedApplication] delegate] application:[NSApplication sharedApplication] openFile:context[@"filePath"]];
    }
}


- (void)checkOutdatedPodsAction:(id)sender
{
    [self showConsole];
    [self checkForOutdatedPodsViaCommand];
}


- (void)checkForOutdatedPodsViaCommand
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(queue, ^
    {
        if ([KFWorkspaceController currentWorkspaceHasPodfile])
        {
            [weakSelf printMessageBold:@"start pod outdated check"];

            NSMutableString *output = [NSMutableString string];

            [_taskController runPodCommand:@[kCommandOutdated] directory:[KFWorkspaceController currentWorkspaceDirectoryPath] outputHandler:^(DSUnixTask *task, NSString *newOutput)
            {
                [output appendString:newOutput];
                [weakSelf printMessage:newOutput forTask:task];
            } terminationHandler:^(DSUnixTask *task)
            {
                NSError *error = nil;
                NSArray *outdatedPods = [YAMLSerialization YAMLWithData:[output dataUsingEncoding:NSUTF8StringEncoding] options:kYAMLReadOptionStringScalars error:&error];

                if (!error)
                {
                    NSMutableArray *pods = [NSMutableArray array];
                    NSArray *podNames = [outdatedPods firstObject][@"The following updates are available"];
                    for (NSString *outdatedPod in podNames)
                    {
                        [pods addObject:[[outdatedPod componentsSeparatedByString:@" "] firstObject]];
                    }

                    if ([pods count] > 0)
                    {
                        [self.notificationController showNotificationWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%d outdated Pods", nil), [pods count]] andMessage:[pods componentsJoinedByString:@", "]];
                    }
                    else
                    {
                        [self.notificationController showNotificationWithTitle:NSLocalizedString(@"No outdated Pods", nil) andMessage:nil];
                    }
                }

                [weakSelf printMessageBold:@"Pod outdated done" forTask:task];
                [weakSelf.consoleController removeTask:task];
            } failureHandler:^(DSUnixTask *task)
            {
                [weakSelf printMessageBold:@"pod outdated failed" forTask:task];
                [weakSelf.consoleController removeTask:task];
            }];
        }
        else
        {
            [weakSelf printMessageBold:@"no podfile - no outdated pods"];
        }
    });
}


- (void)openFileInIDE:(NSString *)file
{
    [[[NSApplication sharedApplication] delegate] application:[NSApplication sharedApplication] openFile:file];
}


- (void)podInitAction:(id)sender
{
    [self showConsole];
    [self printMessageBold:@"pod init"];
    
     __weak typeof(self) weakSelf = self;
    [self.taskController runPodCommand:@[kCommandInit] directory:[KFWorkspaceController currentWorkspaceDirectoryPath] outputHandler:^(DSUnixTask *task, NSString *newOutput)
    {
        [weakSelf printMessage:newOutput forTask:task];
    }
    terminationHandler:^(DSUnixTask *task)
    {
        [weakSelf.consoleController removeTask:task];
        [weakSelf podUpdateAction:nil];
    }
    failureHandler:^(DSUnixTask *task)
    {
        [weakSelf.consoleController removeTask:task];
    }];
}


- (void)podSearchAction:(id)sender
{
    if (!self.podSearchWindowController)
    {
        self.podSearchWindowController = [[KFPodSearchWindowController alloc] initWithRepoData:[self.repos allValues]];
    }
    
    [NSApp beginSheet:self.podSearchWindowController.window modalForWindow:[[NSApplication sharedApplication] keyWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}


- (void)showConsoleAction:(NSMenuItem *)sender
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL onState = ![userDefaults boolForKey:kKFAlwaysShowConsoleEnabledStatus];

    [userDefaults setBool:onState forKey:kKFAlwaysShowConsoleEnabledStatus];
    [userDefaults synchronize];

    [sender setState:onState ? NSOnState : NSOffState];
}


#pragma mark - Logging


- (void)printMessage:(NSString *)message
{
    [self printMessageBold:message forTask:nil];
}


- (void)printMessage:(NSString *)message forTask:(DSUnixTask *)task
{
     __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.consoleController logMessage:message printBold:NO forTask:task];
    });
}


- (void)printMessageBold:(NSString *)message
{
    [self printMessageBold:message forTask:nil];
}


- (void)printMessageBold:(NSString *)message forTask:(DSUnixTask *)task
{
     __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.consoleController logMessage:message printBold:YES forTask:task];
    });
}


#pragma mark -

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
