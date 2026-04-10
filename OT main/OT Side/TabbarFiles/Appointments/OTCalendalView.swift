//
//  OTCalendarView.swift
//  OT main
//
//  Created by user@54 on 27/11/25.
//

import UIKit

protocol OTCalendarViewDelegate: AnyObject {
    func didSelectDate(date: Date)
}

class OTCalendarView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    weak var delegate: OTCalendarViewDelegate?
    
    var appointmentDates: [Date] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    private var baseDate: Date = Date()
    private var selectedDate: Date = Date()
    private let calendar = Calendar.current
    private var days: [String] = []
    
    // UI Components
    private let monthLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
        label.text = "April 2025"
        return label
    }()
    
    private let prevButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        btn.tintColor = .systemBlue
        return btn
    }()
    
    private let nextButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        btn.tintColor = .systemBlue
        return btn
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.delegate = self
        cv.dataSource = self
        cv.register(CalendarDayCell.self, forCellWithReuseIdentifier: "DayCell")
        cv.isScrollEnabled = false
        return cv
    }()
    
    // Weekday headers
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.distribution = .fillEqually
        let days = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
        for day in days {
            let lbl = UILabel()
            lbl.text = day
            lbl.font = .systemFont(ofSize: 11, weight: .medium)
            lbl.textColor = .systemGray2
            lbl.textAlignment = .center
            stack.addArrangedSubview(lbl)
        }
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        updateCalendar()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 24
        layer.masksToBounds = true
        
        addSubview(monthLabel)
        addSubview(prevButton)
        addSubview(nextButton)
        addSubview(stackView)
        addSubview(collectionView)
        
        monthLabel.translatesAutoresizingMaskIntoConstraints = false
        prevButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            monthLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            monthLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            
            nextButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),
            nextButton.centerYAnchor.constraint(equalTo: monthLabel.centerYAnchor),
            
            prevButton.trailingAnchor.constraint(equalTo: nextButton.leadingAnchor, constant: -20),
            prevButton.centerYAnchor.constraint(equalTo: monthLabel.centerYAnchor),
            
            stackView.topAnchor.constraint(equalTo: monthLabel.bottomAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            
            collectionView.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 10),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])
        
        prevButton.addTarget(self, action: #selector(didTapPrev), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(didTapNext), for: .touchUpInside)
    }
    
    @objc private func didTapPrev() {
        baseDate = calendar.date(byAdding: .month, value: -1, to: baseDate) ?? baseDate
        updateCalendar()
    }
    
    @objc private func didTapNext() {
        baseDate = calendar.date(byAdding: .month, value: 1, to: baseDate) ?? baseDate
        updateCalendar()
    }
    
    private func updateCalendar() {
        let components = calendar.dateComponents([.year, .month], from: baseDate)
        guard let startOfMonth = calendar.date(from: components) else { return }
        
        // Update Title
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        monthLabel.text = formatter.string(from: baseDate)
        
        // Calculate days
        days.removeAll()
        
        let range = calendar.range(of: .day, in: .month, for: baseDate)!
        let firstDayWeekday = calendar.component(.weekday, from: startOfMonth)
        
        // Empty slots for days before start of month
        for _ in 1..<firstDayWeekday {
            days.append("")
        }
        
        for day in 1...range.count {
            days.append("\(day)")
        }
        
        collectionView.reloadData()
    }
    
    // MARK: - CollectionView
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return days.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DayCell", for: indexPath) as! CalendarDayCell
        let dayText = days[indexPath.item]
        cell.label.text = dayText
        
        // Logic to determine Today vs Selected
        if let d = Int(dayText) {
            let baseComp = calendar.dateComponents([.month, .year], from: baseDate)
            
            // 1. Check if it is "Today" (Real world date)
            let todayComp = calendar.dateComponents([.day, .month, .year], from: Date())
            let isToday = (d == todayComp.day && baseComp.month == todayComp.month && baseComp.year == todayComp.year)
            
            // 2. Check if it is "Selected" (User clicked date)
            let selectedComp = calendar.dateComponents([.day, .month, .year], from: selectedDate)
            let isSelected = (d == selectedComp.day && baseComp.month == selectedComp.month && baseComp.year == selectedComp.year)
            
            // 3. Check if there are any appointments on this date
            let hasAppointment = appointmentDates.contains { apptDate in
                let comp = calendar.dateComponents([.day, .month, .year], from: apptDate)
                return d == comp.day && baseComp.month == comp.month && baseComp.year == comp.year
            }
            
            cell.configure(isToday: isToday, isSelected: isSelected, hasAppointment: hasAppointment)
        } else {
            // Empty cell (padding)
            cell.configure(isToday: false, isSelected: false, hasAppointment: false)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let d = Int(days[indexPath.item]) else { return }
        
        var comps = calendar.dateComponents([.year, .month], from: baseDate)
        comps.day = d
        if let newDate = calendar.date(from: comps) {
            selectedDate = newDate
            delegate?.didSelectDate(date: newDate)
            collectionView.reloadData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width / 7
        return CGSize(width: width, height: 40)
    }
}

