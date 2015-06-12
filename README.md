##Description
This repository contains two Objective-C classes designed to split a string into a sequence of short messages close to the international standard of SMS messaging. The `GDSMSSplitter` class is responsible for actuall splitting. `GDSMSCounterLabel` is a `UILabel` subclass which implements the basic pattern for showing a user the number of SMS-messages potentially sent to recipient and the count of leftover symbols.

`GDSMSSplitter` provides support for *GSM 03.38* standard (including *basic character set extension table*, but excluding *national language shift tables*). It also supports *UTF-16* (*UCS-2*) encoding standard.

# GDSMSSplitter
