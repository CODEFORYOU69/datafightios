// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "DataFightDependencies",
    platforms: [
        .iOS(.v13)
    ],
    dependencies: [
        // CountryPickerView
        .package(url: "https://github.com/kizitonwose/CountryPickerView.git", from: "3.0.1"),
        
        // GRPC Binary
        .package(url: "https://github.com/google/grpc-binary.git", from: "1.0.0"),
        
        // Google App Measurement
        .package(url: "https://github.com/google/GoogleAppMeasurement.git", from: "8.0.0"),
        
        // Google Utilities
        .package(url: "https://github.com/google/GoogleUtilities.git", from: "7.0.0"),
        
        // Abseil C++ Binary
        .package(url: "https://github.com/google/abseil-cpp-binary.git", from: "20210324.2"),
        
        // GTM Session Fetcher
        .package(url: "https://github.com/google/gtm-session-fetcher.git", from: "1.7.2"),
        
        // Google Data Transport
        .package(url: "https://github.com/google/GoogleDataTransport.git", from: "9.0.0"),
        
        // Firebase iOS SDK
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "8.0.0"),
        
        // SDWebImage
        .package(url: "https://github.com/SDWebImage/SDWebImage.git", from: "5.0.0"),
        
        // Interop for Google SDKs
        .package(url: "https://github.com/google/interop-ios-for-google-sdks.git", from: "1.0.0"),
        
        // Nanopb (Protocol Buffers)
        .package(url: "https://github.com/firebase/nanopb.git", from: "2.30909.0"),
        
        // Firebase App Check
        .package(url: "https://github.com/google/app-check.git", from: "0.0.1"),
        
        // FlagKit
        .package(url: "https://github.com/madebybowtie/FlagKit.git", from: "2.0.0"),
        
        // Swift Protobuf
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.17.0"),
        
        // Promises for Swift
        .package(url: "https://github.com/google/promises.git", from: "2.0.0"),
        
        // Charts Library
        .package(url: "https://github.com/danielgindi/Charts.git", from: "4.0.0"),
        
        // LevelDB (used by Firebase)
        .package(url: "https://github.com/firebase/leveldb.git", from: "1.22.0"),
        
        // Abseil C++
        .package(url: "https://github.com/abseil/abseil-cpp.git", from: "20210324.2")
    ],
    targets: [
        .target(
            name: "DataFightDependencies",
            dependencies: [
                "CountryPickerView",
                "grpc-binary",
                "GoogleAppMeasurement",
                "GoogleUtilities",
                "abseil-cpp-binary",
                "gtm-session-fetcher",
                "GoogleDataTransport",
                "firebase-ios-sdk",
                "SDWebImage",
                "interop-ios-for-google-sdks",
                "nanopb",
                "app-check",
                "FlagKit",
                "swift-protobuf",
                "Promises",
                "Charts",
                "leveldb",
                "abseil-cpp"
            ],
            path: "./Sources"
        )
    ]
)
