//
//  AuthService.swift
//  OT main
//
//  Created by user@54 on 15/01/26.
//
//
//  AuthService.swift
//  OT main
//
//  Created by user@54 on 15/01/26.
//

import Supabase
import Foundation

// FIX: Define this OUTSIDE the class to avoid isolation issues
struct UserProfile: Decodable {
    let role: String?
}

final class AuthService: @unchecked Sendable {

    static let shared = AuthService()
    private let client = SupabaseClientProvider.shared.client

    private init() {}

    // REGISTER
    func register(
        email: String,
        password: String,
        userFields: [String: String]
    ) async throws {
        let jsonData = try JSONEncoder().encode(userFields)
        let supabaseMetaData = try JSONDecoder().decode([String: AnyJSON].self, from: jsonData)
        
        try await client.auth.signUp(
            email: email,
            password: password,
            data: supabaseMetaData
        )
    }

    // LOGIN
    func login(email: String, password: String) async throws {
        try await client.auth.signIn(
            email: email,
            password: password
        )
    }
    
    // FETCH ROLE
    func fetchUserRole() async throws -> String? {
        // 1. Get current user safely
        let user = try await client.auth.user()
        let userId = user.id
        
        // 2. Execute the query
        // We use 'client.database' to fix the "no member 'from'" error
        let response = try await client
            .from("profiles")
            .select("role")
            .eq("id", value: userId)
            .single()
            .execute() // <-- We stop here and get the raw response
        
        // 3. Manual Decode (Fixes the "Main actor-isolated" error)
        // We decode the raw data ourselves, which avoids the concurrency conflict.
        let decoder = JSONDecoder()
        let profile = try decoder.decode(UserProfile.self, from: response.data)
        
        return profile.role
    }
    
    func sendPasswordResetOTP(email: String) async throws {
            try await client.auth.resetPasswordForEmail(email)
    }
    
    func verifyRecoveryOTP(email: String, token: String) async throws {
            
        try await client.auth.verifyOTP(
                email: email,
                token: token,
                type: .recovery
        )
    }
    
    func updatePassword(newPassword: String) async throws {
            try await client.auth.update(user: UserAttributes(password: newPassword))
        }
    func verifyRegistration(email: String, token: String) async throws {
            try await client.auth.verifyOTP(
                email: email,
                token: token,
                type: .signup
            )
        }
}
