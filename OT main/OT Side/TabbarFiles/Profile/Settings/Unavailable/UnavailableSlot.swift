//
//  UnavailableSlot.swift
//  OT main
//
//  Created by Garvit Pareek on 17/01/2026.
//


//
//  AvailabilityViewController.swift
//  OT main
//
//  Created by Alishri Poddar
//





import UIKit

struct UnavailableSlot {
    let id = UUID()
    var fromDate: Date
    var toDate: Date
}

class AvailabilityViewController: UIViewController {

    static var savedSlots: [UnavailableSlot] = []

    private let backgroundView: GradientView = {
        let view = GradientView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Dynamic Card Color
    private lazy var inputContainerView: UIView = {
        let v = UIView()
        v.backgroundColor = .otDynamicCard
        v.layer.cornerRadius = 12
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    // Dynamic Text Color
    private let fromLabel: UILabel = {
        let l = UILabel()
        l.text = "From"
        l.textColor = .otDynamicLabel
        l.font = .systemFont(ofSize: 17, weight: .regular)
        return l
    }()
    
    private let fromDatePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .date
        dp.preferredDatePickerStyle = .compact
        return dp
    }()
    
    private let toLabel: UILabel = {
        let l = UILabel()
        l.text = "To"
        l.textColor = .otDynamicLabel
        l.font = .systemFont(ofSize: 17, weight: .regular)
        return l
    }()
    
    private let toDatePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .date
        dp.preferredDatePickerStyle = .compact
        return dp
    }()
    
    private lazy var addButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Add Date Range", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .systemBlue
        btn.layer.cornerRadius = 8
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(addSlotTapped), for: .touchUpInside)
        return btn
    }()
    
    private lazy var slotsTableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .clear
        tv.delegate = self
        tv.dataSource = self
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "SlotCell")
        return tv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        applyOTNavigationStyling(title: "Unavailability")
        
        let checkImage = UIImage(systemName: "checkmark")
        let saveButton = UIBarButtonItem(image: checkImage, style: .done, target: self, action: #selector(doneTapped))
        saveButton.tintColor = .white
        navigationItem.rightBarButtonItem = saveButton
    }
    
    private func setupUI() {
        view.addSubview(backgroundView)
        view.addSubview(inputContainerView)
        view.addSubview(addButton)
        view.addSubview(slotsTableView)
        
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            inputContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            inputContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            inputContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            inputContainerView.heightAnchor.constraint(equalToConstant: 110),
            
            addButton.topAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: 15),
            addButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 200),
            addButton.heightAnchor.constraint(equalToConstant: 44),
            
            slotsTableView.topAnchor.constraint(equalTo: addButton.bottomAnchor, constant: 10),
            slotsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            slotsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            slotsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        setupInputStack()
    }
    
    private func setupInputStack() {
        let fromStack = UIStackView(arrangedSubviews: [fromLabel, fromDatePicker])
        fromStack.axis = .horizontal
        fromStack.distribution = .equalSpacing
        
        let toStack = UIStackView(arrangedSubviews: [toLabel, toDatePicker])
        toStack.axis = .horizontal
        toStack.distribution = .equalSpacing
        
        let mainStack = UIStackView(arrangedSubviews: [fromStack, toStack])
        mainStack.axis = .vertical
        mainStack.spacing = 15
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        inputContainerView.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            mainStack.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -16)
        ])
    }
    
    @objc func addSlotTapped() {
        let newSlot = UnavailableSlot(fromDate: fromDatePicker.date, toDate: toDatePicker.date)
        AvailabilityViewController.savedSlots.append(newSlot)
        slotsTableView.reloadData()
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    @objc func doneTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

extension AvailabilityViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AvailabilityViewController.savedSlots.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if AvailabilityViewController.savedSlots.isEmpty { return nil }
        return "Unavailable Periods"
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textColor = .white
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SlotCell", for: indexPath)
        let slot = AvailabilityViewController.savedSlots[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = "\(formatDate(slot.fromDate))  →  \(formatDate(slot.toDate))"
        content.textProperties.color = .otDynamicLabel // Unique OT Label Color
        content.secondaryText = "Tap to edit • Swipe to delete"
        content.secondaryTextProperties.color = .secondaryLabel
        
        cell.contentConfiguration = content
        
        // --- KEY FIX FOR DARK MODE ---
        // This ensures the cell background turns dark grey
        cell.backgroundColor = .otDynamicCard
        
        cell.selectionStyle = .default
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let slot = AvailabilityViewController.savedSlots[indexPath.row]
        fromDatePicker.date = slot.fromDate
        toDatePicker.date = slot.toDate
        AvailabilityViewController.savedSlots.remove(at: indexPath.row)
        slotsTableView.deleteRows(at: [indexPath], with: .automatic)
        let alert = UIAlertController(title: "Edit Mode", message: "Dates loaded above. Adjust them and click 'Add' to save changes.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            AvailabilityViewController.savedSlots.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
