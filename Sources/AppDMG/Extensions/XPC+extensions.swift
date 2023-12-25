//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/12/20.
//

import Foundation

public class AppDMGXPCCompatible {
    @objc(_TtCC6AppDMG19AppDMGXPCCompatible8Appendix)
    public class Appendix: NSObject, NSSecureCoding {
        public var value: AppDMG.Appendix
        
        public init(value: AppDMG.Appendix) {
            self.value = value
        }
        
        // NSSecureCoding
        required public init?(coder: NSCoder) {
            guard let name = coder.decodeObject(of: NSString.self, forKey: "name") as String?,
                  let destination = coder.decodeObject(of: NSURL.self, forKey: "destination") as URL?,
                  let type = AppDMG.Appendix.AppendixType(rawValue: coder.decodeInteger(forKey: "type")) else {
                return nil
            }
            
            let positionX = coder.decodeInteger(forKey: "positionX") // 解码 CGPoint 的 x 坐标
            let positionY = coder.decodeInteger(forKey: "positionY") // 解码 CGPoint 的 y 坐标
            
            let position = CGPoint(x: positionX, y: positionY) // 重构 CGPoint
            self.value = AppDMG.Appendix(name: name, destination: destination, type: type, position: position)
        }
        
        public func encode(with aCoder: NSCoder) {
            aCoder.encode(self.value.name, forKey: "name")
            aCoder.encode(self.value.destination, forKey: "destination")
            aCoder.encode(self.value.type.rawValue, forKey: "type")
            aCoder.encode(Int(self.value.position.x), forKey: "positionX") // 编码 CGPoint 的 x 坐标
            aCoder.encode(Int(self.value.position.y), forKey: "positionY") // 编码 CGPoint 的 y 坐标
        }
        public static var supportsSecureCoding: Bool { true }
        
    }
    
    @objc(_TtCC6AppDMG19AppDMGXPCCompatible14CodesignOption)
    public class CodesignOption: NSObject, NSSecureCoding {
        public var value: AppDMG.CodesignOption
        
        public init(value: AppDMG.CodesignOption) {
            self.value = value
        }
        
        // NSSecureCoding
        
        required public init?(coder: NSCoder) {
            let identity = coder.decodeObject(of: NSString.self, forKey: "identity") as? String
            let skip = coder.decodeBool(forKey: "skip")
            
            if skip {
                if let identity = identity {
                    self.value = .manually(identity)
                } else {
                    self.value = .auto
                }
            } else {
                self.value = .skip
            }
            
        }
        
        public func encode(with aCoder: NSCoder) {
            switch self.value {
                case .auto:
                    aCoder.encode(nil, forKey: "identity")
                    aCoder.encode(false, forKey: "skip")
                case .manually(let identity):
                    aCoder.encode(identity, forKey: "identity")
                    aCoder.encode(false, forKey: "skip")
                case .skip:
                    aCoder.encode(nil, forKey: "identity")
                    aCoder.encode(true, forKey: "skip")
            }
        }
        
        public static var supportsSecureCoding: Bool { true }
        
    }
    
    @objc(_TtCC6AppDMG19AppDMGXPCCompatible13DMGIconOption)
    public class DMGIconOption: NSObject, NSSecureCoding {
        public var value: AppDMG.DMGIconOption
        
        public init(value: AppDMG.DMGIconOption) {
            self.value = value
        }
        
        required public init?(coder: NSCoder) {
            let url = coder.decodeObject(of: NSURL.self, forKey: "url") as? URL
            let skip = coder.decodeBool(forKey: "skip")
            
            if skip {
                if let url = url {
                    self.value = .manually(url)
                } else {
                    self.value = .default
                }
            } else {
                self.value = .skip
            }
            
        }
        
        public func encode(with aCoder: NSCoder) {
            switch self.value {
                case .default:
                    aCoder.encode(nil, forKey: "url")
                    aCoder.encode(false, forKey: "skip")
                case .manually(let url):
                    aCoder.encode(url, forKey: "url")
                    aCoder.encode(false, forKey: "skip")
                case .skip:
                    aCoder.encode(nil, forKey: "identity")
                    aCoder.encode(true, forKey: "skip")
            }
        }
        
        public static var supportsSecureCoding: Bool { true }
    }
    
    @objc(_TtCC6AppDMG19AppDMGXPCCompatible15CreateDMGStatus)
    public class CreateDMGStatus: NSObject, NSSecureCoding {
        
        private var rawValue: AppDMG.CreateDMGStatus.RawValue
        
        public var value: AppDMG.CreateDMGStatus {
            get {
                AppDMG.CreateDMGStatus(rawValue: rawValue) ?? .waiting
            }
            
            set {
                self.rawValue = newValue.rawValue
            }
        }
        
        public init(value: AppDMG.CreateDMGStatus) {
            self.rawValue = value.rawValue
        }
        
        required public init?(coder: NSCoder) {
            let rawValue = coder.decodeInteger(forKey: "rawValue")
            self.rawValue = rawValue
        }
        
        public func encode(with aCoder: NSCoder) {
            aCoder.encode(rawValue, forKey: "rawValue")
        }
        public static var supportsSecureCoding: Bool { true }
    }
}
