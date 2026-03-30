//
//  Patient.swift
//  OT main
//
//  Created by user@54 on 27/11/25.
//

// Patient.swift
import Foundation

struct PatientModel: Codable, Equatable {
    var firstName: String
    var lastName: String
    var gender: String
    var dateOfBirth: Date
    var bloodGroup: String
    var address: String
    var parentName: String
    var parentContact: String
    var referredBy: String
    var diagnosis: String
    var medication: String

    // convenience computed age (years)
    var age: Int {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        return comps.year ?? 0
    }
}
