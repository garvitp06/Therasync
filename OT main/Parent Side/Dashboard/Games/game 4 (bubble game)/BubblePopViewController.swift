import UIKit

class BubblePopViewController: UIViewController {
    
    // MARK: - Properties
    private var score = 0
    private var gameTimer: Timer?
    private var isGameOver = false
    
    // MARK: - UI Elements
    // Use the existing GradientView from your project
    private let gradientView = ParentGradientView()
    
    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.text = "Bubbles: 0"
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .label // Adapts to light/dark mode over the gradient
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: Game Over UI
    private let gameOverContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .center
        stack.isHidden = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let gameOverLabel: UILabel = {
        let label = UILabel()
        label.text = "Game Over!"
        label.font = .systemFont(ofSize: 40, weight: .heavy)
        label.textColor = .systemRed
        return label
    }()
    
    private lazy var playAgainButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Play Again", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 25
        button.contentEdgeInsets = UIEdgeInsets(top: 15, left: 30, bottom: 15, right: 30)
        button.addTarget(self, action: #selector(handlePlayAgain), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Bubbly"
        
        setupBackground()
        setupNavBar()
        setupScoreLabel()
        setupGameOverUI()
        setupTapGesture()
        disableSwipeToBack()
        
        startGame()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        gameTimer?.invalidate()
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    // MARK: - Setup
    private func setupBackground() {
        view.addSubview(gradientView)
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            gradientView.topAnchor.constraint(equalTo: view.topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupNavBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .systemBlue
    }
    
    private func setupScoreLabel() {
        view.addSubview(scoreLabel)
        NSLayoutConstraint.activate([
            scoreLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            scoreLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupGameOverUI() {
        view.addSubview(gameOverContainer)
        gameOverContainer.addArrangedSubview(gameOverLabel)
        gameOverContainer.addArrangedSubview(playAgainButton)
        
        NSLayoutConstraint.activate([
            gameOverContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            gameOverContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleScreenTap(_:)))
        view.addGestureRecognizer(tap)
    }
    
    private func disableSwipeToBack() {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    // MARK: - Game Logic
    private func startGame() {
        isGameOver = false
        score = 0
        scoreLabel.text = "Bubbles: 0"
        gameOverContainer.isHidden = true
        
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.createBubble()
        }
    }
    
    private func triggerGameOver() {
        guard !isGameOver else { return } // Prevent multiple triggers
        isGameOver = true
        
        // Stop spawning bubbles
        gameTimer?.invalidate()
        
        // Vibrate to indicate failure
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        // Remove remaining bubbles on screen
        for subview in view.subviews {
            if let bubble = subview as? UIButton, bubble.tag == 0 || bubble.tag == 1 {
                bubble.layer.removeAllAnimations()
                bubble.removeFromSuperview()
            }
        }
        
        // Show Game Over UI
        gameOverContainer.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        gameOverContainer.alpha = 0
        gameOverContainer.isHidden = false
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            self.gameOverContainer.transform = .identity
            self.gameOverContainer.alpha = 1
        })
    }
    
    @objc private func handlePlayAgain() {
        startGame()
    }
    
    private func createBubble() {
        let size: CGFloat = CGFloat.random(in: 80...120)
        let xPosition = CGFloat.random(in: 20...(view.frame.width - size - 20))
        let startY = view.frame.height + size
        
        let bubble = UIButton(type: .custom)
        bubble.frame = CGRect(x: xPosition, y: startY, width: size, height: size)
        
        let colors: [UIColor] = [.systemPink, .systemIndigo, .systemTeal, .systemPurple, .systemOrange]
        bubble.backgroundColor = colors.randomElement()?.withAlphaComponent(0.6)
        
        bubble.layer.cornerRadius = size / 2
        bubble.layer.borderWidth = 3
        bubble.layer.borderColor = UIColor.systemBackground.cgColor
        bubble.isUserInteractionEnabled = false
        bubble.tag = 0 // Tag 0 means it has NOT been popped
        
        view.addSubview(bubble)
        
        let duration = Double.random(in: 4.0...6.0)
        
        UIView.animate(withDuration: duration, delay: 0, options: [.curveLinear, .allowUserInteraction], animations: {
            bubble.frame.origin.y = -size
        }) { [weak self] _ in
            guard let self = self else { return }
            
            // If the animation finished and the bubble hasn't been popped, trigger game over!
            if bubble.tag == 0 && !self.isGameOver {
                self.triggerGameOver()
            }
            
            bubble.removeFromSuperview()
        }
    }
    
    @objc private func handleScreenTap(_ gesture: UITapGestureRecognizer) {
        guard !isGameOver else { return } // Don't allow popping after game over
        
        let location = gesture.location(in: view)
        
        for subview in view.subviews {
            if let bubble = subview as? UIButton, bubble.tag == 0 {
                if let presentationFrame = bubble.layer.presentation()?.frame {
                    if presentationFrame.contains(location) {
                        popBubble(bubble)
                        break
                    }
                }
            }
        }
    }
    
    private func popBubble(_ bubble: UIButton) {
        bubble.tag = 1 // Mark as popped so it doesn't trigger Game Over
        
        score += 1
        scoreLabel.text = "Bubbles: \(score)"
        
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        
        showReward(at: bubble.layer.presentation()?.position ?? bubble.center)
        
        // Overwrite the floating animation with a popping animation
        UIView.animate(withDuration: 0.1, animations: {
            bubble.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            bubble.alpha = 0
        }) { _ in
            bubble.removeFromSuperview()
        }
    }
    
    private func showReward(at point: CGPoint) {
        let star = UILabel()
        star.text = ["🌟", "✨", "🎈", "🌈"].randomElement()
        star.font = .systemFont(ofSize: 50)
        star.center = point
        view.addSubview(star)
        
        UIView.animate(withDuration: 0.8, animations: {
            star.center.y -= 120
            star.alpha = 0
        }) { _ in
            star.removeFromSuperview()
        }
    }
}
