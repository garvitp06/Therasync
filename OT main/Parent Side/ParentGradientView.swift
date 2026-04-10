//
//  GradientView.swift
//  OT main
//
//  Created by Garvit Pareek on 19/12/2025.
//
import UIKit

class ParentGradientView: UIView {
    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateGradient()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTraitTracking()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTraitTracking()
    }

    private func setupTraitTracking() {
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
                self.updateGradient()
            }
        }
    }

    private func updateGradient() {
        guard let gradientLayer = layer as? CAGradientLayer else { return }
        
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        if isDarkMode {
            // DARK MODE: Using 0-255 RGB values
            gradientLayer.colors = [
                UIColor(r: 31, g: 31, b: 46).cgColor,  // Deep Navy
                UIColor(r: 13, g: 13, b: 13).cgColor   // Near Black
            ]
        } else {
            // LIGHT MODE: Using 0-255 RGB values (Figma: #FFC045 and #F5F5F5)
            gradientLayer.colors = [
                UIColor(r: 255, g: 166, b: 0).cgColor, // Vibrant Orange-Yellow
                UIColor(r: 230, g: 230, b: 230).cgColor // Light Grey
            ]
        }
        
        gradientLayer.startPoint = CGPoint(x: 0.4, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.4, y: 1)
        gradientLayer.locations = [0.0, 0.4]
    }
}
extension UIColor {
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1.0) {
        self.init(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: a)
    }
}
