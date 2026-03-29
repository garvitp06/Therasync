//
//  Assignment.swift
//  OT main
//
//  Created by Garvit Pareek on 19/01/2026.
//


import Foundation

struct AssignmentSubmission: Codable {
    let id: UUID
    let assignment_id: UUID
    let patient_id: String
    let answers: [String]
    let video_url: String?
    var submitted_at: Date?
    let score: Int?
    let remarks: String?

    enum CodingKeys: String, CodingKey {
        case id, answers, score, remarks
        case assignment_id = "assignment_id"
        case patient_id = "patient_id"
        case video_url = "video_url"
        case submitted_at = "submitted_at"
    }
}
struct Assignment: Codable {
    var id: UUID? = nil
    let title: String
    let instruction: String
    let dueDate: Date
    let type: String
    var quizQuestions: [String] = []
    var attachmentUrls: [String] = []
    var patient_id: String?
    var videoUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, instruction, type, patient_id
        case dueDate = "due_date"
        case quizQuestions = "quiz_questions"
        case attachmentUrls = "attachment_urls"
        case videoUrl = "video_url"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: dueDate)
    }
}
