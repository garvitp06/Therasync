//
//  Notes.swift
//  OT main
//
//  Created by Garvit Pareek on 11/11/2025.
//

import UIKit

class Notes: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var notes: [String] = ["First Note", "Second Note", "Third Note"]
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // 1. Dequeue and safely cast to your custom class
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PatientCellIdentifier", for: indexPath) as? noteCardCell else {
            return UITableViewCell()
        }
        cell.noteLabel.text = notes[indexPath.row]
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        
        // 5. You need to return the cell
        return cell
    }
    
    
    @IBOutlet weak var notesTableView: UITableView!

    @objc func didTapCustomBack() {
        // If presented modally (like a sheet), use dismiss:
        self.dismiss(animated: true, completion: nil)
        
        // OR, if you need to manually pop the view:
        // self.navigationController?.popViewController(animated: true)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        notesTableView.delegate = self
        notesTableView.dataSource = self
        
        let nib = UINib(nibName: "noteCardCell", bundle: nil)
        notesTableView.register(nib, forCellReuseIdentifier: "PatientCellIdentifier")
        
        
        // 1. Setup Left Button (Close 'X')
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.backward"), // System back arrow icon
            style: .plain,
            target: self,
            action: #selector(didTapCustomBack)
        )
        navigationItem.leftBarButtonItem = backButton

        
        //right button
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add, // System checkmark icon
                target: self,
                action: #selector(didTapSave)
            )
            navigationItem.rightBarButtonItem = addButton
        
    }
    @objc func didTapSave() {
        self.dismiss(animated: true, completion: nil)
    }
    @objc func didTapClose() {
        // Dismisses the modal sheet
        self.dismiss(animated: true, completion: nil)
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
