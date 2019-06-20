# Echo iOS Swift Framework
myBBC Analytics Services - Echo Client for iOS http://bbc.github.io/echo-docs/

### Using Echo

#### Requirements to use
A target of iOS 8.0 or later is required to use embedded frameworks.

#### CocoaPods
In order to use Echo iOS Swift with your product you must use CocoaPods.

Here is an example Podfile that includes Echo:
```ruby
# This is required as Echo is published to the MAP repo
source 'git@github.com:bbc/map-ios-podspecs.git'

target 'MyApp' do
  use_frameworks!

  # Change the version number as appropriate
  pod 'echo-client-ios-swift', '~> 1.0'
end
```
After adding the Echo dependency to your `Podfile`, run `pod install` to add Echo to your project.

### Requirements to build
- Xcode 8.2.1 or later
- Mac OS X 10.11 or later

### Build instructions
- Install CocoaPods (`gem install cocoapods`)
- Checkout the project
- Run `pod install` from the root of the repository
- Open `Echo.xcworkspace` in Xcode
- Build
- Select `Product > Test` menu from the menu bar to run the unit tests

### Spring library
The Spring library had to be manually repackaged as a framework for use with Echo. We should request that Kantar provide their library as a `.framework` bundle in future.

### Library versions
- ComScore - v5.8.2
- Spring - 1.4

### Cocoapod
https://github.com/bbc/map-ios-podspecs/tree/master/Specs/echo-client-ios-swift/

## Release

To release:
- update the semver in echo-client-ios-swift.podspec e.g. `s.version = '0.5.0'`.
- merge develop into master
- release to github and the pod repo using the Jenkins pipeline
