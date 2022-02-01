//
//  UIKit.swift
//  Recorder
//
//  Created by Joe Helton on 1/31/22.
//

import Foundation
import UIKit

enum AppColor: UInt {
    
    case TintColor              = 0x349CD7
    case RecordingTintColor     = 0xD0021B
    case AcceptActionColor      = 0x3DD618
    case ControlColor           = 0x98A2B1
    case ControlColorDark       = 0x4A4A4A
    case ControlColorLight      = 0xD2D7DC
    case ControlDisabledColor   = 0x8D97A6
    case ControlAlternateColor  = 0x7D8692
    case TextColor              = 0x000000
    case HighlightedTextColor   = 0xFFFFFF
}

extension UIColor {
    
    class func appTintColor() -> UIColor {
        
        return UIColor(appColor: AppColor.TintColor)
    }
    
    class func appRecordingTintColor() -> UIColor {
        
        return UIColor(appColor: AppColor.RecordingTintColor)
    }
    
    class func appAcceptActionColor() -> UIColor {
        
        return UIColor(appColor: AppColor.AcceptActionColor)
    }
    
    class func appControlColor() -> UIColor {
        
        return UIColor(appColor: AppColor.ControlColor)
    }
    
    class func appControlColorDark() -> UIColor {
        
        return UIColor(appColor: AppColor.ControlColorDark)
    }
    
    class func appControlColorLight() -> UIColor {
        
        return UIColor(appColor: AppColor.ControlColorLight)
    }
    
    class func appControlDisabledColor() -> UIColor {
        
        return UIColor(appColor: AppColor.ControlDisabledColor)
    }
    
    class func appControlAlternateColor() -> UIColor {
        
        return UIColor(appColor: AppColor.ControlAlternateColor)
    }
    
    class func appTextColor() -> UIColor {
        
        return UIColor(appColor: AppColor.TextColor)
    }
    
    class func appHighlightedTextColor() -> UIColor {
        
        return UIColor(appColor: AppColor.HighlightedTextColor)
    }
    
    convenience init(appColor: AppColor) {
        
        self.init(
            red: CGFloat((appColor.rawValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((appColor.rawValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(appColor.rawValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    convenience init(rgbValue: UInt) {
        
        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
