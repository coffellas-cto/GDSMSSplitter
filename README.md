## About
[![CI Status](http://img.shields.io/travis/coffellas-cto/GDSMSSplitter.svg?style=flat)](https://travis-ci.org/coffellas-cto/GDSMSSplitter)
[![Version](https://img.shields.io/cocoapods/v/GDSMSSplitter.svg?style=flat)](http://cocoapods.org/pods/GDSMSSplitter)
[![License](https://img.shields.io/cocoapods/l/GDSMSSplitter.svg?style=flat)](http://cocoapods.org/pods/GDSMSSplitter)
[![Platform](https://img.shields.io/cocoapods/p/GDSMSSplitter.svg?style=flat)](http://cocoapods.org/pods/GDSMSSplitter)

![screen_record2015-06-13_20_53_45](https://cloud.githubusercontent.com/assets/3193877/8145397/52ab127e-120f-11e5-8994-36d267d44950.gif) ![screen_record2015-06-13_21_06_02](https://cloud.githubusercontent.com/assets/3193877/8145421/6f418b9c-1210-11e5-9c40-280b3651cef3.gif)

This repository contains two Objective-C classes designed to split a string into a sequence of short messages close to the international standard of SMS messaging. The `GDSMSSplitter` class is responsible for actuall splitting. `GDSMSCounterLabel` is a `UILabel` subclass which implements the basic pattern for showing a user the number of SMS-messages potentially sent to recipient and the count of leftover symbols.

You can check `GDSMSSplitterDemo` project to see how it's used (it's really straightforward).

`GDSMSSplitter` provides support for **GSM 03.38** standard (including **basic character set extension table**, but *excluding* **national language shift tables**). It also supports **UTF-16** (*UCS-2*) encoding standard.

[Wikipedia article on GSM 03.38](http://en.wikipedia.org/wiki/GSM_03.38)

Your comments and smart pull requests are welcome.

# GDSMSCounterLabel

 A `UILabel` subclass used to to represent the number of messages and symbols left. This class uses `GDSMSSplitter` class under the hood. The `setText:` setter for this class is overriden and does nothing.
 
 To see the time spent for each text processing operation in your debug output add the following line to your prefix header:
```objective-c
#define GD_SMS_COUNTER_SHOW_DEBUGTIME 1
```
 Minimum platforms versions: iOS 6.
 
## Methods
 
```objective-c
- (void)countForText:(NSString *)text;
```

**Description**

Processes the input string and changes the `text` property of the label to represent the number of messages and symbols left.

After a call to this method the label's text shows the counting information in X/Y format, where X is the number of potential SMS messages to be sent and Y is the number of symbols left in the last message in the sequence.

**Parameters**

`text` - A string to be processed.

# GDSMSSplitter
Class used to split a string into a sequence of short messages (parts) close to the international standard of SMS messaging.

You can instantiate a new instance of this class or use a singleton accessor method `sharedSplitter`.

Minimum platforms versions: iOS 6, MacOS X 10.6.

## Methods
```objective-c
- (NSDictionary *)split:(NSString *)messageString includeContents:(BOOL)includeContents;
```
**Description**

Splits a string into a sequence of short messages (parts) close to the international standard of SMS messaging.

The original message string is split into parts according to the following rules.
 
 1. If the string contains at least one symbol which is not present in GSM 03.38 basic and extended character sets, the message is automatically treated as UTF16-encoded. This means every message now can contain at most 70 symbols (140 bytes).
 
 2. Otherwise the resulting message parts will be encoded using GSM 03.38 standard, where every message can contain up to 160 symbols (~1 byte for a symbol in basic character set and 2 bytes for a symbol from extended character set).

**Parameters**

`messageString` - A string to be split.

`includeContents` - A boolean flag which tells the splitter whether the objects inside the array of message parts should include the partial string (value for `kGDSMSSplitterPartKeyContent` key). If set to `NO` these values are empty strings.

**Returns**

The return value is a dictionary containing the following keys and values:
 
 - Key: `kGDSMSSplitterResultKeyTotalLength`. Value: An `NSNumber` object containing the total number of symbols which represent the input string.
 
 - Key: `kGDSMSSplitterResultKeyTotalBytes`. Value: An `NSNumber` object containing the total number of bytes accupied by the input string.
 
 - Key: `kGDSMSSplitterResultKeyMessageMode`. Value: An `NSNumber` object containing one of the predefined values of `GDSMSSplitterMessageMode` enumerated type.
 
 - Key: `kGDSMSSplitterResultKeyLeftoverLength`. Value: An `NSNumber` object containing the number of symbols available for the last message inside the parts array.
 
 - Key: `kGDSMSSplitterResultKeyParts`. Value: An instance of `NSArray` array which contains the parts into which the original input string is split.
 

Every element of the array value of the `kGDSMSSplitterResultKeyParts` key is itself an `NSDictionary` object. This dictionary contains the following keys and values:
 
 - Key: `kGDSMSSplitterPartKeyLength`. Value: An `NSNumber` object containing the number of symbols which represent the part string.
 
 - Key: `kGDSMSSplitterPartKeyBytes`. Value: An `NSNumber` object containing the number of bytes accupied by the part string.
 
 - Key: `kGDSMSSplitterPartKeyContent`. Value: An `NSString` object containing the current part content of the original input string.
 
**Attention**

 Once the number of bytes occupied by the input message string exceeds the available number of bytes for a single SMS message (according to an infered encoding), every message part will use extra bytes to represent a sequence number of every SMS. Therefore, the number of available bytes for a message part decreases. For GSM 03.38 encoded messages it drops down to 153 symbols per message (from 160); for UTF-16 encoded messages it drops down to 67 symbols per message (from 70).

---

```objective-c
+ (instancetype)sharedSplitter;
```

**Description**

Returns a singleton splitter object. On the first call this method creates a newly allocated and instantiated splitter object. On any of subsequent calls it returns the previously created object.

## Additional type
```objective-c
typedef NS_ENUM(NSUInteger, GDSMSSplitterMessageMode) {
    GDSMSSplitterMessageModeGSM0338,
    GDSMSSplitterMessageModeUTF16
} 
```

Message group encoding mode.

`GDSMSSplitterMessageModeGSM0338` - Messages are encoded using GSM 03.38 standard.

`GDSMSSplitterMessageModeUTF16` - Messages are encoded using UTF16 (USC-2) standard.

## Installation via CocoaPods

GDSMSSplitter is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "GDSMSSplitter"
```
# License
MIT License. Read `LICENSE` file for more details.

Copyright (c) 2015 Alex Gordiyenko
