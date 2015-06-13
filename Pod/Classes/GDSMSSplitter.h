//
//  GDSMSSplitter.h
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

#import <Foundation/Foundation.h>

extern NSString * const kGDSMSSplitterResultKeyParts;
extern NSString * const kGDSMSSplitterResultKeyTotalLength;
extern NSString * const kGDSMSSplitterResultKeyTotalBytes;
extern NSString * const kGDSMSSplitterResultKeyMessageMode;
extern NSString * const kGDSMSSplitterResultKeyLeftoverLength;

extern NSString * const kGDSMSSplitterPartKeyContent;
extern NSString * const kGDSMSSplitterPartKeyLength;
extern NSString * const kGDSMSSplitterPartKeyBytes;

/*!
 @abstract Message group encoding mode.
 @constant GDSMSSplitterMessageModeGSM0338 Messages are encoded using GSM 03.38 standard.
 @constant GDSMSSplitterMessageModeUTF16 Messages are encoded using UTF16 (USC-2) standard.
 */
typedef NS_ENUM(NSUInteger, GDSMSSplitterMessageMode) {
    /*! @field Messages are encoded using GSM 03.38 standard. */
    GDSMSSplitterMessageModeGSM0338,
    /*! @field Messages are encoded using UTF16 (USC-2) standard. */
    GDSMSSplitterMessageModeUTF16
} NS_ENUM_AVAILABLE(10_6, 6_0);

/*!
 @class GDSMSSplitter
 @abstract
 Class used to split a string into a sequence of short messages (parts) close to the international standard of SMS messaging.
 @discussion
 You can instantiate a new instance of this class or use a singleton accessor method @c sharedSplitter.
 */
NS_AVAILABLE(10_6, 6_0)
@interface GDSMSSplitter : NSObject

/*!
 @brief Splits a string into a sequence of short messages (parts) close to the international standard of SMS messaging.
 @discussion The original message string is split into parts according to the following rules.
 
 1. If the string contains at least one symbol which is not present in GSM 03.38 basic and extended character sets, the message is automatically treated as UTF16-encoded. This means every message now can contain at most 70 symbols (140 bytes).
 
 2. Otherwise the resulting message parts will be encoded using GSM 03.38 standard, where every message can contain up to 160 symbols (~1 byte for a symbol in basic character set and 2 bytes for a symbol from extended character set).
 
 @attention
 Once the number of bytes occupied by the input message string exceeds the available number of bytes for a single SMS message (according to an infered encoding), every message part will use extra bytes to represent a sequence number of every SMS. Therefore, the number of available bytes for a message part decreases. For GSM 03.38 encoded messages it drops down to 153 symbols per message (from 160); for UTF-16 encoded messages it drops down to 67 symbols per message (from 70).
 
 ______________________________
 
 The return value is a dictionary containing the following keys and values:
 
 - Key: @c kGDSMSSplitterResultKeyTotalLength. Value: An @c NSNumber object containing the total number of symbols which represent the input string.
 
 - Key: @c kGDSMSSplitterResultKeyTotalBytes. Value: An @c NSNumber object containing the total number of bytes accupied by the input string.
 
 - Key: @c kGDSMSSplitterResultKeyMessageMode. Value: An @c NSNumber object containing one of the predefined values of @c GDSMSSplitterMessageMode enumerated type.
 
 - Key: @c kGDSMSSplitterResultKeyLeftoverLength. Value: An @c NSNumber object containing the number of symbols available for the last message inside the parts array.
 
 - Key: @c kGDSMSSplitterResultKeyParts. Value: An instance of @c NSArray array which contains the parts into which the original input string is split.
 
 ______________________________
 
 Every element of the array value of the @c kGDSMSSplitterResultKeyParts key is itself an @c NSDictionary object. This dictionary contains the following keys and values:
 
 - Key: @c kGDSMSSplitterPartKeyLength. Value: An @c NSNumber object containing the number of symbols which represent the part string.
 
 - Key: @c kGDSMSSplitterPartKeyBytes. Value: An @c NSNumber object containing the number of bytes accupied by the part string.
 
 - Key: @c kGDSMSSplitterPartKeyContent. Value: An @c NSString object containing the current part content of the original input string.
 
 @param messageString A string to be split.
 @param includeContents A boolean flag which tells the splitter whether the objects inside the array of message parts should include the partial string (value for @c kGDSMSSplitterPartKeyContent key). If set to @c NO these values are empty strings.
 @return A dictionary containing the keys and values described in Description section.
 */
- (NSDictionary *)split:(NSString *)messageString includeContents:(BOOL)includeContents;

/*!
 @brief Returns a singleton splitter object.
 @discussion On the first call this method creates a newly allocated and instantiated splitter object. On any of subsequent calls it returns the previously created object.
 @return A singleton splitter object or nil if the object could not be created.
 */
+ (instancetype)sharedSplitter;

@end
