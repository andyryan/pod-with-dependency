#
# Be sure to run `pod lib lint Echo.podspec' to ensure this is a
# valid spec before submitting.
#

Pod::Spec.new do |s|
  s.name             = 'echo-client-ios-swift'
  s.version          = '5.2.1'
  s.summary          = 'myBBC Analytics Services - Echo Client Swift Framework for iOS https://bbc.github.io/echo-docs/'
  s.description      = <<-DESC
                       Echo presents a single interface for multiple analytics and event reporting systems. By providing a layer of abstraction it is possible for a product to report data to multiple vendors without the need to integrate directly with multiple different libraries.
                       DESC

  s.homepage         = 'https://bbc.github.io/echo-docs/'
  s.license          = 'None'
  s.authors          = { 'Analytics' => 'D&EAalyticsSupportTeam@bbc.co.uk' }
  s.source           = { :git => 'git@github.com:bbc/echo-client-ios-swift.git', :tag => s.version.to_s }
  s.module_name      = 'Echo'

  s.platforms = {:ios => '8.0', :tvos => '9.0' }
  s.swift_version = '5'

  s.source_files = 'Echo/**/*.{h,swift,m}'
  s.tvos.source_files = 'Echo/EchoTVOS/**/*.{h,swift,m}'
  s.public_header_files = 'Echo/**/*.h'
  s.ios.vendored_frameworks = 'Libraries/Tracker.framework', 'Libraries/KMA_SpringStreams.framework'
  s.tvos.vendored_frameworks = 'Libraries/tvOSTracker.framework', 'Libraries/TVOSKMA_SpringStreams.framework'
  s.frameworks = 'SystemConfiguration'
  s.dependency "ComScore", '5.8.2'

  s.xcconfig = { 'OTHER_LDFLAGS' => '-ObjC', 'OTHER_CFLAGS' => '-fembed-bitcode', 'FRAMEWORK_SEARCH_PATHS' => '${PODS_ROOT}/echo-client-ios-swift/Libraries' }

end
