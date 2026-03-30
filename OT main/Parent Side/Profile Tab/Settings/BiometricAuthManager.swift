//
//  BiometricAuthManager.swift
//  OT main
//
//  Created by Garvit Pareek on 20/12/2025.
//


import LocalAuthentication
import UIKit

class BiometricAuthManager {
    static let shared = BiometricAuthManager()
    
    func authenticateUser(completion: @escaping (Bool, String?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric authentication is available (FaceID, TouchID, or Passcode)
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Access parental settings."
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
                DispatchQueue.main.async {
                    if success {
                        completion(true, nil)
                    } else {
                        let message = authError?.localizedDescription ?? "Failed to authenticate."
                        completion(false, message)
                    }
                }
            }
        } else {
            completion(false, "Biometrics not available on this device.")
        }
    }
}