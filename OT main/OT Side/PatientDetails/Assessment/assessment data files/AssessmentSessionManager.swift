//
//  AssessmentSessionManager.swift
//  OT main
//
//  Created by Garvit Pareek on 30/01/2026.
//

import Foundation

class AssessmentSessionManager {
    static let shared = AssessmentSessionManager()
    
    // We store data keyed by Patient ID
    private var patientSessions: [String: PatientSessionData] = [:]
    
    private init() {}
    
    struct PatientSessionData {
        var selectedAssessments: Set<String> = []
        var visitedAssessments: Set<String> = []
        var isSubmitted: Bool = false
        var testAnswers: [String: Any] = [:]
        
        // Medical History
        var medicalConditions: Set<String> = []
        var medicalNotes: String = ""
        var didFetchMedical: Bool = false
        
        // NEW: Birth History
        var birthHistoryData: [String: String] = [:]
        var didFetchBirthHistory: Bool = false
        
        // NEW: School Complaints
        var schoolComplaintsData: [String: String] = [:]
        var didFetchSchoolComplaints: Bool = false
    }
    
    // MARK: - General Getters
    
    func getSelectedAssessments(for patientID: String) -> Set<String> {
        return patientSessions[patientID]?.selectedAssessments ?? []
    }
    
    func getVisitedAssessments(for patientID: String) -> Set<String> {
        return patientSessions[patientID]?.visitedAssessments ?? []
    }
    
    func isSubmitted(for patientID: String) -> Bool {
        return patientSessions[patientID]?.isSubmitted ?? false
    }
    
    func getTestAnswers(for patientID: String) -> [String: Any] {
        return patientSessions[patientID]?.testAnswers ?? [:]
    }

    // MARK: - Medical History
    func getMedicalHistory(for patientID: String) -> (conditions: Set<String>, notes: String, didFetch: Bool) {
        let session = patientSessions[patientID]
        return (session?.medicalConditions ?? [], session?.medicalNotes ?? "", session?.didFetchMedical ?? false)
    }
    
    func updateMedicalHistory(for patientID: String, conditions: Set<String>, notes: String, didFetch: Bool = true) {
        ensureSessionExists(for: patientID)
        patientSessions[patientID]?.medicalConditions = conditions
        patientSessions[patientID]?.medicalNotes = notes
        patientSessions[patientID]?.didFetchMedical = didFetch
    }
    
    // MARK: - Birth History (NEW)
    func getBirthHistory(for patientID: String) -> (data: [String: String], didFetch: Bool) {
        let session = patientSessions[patientID]
        return (session?.birthHistoryData ?? [:], session?.didFetchBirthHistory ?? false)
    }
    
    func updateBirthHistory(for patientID: String, data: [String: String], didFetch: Bool = true) {
        ensureSessionExists(for: patientID)
        patientSessions[patientID]?.birthHistoryData = data
        patientSessions[patientID]?.didFetchBirthHistory = didFetch
    }
    
    // MARK: - School Complaints (NEW)
    func getSchoolComplaints(for patientID: String) -> (data: [String: String], didFetch: Bool) {
        let session = patientSessions[patientID]
        return (session?.schoolComplaintsData ?? [:], session?.didFetchSchoolComplaints ?? false)
    }
    
    func updateSchoolComplaints(for patientID: String, data: [String: String], didFetch: Bool = true) {
        ensureSessionExists(for: patientID)
        patientSessions[patientID]?.schoolComplaintsData = data
        patientSessions[patientID]?.didFetchSchoolComplaints = didFetch
    }
    
    // MARK: - General Setters
    
    func updateSelection(for patientID: String, selection: Set<String>) {
        ensureSessionExists(for: patientID)
        patientSessions[patientID]?.selectedAssessments = selection
    }
    
    func markAssessmentVisited(for patientID: String, assessmentName: String) {
        ensureSessionExists(for: patientID)
        patientSessions[patientID]?.visitedAssessments.insert(assessmentName)
    }
    
    func markAsSubmitted(for patientID: String) {
        ensureSessionExists(for: patientID)
        patientSessions[patientID]?.isSubmitted = true
    }
    
    func updateTestAnswer(for patientID: String, key: String, value: Any) {
        ensureSessionExists(for: patientID)
        patientSessions[patientID]?.testAnswers[key] = value
    }
    
    // MARK: - Helpers
    
    private func ensureSessionExists(for patientID: String) {
        if patientSessions[patientID] == nil {
            patientSessions[patientID] = PatientSessionData()
        }
    }
    
    func clearAllSessions() {
        patientSessions.removeAll()
    }
}
