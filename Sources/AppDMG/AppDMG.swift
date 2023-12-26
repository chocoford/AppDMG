// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import AppKit
import OSLog
import UniformTypeIdentifiers

import hdiutil
import DSStoreKit

extension AppDMG {
    enum AppDMGError: LocalizedError {
        case codesignFailed
        case dmgIconError(_ message: String)
        case loadImageFailed(URL)
        
        var errorDescription: String? {
            switch self {
                case .codesignFailed:
                    "Codesign failed"
                case .dmgIconError(let message):
                    "Dmg icon error: \(message)"
                case .loadImageFailed(let url):
                    "Load image failed: \(url)"
            }
        }
    }
    
    public enum DMGBackgroundOption {
        case `default`
        case manually(_ url: URL)
        case skip
    }
    
    public enum DMGIconOption {
        case `default`
        case manually(_ url: URL)
        case skip
    }
    
    public struct Appendix {
        public enum AppendixType: Int {
            case symbolLink
            case file
        }
        
        public var name: String
        public var destination: URL
        public var type: AppendixType
        public var position: CGPoint
        
        public init(name: String?, destination: URL, type: AppendixType, position: CGPoint) {
            self.name = name ?? destination.lastPathComponent
            self.destination = destination
            self.type = type
            self.position = position
        }
        
        public static func application(position: CGPoint = CGPoint(x: 480, y: 170)) -> Appendix {
            Appendix(name: "Applications", destination: URL(string: "file:///Applications")!, type: .symbolLink, position: position)
        }
        public static func quickLook(position: CGPoint = CGPoint(x: 480, y: 170)) -> Appendix {
            Appendix(name: "QuickLook", destination: URL(string: "file:///Library/QuickLook")!, type: .symbolLink, position: position)
        }
    }
    
    public enum CodesignOption {
        case auto
        case manually(_ identity: String)
        case skip
    }
    
}

public class AppDMG {
    public static var `default`: AppDMG = AppDMG()
    
    let logger = Logger(subsystem: "com.chocoford.AppDMG", category: "AppDMG")
    
    private init() {}
    
    public var log: Bool = false {
        didSet {
            hdiutil.configure(options: .log(self.log))
        }
    }
    
    private var createDMGProgress: [UUID : CreateDMGStatus] = [:]
    
