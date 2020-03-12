# ECNU-Timetable-ics
<p align="left">
<img src="https://img.shields.io/badge/Swift-5.1-orange.svg?style=flat" alt="Swift 5.1">
<img src="https://img.shields.io/badge/os-macOS-brightgreen.svg?style=flat" alt="macOS">
<img src="https://img.shields.io/badge/os-Linux-brightgreen.svg?style=flat" alt="Linux">
</p>

This project is based on [Swift Package Manager](https://swift.org/package-manager/).

## Deploy

### Dependency

Use brew on macOS.

`sudo apt install tesseract-ocr`

`sudo apt install libtesseract-dev`

`sudo apt-get install libxml2-dev`

`pip3 install pytesseract`

If Linux: `pip3 install PyExecJS`

### Install Swift

Follow the instruction in [swift.org](https://swift.org/getting-started/).

### Build

`swift build`

### Generate Xcode Project

`swift package generate-xcodeproj`

## Roadmap

- [x] Migrate to Linux.~~(Unfortunately, Alamofire not supports Linux now..)~~ (Fortunately, URLSession provided by FoundationNetworking now works on Linux with `Swift 5`)
