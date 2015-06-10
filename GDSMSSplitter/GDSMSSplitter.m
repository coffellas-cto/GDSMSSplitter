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

//
// Inspired by https://github.com/Codesleuth/split-sms by David Wood.
//


#import "GDSMSSplitter.h"

NSString * const kGDSMSSplitterResultKeyParts = @"parts";
NSString * const kGDSMSSplitterResultKeyTotalLength = @"totalLength";
NSString * const kGDSMSSplitterResultKeyTotalBytes = @"totalBytes";
NSString * const kGDSMSSplitterResultKeyLeftoverLength = @"leftoverLength";
NSString * const kGDSMSSplitterResultKeyMessageMode = @"messageMode";

NSString * const kGDSMSSplitterPartKeyContent = @"content";
NSString * const kGDSMSSplitterPartKeyLength = @"length";
NSString * const kGDSMSSplitterPartKeyBytes = @"bytes";

NSString * const kGDSMSSplitterGSMCharsString = @"@£$¥èéùìòÇ\nØø\rÅåΔ_ΦΓΛΩΠΨΣΘΞÆæßÉ\x20!\"#¤%&'()*+,-./0123456789:;<=>?¡ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÑÜ§¿abcdefghijklmnopqrstuvwxyzäöñüà\f|^€{}[~]\\";
NSString * const kGDSMSSplitterGSMCharsExString = @"\f|^€{}[~]\\";

#pragma mark - NSCharacterSet

@implementation NSCharacterSet (GDSMSSplitter)

+ (NSCharacterSet *)gdsmssplitter_GSMCharacterSet {
    static NSCharacterSet *charSet = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        charSet = [NSCharacterSet characterSetWithCharactersInString:kGDSMSSplitterGSMCharsString];
    });
    return charSet;
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
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        set = [self gdsmssplitter_charsSetForString:kGDSMSSplitterGSMCharsExString];
    });
    
    @synchronized(set) {
        return [set containsObject:@(c)];
    }
}

@end

#pragma mark - GDSMSSplitter

@interface GDSMSSplitter ()

@end

@implementation GDSMSSplitter

#pragma mark - Private Helpers

- (NSUInteger)leftoverLengthForMode:(GDSMSSplitterMessageMode)mode parts:(NSArray *)parts {
    BOOL isGSM = mode == GDSMSSplitterMessageModeGSM0338;
    NSUInteger singleMessageBytes = isGSM ? 160 : 140;
    NSUInteger multiMessageBytes = isGSM ? 153 : 134;
    NSUInteger bytesForChar = isGSM ? 1 : 2;
    
    NSDictionary *lastObject = [parts lastObject];
    if (!lastObject)
        return singleMessageBytes / bytesForChar;
    
    NSUInteger lastMessageBytes = [lastObject[kGDSMSSplitterPartKeyBytes] unsignedIntegerValue];
    if (parts.count == 1) {
        return (singleMessageBytes - lastMessageBytes) / bytesForChar;
    }
    
    return (multiMessageBytes - lastMessageBytes) / bytesForChar;
}

- (NSDictionary *)resultWithParts:(NSArray *)parts length:(NSUInteger)length bytes:(NSUInteger)bytes mode:(GDSMSSplitterMessageMode)mode {
    return @{kGDSMSSplitterResultKeyParts: parts ? parts : @[],
             kGDSMSSplitterResultKeyTotalLength: @(length),
             kGDSMSSplitterResultKeyTotalBytes: @(bytes),
             kGDSMSSplitterResultKeyMessageMode: @(mode),
             kGDSMSSplitterResultKeyLeftoverLength: @([self leftoverLengthForMode:mode parts:parts])
             };
}

- (NSDictionary *)partWithContent:(NSString *)content length:(NSUInteger)length bytes:(NSUInteger)bytes {
    return @{kGDSMSSplitterPartKeyContent: content ? content : @"",
             kGDSMSSplitterPartKeyLength: @(length),
             kGDSMSSplitterPartKeyBytes: @(bytes)
             };
}

