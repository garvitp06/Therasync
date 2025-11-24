//
//  GradientView.swift
//  OT main
//
//  Created by Garvit Pareek on 07/11/2025.
//

import UIKit

@IBDesignable
class GradientView: UIView {
    @IBInspectable var topColor: UIColor = UIColor(red: 0.00, green: 0.48, blue: 1.00, alpha: 1) // #00B8FF
    @IBInspectable var bottomColor: UIColor = UIColor(white: 0.95, alpha: 1)     // light gray

    override class var layerClass: AnyClass { CAGradientLayer.self }

    private var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.colors = [topColor.cgColor, bottomColor.cgColor]
        gradientLayer.locations = [0, 1]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint   = CGPoint(x: 0.5, y: 1)
    }
}
