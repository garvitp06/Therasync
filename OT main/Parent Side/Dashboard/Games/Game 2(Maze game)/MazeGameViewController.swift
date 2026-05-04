//
//  MazeGameViewController.swift
//  MazeGame
//
//  Created by Alishri Poddar on 16/01/26.
//

import UIKit

class MazeGameViewController: UIViewController {

    // MARK: - Game Enums
    enum MazePattern: CaseIterable {
        case snake
        case cShape
        case stairs
        case mShape
        case valley
    }

    // MARK: - UI Elements
    private let backgroundView = ParentGradientView()
    private let mazeContainerView = UIView()
    
    private let startImageView = UIImageView() // Black Rabbit
    private let endImageView = UIImageView()   // Orange Carrot
    
    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    
    // Logic
    private var currentPattern: MazePattern = .snake
    private var mazePath: UIBezierPath?
    private var mazePoints: [CGPoint] = [] // NEW: Stores the exact corner points
    private var isGameActive = true
    
    // MARK: - Overlay Elements
    private let overlayView = UIView()
    private let resultLabel = UILabel()
    private let resultIcon = UIImageView()
    private let playAgainButton = UIButton(type: .system)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Hungry Bunny"
        
        setupNavigationBar()
        setupUI()
        setupOverlayUI()
        setupGestures()
        