#pragma mark - Private Methods

- (NSDictionary *)splitGSM:(NSString *)messageString includeContents:(BOOL)includeContents {
    if (!messageString.length) {
        return [self resultWithParts:nil length:0 bytes:0 mode:GDSMSSplitterMessageModeGSM0338];
    }
    
    NSMutableArray *messages = [NSMutableArray new];
    __block NSUInteger curMessageLength = 0;
    __block NSUInteger curMessageBytes = 0;
    __block NSUInteger totalLength = 0;
    __block NSUInteger totalBytes = 0;
    __block NSMutableString *messagePart = includeContents ? [NSMutableString string] : nil;
    
    void(^split)() = ^{
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
                              length:totalLength bytes:totalBytes mode:GDSMSSplitterMessageModeGSM0338];
    }
    
    return [self resultWithParts:[messages copy] length:totalLength bytes:totalBytes mode:GDSMSSplitterMessageModeGSM0338];
}

- (NSDictionary *)splitUnicode:(NSString *)messageString includeContents:(BOOL)includeContents {
    if (!messageString.length) {
        return [self resultWithParts:nil length:0 bytes:0 mode:GDSMSSplitterMessageModeUTF16];
    }
    
    NSMutableArray *messages = [NSMutableArray new];
    __block NSUInteger curMessageLength = 0;
    __block NSUInteger curMessageBytes = 0;
    __block NSUInteger totalLength = 0;
    __block NSUInteger totalBytes = 0;
    __block NSUInteger partStart = 0;
    
    void(^split)(NSUInteger) = ^(NSUInteger partEnd){
        NSString *messagePart = includeContents ? [messageString substringWithRange:NSMakeRange(partStart, partEnd - partStart)] : nil;
        [messages addObject:[self partWithContent:messagePart length:curMessageLength bytes:curMessageBytes]];
        
        partStart = partEnd + 1;
        
        totalLength += curMessageLength;
        totalBytes += curMessageBytes;
        curMessageLength = 0;
        curMessageBytes = 0;
    };
    
    NSUInteger messageLength = messageString.length;
    unichar *message = calloc(messageLength, sizeof(unichar));
    [messageString getCharacters:message range:NSMakeRange(0, messageLength)];
    
    for (NSUInteger i = 0; i < messageLength; i++) {
        unichar c = message[i];
        if (c >= 0xD800 && c <= 0xDBFF) { // High surrogate
            if (curMessageBytes == 132)
                split(i - 1);
            
            curMessageBytes += 2;
            curMessageLength++;
        }
        
        curMessageBytes += 2;
        curMessageLength++;
        
        if (curMessageBytes == 134)
            split(i);
    }
    
    free(message);
    
    if (curMessageBytes > 0)
        split(messageLength);
    
    if (messages.count > 1 && totalBytes <= 140) {
        NSDictionary *solePart = [self partWithContent:[NSString stringWithFormat:@"%@%@",
                                                        messages[0][kGDSMSSplitterPartKeyContent],
                                                        messages[1][kGDSMSSplitterPartKeyContent]]
                                                length:totalLength bytes:totalBytes];
        return [self resultWithParts:@[solePart]
                              length:totalLength bytes:totalBytes mode:GDSMSSplitterMessageModeUTF16];
    }
    
    return [self resultWithParts:[messages copy] length:totalLength bytes:totalBytes mode:GDSMSSplitterMessageModeUTF16];
    
    return nil;
}

#pragma mark - Public Methods

- (NSDictionary *)split:(NSString *)messageString includeContents:(BOOL)includeContents {
    if ([messageString gdsmssplitter_isGSMcompliant]) {
        return [self splitGSM:messageString includeContents:includeContents];
    }
    
    return [self splitUnicode:messageString includeContents:includeContents];
}

#pragma mark - Life Cycle

+ (instancetype)sharedSplitter {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Allocate and initialize instance
        sharedInstance = [self new];
    });
    
    return sharedInstance;
}

@end
