import UIKit

final class ConditionViewController: UIViewController {

    // MARK: - Tab Bar Hiding Fix
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.hidesBottomBarWhenPushed = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let textView: UITextView = {
        let tv = UITextView()
        tv.isEditable = false
        tv.alwaysBounceVertical = true
        tv.font = .systemFont(ofSize: 16, weight: .regular)
        tv.backgroundColor = .white
        tv.textColor = .darkGray 
        tv.textAlignment = .justified
        tv.layoutManager.hyphenationFactor = 1.0
        tv.showsVerticalScrollIndicator = true
        tv.textContainerInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.isScrollEnabled = false
        return tv
    }()

    // MARK: - Lifecycle
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.isScrollEnabled = true
        textView.setContentOffset(.zero, animated: false) // Force jump to top
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupGradientBackground()
        setupNavBar()
        setupLayout()
        
        textView.text = loadTextFile(named: "termsandcondition")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Setup
    private func setupGradientBackground() {
        let gradientView = GradientView(frame: view.bounds)
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

    private func setupNavBar() {
        title = "Terms & Conditions"
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        let back = UIBarButtonItem(image: UIImage(systemName: "chevron.left"),
                                 style: .plain,
                                 target: self,
                                 action: #selector(backTapped))
        back.tintColor = .black
        navigationItem.leftBarButtonItem = back
    }

    private func setupLayout() {
        view.addSubview(textView)
        
        let guide = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: guide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    private func loadTextFile(named name: String) -> String {
        if let filepath = Bundle.main.path(forResource: name, ofType: "txt") {
            do {
                return try String(contentsOfFile: filepath)
            } catch {
                return "Terms & Conditions information could not be loaded."
            }
        } else {
            return """
            TERMS AND CONDITIONS
            
            Welcome to TheraSync. By accessing our services, you agree to comply with and be bound by the following terms and conditions of use. 
            
            1. User Agreement: You agree to provide accurate data regarding therapist activities and patient progress.
            
            2. Privacy: All student data is handled according to our strict encryption protocols to ensure safety and confidentiality.
            
            3. Responsibility: The app is a tool to assist therapy and does not replace professional medical judgment.
            
            (Text file 'termsandcondition.txt' not found)
            """
        }
    }
}
