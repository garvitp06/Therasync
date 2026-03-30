import UIKit

final class ParentAboutUsViewController: UIViewController {

    // MARK: - Initializer
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.hidesBottomBarWhenPushed = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Components
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .dynamicCard
        view.layer.cornerRadius = 24
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.12
        view.layer.shadowOffset = CGSize(width: 0, height: 8)
        view.layer.shadowRadius = 15
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let textView: UITextView = {
        let tv = UITextView()
        tv.isEditable = false
        tv.alwaysBounceVertical = true
        tv.font = .systemFont(ofSize: 17, weight: .regular)
        tv.backgroundColor = .clear
        tv.textColor = .dynamicLabel
        tv.textAlignment = .justified
        tv.layoutManager.hyphenationFactor = 1.0
        tv.showsVerticalScrollIndicator = true
        tv.textContainerInset = UIEdgeInsets(top: 20, left: 15, bottom: 20, right: 15)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.isScrollEnabled = false // Initially false to handle lifecycle offset fix
        return tv
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientBackground()
        setupLayout()
        textView.text = loadTextFile(named: "aboutus")
        
        NotificationCenter.default.addObserver(self, selector: #selector(applyTheme), name: NSNotification.Name("AppThemeChanged"), object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 1. Show the bar for this detail screen
        navigationController?.setNavigationBarHidden(false, animated: animated)
        setupNavBar()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 2. Hide bar immediately as we leave to prevent Dashboard shift
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.isScrollEnabled = true
        textView.setContentOffset(.zero, animated: false)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Navigation & Theming
    private func setupNavBar() {
        self.title = "About Us"
        
        // Ensure standard centered title mode
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
        
        let isDark = UserDefaults.standard.bool(forKey: "Dark Mode")
        let color: UIColor = isDark ? .white : .black
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [
            .foregroundColor: color,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        
        // Custom Back Button to match color
        let back = UIBarButtonItem(image: UIImage(systemName: "chevron.left"),
                                 style: .plain,
                                 target: self,
                                 action: #selector(backTapped))
        back.tintColor = color
        navigationItem.leftBarButtonItem = back
    }

    @objc private func applyTheme() {
        setupNavBar()
    }

    // MARK: - Setup UI
    private func setupGradientBackground() {
        let gradientView = ParentGradientView(frame: view.bounds)
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gradientView)
        view.sendSubviewToBack(gradientView)
        
        NSLayoutConstraint.activate([
            gradientView.topAnchor.constraint(equalTo: view.topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupLayout() {
        view.addSubview(cardView)
        cardView.addSubview(textView)
        
        // FIXED: Using safeAreaLayoutGuide.topAnchor ensures the card sits below the bar
        let guide = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: guide.topAnchor, constant: 15),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cardView.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -30),

            textView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 5),
            textView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 5),
            textView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -5),
            textView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -5)
        ])
    }

    // MARK: - Logic
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    private func loadTextFile(named name: String) -> String {
        if let filepath = Bundle.main.path(forResource: name, ofType: "txt") {
            do {
                return try String(contentsOfFile: filepath)
            } catch {
                return "Information could not be loaded."
            }
        } else {
            return "Welcome to TheraSync. We provide specialized tools for Occupational Therapy. Our mission is to bridge the gap for students through data management and academic support. We empower therapists and parents with tools to track progress and enhance learning outcomes."
        }
    }
}
