Pod::Spec.new do |s|
  s.name             = "ZRPagedArray"
  s.version          = "0.1.0"
  s.summary          = "Fork of AWPagedArray to improve performance with a large number of objects."
  s.homepage         = "https://github.com/zradke/ZRPagedArray"
  s.license          = 'MIT'
  s.authors          = { "Zach Radke"  => "zach.radke@gmail.com",
                         "Alek Åström" => "hi@mralek.se" }
  s.source           = { :git => "https://github.com/zradke/ZRPagedArray.git", :tag => s.version.to_s }
  s.source_files = 'Pod/Classes/**/*'
  s.platform     = :ios, '7.0'
  s.requires_arc = true
end
