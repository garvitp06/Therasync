//
//  Question.swift
//  OT main
//
//  Created by Garvit Pareek on 30/01/2026.
//


import Foundation
struct Question {
    let id: Int
    let text: String
    let options: [String]
    var selectedOptionIndex: Int?
}

// MARK: - Shared Data Models

// 1. Log Model (Sending Data)
struct AssessmentLog: Codable {
    let patient_id: String
    let assessment_type: String
    let assessment_data: [String: AnyCodable]
}

/// A type-safe wrapper that handles dynamic JSON values (String, Int, Double, Bool, Array)
struct AnyCodable: Codable {
    let value: Any

    init(value: Any) {
        self.value = value
    }

    // Decoding: Converting Database JSON back to Swift types
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) { value = intVal }
        else if let strVal = try? container.decode(String.self) { value = strVal }
        else if let boolVal = try? container.decode(Bool.self) { value = boolVal }
        else if let doubleVal = try? container.decode(Double.self) { value = doubleVal }
        else if let arrayVal = try? container.decode([String].self) { value = arrayVal }
        else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable: Unsupported type")
        }
    }

    // Encoding: Converting Swift types to Database JSON
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let intVal = value as? Int { try container.encode(intVal) }
        else if let strVal = value as? String { try container.encode(strVal) }
        else if let boolVal = value as? Bool { try container.encode(boolVal) }
        else if let doubleVal = value as? Double { try container.encode(doubleVal) }
        else if let arrayVal = value as? [String] { try container.encode(arrayVal) }
        else {
            try container.encode(String(describing: value))
        }
    }
}

// 2. Response Model (Receiving Data)
struct AssessmentLogResponse: Decodable {
    let id: Int
    let assessment_type: String
    let assessment_data: AnyDecodable
    let created_at: Date
}

// 3. Helper for decoding dynamic JSON
struct AnyDecodable: Decodable {
    let value: Any
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) { value = intVal }
        else if let strVal = try? container.decode(String.self) { value = strVal }
        else if let boolVal = try? container.decode(Bool.self) { value = boolVal }
        else if let arrayVal = try? container.decode([String].self) { value = arrayVal }
        else if let dictVal = try? container.decode([String: String].self) { value = dictVal }
        else { value = "" }
    }
}