        randomizeAndDraw()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        drawCurrentMaze()
    }

    // MARK: - Setup Navigation
    private func setupNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label, .font: UIFont.boldSystemFont(ofSize: 20)]
        navigationController?.navigationBar.tintColor = .label
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backTapped)
        )
    }
    
    @objc func backTapped() {
        if let nav = navigationController, nav.viewControllers.first != self {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

    // MARK: - Setup UI
    private func setupUI() {
        backgroundView.frame = view.bounds
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(backgroundView)
        view.sendSubviewToBack(backgroundView)
        
        mazeContainerView.backgroundColor = .clear
        mazeContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mazeContainerView)
        
        // Rabbit (Black)
        setupCharacter(imageView: startImageView, imageName: "hare.fill", color: .black)
        // Carrot (Orange)
        setupCharacter(imageView: endImageView, imageName: "carrot.fill", color: .systemOrange)
        
        mazeContainerView.addSubview(startImageView)
        mazeContainerView.addSubview(endImageView)
        
        NSLayoutConstraint.activate([
            mazeContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            mazeContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            mazeContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            mazeContainerView.heightAnchor.constraint(equalToConstant: 500)
        ])
    }
    
    private func setupOverlayUI() {
        overlayView.frame = view.bounds
        overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlayView.backgroundColor = UIColor.label.withAlphaComponent(0.0)
        overlayView.alpha = 0
        overlayView.isUserInteractionEnabled = false
        view.addSubview(overlayView)
        
        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = overlayView.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlayView.addSubview(blurView)
        
        resultIcon.translatesAutoresizingMaskIntoConstraints = false
        resultIcon.contentMode = .scaleAspectFit
        overlayView.addSubview(resultIcon)
        
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        resultLabel.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        resultLabel.textAlignment = .center
        resultLabel.textColor = .label
        overlayView.addSubview(resultLabel)
        
        playAgainButton.translatesAutoresizingMaskIntoConstraints = false
        playAgainButton.setTitle("Play Again", for: .normal)
        playAgainButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        playAgainButton.setTitleColor(.white, for: .normal)
        playAgainButton.backgroundColor = .systemBlue
        playAgainButton.layer.cornerRadius = 25
        playAgainButton.addTarget(self, action: #selector(resetGame), for: .touchUpInside)
        overlayView.addSubview(playAgainButton)
        
        NSLayoutConstraint.activate([
            resultIcon.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            resultIcon.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor, constant: -50),
            resultIcon.widthAnchor.constraint(equalToConstant: 120),
            resultIcon.heightAnchor.constraint(equalToConstant: 120),
            
            resultLabel.topAnchor.constraint(equalTo: resultIcon.bottomAnchor, constant: 20),
            resultLabel.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            
            playAgainButton.bottomAnchor.constraint(equalTo: overlayView.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            playAgainButton.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            playAgainButton.widthAnchor.constraint(equalToConstant: 200),
            playAgainButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupCharacter(imageView: UIImageView, imageName: String, color: UIColor) {
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .bold)
        imageView.image = UIImage(systemName: imageName, withConfiguration: config)
        imageView.tintColor = color
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    // MARK: - Maze Logic & Drawing
    
    private func randomizeAndDraw() {
        currentPattern = MazePattern.allCases.randomElement() ?? .snake
        drawCurrentMaze()
    }
    
    private func drawCurrentMaze() {
        trackLayer.removeFromSuperlayer()
        progressLayer.removeFromSuperlayer()
        mazePoints.removeAll() // Clear old points
        
        let w = mazeContainerView.bounds.width
        let h = mazeContainerView.bounds.height
        if w == 0 || h == 0 { return }
        
        let path = UIBezierPath()
        
        // --- DEFINE POINTS AND FILL ARRAY ---
        switch currentPattern {
        case .snake:
            mazePoints = [
                CGPoint(x: w * 0.1, y: h * 0.1),
                CGPoint(x: w * 0.9, y: h * 0.1),
                CGPoint(x: w * 0.9, y: h * 0.35),
                CGPoint(x: w * 0.2, y: h * 0.35),
                CGPoint(x: w * 0.2, y: h * 0.65),
                CGPoint(x: w * 0.9, y: h * 0.65),
                CGPoint(x: w * 0.9, y: h * 0.9)
            ]
            
        case .cShape:
            mazePoints = [
                CGPoint(x: w * 0.1, y: h * 0.1),
                CGPoint(x: w * 0.9, y: h * 0.1),
                CGPoint(x: w * 0.9, y: h * 0.9),
                CGPoint(x: w * 0.1, y: h * 0.9)
            ]
            
        case .stairs:
            mazePoints = [
                CGPoint(x: w * 0.1, y: h * 0.1),
                CGPoint(x: w * 0.4, y: h * 0.1),
                CGPoint(x: w * 0.4, y: h * 0.5),
                CGPoint(x: w * 0.6, y: h * 0.5),
                CGPoint(x: w * 0.6, y: h * 0.9),
                CGPoint(x: w * 0.9, y: h * 0.9)
            ]
            
        case .mShape:
            mazePoints = [
                CGPoint(x: w * 0.1, y: h * 0.9),
                CGPoint(x: w * 0.1, y: h * 0.1),
                CGPoint(x: w * 0.5, y: h * 0.5),
                CGPoint(x: w * 0.9, y: h * 0.1),
                CGPoint(x: w * 0.9, y: h * 0.9)
            ]
            
        case .valley:
            mazePoints = [
                CGPoint(x: w * 0.1, y: h * 0.1),
                CGPoint(x: w * 0.1, y: h * 0.8),
                CGPoint(x: w * 0.5, y: h * 0.5),
                CGPoint(x: w * 0.5, y: h * 0.8),
                CGPoint(x: w * 0.9, y: h * 0.8),
                CGPoint(x: w * 0.9, y: h * 0.1)
            ]
        }
        
        // --- DRAW PATH FROM POINTS ---
        guard let first = mazePoints.first else { return }
        path.move(to: first)
        for i in 1..<mazePoints.count {
            path.addLine(to: mazePoints[i])
        }
        
        self.mazePath = path
        
        // Track Layer
        trackLayer.path = path.cgPath
        trackLayer.strokeColor = UIColor(white: 0.6, alpha: 0.4).cgColor
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineWidth = 40
        trackLayer.lineCap = .round
        trackLayer.lineJoin = .round
        mazeContainerView.layer.insertSublayer(trackLayer, at: 0)
        
        // Progress Layer
        progressLayer.path = path.cgPath
        progressLayer.strokeColor = UIColor(red: 1.00, green: 0.75, blue: 0.27, alpha: 1.00).cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = 40
        progressLayer.lineCap = .round
        progressLayer.lineJoin = .round
        progressLayer.strokeEnd = 0.0
        progressLayer.shadowColor = UIColor.orange.cgColor
        progressLayer.shadowRadius = 10
        progressLayer.shadowOpacity = 0.8
        progressLayer.shadowOffset = .zero
        
        mazeContainerView.layer.insertSublayer(progressLayer, above: trackLayer)
        
        // Move Icons
        if let start = mazePoints.first, let end = mazePoints.last {
            startImageView.center = start
            endImageView.center = end
        }
    }
    
    // MARK: - Gesture Handling
    private func setupGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        mazeContainerView.addGestureRecognizer(panGesture)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard isGameActive else { return }
        let location = gesture.location(in: mazeContainerView)
        
        switch gesture.state {
        case .began:
            if distance(from: location, to: startImageView.center) > 70 {
                gesture.state = .cancelled
            }
        case .changed:
            handleTracing(at: location)
        case .ended, .cancelled:
            if progressLayer.strokeEnd >= 0.95 {
                gameWon()
            } else {
                resetProgress()
            }
        default: break
        }
    }
    
    private func handleTracing(at point: CGPoint) {
        guard let path = mazePath else { return }
        
        let hitTestWidth: CGFloat = 80.0
        let pathOutline = path.cgPath.copy(
            strokingWithWidth: hitTestWidth, lineCap: .round, lineJoin: .round, miterLimit: 10, transform: .identity
        )
        
        if pathOutline.contains(point) {
            calculatePolylineProgress(at: point)
        } else {
            gameLost()
        }
    }
    
    // MARK: - Precise Progress Calculation
    // This function calculates exactly how far along the multi-segment line the finger is.
    private func calculatePolylineProgress(at point: CGPoint) {
        guard mazePoints.count > 1 else { return }
        
        var totalLength: CGFloat = 0.0
        var segmentLengths: [CGFloat] = []
        
        // 1. Calculate length of each segment and total length
        for i in 0..<mazePoints.count - 1 {
            let len = distance(from: mazePoints[i], to: mazePoints[i+1])
            segmentLengths.append(len)
            totalLength += len
        }
        
        // 2. Find which segment contains the touch point (closest projection)
        var closestDist: CGFloat = .greatestFiniteMagnitude
        var activeSegmentIndex = 0
        var distanceAlongActiveSegment: CGFloat = 0.0
        var bestProjectedPoint = point
        
        for i in 0..<mazePoints.count - 1 {
            let start = mazePoints[i]
            let end = mazePoints[i+1]
            
            // Project point onto line segment
            let (projectedPoint, t) = project(point: point, ontoLineSegment: (start, end))
            
            let dist = distance(from: point, to: projectedPoint)
            if dist < closestDist {
                closestDist = dist
                activeSegmentIndex = i
                // How far along THIS segment are we?
                distanceAlongActiveSegment = distance(from: start, to: projectedPoint)
                bestProjectedPoint = projectedPoint
            }
        }
        
        // 3. Sum up lengths of all previous segments + current progress
        var currentDistance: CGFloat = 0.0
        for i in 0..<activeSegmentIndex {
            currentDistance += segmentLengths[i]
        }
        currentDistance += distanceAlongActiveSegment
        
        // 4. Convert to percentage
        let percent = max(0, min(1, currentDistance / totalLength))
        
        // Prevent cheating by fast swiping or jumping gaps
        if percent - progressLayer.strokeEnd > 0.15 {
            gameLost()
            return
        }
        
        // Update both progress line and rabbit position
        progressLayer.strokeEnd = percent
        startImageView.center = bestProjectedPoint
        
        // Check for win condition interactively
        if percent >= 0.98 {
            gameWon()
        }
    }
    
    // Helper: Project point onto a line segment (math)
    private func project(point: CGPoint, ontoLineSegment segment: (CGPoint, CGPoint)) -> (CGPoint, CGFloat) {
        let A = segment.0
        let B = segment.1
        let AP = CGPoint(x: point.x - A.x, y: point.y - A.y)
        let AB = CGPoint(x: B.x - A.x, y: B.y - A.y)
        
        let ab2 = AB.x*AB.x + AB.y*AB.y
        let ap_dot_ab = AP.x*AB.x + AP.y*AB.y
        
        // Normalized distance along the segment (0.0 to 1.0)
        var t = ap_dot_ab / ab2
        t = max(0, min(1, t)) // Clamp to segment
        
        let closest = CGPoint(x: A.x + AB.x * t, y: A.y + AB.y * t)
        return (closest, t)
    }
    
    // MARK: - Game State
    private func gameWon() {
        isGameActive = false
        progressLayer.strokeEnd = 1.0
        showOverlay(isWin: true)
    }
    
    private func gameLost() {
        isGameActive = false
        showOverlay(isWin: false)
    }
    
    @objc private func resetGame() {
        UIView.animate(withDuration: 0.3) {
            self.overlayView.alpha = 0
        } completion: { _ in
            self.overlayView.isUserInteractionEnabled = false
            self.randomizeAndDraw()
        }
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.toValue = 0
        animation.duration = 0.5
        progressLayer.add(animation, forKey: "reset")
        progressLayer.strokeEnd = 0
        isGameActive = true
    }
    
    private func resetProgress() {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.toValue = 0
        animation.duration = 0.5
        progressLayer.add(animation, forKey: "dim")
        progressLayer.strokeEnd = 0
        
        if let start = mazePoints.first {
            UIView.animate(withDuration: 0.5) {
                self.startImageView.center = start
            }
        }
    }
    
    private func showOverlay(isWin: Bool) {
        overlayView.isUserInteractionEnabled = true
        if isWin {
            overlayView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.8)
            resultLabel.text = "Yummy Carrot!"
            resultIcon.image = UIImage(systemName: "hand.thumbsup.fill")
            resultIcon.tintColor = .label
        } else {
            overlayView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.8)
            resultLabel.text = "Lost the Carrot!"
            resultIcon.image = UIImage(systemName: "xmark")
            resultIcon.tintColor = .label
        }
        playAgainButton.isHidden = false
        resultIcon.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [], animations: {
            self.resultIcon.transform = .identity
            self.overlayView.alpha = 1
        }, completion: nil)
    }
    
    private func distance(from p1: CGPoint, to p2: CGPoint) -> CGFloat {
        return hypot(p1.x - p2.x, p1.y - p2.y)
    }
}
