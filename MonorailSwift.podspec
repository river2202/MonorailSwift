#
# Be sure to run `pod lib lint MonorailSwift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#
# https://guides.cocoapods.org/making/making-a-cocoapod.html
# git tag '1.5.5'
# git push --tags
# pod trunk push MonorailSwift.podspec --allow-warnings

Pod::Spec.new do |s|
  s.name             = 'MonorailSwift'
  s.version          = '1.5.5'
  s.summary          = 'MonorailSwift is a test tool to log/write/replay network interactions.'
  s.description      = <<-DESC
Works out of box with iOS build in api and most of 3rd SDK to print the network api calls, write them to file and replay the tap with simply setup.
                       DESC

  s.homepage         = 'https://github.com/river2202/MonorailSwift'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'river2202@gmail.com' => 'River2202@gmail.com' }
  s.source           = { :git => 'https://github.com/river2202/MonorailSwift.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '9.0'
  s.swift_version = '5.0'

  s.source_files = 'MonorailSwift/Classes/**/*'
end