    /// Create DMG with specific options.
    /// - Parameters:
    ///   - id: The ID identify the task for later check progress.
    ///   - url: The file url of the source App.
    ///   - to: The file url of the output location. Pass nil if you want to place it on the same folder of source App.
    ///   - backgroundImage: The url of the background image of dmg.
    ///   - dmgIcon: The icon url of dmg.
    ///   - windowRect: The rect of the dmg window. (Displayed when user open it)
    ///   - appIconPos: The icon position of the source app in the dmg file.
    ///   - appendixes: Appendixes of dmg file. You can copy anohter file in dmg or make symbol links to dmg. By default there is a symbol link to `/Applications`
    ///   - codesign: The codesign options of dmg file. By default the dmg is codesign automatically.
    @discardableResult
    public func createDMG(
        id: UUID = UUID(),
        url: URL,
        to desDirectory: URL? = nil,
        backgroundImage: DMGBackgroundOption = .default,
        dmgIcon: DMGIconOption = .default,
        windowRect: CGRect = CGRect(x: 200, y: 200, width: 660, height: 400),
        appIconPos: CGPoint = CGPoint(x: 180, y: 170),
        appendixes: [Appendix] = [.application()],
        codesign: CodesignOption = .auto,
        onProgress: (CreateDMGStatus) -> Void = { _ in }
    ) async throws -> URL {
        self.createDMGProgress.updateValue(.waiting, forKey: id)
        defer { self.createDMGProgress.removeValue(forKey: id) }
        let fileManager = FileManager.default
        if log { logger.info("Start read app info: \(url, privacy: .public)") }
        let appPlist = try AppPlist(appURL: url)
        let appFileName = url.lastPathComponent
        
        var desURL = desDirectory ?? url.deletingLastPathComponent()
        var desPath: String { desURL.filePath }
        var isDesURLADir = false
        let imageName: String
        _ = fileManager.fileExists(at: desURL, isDirectory: &isDesURLADir)
        if isDesURLADir {
            imageName = "\(appPlist.appName) \(appPlist.shortVersionString ?? "").dmg"
        } else {
            imageName = desURL.lastPathComponent
            desURL = desURL.deletingLastPathComponent()
        }
        
        
        
        if log { logger.info("Start create dmg") }
        onProgress(.create)
        self.createDMGProgress.updateValue(.create, forKey: id)
        // Create DMGs
        let createOutput = try await hdiutil.create(
            image: imageName,
            to: desPath,
            options: [
                .srcFolder(url.filePath),
                .volname(appPlist.appName),
                .fs(.hfs),
                .fsargs("-c c=64,a=16,e=16"),
                .format(.udrw),
                .overwrite
            ]
        )

        let dmgURL = createOutput.dmgURL
        
        // Attach
        if log { logger.info("Start attach dmg") }
        onProgress(.attach)
        self.createDMGProgress.updateValue(.attach, forKey: id)
        // Attach image to modify its contents
        let attachOutput = try await hdiutil.attach(image: dmgURL.filePath, options: [
            .mountRandom("/tmp"),
            .readwrite,
            .verify(false),
            .autoOpen(false),
            .noBrowse
        ])
        let deviceName = attachOutput.deviceNode
        let mountURL = attachOutput.mountPoint
        
        // Background image
        onProgress(.makeBackground)
        self.createDMGProgress.updateValue(.makeBackground, forKey: id)
        let backgroundDir = mountURL.appendingPathComponent(".background", conformingTo: .directory)
        if fileManager.fileExists(at: backgroundDir) {
            try fileManager.removeItem(at: backgroundDir)
        }
        try fileManager.createDirectory(
            at: mountURL.appendingPathComponent(".background", conformingTo: .directory),
            withIntermediateDirectories: true
        )
        let backgroundURL: URL?
        switch backgroundImage {
            case .default:
//                let bgFileURL = Bundle.module.url(forResource: "default-bg@2x", withExtension: "png")!
                let bgFileURL = Bundle.module.url(forResource: "dmg-background", withExtension: "tiff")!
                backgroundURL = mountURL
                    .appendingPathComponent(".background", conformingTo: .directory)
                    .appendingPathComponent(bgFileURL.lastPathComponent, conformingTo: .image)
                try fileManager.copyItem(at: bgFileURL, to: backgroundURL!)
            case .manually(let url):
                backgroundURL = mountURL
                    .appendingPathComponent(".background", conformingTo: .directory)
                    .appendingPathComponent(url.lastPathComponent, conformingTo: .image)
                try fileManager.copyItem(at: url, to: backgroundURL!)
            case .skip:
                backgroundURL = nil
        }

        // Appendix
        onProgress(.addAppendix)
        self.createDMGProgress.updateValue(.addAppendix, forKey: id)
        for appendix in appendixes {
            switch appendix.type {
                case .symbolLink:
                    try fileManager.createSymbolicLink(
                        at: mountURL.appendingPathComponent(appendix.name, conformingTo: .symbolicLink),
                        withDestinationURL: appendix.destination
                    )
                case .file:
                    try fileManager.copyItem(atPath: appendix.destination.filePath, toPath: "\(mountURL.filePath)/\(appendix.name)")
            }
        }

        
        // copy icon
        onProgress(.setIcon)
        self.createDMGProgress.updateValue(.setIcon, forKey: id)
        var volIcon: NSImage? = nil
        switch dmgIcon {
            case .default:
                if let appIconFileName = appPlist.iconFileName {
                    let resourcesDir = url.appendingPathComponent("Contents", conformingTo: .directory)
                        .appendingPathComponent("Resources", conformingTo: .directory)
                    var extensionType: UTType? = nil
                    if let pathExtension = appIconFileName.components(separatedBy: ".").last,
                       pathExtension != appIconFileName {
                        extensionType = UTType(filenameExtension: pathExtension)
                    }
                    let appIcon = resourcesDir
                        .appendingPathComponent(appIconFileName, conformingTo: extensionType ?? .icns)
                    
                    volIcon = try makeIcon(appIcon: appIcon)
                }
                
            case .manually(let url):
                volIcon = NSImage(contentsOf: url)
                
            default:
                break
        }

        if let volIcon = volIcon {
            NSWorkspace.shared.setIcon(volIcon, forFile: mountURL.filePath)
        }

        // prettyDMG
        onProgress(.decorateContent)
        self.createDMGProgress.updateValue(.decorateContent, forKey: id)
        try await self.prettyDMG(
            mountURL: mountURL,
            backgroundURL: backgroundURL,
            windowRect: windowRect,
            appName: appFileName, 
            appPos: appIconPos,
            appendixes: appendixes
        )
        
        // make readonly
        onProgress(.modifyPermission)
        self.createDMGProgress.updateValue(.modifyPermission, forKey: id)
        // # Tell the volume that it has a special file attribute
        // SetFile -a C "$MOUNT_DIR"
        try fileManager.setAttributes([.posixPermissions : 0777], of: dmgURL)
        
        
        // Delete unnecessary file system events log if possible
        if fileManager.fileExists(atPath: "\(mountURL.filePath)/.fseventsd") {
            try fileManager.removeItem(atPath: "\(mountURL.filePath)/.fseventsd")
        }
        
        
        // detach
        onProgress(.detach)
        self.createDMGProgress.updateValue(.detach, forKey: id)
        try await hdiutil.detach(deviceName: deviceName)
        
        // Compress image and optionally encrypt
        onProgress(.compress)
        self.createDMGProgress.updateValue(.compress, forKey: id)
        try await hdiutil.convert(
            image: dmgURL.filePath,
            format: .udzo,
            outFile: dmgURL.filePath,
            options: [
                .overwrite,
                .imageKey("zlib-level", "9")
            ]
        )
        
        // codesign
        onProgress(.codesign)
        self.createDMGProgress.updateValue(.codesign, forKey: id)
        if log { logger.info("begin codesign") }
        switch codesign {
            case .auto:
                let identities = try await SecurityHelper.shared.listIdentities(policy: .codesigning)
                if log { logger.info("identities: \(identities, privacy: .public)") }
                let identity = identities.first(where: {$0.type == .developerID}) ?? identities.first(where: {$0.type == .macDeveloper}) ?? identities.first(where: {$0.type == .appleDevelopment})
                guard let identity = identity else { throw AppDMGError.codesignFailed }
                try await CodesignHelper.shared.codesign(identity: identity.id, target: dmgURL)
                
            case .manually(let identity):
                try await CodesignHelper.shared.codesign(identity: identity, target: dmgURL)
                
            case .skip:
                break
        }
        
        // notarize
        onProgress(.setIcon)
        self.createDMGProgress.updateValue(.setIcon, forKey: id)
        if let volIcon = volIcon {
            NSWorkspace.shared.setIcon(volIcon, forFile: dmgURL.filePath)
        }
        
        return dmgURL
    }
    
