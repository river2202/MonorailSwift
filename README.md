# Monorail

[![Version](https://img.shields.io/cocoapods/v/https://cocoapods.org/pods/MonorailSwift.svg?style=flat)](https://cocoapods.org/pods/MonorailSwift)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://cocoapods.org/pods/MonorailSwift)
![Xcode 9.0+](https://img.shields.io/badge/Xcode-9.0%2B-blue.svg)
![iOS 8.0+](https://img.shields.io/badge/iOS-8.0%2B-blue.svg)
![Swift 4.0+](https://img.shields.io/badge/Swift-4.0%2B-orange.svg)


## Introduction

Monorail is a testing tool to log, record and replay network interactions when doing manual and automatic testing. 

Inspired by pact.io but the Monorail can be use not only for unit test but also manual test, stub integration testing and offline demo.

## Features

0. All features work out of box with minimum impact to product code.
1. Intercept network call and output to debug terminal. Works out of box with native api and most of 3rd SDKs.
2. Save network interactions into json file
3. Playback saved network interactions response. Remove the dependence of backend server when doing development or offline demo. 

## When to use
1. Troubleshooting, build-in mini network sniffer, print api request and response so developer can see clearly what is sending and receieving.
2. When manual testing, save and share log to your workstation with shake and click.
3. Playback the saved log file without backend.
4. CI
    1. Use saved or manually created log file as stub, run test without backend.
    2. Save network interactions to file when running integration tests 
    3. Easely switch between local stub and real backend

## How to use

### CocoaPods

pod 'MonorailSwift', '~> 1.0'

### Carthage

github "river2202/MonorailSwift" ~> 1.0.0

### Code example

```Monorail.enableLogger()```

```Monorail.writeLog()```

```Monorail.enableReader(from: demo1)```

Check MonorailSwift example project for details.

Check [wiki](https://github.com/river2202/MonorailSwift/wiki) for more documents.

## Tools

Tools under ```monorailswift⁩/⁨MonorailSwift⁩Example/Helper⁩/Monorail⁩```

Download example project come with the MonorailSwift repository. Run the app in simulator and press keyboard shortcut Cmd + Ctrl + z

## Communication
- If you need any help, use [Stack Overflow](https://stackoverflow.com/questions/tagged/monorailswift) and tag `monorailswift`.

## Author

River2202@gmail.com

## License

Monorail is available under the MIT license. See the LICENSE file for more info.
