//
//  for.swift
//  OT main
//
//  Created by Garvit Pareek on 19/01/2026.
//
import Foundation
// Unique struct for the UI side to avoid conflicts with AuthService
struct OTProfileDetails: Codable {
    let id: UUID
    let first_name: String?
    let last_name: String?
    let contact_no: String?
    let aiota_number: String?
    let degree: String?
    let experience: String?
    var avatar_url: String?
    
    var fullName: String {
        let first = first_name ?? ""
        let last = last_name ?? ""
        let combined = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
        return combined.isEmpty ? "OT Profile" : combined
    }
}
// Struct for sending updates
struct OTProfileUpdatePayload: Codable {
    let first_name: String
    let last_name: String
    let contact_no: String
    let aiota_number: String
    let degree: String
    let experience: String
    let avatar_url: String?
}
