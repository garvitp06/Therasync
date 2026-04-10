//
//  GradientView.swift
//  OT main
//
//  Created by Garvit Pareek on 07/11/2025.
//

import UIKit

@IBDesignable
class GradientView: UIView {
    @IBInspectable var topColor: UIColor = UIColor.systemBlue // Adjusted for dark mode compatibility (from hardcoded #00B8FF)
    @IBInspectable var bottomColor: UIColor = UIColor.systemBackground

    override class var layerClass: AnyClass { CAGradientLayer.self }

    private var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateColors()
        gradientLayer.locations = [0, 1]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint   = CGPoint(x: 0.5, y: 1)
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
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
                self.updateColors()
            }
        }
    }

    private func updateColors() {
        gradientLayer.colors = [topColor.resolvedColor(with: traitCollection).cgColor, bottomColor.resolvedColor(with: traitCollection).cgColor]
    }
}
