import UIKit
import AVFoundation

class MemoryGameViewController: UIViewController {

    // MARK: - Game Logic Properties
    private var sequence: [Int] = []
    private var inputIndex: Int = 0
    private var isPlayerTurn = false
    private var isGameActive = true
    private let maxLevel = 7
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)
    
    private let tileColors: [UIColor] = [
        UIColor(red: 0.68, green: 0.82, blue: 0.95, alpha: 1.0),
        UIColor(red: 0.95, green: 0.72, blue: 0.72, alpha: 1.0),
        UIColor(red: 0.75, green: 0.90, blue: 0.80, alpha: 1.0),
        UIColor(red: 0.98, green: 0.92, blue: 0.75, alpha: 1.0),
        UIColor(red: 0.90, green: 0.80, blue: 0.95, alpha: 1.0),
        UIColor(red: 1.00, green: 0.85, blue: 0.75, alpha: 1.0)
    ]
    
    // MARK: - UI Components
    private let gradientView = ParentGradientView()

    private let statusLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Press Start to Play"
        lbl.font = .systemFont(ofSize: 24, weight: .semibold)
        lbl.textColor = .dynamicLabel
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let gridStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical; stack.distribution = .fillEqually; stack.spacing = 25
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let startButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Start Game", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 22, weight: .bold)
        btn.backgroundColor = UIColor(red: 0.45, green: 0.70, blue: 0.90, alpha: 1.0)
        btn.setTitleColor(.white, for: .normal); btn.layer.cornerRadius = 30
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private var tileButtons: [UIButton] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        createGrid()
        setupNavigationBar()
        
        NotificationCenter.default.addObserver(self, selector: #selector(applyTheme), name: NSNotification.Name("AppThemeChanged"), object: nil)
        applyTheme()
        
        startButton.addTarget(self, action: #selector(startGame), for: .touchUpInside)
        hapticGenerator.prepare()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup
    private func setupUI() {
        view.addSubview(gradientView)
        gradientView.frame = view.bounds
        
        [statusLabel, gridStackView, startButton].forEach { view.addSubview($0) }
        
        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: safe.topAnchor, constant: 15),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            startButton.bottomAnchor.constraint(equalTo: safe.bottomAnchor, constant: -25),
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.widthAnchor.constraint(equalToConstant: 220),
            startButton.heightAnchor.constraint(equalToConstant: 60),

            gridStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            gridStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -10),
            gridStackView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.75),
            gridStackView.topAnchor.constraint(greaterThanOrEqualTo: statusLabel.bottomAnchor, constant: 10),
            gridStackView.bottomAnchor.constraint(lessThanOrEqualTo: startButton.topAnchor, constant: -10)
        ])
    }

    private func createGrid() {
        gridStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        tileButtons.removeAll()
        let spacingValue: CGFloat = view.frame.height < 600 ? 15 : 25
        gridStackView.spacing = spacingValue
        
        var tag = 0
        for _ in 0..<3 {
            let row = UIStackView()
            row.axis = .horizontal; row.distribution = .fillEqually; row.spacing = spacingValue
            for _ in 0..<2 {
                let btn = UIButton()
                btn.backgroundColor = tileColors[tag]
                btn.layer.cornerRadius = 20
                btn.tag = tag
                btn.addTarget(self, action: #selector(tileTapped), for: .touchUpInside)
                btn.translatesAutoresizingMaskIntoConstraints = false
                btn.heightAnchor.constraint(equalTo: btn.widthAnchor).isActive = true
                tileButtons.append(btn)
                row.addArrangedSubview(btn)
                tag += 1
            }
            gridStackView.addArrangedSubview(row)
        }
    }

    private func setupNavigationBar() {
        title = "Memorizo"
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.font: UIFont.systemFont(ofSize: 22, weight: .bold)]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    // MARK: - Theme Logic
    @objc private func applyTheme() {
        let isHighContrast = UserDefaults.standard.bool(forKey: "High Contrast")
        let isDarkMode = UserDefaults.standard.bool(forKey: "Dark Mode")
        let color: UIColor = isDarkMode ? .white : .black
        
        DispatchQueue.main.async {
            if isHighContrast {
                self.gradientView.isHidden = true
                self.view.backgroundColor = isDarkMode ? .black : .white
            } else {
                self.gradientView.isHidden = false
            }

            self.tileButtons.forEach {
                if isHighContrast {
                    $0.layer.borderWidth = 6
                    $0.layer.borderColor = isDarkMode ? UIColor.white.cgColor : UIColor.black.cgColor
                } else {
                    $0.layer.borderWidth = 4
                    $0.layer.borderColor = isDarkMode ? UIColor.darkGray.cgColor : UIColor.white.cgColor
                }
            }
            
            self.statusLabel.textColor = .dynamicLabel
            self.navigationController?.navigationBar.tintColor = color
            
            // Re-apply title color in navigation bar
            let appearance = self.navigationController?.navigationBar.standardAppearance
            appearance?.titleTextAttributes = [
                .font: UIFont.systemFont(ofSize: 22, weight: .bold),
                .foregroundColor: color
            ]
        }
    }

    // MARK: - Game Logic
    private func flashTile(at index: Int) {
        guard isGameActive else { return }
        let shouldReduceMotion = UserDefaults.standard.bool(forKey: "Reduced Motion")
        let isHighContrast = UserDefaults.standard.bool(forKey: "High Contrast")
        let isDarkMode = UserDefaults.standard.bool(forKey: "Dark Mode")
        
        AudioServicesPlaySystemSound(1104)
        if UserDefaults.standard.bool(forKey: "Global Haptics") { hapticGenerator.impactOccurred() }
        
        let btn = tileButtons[index]
        let duration = shouldReduceMotion ? 0.0 : 0.3
        let scale: CGFloat = shouldReduceMotion ? 1.0 : 0.9
        
        let normalBorderColor = isHighContrast ? (isDarkMode ? UIColor.white.cgColor : UIColor.black.cgColor) : (isDarkMode ? UIColor.darkGray.cgColor : UIColor.white.cgColor)
        
        UIView.animate(withDuration: duration, animations: {
            btn.alpha = 0.3
            btn.transform = CGAffineTransform(scaleX: scale, y: scale)
            if isHighContrast { btn.layer.borderColor = UIColor.systemYellow.cgColor }
        }) { _ in
            UIView.animate(withDuration: duration) {
                btn.alpha = 1.0
                btn.transform = .identity
                btn.layer.borderColor = normalBorderColor
            }
        }
    }

    @objc private func startGame() { sequence.removeAll(); startButton.isHidden = true; startNewRound() }

    private func startNewRound() {
        if sequence.count == maxLevel { gameCompleted(); return }
        sequence.append(Int.random(in: 0..<6))
        inputIndex = 0; isPlayerTurn = false; statusLabel.text = "Watch..."
        playSequenceAnimation()
    }

    private func playSequenceAnimation() {
        view.isUserInteractionEnabled = false
        for (index, tileIndex) in sequence.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + (0.9 * Double(index) + 0.5)) {
                self.flashTile(at: tileIndex)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + (0.9 * Double(sequence.count) + 0.5)) {
            guard self.isGameActive else { return }
            self.view.isUserInteractionEnabled = true; self.isPlayerTurn = true
            self.statusLabel.text = "Your Turn! (Level \(self.sequence.count))"
        }
    }

    @objc private func tileTapped(_ sender: UIButton) {
        guard isPlayerTurn else { return }
        flashTile(at: sender.tag)
        if sender.tag == sequence[inputIndex] {
            inputIndex += 1
            if inputIndex == sequence.count {
                isPlayerTurn = false; statusLabel.text = "Excellent!"
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { self.startNewRound() }
            }
        } else { gameOver() }
    }

    private func gameCompleted() {
        AudioServicesPlaySystemSound(1025)
        let successView = CustomSuccessView(frame: view.bounds)
        successView.onFinish = { [weak self] in
            successView.removeFromSuperview()
            self?.navigationController?.popViewController(animated: true)
        }
        view.addSubview(successView)
        NSLayoutConstraint.activate([
            successView.topAnchor.constraint(equalTo: view.topAnchor),
            successView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            successView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            successView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func gameOver() {
        AudioServicesPlaySystemSound(1052)
        startButton.isHidden = false
        statusLabel.text = "Let's try again!"
    }
}
