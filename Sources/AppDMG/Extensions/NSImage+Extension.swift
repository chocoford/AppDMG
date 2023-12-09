//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/12/8.
//

import Foundation
import AppKit
import CoreGraphics
import UniformTypeIdentifiers


extension NSImage {
    func saveIcns(to url: URL) throws {
        struct MakeIcnsError: LocalizedError {
            var errorDescription: String?
            
            init(message errorDescription: String? = nil) {
                self.errorDescription = errorDescription
            }
        }
        
        guard let desRef = CGImageDestinationCreateWithURL(url as CFURL, UTType.icns.identifier as CFString, representations.count, nil) else {
            throw MakeIcnsError(message: "create icns failed")
        }
        
        for representation in representations {
            guard let bitmapRep = representation as? NSBitmapImageRep,
                  let cgImage = bitmapRep.cgImage else {
                print("get cgImage failed")
                continue
            }
            
            CGImageDestinationAddImage(desRef, cgImage, nil)
        }
        
        guard CGImageDestinationFinalize(desRef) else {
            throw MakeIcnsError(message: "Finalize icns failed.")
        }
    }
}
