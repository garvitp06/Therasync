//
//  PatternGameViewController.swift
//  PatternGame
//
//  Created by Alishri Poddar on 16/01/26.
//

import UIKit

class PatternGameViewController: UIViewController {

    // MARK: - Game Data
    enum ShapeType: String, CaseIterable {
        case circle = "circle.fill"
        case square = "square.fill"
        case star = "star.fill"
        case triangle = "triangle.fill"
        case hexagon = "hexagon.fill"
        case diamond = "diamond.fill"
    }
    
    struct PatternItem {
        let type: ShapeType
        let color: UIColor
    }
    
    // Game State
    private var currentLevel = 1
    private let maxLevels = 3
    private var score = 0 // Levels completed successfully
    
    private var currentPattern: [PatternItem] = []
    private var correctItem: PatternItem?
    
    // MARK: - UI Elements
    private let backgroundView = ParentGradientView()
    
    private let levelLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Level 1"
        lbl.font = .systemFont(ofSize: 18, weight: .semibold)
        lbl.textColor = .darkGray
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Complete the pattern!"
        lbl.font = .systemFont(ofSize: 28, weight: .bold)
        lbl.textColor = .black
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    // Holds the pattern row
    private let patternContainerView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 15
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // Holds the answer buttons
    private let optionsContainerView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 30
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // MARK: - Overlay Elements
    private let overlayView = UIView()
    private let resultLabel = UILabel()
    private let starsStackView = UIStackView() // To hold the 3 stars
    private let playAgainButton = UIButton(type: .system)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        setupOverlayUI()
        startLevel()
    }
    
    // MARK: - Game Logic
    
    private func startLevel() {
        // Reset Views
        patternContainerView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        optionsContainerView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        levelLabel.text = "Level \(currentLevel) of \(maxLevels)"
        
        // Generate Logic based on Difficulty
        generatePatternForLevel(currentLevel)
        
        // Build Pattern UI
        for item in currentPattern {
            let iv = createShapeView(item: item)
            patternContainerView.addArrangedSubview(iv)
        }
        
        // Add Empty Slot
        let emptySlot = createEmptySlot()
        patternContainerView.addArrangedSubview(emptySlot)
        
        // Build Options (1 Correct, 1 Wrong)
        setupOptions()
        
        // Hide overlay if it was showing
        overlayView.alpha = 0
        overlayView.isUserInteractionEnabled = false
    }
    
    private func generatePatternForLevel(_ level: Int) {
        let shapes = ShapeType.allCases.shuffled()
        
        // Define some nice colors
        let colors = [
            UIColor(red: 1.00, green: 0.42, blue: 0.42, alpha: 1.0), // Red
            UIColor(red: 0.26, green: 0.52, blue: 0.96, alpha: 1.0), // Blue
            UIColor(red: 0.20, green: 0.80, blue: 0.40, alpha: 1.0), // Green
            UIColor(red: 1.00, green: 0.80, blue: 0.20, alpha: 1.0)  // Yellow
        ]
        
        let itemA = PatternItem(type: shapes[0], color: colors[0])
        let itemB = PatternItem(type: shapes[1], color: colors[1])
        let itemC = PatternItem(type: shapes[2], color: colors[2])
        
        switch level {
        case 1:
            // Easy: A - B - A - [B]
            currentPattern = [itemA, itemB, itemA]
            correctItem = itemB
            
        case 2:
            // Medium: A - A - B - [B] (Double repetition)
            currentPattern = [itemA, itemA, itemB]
            correctItem = itemB
            
        case 3:
            // Hard: A - B - C - [A] (Sequence loop)
            currentPattern = [itemA, itemB, itemC]
            correctItem = itemA
            
        default:
            // Fallback
            currentPattern = [itemA, itemB, itemA]
            correctItem = itemB
        }
    }
    
    private func setupOptions() {
        guard let correct = correctItem else { return }
        
        // Pick a wrong item different from correct
        let shapes = ShapeType.allCases.filter { $0 != correct.type }
        let randomShape = shapes.randomElement()!
        let randomColor = UIColor.systemPurple // Distinct color for wrong answer
        
        let wrongItem = PatternItem(type: randomShape, color: randomColor)
        
        var options = [correct, wrongItem]
        options.shuffle()
        
        for option in options {
            let btn = createOptionButton(item: option)
            optionsContainerView.addArrangedSubview(btn)
        }
    }
    
    private func checkAnswer(selectedItem: PatternItem) {
        guard let correct = correctItem else { return }
        
        if selectedItem.type == correct.type {
            // Correct!
            handleLevelSuccess(correctItem: correct)
        } else {
            // Wrong! Game Over immediately
            showFinalFeedback()
        }
    }
    
    private func handleLevelSuccess(correctItem: PatternItem) {
        // 1. Fill the slot visually
        if let emptySlot = patternContainerView.arrangedSubviews.last as? UILabel {
            emptySlot.text = ""
            emptySlot.backgroundColor = .clear
            emptySlot.layer.borderWidth = 0
            
            let successView = createShapeView(item: correctItem)
            successView.frame = emptySlot.bounds
            successView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            emptySlot.addSubview(successView)
            
            successView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            UIView.animate(withDuration: 0.3) {
                successView.transform = .identity
            }
        }
        
        // 2. Play Wave
        playWaveAnimation {
            // 3. Logic: Next Level or Finish
            self.score += 1
            
            if self.currentLevel < self.maxLevels {
                // Go to next level
                self.currentLevel += 1
                // Small delay before next level
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.startLevel()
                }
            } else {
                // All levels done!
                self.showFinalFeedback()
            }
        }
    }
    
    private func playWaveAnimation(completion: @escaping () -> Void) {
        for (index, view) in patternContainerView.arrangedSubviews.enumerated() {
            let delay = Double(index) * 0.1
            UIView.animateKeyframes(withDuration: 0.8, delay: delay, options: [], animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                    view.transform = CGAffineTransform(translationX: 0, y: -20)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                    view.transform = .identity
                }
            }) { _ in
                if index == self.patternContainerView.arrangedSubviews.count - 1 {
                    completion()
                }
            }
        }
    }
    
    // MARK: - UI Helper Functions (Shapes)
    
    private func createShapeView(item: PatternItem) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .bold)
        iv.image = UIImage(systemName: item.type.rawValue, withConfiguration: config)
        iv.tintColor = item.color
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(iv)
        NSLayoutConstraint.activate([
            iv.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iv.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iv.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 0.8),
            iv.heightAnchor.constraint(equalTo: container.heightAnchor, multiplier: 0.8)
        ])
        return container
    }
    
    private func createEmptySlot() -> UILabel {
        let lbl = UILabel()
        lbl.text = "?"
        lbl.font = .systemFont(ofSize: 40, weight: .bold)
        lbl.textColor = .lightGray
        lbl.textAlignment = .center
        lbl.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        lbl.layer.cornerRadius = 15
        lbl.layer.borderWidth = 2
        lbl.layer.borderColor = UIColor.lightGray.cgColor
        lbl.clipsToBounds = true
        return lbl
    }
    
    private func createOptionButton(item: PatternItem) -> UIButton {
        let btn = UIButton(type: .custom)
        let config = UIImage.SymbolConfiguration(pointSize: 50, weight: .bold)
        btn.setImage(UIImage(systemName: item.type.rawValue, withConfiguration: config), for: .normal)
        btn.tintColor = item.color
        btn.backgroundColor = .white
        btn.layer.cornerRadius = 20
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.1
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.layer.shadowRadius = 6
        
        btn.addAction(UIAction { [weak self] _ in
            self?.checkAnswer(selectedItem: item)
        }, for: .touchUpInside)
        
        return btn
    }

    // MARK: - Setup UI & Nav
    private func setupNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.black, .font: UIFont.boldSystemFont(ofSize: 20)]
        title = "Sequenco"
        
        navigationController?.navigationBar.tintColor = .black
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
    }
    
    @objc func backTapped() {
        if let nav = navigationController, nav.viewControllers.first != self {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

    private func setupUI() {
        backgroundView.frame = view.bounds
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(backgroundView)
        view.sendSubviewToBack(backgroundView)
        
        view.addSubview(levelLabel)
        view.addSubview(titleLabel)
        view.addSubview(patternContainerView)
        view.addSubview(optionsContainerView)
        
        NSLayoutConstraint.activate([
            levelLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            levelLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: levelLabel.bottomAnchor, constant: 10),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            patternContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -80),
            patternContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            patternContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            patternContainerView.heightAnchor.constraint(equalToConstant: 80),
            
            optionsContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),
            optionsContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            optionsContainerView.widthAnchor.constraint(equalToConstant: 240),
            optionsContainerView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    // MARK: - Final Feedback Logic
    
    private func setupOverlayUI() {
        overlayView.frame = view.bounds
        overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.0)
        overlayView.alpha = 0
        overlayView.isUserInteractionEnabled = false
        view.addSubview(overlayView)
        
        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = overlayView.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlayView.addSubview(blurView)
        
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        resultLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        resultLabel.textAlignment = .center
        resultLabel.textColor = .black
        overlayView.addSubview(resultLabel)
        
        // Stars Stack
        starsStackView.axis = .horizontal
        starsStackView.distribution = .fillEqually
        starsStackView.spacing = 10
        starsStackView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.addSubview(starsStackView)
        
        playAgainButton.translatesAutoresizingMaskIntoConstraints = false
        playAgainButton.setTitle("Play Again", for: .normal)
        playAgainButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        playAgainButton.setTitleColor(.white, for: .normal)
        playAgainButton.backgroundColor = .systemBlue
        playAgainButton.layer.cornerRadius = 25
        playAgainButton.addTarget(self, action: #selector(resetGame), for: .touchUpInside)
        overlayView.addSubview(playAgainButton)
        
        NSLayoutConstraint.activate([
            resultLabel.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor, constant: -80),
            resultLabel.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            
            starsStackView.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 20),
            starsStackView.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            starsStackView.heightAnchor.constraint(equalToConstant: 60),
            starsStackView.widthAnchor.constraint(equalToConstant: 200),
            
            playAgainButton.bottomAnchor.constraint(equalTo: overlayView.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            playAgainButton.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            playAgainButton.widthAnchor.constraint(equalToConstant: 200),
            playAgainButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func showFinalFeedback() {
        overlayView.isUserInteractionEnabled = true
        
        // 1. Text Feedback
        if score == 3 {
            resultLabel.text = "Amazing Work!"
            overlayView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.8)
        } else if score > 0 {
            resultLabel.text = "Good Job!"
            overlayView.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.8)
        } else {
            resultLabel.text = "Keep Trying!"
            overlayView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.8)
        }
        
        // 2. Star Feedback
        starsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for i in 1...3 {
            let starIV = UIImageView()
            starIV.contentMode = .scaleAspectFit
            
            // Gold star if level passed, Gray if not
            if i <= score {
                starIV.image = UIImage(systemName: "star.fill")
                starIV.tintColor = .systemYellow
            } else {
                starIV.image = UIImage(systemName: "star")
                starIV.tintColor = .gray
            }
            starsStackView.addArrangedSubview(starIV)
        }
        
        // 3. Bubbling/Balloon Animation if Score is 3
        if score == 3 {
            createBalloonConfetti()
        }
        
        // Fade in
        UIView.animate(withDuration: 0.5) {
            self.overlayView.alpha = 1
        }
        
        // Pop stars animation
        starsStackView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        UIView.animate(withDuration: 0.5, delay: 0.2, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [], animations: {
            self.starsStackView.transform = .identity
        }, completion: nil)
    }
    
    // Creates bubbles/balloons rising up
    private func createBalloonConfetti() {
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: view.frame.width / 2, y: view.frame.height + 50)
        emitter.emitterSize = CGSize(width: view.frame.width, height: 20)
        emitter.emitterShape = .line
        
        let cell = CAEmitterCell()
        // We can use a circle symbol as a "balloon" or "bubble"
        let bubbleImage = UIImage(systemName: "circle.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal)
        
        cell.contents = bubbleImage?.cgImage
        cell.birthRate = 10
        cell.lifetime = 5.0
        cell.velocity = -150 // Moving UP
        cell.velocityRange = 50
        cell.scale = 0.5
        cell.scaleRange = 0.3
        cell.alphaSpeed = -0.1
        cell.color = UIColor(white: 1.0, alpha: 0.7).cgColor
        
        // Make them wobble slightly
        cell.emissionRange = .pi / 4
        
        emitter.emitterCells = [cell]
        overlayView.layer.addSublayer(emitter)
    }
    
    @objc private func resetGame() {
        // Remove confetti layer if exists
        overlayView.layer.sublayers?.compactMap { $0 as? CAEmitterLayer }.forEach { $0.removeFromSuperlayer() }
        
        UIView.animate(withDuration: 0.3) {
            self.overlayView.alpha = 0
        } completion: { _ in
            self.overlayView.isUserInteractionEnabled = false
            self.currentLevel = 1
            self.score = 0
            self.startLevel()
        }
    }
}
