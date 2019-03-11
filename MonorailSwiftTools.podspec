#
# Be sure to run `pod lib lint MonorailSwift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MonorailSwiftTools'
  s.version          = '1.0.2'
  s.summary          = 'MonorailSwiftTools is a test tool to log/write/replay network interactions.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Works out of box with iOS build in api and most of 3rd SDK to print the network api calls, write them to file and replay the tap with simply setup.
                       DESC

  s.homepage         = 'https://github.com/river2202/MonorailSwift'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'river2202@gmail.com' => 'River2202@gmail.com' }
  s.source           = { :git => 'https://github.com/river2202/MonorailSwift.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://stackoverflow.com/questions/tagged/MonorailSwift'

  s.ios.deployment_target = '9.0'
  s.swift_version = '4.2'

  s.source_files = 'MonorailSwift/Helper/**/*'
  
  # s.resource_bundles = {
  #   'MonorailSwift' => ['MonorailSwift/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'MonorailSwift', '~> 1.0.0'
end
