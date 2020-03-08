// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ECNU-Timetable-ics",
    platforms: [
        .macOS(.v10_12), .iOS(.v11),
    ],
    dependencies: [
        .package(url: "https://github.com/PerfectlySoft/Perfect-HTTPServer.git", from: "3.0.0"),
        .package(url: "https://github.com/tid-kijyun/Kanna.git", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "ECNU-Timetable-ics",
            dependencies: ["PerfectHTTPServer", "Kanna"]),
    ]
)
