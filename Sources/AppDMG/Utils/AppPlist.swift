//
//  AppPlist.swift
//  Sparkling
//
//  Created by Dove Zachary on 2023/10/24.
//

import Foundation

typealias AppPlist = [String : AppPlistValue]

extension AppPlist {
    init(appURL: URL) throws {
        let plistURL = appURL
            .appendingPathComponent("Contents", conformingTo: .directory)
            .appendingPathComponent("Info", conformingTo: .propertyList)

        let data = try Data(contentsOf: plistURL)
        self = try PropertyListDecoder().decode(AppPlist.self, from: data)
    }
    
    var appName: String {
        self[AppPlistKey.bundleDisplayName]?.stringValue ?? self[AppPlistKey.bundleName]?.stringValue ?? ""
    }
    
    /// Specified in Info.plist with the key of `CFBundleIconFile`.
    ///
    /// Indicating the icon files located under `Contents/Resources`.
    var iconFileName: String? {
        self[AppPlistKey.bundleIconFile]?.stringValue
    }
    
    /// Specified in Info.plist with the key of `CFBundleIconName`
    var assertIconName: String? {
        self[AppPlistKey.bundleIconName]?.stringValue
    }
    
    var bundleIdentifier: String? {
        self[AppPlistKey.bundleIdentifier]?.stringValue
    }
    
    var shortVersionString: String? {
        self[AppPlistKey.bundleShortVersionString]?.stringValue
    }
    
    var build: Int {
        self[AppPlistKey.bundleVersion]?.intValue ?? -1
    }
    
    var version: String {
        "\(self.shortVersionString ?? "unknown")(\(build))"
    }
}

enum AppPlistValue: Codable, Hashable {
    case string(String)
    case int(Int)
    case bool(Bool)
    case array([AppPlistValue])
    case dictionary([String : AppPlistValue])
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let x = try? container.decode(String.self) {
            self = .string(x)
        } else if let x = try? container.decode(Int.self) {
            self = .int(x)
        } else if let x = try? container.decode(Bool.self) {
            self = .bool(x)
        } else if let x = try? container.decode([AppPlistValue].self) {
            self = .array(x)
        } else if let x = try? container.decode([String : AppPlistValue].self) {
            self = .dictionary(x)
        } else {
            throw DecodingError.typeMismatch(
                AppPlistValue.self,
                .init(codingPath: decoder.codingPath, 
                      debugDescription: "AppPlistValue type mismatched")
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
            case .string(let string):
                try container.encode(string)
            case .int(let int):
                try container.encode(int)
            case .bool(let bool):
                try container.encode(bool)
            case .array(let array):
                try container.encode(array)
            case .dictionary(let dict):
                try container.encode(dict)
        }
    }
    
    var stringValue: String {
        switch self {
            case .string(let string):
                return string
            case .int(let int):
                return String(int)
            case .bool(let bool):
                return String(bool)
            case .array(let array):
                return array.description
            case .dictionary(let dict):
                return dict.description
        }
    }
    
    var intValue: Int {
        switch self {
            case .string(let string):
                return Int(string) ?? 0
            case .int(let int):
                return int
            case .bool(let bool):
                return bool ? 1 : 0
            case .array(let array):
                return array.hashValue
            case .dictionary(let dict):
                return dict.hashValue
        }
    }
}

internal struct _AppPlistKey {
    var buildMachineOSBuild = "BuildMachineOSBuild"
    var bundleDevelopmentRegion = "CFBundleDevelopmentRegion"
    var bundleDisplayName = "CFBundleDisplayName"
    var bundleExecutable = "CFBundleExecutable"
    var bundleIconFile = "CFBundleIconFile"
    var bundleIconName = "CFBundleIconName"
    var bundleIdentifier = "CFBundleIdentifier"
    var bundleInfoDictionaryVersion = "CFBundleInfoDictionaryVersion"
    var bundleName = "CFBundleName"
    var bundlePackageType = "CFBundlePackageType"
    var bundleShortVersionString = "CFBundleShortVersionString"
    var bundleSupportedPlatforms = "CFBundleSupportedPlatforms"
    var bundleVersion = "CFBundleVersion"
    var compiler = "DTCompiler"
    var platformBuild = "DTPlatformBuild"
    var platformName = "DTPlatformName"
    var platformVersion = "DTPlatformVersion"
    var sdkBuild = "DTSDKBuild"
    var sdkName = "DTSDKName"
    var xcode = "DTXcode"
    var xcodeBuild = "DTXcodeBuild"
//       case itsAppUsesNonExemptEncryption = "ITSAppUsesNonExemptEncryption"
    var lsApplicationCategoryType = "LSApplicationCategoryType"
    var lsMinimumSystemVersion = "LSMinimumSystemVersion"
    var lsuiElement = "LSUIElement"
    var nsAccentColorName = "NSAccentColorName"
    var suEnableInstallerLauncherService = "SUEnableInstallerLauncherService"
    var suFeedURL = "SUFeedURL"
    var suPublicEDKey = "SUPublicEDKey"
    var uiApplicationSupportsIndirectInputEvents = "UIApplicationSupportsIndirectInputEvents"
    var uiStatusBarStyle = "UIStatusBarStyle"
    var uiSupportedInterfaceOrientationsIpad = "UISupportedInterfaceOrientations~ipad"
    var uiSupportedInterfaceOrientationsIphone = "UISupportedInterfaceOrientations~iphone"
    
    
    var allKeys: [String] {
        let mirror = Mirror(reflecting: _AppPlistKey())
        return mirror.children.compactMap {
            $0.value as? String
        }
    }
}

let AppPlistKey = _AppPlistKey()


