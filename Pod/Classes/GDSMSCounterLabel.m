//
//  GDSMSCounterLabel.m
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

#import "GDSMSCounterLabel.h"
#import <objc/runtime.h>
#import "GDSMSSplitter.h"

@implementation GDSMSCounterLabel

#pragma mark - Swizzling Magic

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        SEL originalSelector = @selector(setText:);
        SEL swizzledSelector = @selector(gdsmscounterlabel_setText:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (void)gdsmscounterlabel_setText:(NSString *)text {
    // This method does nothing :)
}

#pragma mark - Public Methods

- (void)countForText:(NSString *)text {
#if(GD_SMS_COUNTER_SHOW_DEBUGTIME)
    NSDate *date = [NSDate date];
#endif
    
    NSDictionary *splittedDictionary = [[GDSMSSplitter sharedSplitter] split:text includeContents:NO];
    NSString *result = [NSString stringWithFormat:@"%@/%@",
                        @([splittedDictionary[kGDSMSSplitterResultKeyParts] count]),
                        splittedDictionary[kGDSMSSplitterResultKeyLeftoverLength]];
    [self gdsmscounterlabel_setText:result];
    
#if(GD_SMS_COUNTER_SHOW_DEBUGTIME)
    NSLog(@"Text counted in %f seconds", [[NSDate date] timeIntervalSinceDate:date]);
#endif
}

#pragma mark - Life Cycle

- (void)commonInit {
    [self gdsmscounterlabel_setText:@"0/160"];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

@end
