//
//  AuthError.swift
//  OT main
//
//  Created by user@54 on 15/01/26.

import Foundation

enum AuthError: LocalizedError {
    case invalidCredentials
    case userNotLoggedIn
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password."
        case .userNotLoggedIn:
            return "User not logged in."
        case .unknown(let message):
            return message
        }
    }
}