    public func getCreateDMGStatus(id: UUID) -> CreateDMGStatus? {
        createDMGProgress[id]
    }
    
    public func help() async throws -> String {
        return try await hdiutil.help()
    }
    
    public func prettyDMG(
        mountURL: URL, 
        backgroundURL: URL?,
        windowRect: CGRect,
        appName: String,
        appPos: CGPoint,
        appendixes: [Appendix]
    ) async throws {
        struct PrettyDMGError: LocalizedError {
            var errorDescription: String?
        }
        
        var dsStore = DSStore.create()
        try dsStore.insertRecord(.bwsp(.createNew(
            value: .init(
                containerShowSidebar: false, 
                showPathbar: false,
                showSidebar: false, showStatusBar: false,
                showTabView: false, showToolbar: false,
                windowBounds: windowRect
            ))))
        try dsStore.insertRecord(
            .icvp(
                .createNew(
                    value: .init(
                        backgroundImageAlias: Record.icvpRecord.createBackgroundAlias(backgroundURL: backgroundURL),
                        backgroundType: 2
                    )
                )
            )
        )
        
        dsStore.insertRecord(.vSrn(.general()))

        // Iloc
        try dsStore.insertRecord(.Iloc(.createNew(name: appName, iconPos: appPos)))
        for appendix in appendixes {
            try dsStore.insertRecord(.Iloc(.createNew(name: appendix.name, iconPos: appendix.position)))
        }
        
        
        try dsStore.save(to: mountURL)
    }
    
