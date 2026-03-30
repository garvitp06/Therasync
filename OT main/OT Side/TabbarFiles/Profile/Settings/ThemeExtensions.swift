//
//  ThemeExtensions.swift
//  OT main
//
//  Created by Alishri Poddar on 16/01/26.
//




import UIKit

// Prefixed with 'ot' to avoid conflicts with parent side
extension UIColor {
    
    // Text: Black in Light Mode, White in Dark Mode
    static var otDynamicLabel: UIColor {
        return UIColor { (traitCollection) -> UIColor in
            return traitCollection.userInterfaceStyle == .dark ? .white : .label
        }
    }
    
    // Cards: White in Light Mode, Dark Grey in Dark Mode
    static var otDynamicCard: UIColor {
        return UIColor { (traitCollection) -> UIColor in
            return traitCollection.userInterfaceStyle == .dark ? .secondarySystemGroupedBackground : .white
        }
    }
}
