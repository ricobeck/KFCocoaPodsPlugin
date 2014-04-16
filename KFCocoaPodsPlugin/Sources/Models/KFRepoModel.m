//
//  KFRepoModel.m
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

#import "KFRepoModel.h"
#import "KFReplController.h"

#import "NSAttributedString+Hyperlinks.h"

#import <YAML-Framework/YAMLSerialization.h>

@interface KFRepoModel ()


@property (nonatomic, strong, readwrite) NSString *summary;

@property (nonatomic, strong, readwrite) NSString *specDescription;

@property (nonatomic, strong, readwrite) NSString *license;

@property (nonatomic, strong, readwrite) NSString *plattforms;

@property (nonatomic, strong, readwrite) NSString *author;

@property (nonatomic, strong, readwrite) NSAttributedString *homepage;


@end


@implementation KFRepoModel


- (NSString *)description
{
    return [NSString stringWithFormat:@"%@, installed: %@, available: %@", self.pod, self.installedVersion, self.version];
}


- (void)setPodspec:(NSData *)podspec
{
    _podspec = podspec;
}


- (void)parsePodspec
{
    [[KFReplController sharedController] parseSpec:self.specFilePath withCompletionBlock:^(NSDictionary *parsedSpec)
    {
        [self performSelectorInBackground:@selector(applyParsedPodspec:) withObject:parsedSpec];
    }];
}


- (void)applyParsedPodspec:(NSDictionary *)parsedSpec
{
    NSError *error = nil;
    
    @try
    {
        NSDictionary *yaml = [[YAMLSerialization YAMLWithData:[parsedSpec[@"summary"] dataUsingEncoding:NSUTF8StringEncoding] options:kYAMLReadOptionStringScalars error:&error] firstObject];
        
        if (yaml != nil && error == nil)
        {
            NSString *summary = yaml[@"summary"] != nil ? yaml[@"summary"] : parsedSpec[@"summary"];
            self.summary = summary;
            
            if ([yaml objectForKey:@"authors"] && [yaml[@"authors"] isKindOfClass:[NSDictionary class]])
            {
                self.author = [[yaml[@"authors"] allKeys] componentsJoinedByString:@", "];
            }
            else
            {
                self.author = NSLocalizedString(@"Unknown", nil);
            }
            self.author = [NSString stringWithFormat:NSLocalizedString(@"Authors: %@", nil), self.author];
            
            if ([yaml objectForKey:@"license"] != nil)
            {
                id license = yaml[@"license"];
                if ([license isKindOfClass:[NSDictionary class]] && [license objectForKey:@"type"] != nil)
                {
                    self.license = yaml[@"license"][@"type"];
                }
                else if ([license isKindOfClass:[NSString class]])
                {
                    self.license = license;
                }
                else
                {
                    self.license = NSLocalizedString(@"Unknown", nil);
                }
            }
            self.license = [NSString stringWithFormat:NSLocalizedString(@"License: %@", nil), self.license];
            
            NSString *homepage = yaml[@"homepage"];
            if (homepage != nil)
            {
                self.homepage = [NSAttributedString hyperlinkFromString:homepage withURL:[NSURL URLWithString:homepage]];
            }
            
            
            if ([yaml objectForKey:@"platforms"] != nil)
            {
                self.plattforms = [[yaml[@"platforms"] allKeys] componentsJoinedByString:@", "];
            }
            else
            {
                self.plattforms = @"ios";
            }
            self.plattforms = [NSString stringWithFormat:NSLocalizedString(@"Plattform: %@", nil), self.plattforms];
            
            if ([yaml isKindOfClass:[NSDictionary class]])
            {
                id specDescription = [yaml objectForKey:@"description"] != nil ? yaml[@"description"] : self.summary;
                self.specDescription = specDescription;
            }
            else
            {
                self.specDescription = [yaml description];
            }
        }
    }
    @catch (NSException *exception)
    {
        self.specDescription = [NSString stringWithFormat:@"Caught exception: %@", exception];
    }
}


- (void)matchSummary
{
    NSString *podspecString = [[NSString alloc] initWithData:_podspec encoding:NSUTF8StringEncoding];
    
    __weak typeof(self) weakSelf = self;
    NSError *regexError = nil;
    
    NSRegularExpressionOptions options = NSRegularExpressionAnchorsMatchLines;
    NSString *pattern = @"(?<=.(\\w{1,10})\\s{0,10}\\s{0,10}=\\s{0,10}['|\"]).*(?=['|\"])";
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:pattern options:options error:&regexError];
    
    [expression enumerateMatchesInString:podspecString options:kNilOptions range: NSMakeRange(0, [podspecString length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
     {
         weakSelf.summary = [podspecString substringWithRange:result.range];
     }];
}


- (id)copyWithZone:(NSZone *)zone
{
    KFRepoModel *copy = [KFRepoModel new];
    copy.pod = [self.pod copy];
    copy.installedVersion = [self.installedVersion copy];
    copy.checksum = [self.checksum copy];
    copy.installedVersion = [self.installedVersion copy];
    copy.podspec = [self.podspec copy];
    
    return copy;
}

#pragma mark - Caching additions

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *representation = [[self dictionaryWithValuesForKeys:@[@"pod", @"version", @"checksum", @"installedVersion"]] mutableCopy];
    if (self.podspec) {
        [representation setObject:[self.podspec base64EncodedStringWithOptions:0] forKey:@"podspec"];
    }
    return [representation copy];
}

- (instancetype)initWithDictionaryRepresentation:(NSDictionary *)representation {
    self = [self init];
    if (self) {
        NSMutableDictionary *mutableRepresentation = [representation mutableCopy];
        NSData *podspecData = [mutableRepresentation[@"podspec"] dataUsingEncoding:NSUTF8StringEncoding];
        if (podspecData) {
            [mutableRepresentation setObject:[podspecData base64EncodedDataWithOptions:0] forKey:@"podspec"];
        }
        [self setValuesForKeysWithDictionary:mutableRepresentation];
    }
    return self;
}

@end
