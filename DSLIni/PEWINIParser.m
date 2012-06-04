//
//  PWINIParser.m
//  DSLIni
//
//  Created by Fredrik Olsson on 2012-04-01.
//  Copyright (c) 2012 Jayway. All rights reserved.
//

#import "PEWINIParser.h"

@implementation PEWINIParser {
    NSScanner *_scanner;
}

- (void)skipWhiteSpace;
{
    [_scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]
                         intoString:NULL];
}

- (BOOL)tryString:(NSString *)string;
{
    [self skipWhiteSpace];
    return [_scanner scanString:string intoString:NULL];
}

- (BOOL)takeString:(NSString *)string;
{
    if (![self tryString:string]) {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Failed to take string '%@'", string];
    }
    return YES;
}

- (NSString *)trySymbol;
{
    [self skipWhiteSpace];
    NSString *symbol;
    [_scanner scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet]
                         intoString:&symbol];
    return symbol;
}

- (NSString *)takeSymbol;
{
    NSString *symbol = [self trySymbol];
    if (!symbol) {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Failed to take SYMBOL"];
    }
    return symbol;
}

- (NSString *)takeText;
{
    [self skipWhiteSpace];
    NSString* text;
    [_scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet]
                             intoString:&text];
    if (!text) {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Failed to take text"];
    }
    return [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (NSString *)tryGroupName;
{
    if ([self tryString:@"["]) {
        NSString* groupName = [self takeSymbol];
        if (groupName && [self takeString:@"]"]) {
            return groupName;
        }
    }
    return nil;
}

- (BOOL)parseSettingIntoGroup:(NSMutableDictionary *)group;
{
    NSString *name = [self trySymbol];
    if (name) {
        [self takeString:@"="];
        NSString *text = [self takeText];
        [group setObject:text forKey:name];
        return YES;
    }
    return NO;
}


- (BOOL)parseGroupIntoINIFile:(NSMutableDictionary *)iniFile;
{
    NSString *groupName = [self tryGroupName];
    if (groupName) {
        NSMutableDictionary *group = [NSMutableDictionary dictionary];
        while ([self parseSettingIntoGroup:group]);
        [iniFile setObject:group forKey:groupName];
        return YES;
    }
    return NO;
}

- (NSDictionary *)parseINIFile;
{
    NSMutableDictionary *iniFile = [NSMutableDictionary dictionary];
    while ([self parseGroupIntoINIFile:iniFile]);
    return [iniFile copy];
}


- (id)initWithData:(NSData *)data
{
    self = [super init];
    if (self) {
        NSString* string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        _scanner = [[NSScanner  alloc] initWithString:string];
        [_scanner setCharactersToBeSkipped:nil];
    }
    return self;
}

+ (NSDictionary *)dictionaryWithINIFile:(NSString *)path;
{
    return [self dictionaryWithData:[NSData dataWithContentsOfFile:path options:0 error:NULL]];
}

+ (NSDictionary *)dictionaryWithData:(NSData *)data
{
    PEWINIParser *parser = [[self alloc] initWithData:data];
    return [parser parseINIFile];
}

@end
