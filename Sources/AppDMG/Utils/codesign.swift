//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/12/7.
//

import Foundation

extension CodesignHelper {
    struct CodesignError: LocalizedError {
        var errorDescription: String?
        
        init(message errorDescription: String? = nil) {
            self.errorDescription = errorDescription
        }
    }
    
    public struct CodesignInfo: Codable {
        public var executable: String = ""
        public var identifier: String = ""
        public var format: String = ""
        public var codeDirectoryVersion: String = ""
        public var codeDirectorySize: Int = 0
        public var codeDirectoryFlags: String = ""
        public var hashType: String = ""
        public var hashSize: Int = 0
    //    public var candidateCDHash: String
    //    public var candidateCDHashFull: String
        public var cmsDigest: String = ""
        public var cmsDigestType: Int = 0
        public var cdHash: String = ""
        public var signatureSize: Int = 0
        public var authority: [String] = []
        public var timestamp: String = ""
        public var infoPlist: String = ""
        public var teamIdentifier: String = ""
        public var sealedResources: String = ""
        public var internalRequirementsCount: Int = 0
        public var internalRequirementsSize: Int = 0
        
        public init(string: String) {
            let lines = string.components(separatedBy: "\n")
            for line in lines {
                if line.hasPrefix("Executable") {
                    self.executable = line.components(separatedBy: "=").last ?? ""
                } else if line.hasPrefix("Identifier") {
                    self.identifier = line.components(separatedBy: "=").last ?? ""
                } else if line.hasPrefix("Format") {
                    self.format = line.components(separatedBy: "=").last ?? ""
                } else if line.hasPrefix("CodeDirectory") {
                    let components = Array(line.components(separatedBy: " ").dropFirst())
                    print(components)
                    self.codeDirectoryVersion = components[0].components(separatedBy: "=").last ?? ""
                    self.codeDirectorySize = Int(components[1].components(separatedBy: "=").last ?? "") ?? 0
                    self.codeDirectoryFlags = components[2].components(separatedBy: "=").last ?? ""
                } else if line.hasPrefix("Hash type") {
                    let kvs = line.components(separatedBy: " ")
                    self.hashType = kvs[0].components(separatedBy: "=").last ?? ""
                    self.hashSize = Int(kvs[1].components(separatedBy: "=").last ?? "") ?? 0
                } else if line.hasPrefix("CandidateCDHash") {
                    
                } else if line.hasPrefix("CandidateCDHashFull") {
                    
                } else if line.hasPrefix("Hash choices") {
                    
                } else if line.hasPrefix("CMSDigest") {
                    self.cmsDigest = line.components(separatedBy: "=").last ?? ""
                } else if line.hasPrefix("CMSDigestType") {
                    self.cmsDigestType = Int(line.components(separatedBy: "=").last ?? "") ?? 0
                } else if line.hasPrefix("CDHash") {
                    self.cdHash = line.components(separatedBy: "=").last ?? ""
                } else if line.hasPrefix("Authority") {
                    self.authority.append(line.components(separatedBy: "=").last ?? "")
                } else if line.hasPrefix("Timestamp") {
                    self.timestamp = line.components(separatedBy: "=").last ?? ""
                } else if line.hasPrefix("Info.plist") {
                    self.infoPlist = line.components(separatedBy: "=").last ?? ""
                } else if line.hasPrefix("TeamIdentifier") {
                    self.teamIdentifier = line.components(separatedBy: "=").last ?? ""
                } else if line.hasPrefix("Sealed Resources") {
                    self.sealedResources = line.components(separatedBy: "=").last ?? ""
                } else if line.hasPrefix("Internal requirements count") {
                    let componenets = line.components(separatedBy: " ")
                    self.internalRequirementsCount = Int(componenets[2].components(separatedBy: "=").last ?? "") ?? 0
                    self.internalRequirementsSize = Int(componenets[3].components(separatedBy: "=").last ?? "") ?? 0
                }
            }
        }
    }
}

class CodesignHelper {
    
    static var shared: CodesignHelper = CodesignHelper()
    
    private init() {}
    
    func codesign(identity: String, target: URL) async throws {
        let _: String = try await withCheckedThrowingContinuation { continuation in
            do {
                let task = Process()
                let pipe = Pipe()
                let errPipe = Pipe()
                
                task.standardInput = nil
                task.standardOutput = pipe
                task.standardError = errPipe
                task.arguments = ["-s", identity, target.filePath]
                task.executableURL = URL(string: "file:///usr/bin/codesign")
                
                try task.run()
                task.waitUntilExit()
                
                let output: String
                
                if #available(macOS 10.15.4, *),
                    let data = try errPipe.fileHandleForReading.readToEnd() {
                    guard data.isEmpty else {
                        throw CodesignError(message: String(data: data, encoding: .utf8) ?? "")
                    }
                } else {
                    let data = errPipe.fileHandleForReading.readDataToEndOfFile()
                    guard data.isEmpty else {
                        throw CodesignError(message: String(data: data, encoding: .utf8) ?? "")
                    }
                }
                
                if #available(macOS 10.15.4, *), let data = try pipe.fileHandleForReading.readToEnd() {
                    output = String(data: data, encoding: .utf8) ?? ""
                } else {
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    output = String(data: data, encoding: .utf8)!
                }
                
                continuation.resume(returning: output)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func verify(target: URL) async throws -> CodesignInfo {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let task = Process()
                let pipe = Pipe()
                let errPipe = Pipe()
                
                task.standardInput = nil
                task.standardOutput = pipe
                task.standardError = errPipe
                task.arguments = ["-d", "-vvv", target.filePath]
                task.executableURL = URL(string: "file:///usr/bin/codesign")
                
                try task.run()
                task.waitUntilExit()
                
                let output: String
                
                if #available(macOS 10.15.4, *),
                    let data = try errPipe.fileHandleForReading.readToEnd() {
                    guard data.isEmpty else {
                        throw CodesignError(message: String(data: data, encoding: .utf8) ?? "")
                    }
                } else {
                    let data = errPipe.fileHandleForReading.readDataToEndOfFile()
                    guard data.isEmpty else {
                        throw CodesignError(message: String(data: data, encoding: .utf8) ?? "")
                    }
                }
                
                if #available(macOS 10.15.4, *), let data = try pipe.fileHandleForReading.readToEnd() {
                    output = String(data: data, encoding: .utf8) ?? ""
                } else {
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    output = String(data: data, encoding: .utf8)!
                }
                
                continuation.resume(returning: CodesignInfo(string: output))
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
