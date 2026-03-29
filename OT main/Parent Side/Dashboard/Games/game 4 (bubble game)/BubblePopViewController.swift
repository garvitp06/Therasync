import UIKit

class BubblePopViewController: UIViewController {
    
    // MARK: - Properties
    private var score = 0
    private var gameTimer: Timer?
    
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
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Bubbly"
        
        setupBackground()
        setupNavBar()
        setupScoreLabel()
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
        // Add the gradient view and pin it to the edges
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
        appearance.configureWithTransparentBackground() // Transparent looks better with gradients
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
    
    private func setupTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleScreenTap(_:)))
        view.addGestureRecognizer(tap)
    }
    
    private func disableSwipeToBack() {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    // MARK: - Game Logic
    private func startGame() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.createBubble()
        }
    }
    
    private func createBubble() {
        let size: CGFloat = CGFloat.random(in: 80...120)
        let xPosition = CGFloat.random(in: 20...(view.frame.width - size - 20))
        let startY = view.frame.height + size
        
        let bubble = UIButton(type: .custom)
        bubble.frame = CGRect(x: xPosition, y: startY, width: size, height: size)
        
        // Random pastel colors look great over gradients
        let colors: [UIColor] = [.systemPink, .systemIndigo, .systemTeal, .systemPurple, .systemOrange]
        bubble.backgroundColor = colors.randomElement()?.withAlphaComponent(0.6)
        
        bubble.layer.cornerRadius = size / 2
        bubble.layer.borderWidth = 3
        bubble.layer.borderColor = UIColor.white.cgColor
        bubble.isUserInteractionEnabled = false
        
        view.addSubview(bubble)
        
        let duration = Double.random(in: 4.0...6.0)
        UIView.animate(withDuration: duration, delay: 0, options: [.curveLinear, .allowUserInteraction], animations: {
            bubble.frame.origin.y = -size
        }) { _ in
            bubble.removeFromSuperview()
        }
    }
    
    @objc private func handleScreenTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        
        for subview in view.subviews {
            if let bubble = subview as? UIButton {
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
        score += 1
        scoreLabel.text = "Bubbles: \(score)"
        
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        
        showReward(at: bubble.layer.presentation()?.position ?? bubble.center)
        
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
