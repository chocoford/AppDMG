//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/12/7.
//

import Foundation
import OSLog

extension SecurityHelper {
    struct SecurityError: LocalizedError {
        var errorDescription: String?
        
        init(message errorDescription: String? = nil) {
            self.errorDescription = errorDescription
        }
    }
}

public class SecurityHelper {
    let logger = Logger(subsystem: "com.chocoford.AppDMG", category: "SecurityHelper")
    
    static var shared: SecurityHelper = SecurityHelper()
    
    private init() {}
    
    public enum Policy: String {
        case ipsec
        case ichat
        case codesigning
        case sysDefault = "sys-default"
        case sysKerberosKdc = "sys-kerberos-kdc"
        case macappstore
        case appleID
    }
    
    public struct Identity {
        enum IdentityType: String {
            case developerID = "Developer ID Application"
            case macDeveloper = "Mac Developer"
            case appleDevelopment = "Apple Development"
            case appleDistribution = "Apple Distribution"
        }
        
        var id: String
        var type: IdentityType
        var entity: String
        var teamID: String
    }
    
    func listIdentities(policy: Policy?, validOnly: Bool = true) async throws -> [Identity] {
        try await withCheckedThrowingContinuation { continuation in
            do {
                var arguments: [String] = ["find-identity"]
                
                if validOnly {
                    arguments.append("-v")
                }
                
                if let policy = policy {
                    arguments.append("-p")
                    arguments.append(policy.rawValue)
                }
                
                
                let task = Process()
                let pipe = Pipe()
                let errPipe = Pipe()
                
                task.standardInput = nil
                task.standardOutput = pipe
                task.standardError = errPipe
                task.arguments = arguments
                
                task.executableURL = URL(string: "file:///usr/bin/security")
                
                try task.run()
                task.waitUntilExit()
                
                let outputString: String
                
                struct TaskError: LocalizedError {
                    var errorDescription: String?
                }
                if #available(macOS 10.15.4, *), 
                    let data = try errPipe.fileHandleForReading.readToEnd() {
                    guard data.isEmpty else {
                        throw SecurityError(message: String(data: data, encoding: .utf8) ?? "")
                    }
                } else {
                    let data = errPipe.fileHandleForReading.readDataToEndOfFile()
                    guard data.isEmpty else {
                        throw SecurityError(message: String(data: data, encoding: .utf8) ?? "")
                    }
                }
                if #available(macOS 10.15.4, *), let data = try pipe.fileHandleForReading.readToEnd() {
                    outputString = String(data: data, encoding: .utf8) ?? ""
                } else {
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    outputString = String(data: data, encoding: .utf8)!
                }
//                logger.error("outputString: \(outputString, privacy: .public)")
                
                var output: [Identity] = []
                
                for line in outputString.components(separatedBy: "\n").dropLast(2) {
                    // example--
                    //   1) 1111ASDF69CBF4WWWW96C72173FCDDDDEBAFFFD4 "Apple Development: 11111111111@xxx.com (12345MQWW0)"
                    let components = line.dropFirst(5).components(separatedBy: "\"")
                    let components2 = components[1].components(separatedBy: ":")
                    let components3 = components2[1].components(separatedBy: " (")
                    
                    let id = components[0].replacingOccurrences(of: " ", with: "")
                    let type = components2[0].replacingOccurrences(of: "\"", with: "")
                    let entity = components3[0]
                    let teamID = components3[1].replacingOccurrences(of: ")", with: "")
                    
                    if let type = Identity.IdentityType(rawValue: type) {
                        output.append(Identity(id: id, type: type, entity: entity, teamID: teamID))
                    }
                }
                
                continuation.resume(returning: output)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
