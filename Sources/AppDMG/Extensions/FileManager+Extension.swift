//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/11/6.
//

import Foundation

extension FileManager {
    
    func fileExists(at url: URL) -> Bool {
        let path: String
        if #available(macOS 13.0, *) {
            path = url.path(percentEncoded: false)
        } else {
            path = url.path
        }
        
        let result = self.fileExists(atPath: path)
        
        return result
    }
    
    func fileExists(at url: URL, isDirectory: inout Bool) -> Bool {
        var _isDirectory = ObjCBool(isDirectory)
        let path: String
        if #available(macOS 13.0, *) {
            path = url.path(percentEncoded: false)
        } else {
            path = url.path
        }
        
        let result = self.fileExists(atPath: path, isDirectory: &_isDirectory)
        isDirectory = _isDirectory.boolValue
        
        return result
    }
    
    func setAttributes(
        _ attributes: [FileAttributeKey : Any],
        of url: URL
    ) throws {
        let path: String
        if #available(macOS 13.0, *) {
            path = url.path(percentEncoded: false)
        } else {
            path = url.path
        }
        
        try self.setAttributes(attributes, ofItemAtPath: path)
    }
}
