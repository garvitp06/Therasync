//
//  Appointment.swift
//  OT main
//
//  Created by user@54 on 19/01/26.
//


import Foundation

struct Appointment: Codable {
    var id: UUID?
    var title: String
    var date: Date
    var status: String
    var createdByRole: String
    
    // Database Links
    var patientId: UUID?
    var therapistId: UUID?
    var parentId: UUID? // This allows the parent to see it
    
    // Helper for joining data (Optional)
    var patient: Patient?
    
    enum CodingKeys: String, CodingKey {
        case id, title, date, status
        case createdByRole = "created_by_role"
        case patientId = "patient_id"
        case therapistId = "therapist_id"
        case parentId = "parent_id"
        case patient = "patients"
    }
}