// MARK: - Updated Cell Class
class CalendarDayCell: UICollectionViewCell {
    
    let label: UILabel = {
        let lbl = UILabel()
        lbl.textAlignment = .center
        lbl.font = .systemFont(ofSize: 16)
        return lbl
    }()
    
    // The filled blue circle for SELECTED date
    private let selectionLayer: UIView = {
        let v = UIView()
        // Less opaque blue (Alpha 0.2)
        v.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
        v.layer.cornerRadius = 18
        v.isHidden = true
        return v
    }()
    
    // The outlined blue ring for TODAY'S date
    private let todayRing: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.layer.borderColor = UIColor.systemBlue.cgColor
        v.layer.borderWidth = 1.5
        v.layer.cornerRadius = 18
        v.isHidden = true
        return v
    }()
    
    // The colored dot indicating an appointment
    private let dotView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemOrange
        v.layer.cornerRadius = 2
        v.isHidden = true
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        // Order matters: selection behind, today ring on top/behind text
        contentView.addSubview(selectionLayer)
        contentView.addSubview(todayRing)
        contentView.addSubview(label)
        contentView.addSubview(dotView)
        
        selectionLayer.translatesAutoresizingMaskIntoConstraints = false
        todayRing.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        dotView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Center Selection Layer
            selectionLayer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            selectionLayer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            selectionLayer.widthAnchor.constraint(equalToConstant: 36),
            selectionLayer.heightAnchor.constraint(equalToConstant: 36),
            
            // Center Today Ring (Same size as selection)
            todayRing.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            todayRing.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            todayRing.widthAnchor.constraint(equalToConstant: 36),
            todayRing.heightAnchor.constraint(equalToConstant: 36),
            
            // Center Label
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            // Dot View
            dotView.centerXAnchor.constraint(equalTo: label.centerXAnchor),
            dotView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: -2),
            dotView.widthAnchor.constraint(equalToConstant: 4),
            dotView.heightAnchor.constraint(equalToConstant: 4)
        ])

        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
                self.todayRing.layer.borderColor = UIColor.systemBlue.resolvedColor(with: self.traitCollection).cgColor
            }
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    
    func configure(isToday: Bool, isSelected: Bool, hasAppointment: Bool) {
        // Toggle Views
        todayRing.isHidden = !isToday
        selectionLayer.isHidden = !isSelected
        dotView.isHidden = !hasAppointment
        
        // Logic for Text Color
        if isSelected {
            // Selected takes priority for text color (Bold Blue)
            label.textColor = .systemBlue
            label.font = .systemFont(ofSize: 16, weight: .bold)
        } else if isToday {
            // Today but not selected (Standard Blue)
            label.textColor = .systemBlue
            label.font = .systemFont(ofSize: 16, weight: .regular)
        } else {
            // Normal Day
            label.textColor = .label
            label.font = .systemFont(ofSize: 16, weight: .regular)
        }
    }
}
