Pod::Spec.new do |s|
  s.name             = "GDSMSSplitter"
  s.version          = "0.1.0"
  s.summary          = "Objective-C classes designed to split a string into a sequence of short messages close to the international standard of SMS messaging."
  s.description      = <<-DESC
The `GDSMSSplitter` class is responsible for actuall splitting. `GDSMSCounterLabel` is a `UILabel` subclass which implements the basic pattern for showing a user the number of SMS-messages potentially sent to recipient and the count of leftover symbols.

`GDSMSSplitter` provides support for **GSM 03.38** standard (including **basic character set extension table**, but *excluding* **national language shift tables**). It also supports **UTF-16** (*UCS-2*) encoding standard.

[Wikipedia article on GSM 03.38](http://en.wikipedia.org/wiki/GSM_03.38)
                       DESC
  s.homepage         = "https://github.com/coffellas-cto/GDSMSSplitter"
  s.screenshots     = "https://cloud.githubusercontent.com/assets/3193877/8145397/52ab127e-120f-11e5-8994-36d267d44950.gif", "https://cloud.githubusercontent.com/assets/3193877/8145421/6f418b9c-1210-11e5-9c40-280b3651cef3.gif"
  s.license          = 'MIT'
  s.author           = { "Alex Gordiyenko" => "cto@coffellas.com" }
  s.source           = { :git => "https://github.com/coffellas-cto/GDSMSSplitter.git", :tag => s.version.to_s }

  s.platform     = :ios, '6.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'GDSMSSplitter' => ['Pod/Assets/*.png']
  }

  s.public_header_files = 'Pod/Classes/**/*.h'
end
