//
//  segGRADIENT.swift
//  OT main
//
//  Created by Garvit Pareek on 16/11/2025.
//

import UIKit

// @IBDesignable lets you see your gradient live in the XIB file
@IBDesignable
class segGradientView: UIView {

    // This will be the color at the very top (e.g., blue or yellow)
    @IBInspectable var topColor: UIColor = UIColor.blue {
        didSet { updateColors() }
    }
    
    // This will be the color it fades into (white, in your case)
    @IBInspectable var bottomColor: UIColor = UIColor.white {
        didSet { updateColors() }
    }
    
    // This controls where the fade finishes (0.5 = 50% down the screen)
    @IBInspectable var middleStop: Double = 0.4 {
        didSet { updateLocations() }
    }

    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradient()
    }

    private func setupGradient() {
        layer.insertSublayer(gradientLayer, at: 0)
        updateColors()
        updateLocations()
    }

    private func updateColors() {
        // The gradient will be [TopColor, BottomColor, BottomColor]
        // This makes it fade from top to middle, then stay solid
        gradientLayer.colors = [topColor.cgColor, bottomColor.cgColor, bottomColor.cgColor]
    }
    
    private func updateLocations() {
        // The locations match the colors.
        // 0.0 = Top
        // middleStop (0.5) = Middle
        // 1.0 = Bottom
        gradientLayer.locations = [0.0, NSNumber(value: middleStop), 1.0]
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Ensure the gradient layer's frame always matches the view's bounds
        gradientLayer.frame = self.bounds
    }
}
