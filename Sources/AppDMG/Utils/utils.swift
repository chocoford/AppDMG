//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/11/6.
//

import Foundation

func composeFilePaths(paths: String...) -> String {
    var output = ""
    
    for (i, path) in paths.enumerated() {
        output += path
        if i < paths.count - 1, !path.hasSuffix("/") {
            output += "/"
        }
    }
    
    return output
}
