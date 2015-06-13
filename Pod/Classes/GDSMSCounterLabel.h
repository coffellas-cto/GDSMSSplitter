//
//  GDSMSCounterLabel.h
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

#import <UIKit/UIKit.h>

/*!
 @class GDSMSCounterLabel
 @abstract
 A @c UILabel subclass used to to represent the number of messages and symbols left.
 @discussion
 This class uses @c GDSMSSplitter class under the hood. The @c setText: setter for this class is overriden and does nothing.
 @see GDSMSSplitter
 @discussion
 To see the time spent for each text processing operation in your debug output add the following line to your prefix header:
 @code #define GD_SMS_COUNTER_SHOW_DEBUGTIME 1
*/

IB_DESIGNABLE
NS_AVAILABLE_IOS(6_0)
@interface GDSMSCounterLabel : UILabel

/*!
 @brief Processes the input string and changes the @c text property of the label to represent the number of messages and symbols left.
 @discussion After a call to this method the label's text shows the counting information in X/Y format, where X is the number of potential SMS messages to be sent and Y is the number of symbols left in the last message in the sequence.
 
 @param text A string to be processed.
 */
- (void)countForText:(NSString *)text;

@end