    public func listIdentities(policy: SecurityHelper.Policy?, validOnly: Bool = true) async throws -> [SecurityHelper.Identity] {
        try await SecurityHelper.shared.listIdentities(policy: policy, validOnly: validOnly)
    }
    
    func makeIcon(appIcon: URL) throws -> NSImage {
        guard let diskIconURL = Bundle.module.url(forResource: "disk-icon", withExtension: "icns") else {
            throw AppDMGError.dmgIconError("disk icon not found")
        }
        guard let diskIcon = NSImage(contentsOf: diskIconURL), diskIcon.isValid else {
            throw AppDMGError.loadImageFailed(diskIconURL)
        }
        guard let appIcon = NSImage(contentsOf: appIcon), appIcon.isValid else {
            throw AppDMGError.dmgIconError("load app icon failed")
        }
        
        if log { logger.debug("Begin to make icon. Disk icon size: \(diskIcon.size.debugDescription)") }
        
        
        var newRepresentations = [NSImageRep]()
        for representation in diskIcon.representations {
            guard let bitmapRep = representation as? NSBitmapImageRep else {
                throw AppDMGError.dmgIconError("get disk icon bitmap failed.")
            }
            
            let width = bitmapRep.pixelsWide
            let height = bitmapRep.pixelsHigh
            guard let newBitmapRep = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: width,
                pixelsHigh: height,
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            ) else {
                throw AppDMGError.dmgIconError("Failed to create NSBitmapImageRep")
            }
            
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: newBitmapRep)
            
            let contextSize = NSMakeSize(CGFloat(width), CGFloat(height))
            bitmapRep.draw(in: NSMakeRect(0, 0, contextSize.width, contextSize.height))
            let appIconSize = CGSize(width: contextSize.width * 0.618, height: contextSize.height * 0.618)
            appIcon.draw(
                in: NSRect(x: (contextSize.width - appIconSize.width) / 2,
                           y: (contextSize.height - appIconSize.height * 0.8) / 2,
                           width: appIconSize.width,
                           height: appIconSize.height),
                from: .zero,
                operation: .sourceOver,
                fraction: 1.0
            )
            
            NSGraphicsContext.restoreGraphicsState()
            
            newRepresentations.append(newBitmapRep)
        }
        
        let largestSize = newRepresentations.reduce(.zero) {
            CGSize(width: max($0.width, CGFloat($1.pixelsWide)), height: max($0.height, CGFloat($1.pixelsHigh)))
        }
        
        let newIcon = NSImage(size: largestSize)
        for rep in newRepresentations {
            newIcon.addRepresentation(rep)
        }
        
        guard newIcon.isValid else {
            throw AppDMGError.dmgIconError("Making icon failed: Invalid.")
        }
        
        return newIcon
    }
    
    func resizeImage(_ image: NSImage, to newSize: NSSize) -> NSImage {
        let resizedImage = NSImage(size: newSize)
        resizedImage.lockFocus()
        image.draw(in: NSMakeRect(0, 0, newSize.width, newSize.height), from: NSZeroRect, operation: .copy, fraction: 1.0)
        resizedImage.unlockFocus()
        return resizedImage
    }
}


extension AppDMG {
    public enum CreateDMGStatus: Int, Codable, CustomStringConvertible {
        case waiting
        case create
        case attach
        case makeBackground
        case addAppendix
        case setIcon
        case decorateContent
        case modifyPermission
        case clean
        case detach
        case compress
        case codesign
        
        public var description: String {
            switch self {
                case .waiting:
                    "Waiting..."
                case .create:
                    "Creating DMG..."
                case .attach:
                    "Attaching DMG..."
                case .makeBackground:
                    "Making background of DMG..."
                case .addAppendix:
                    "Linking symbols..."
                case .setIcon:
                    "Setting icon..."
                case .decorateContent:
                    "Decorating DMG's content..."
                case .modifyPermission:
                    "Modifying permission..."
                case .clean:
                    "Clean redundant files..."
                case .detach:
                    "Detaching DMG..."
                case .compress:
                    "Compressing DMG..."
                case .codesign:
                    "Codesigning DMG..."
            }
        }
    }
}
