import UIKit

protocol AddPatientDelegate: AnyObject {
    func didAddPatient(_ patient: Patient)
}

class addPatient: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    // MARK: - Delegate
    weak var delegate: AddPatientDelegate?
    
    // MARK: - Outlets
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    @IBOutlet weak var genderTextField: UITextField!
    @IBOutlet weak var bloodGroupTextField: UITextField!
    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var parentNameTextField: UITextField!
    @IBOutlet weak var parentContactTextField: UITextField!
    
    @IBOutlet weak var referredByTextField: UITextField!
    @IBOutlet weak var existingDiagnosisTextField: UITextField!
    @IBOutlet weak var existingMedicationTextField: UITextField!

    // MARK: - Properties
    let genderOptions = ["Male", "Female", "Non-binary", "Prefer not to say"]
    let genderPickerView = UIPickerView()
    
    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Add Patient"
        
        // Setup Input Views
        setupGenderPicker()
        
        // --- NEW: Set Keyboard to Number Pad ---
        parentContactTextField.keyboardType = .numberPad
        
        // Setup Navigation Bar Buttons
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(didTapClose))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(didTapSave))
    }

    // MARK: - Input Setup Helpers

    func setupGenderPicker() {
        genderTextField.inputView = genderPickerView
        genderPickerView.delegate = self
        genderPickerView.dataSource = self
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(pickerDoneTapped))
        toolbar.setItems([doneButton], animated: false)
        genderTextField.inputAccessoryView = toolbar
    }

    // MARK: - Actions

    @objc func didTapClose() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc func pickerDoneTapped() {
        if genderTextField.text?.isEmpty ?? true {
            genderTextField.text = genderOptions[genderPickerView.selectedRow(inComponent: 0)]
        }
        self.view.endEditing(true)
    }

    @objc func didTapSave() {
        
        // --- FORM VALIDATION ---
        
        guard let firstName = validateField(firstNameTextField, fieldName: "First Name") else { return }
        guard let lastName = validateField(lastNameTextField, fieldName: "Last Name") else { return }
        
        guard let gender = validateField(genderTextField, fieldName: "Gender") else { return }
        guard let bloodGroup = validateField(bloodGroupTextField, fieldName: "Blood Group") else { return }
        guard let address = validateField(addressTextField, fieldName: "Address") else { return }
        guard let parentName = validateField(parentNameTextField, fieldName: "Parent's Name") else { return }
        
        // 1. Basic empty check for Contact
        guard let parentContact = validateField(parentContactTextField, fieldName: "Parent's Contact No.") else { return }

        // 2. --- NEW: Exact 10 Digit Validation ---
        // Check if the string contains only numbers and is exactly 10 characters long
        if !CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: parentContact)) || parentContact.count != 10 {
            let alert = UIAlertController(title: "Invalid Number", message: "Parent's Contact No. must be exactly 10 digits.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        guard let referredBy = validateField(referredByTextField, fieldName: "Referred By") else { return }
        guard let diagnosis = validateField(existingDiagnosisTextField, fieldName: "Existing Diagnosis") else { return }
        guard let medication = validateField(existingMedicationTextField, fieldName: "Existing Medication") else { return }

        // --- ALL FIELDS VALID ---
            
            // --- UPDATE THIS LINE ---
            // Create the new Patient object with ALL fields
            let newPatient = Patient(
                firstName: firstName,
                lastName: lastName,
                gender: gender,
                dateOfBirth: datePicker.date,
                bloodGroup: bloodGroup,
                address: address,
                parentName: parentName,
                parentContact: parentContact,
                referredBy: referredBy,
                diagnosis: diagnosis,
                medication: medication
            )
            // Send it back to the list
            delegate?.didAddPatient(newPatient)
            
            // Dismiss
            self.dismiss(animated: true, completion: nil)
    }

    // MARK: - Validation Helper
    
    func validateField(_ textField: UITextField, fieldName: String) -> String? {
        guard let text = textField.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert(fieldName: fieldName)
            return nil
        }
        return text
    }
    
    func showAlert(fieldName: String) {
        let alert = UIAlertController(title: "Missing Information", message: "Please enter the \(fieldName).", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - UIPickerView DataSource & Delegate (Gender)
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return genderOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return genderOptions[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        genderTextField.text = genderOptions[row]
    }
}
