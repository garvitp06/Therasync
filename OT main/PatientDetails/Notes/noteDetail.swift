//
//  noteDetail.swift
//  OT main
//
//  Created by Garvit Pareek on 12/11/2025.
//

import UIKit

class noteDetail: UIViewController {
    
    @IBOutlet weak var dateTitleLabel: UILabel!
    @IBOutlet weak var noteTextView: UITextView!
    override func viewDidLoad() {
        
        super.viewDidLoad()
                noteTextView.text = "Start typing your note here..."
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.backward"), // System back arrow icon
            style: .plain,
            target: self,
            action: #selector(didTapCustomBack)
        )
        navigationItem.leftBarButtonItem = backButton
        // Do any additional setup after loading the view.
    }
    @objc func didTapCustomBack() {
        // If pushed on a navigation stack, use pop:
        navigationController?.popViewController(animated: true)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // self.isMovingFromParent is true when the user taps the system Back button
        if self.isMovingFromParent {
            // When the view disappears, save the content of noteTextView.text
            print("Note content saved: \(noteTextView.text ?? "")")
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 1. Force the navigation bar to show
        navigationController?.setNavigationBarHidden(false, animated: animated)
        
        // 2. Reset the navigation bar to the default white/gray style
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .systemBlue // Or your app's main color
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
