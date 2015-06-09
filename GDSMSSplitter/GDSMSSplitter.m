//
//  GDSMSSplitter.m
//
//  Copyright (c) 2015 A. Gordiyenko. All rights reserved.
//

/*
The MIT License (MIT)

Copyright (c) 2015 A. Gordiyenko

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */


#import "GDSMSSplitter.h"

NSString * const kGDSMSSplitterResultKeyParts = @"parts";
NSString * const kGDSMSSplitterResultKeyTotalLength = @"totalLength";
NSString * const kGDSMSSplitterResultKeyTotalBytes = @"totalBytes";

NSString * const kGDSMSSplitterPartKeyContent = @"content";
NSString * const kGDSMSSplitterPartKeyLength = @"length";
NSString * const kGDSMSSplitterPartKeyBytes = @"bytes";

NSString * const kGDSMSSplitterGSMCharsString = @"@£$¥èéùìòÇ\nØø\rÅåΔ_ΦΓΛΩΠΨΣΘΞÆæßÉ\x20!\"#¤%&'()*+,-./0123456789:;<=>?¡ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÑÜ§¿abcdefghijklmnopqrstuvwxyzäöñüà\f|^€{}[~]\\";
NSString * const kGDSMSSplitterGSMCharsExString = @"\f|^€{}[~]\\";

#pragma mark - NSCharacterSet

@implementation NSCharacterSet (GDSMSSplitter)

+ (NSCharacterSet *)gdsmssplitter_GSMCharacterSet {
    static NSCharacterSet *retVal = nil;
    if (!retVal) {
        retVal = [NSCharacterSet characterSetWithCharactersInString:kGDSMSSplitterGSMCharsString];
    }
    
    return retVal;
}

@end

#pragma mark - NSString

@implementation NSString (GDSMSSplitter)

- (BOOL)gdsmssplitter_isGSMcompliant {
    NSCharacterSet *stringCharSet = [NSCharacterSet characterSetWithCharactersInString:self];
    return [[NSCharacterSet gdsmssplitter_GSMCharacterSet] isSupersetOfSet:stringCharSet];
}

@end

#pragma mark - NSSet

@implementation NSSet (GDSMSSplitter)

+ (NSSet *)gdsmssplitter_charsSetForString:(NSString *)charsString {
    NSUInteger length = charsString.length;
    NSMutableSet *mutableSet = [NSMutableSet setWithCapacity:length];
    unichar *characters = calloc(length, sizeof(unichar));
    [charsString getCharacters:characters range:NSMakeRange(0, length)];
    for (NSUInteger i = 0; i < length; i++) {
        [mutableSet addObject:@(characters[i])];
    }
    free(characters);
    return [mutableSet copy];
}

+ (BOOL)gdsmssplitter_CharInGSMCharacterExtendedSet:(unichar)c {
    static NSSet *set = nil;
    if (!set) {
        set = [self gdsmssplitter_charsSetForString:kGDSMSSplitterGSMCharsExString];
    }
    return [set containsObject:@(c)];
}

@end

#pragma mark - GDSMSSplitter

@interface GDSMSSplitter ()

@end

@implementation GDSMSSplitter

- (NSDictionary *)resultWithParts:(NSArray *)parts length:(NSUInteger)length bytes:(NSUInteger)bytes {
    return @{kGDSMSSplitterResultKeyParts: parts ? parts : @[],
             kGDSMSSplitterResultKeyTotalLength: @(length),
             kGDSMSSplitterResultKeyTotalBytes: @(bytes)
             };
}

- (NSDictionary *)partWithContent:(NSString *)content length:(NSUInteger)length bytes:(NSUInteger)bytes {
    return @{kGDSMSSplitterPartKeyContent: content ? content : @"",
             kGDSMSSplitterPartKeyLength: @(length),
             kGDSMSSplitterPartKeyBytes: @(bytes)
             };
}

- (NSDictionary *)splitGSM:(NSString *)messageString includeContents:(BOOL)includeContents {
    if (!messageString.length) {
        return [self resultWithParts:nil length:0 bytes:0];
    }
    
    NSMutableArray *messages = [NSMutableArray new];
    __block NSUInteger curMessageLength = 0;
    __block NSUInteger curMessageBytes = 0;
    __block NSUInteger totalLength = 0;
    __block NSUInteger totalBytes = 0;
    __block NSMutableString *messagePart = includeContents ? [NSMutableString string] : nil;
    
    dispatch_block_t split = ^{
        [messages addObject:[self partWithContent:[messagePart copy] length:curMessageLength bytes:curMessageBytes]];
        
        totalLength += curMessageLength;
        totalBytes += curMessageBytes;
        curMessageLength = 0;
        curMessageBytes = 0;
        messagePart = includeContents ? [NSMutableString string] : nil;
    };
    
    NSUInteger messageLength = messageString.length;
    unichar *message = calloc(messageLength, sizeof(unichar));
    [messageString getCharacters:message range:NSMakeRange(0, messageLength)];
    
    for (NSUInteger i = 0; i < messageLength; i++) {
        unichar c = message[i];
        if ([NSSet gdsmssplitter_CharInGSMCharacterExtendedSet:c]) {
            if (curMessageBytes == 152)
                split();
            
            curMessageBytes++;
        }
        
        curMessageBytes++;
        curMessageLength++;
        
        if (includeContents) {
            [messagePart appendString:[NSString stringWithCharacters:&c length:1]];
        }
        
        if (curMessageBytes == 153)
            split();
    }
    
    free(message);
    
    if (curMessageBytes > 0)
        split();
    
    if (messages.count > 1 && totalBytes <= 160) {
        NSDictionary *solePart = [self partWithContent:[NSString stringWithFormat:@"%@%@",
                                                        messages[0][kGDSMSSplitterPartKeyContent],
                                                        messages[1][kGDSMSSplitterPartKeyContent]]
                                                length:totalLength bytes:totalBytes];
        return [self resultWithParts:@[solePart]
                              length:totalLength bytes:totalBytes];
    }
    
    return [self resultWithParts:[messages copy] length:totalLength bytes:totalBytes];
}

- (NSDictionary *)splitUnicode:(NSString *)messageString includeContents:(BOOL)includeContents {
    return nil;
}

#pragma mark - Public Methods

- (NSDictionary *)split:(NSString *)messageString includeContents:(BOOL)includeContents {
    if ([messageString gdsmssplitter_isGSMcompliant]) {
        return [self splitGSM:messageString includeContents:includeContents];
    }
    
    return [self splitUnicode:messageString includeContents:includeContents];
}

@end
