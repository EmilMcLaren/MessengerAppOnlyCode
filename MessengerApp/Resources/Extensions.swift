//
//  Extensions.swift
//  MessengerApp
//
//  Created by Emil on 11.01.2023.
//

import Foundation
import UIKit

extension UIView {
    public var width: CGFloat {
        return frame.size.width
    }
    
    public var height: CGFloat {
        return frame.size.height
    }
    
    public var top: CGFloat {
        return frame.origin.y
    }
    
    public var buttom: CGFloat {
        return frame.size.height + frame.origin.y
    }
    
    public var left: CGFloat {
        return frame.origin.x
    }
    
    public var right: CGFloat {
        return frame.size.width + frame.origin.x
    }
}

/// notification when user log in
extension Notification.Name {
    static let didLogInNotification = Notification.Name("didLogInNotification")
}

































































