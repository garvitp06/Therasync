//
//  MessageModel.swift
//  OT main
//
//  Created by Garvit Pareek on 19/01/2026.

import Foundation
import FirebaseFirestore

struct MessageModel {
    let id: String
    let senderId: String
    let receiverId: String
    let content: String
    let date: Date
    
    // Helper to check if the message was sent by the current user
    func isIncoming(myUserId: String) -> Bool {
        return senderId != myUserId
    }
}
