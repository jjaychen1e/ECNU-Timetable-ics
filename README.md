# ECNU-Timetable-ics
<p align="left">
<img src="https://img.shields.io/badge/Swift-5.1-orange.svg?style=flat" alt="Swift 5.1">
<img src="https://img.shields.io/badge/os-macOS-brightgreen.svg?style=flat" alt="macOS">
<img src="https://img.shields.io/badge/os-Linux-brightgreen.svg?style=flat" alt="Linux">
</p>

This project is based on [Swift Package Manager](https://swift.org/package-manager/).

## Deploy

### Install Swift

Follow the instructions in [swift.org](https://swift.org/getting-started/).


### Dependency

Install python first.

(Use brew on macOS.)

`sudo apt install tesseract-ocr`

`sudo apt install libtesseract-dev`

`sudo apt-get install libxml2-dev`

`pip3 install pytesseract`

If Linux: 

`sudo apt-get install openssl libssl-dev uuid-dev`

`sudo apt-get install nodejs`

`pip3 install PyExecJS`

### Configuration

You should set your own python/tesseract path in  `Helper/Config/PathConstants.swift`.

The default path is: `/usr/local/bin/`.

The default mode is HTTPS now, you should set your cert path and key path in `Helper/Config/PathConstants.swift`. Or you can choose to uncomment the corresponding codes to run HTTP server in `main.swift`.

### Build

`swift build`

### Build and Run

`swift run`

### Generate Xcode Project

`swift package generate-xcodeproj`

## Roadmap

- [x] Migrate to Linux.~~(Unfortunately, Alamofire not supports Linux now..)~~ (Fortunately, URLSession provided by FoundationNetworking now works on Linux with `Swift 5`)
