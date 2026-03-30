import UIKit

final class ProgressArcView: UIView {

    private let bgLayer = CAShapeLayer()
    private let fgLayer = CAShapeLayer()

    var progress: CGFloat = 0.33 {
        didSet { animateProgress() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        drawArc()
    }

    private func setupLayers() {
        bgLayer.strokeColor = UIColor.lightGray.withAlphaComponent(0.4).cgColor
        bgLayer.lineWidth = 16
        bgLayer.fillColor = UIColor.clear.cgColor

        fgLayer.strokeColor = UIColor.systemGreen.cgColor
        fgLayer.lineWidth = 16
        fgLayer.fillColor = UIColor.clear.cgColor
        fgLayer.strokeEnd = 0

        layer.addSublayer(bgLayer)
        layer.addSublayer(fgLayer)
    }

    private func drawArc() {
        let center = CGPoint(x: bounds.midX, y: bounds.maxY)
        let radius = bounds.width / 2 - 10

        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: .pi,
            endAngle: 0,
            clockwise: true
        )

        bgLayer.path = path.cgPath
        fgLayer.path = path.cgPath
    }

    private func animateProgress() {
        let anim = CABasicAnimation(keyPath: "strokeEnd")
        anim.fromValue = 0
        anim.toValue = progress
        anim.duration = 1
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        fgLayer.strokeEnd = progress
        fgLayer.add(anim, forKey: "progress")
        fgLayer.lineCap = .round
        bgLayer.lineCap = .round

    }
}

