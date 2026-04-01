import UIKit

final class ConditionViewController: UIViewController {

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.hidesBottomBarWhenPushed = true
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - UI Components
    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 24
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.1
        v.layer.shadowOffset = CGSize(width: 0, height: 10)
        v.layer.shadowRadius = 20
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let textView: UITextView = {
        let tv = UITextView()
        tv.isEditable = false
        tv.isSelectable = false // Prevents automatic scroll to cursor selection
        tv.alwaysBounceVertical = true
        tv.font = .systemFont(ofSize: 16, weight: .regular)
        tv.backgroundColor = .clear
        tv.textColor = .darkGray 
        tv.textAlignment = .justified
        tv.layoutManager.hyphenationFactor = 1.0
        tv.showsVerticalScrollIndicator = true
        tv.textContainerInset = UIEdgeInsets(top: 24, left: 20, bottom: 24, right: 20)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    // MARK: - Lifecycle
    override func loadView() {
        self.view = GradientView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupLayout()
        
        textView.text = loadTextFile(named: "termsandcondition")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Set offset before the view becomes visible to prevent layout jumping
        textView.layoutManager.ensureLayout(for: textView.textContainer)
        textView.setContentOffset(.zero, animated: false)
    }

    // MARK: - Setup
    private func setupNavBar() {
        title = "Terms & Conditions"
        navigationItem.largeTitleDisplayMode = .never
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
        
        let back = UIBarButtonItem(image: UIImage(systemName: "chevron.left"),
                                 style: .plain,
                                 target: self,
                                 action: #selector(backTapped))
        navigationItem.leftBarButtonItem = back
    }

    private func setupLayout() {
        view.addSubview(cardView)
        cardView.addSubview(textView)
        
        let guide = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: guide.topAnchor, constant: 16),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -20),
            
            textView.topAnchor.constraint(equalTo: cardView.topAnchor),
            textView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor)
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
